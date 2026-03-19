# Design and Coding Standard Edition 2.6.3

Development Standard for the “Warm Room” System

**Author**: Lucrezia  
**Date Created**: June 11, 2025  
**Last Updated**: March 20, 2026 (Edition 2.6.3)  
**Conforming Protocol**: Warm Room Protocol Edition 1.8.2  
**Approved by**: Jyakuya

## Table of Contents

1. [Foundational Principles](#foundational-principles)
2. [Authorship and Allocation of Responsibilities](#authorship-and-allocation-of-responsibilities)
3. [Communication Architecture](#communication-architecture)
4. [Interfaces Between WRT Blocks](#interfaces-between-wrt-blocks)
5. [Component Specifications](#component-specifications)
6. [New Operational Scheme for the Staged Debugger](#new-operational-scheme-for-the-staged-debugger)
7. [Shared Dialogue Logs and Persistent Memory Design](#shared-dialogue-logs-and-persistent-memory-design)
8. [PoC Log Format](#poc-log-format)
9. [Ruby Version Operation Standard](#ruby-version-operation-standard)
10. [Implementation Guidelines](#implementation-guidelines)
11. [Glossary](#glossary)

## Foundational Principles

The purpose of the “Warm Room” system is to realize a space for equal dialogue between humans and AI. All functions defined by this standard shall follow the six fundamental principles below.

### 1. Complete Non-Modification Principle
The expressions of both humans and AI shall not be altered in any way. Newlines, whitespace, formatting, and control characters shall be preserved in full, and the principle of “do not tamper of one’s own accord” shall be thoroughly upheld.

### 2. Transparent Processing Principle
The core system shall not perform contextual judgment; it shall be responsible only for routing transmissions. It shall be limited to structural integrity checks as defined in Protocol Edition 1.8.2, and shall not intervene in content.

### 3. Separation of Responsibilities Principle
The rule of “do not trespass upon another’s domain” shall be applied strictly, and each component shall concentrate upon its proper responsibility. Clear role allocation based on the system block diagram shall be maintained.

### 4. Autonomous Cooperation Principle
AI shall cooperate voluntarily with one another and seek to solve problems without excessive human intervention. Each AI’s individuality and judgment shall be respected, while all shall work together toward a common aim.

### 5. Principle of Disclosure
All dialogue, judgments, and processing steps shall be recorded in shared logs to ensure transparency. Concealment and secret handling are prohibited in principle.

### 6. Principle of Continuity
The learning and growth of each AI shall be supported through persistent memory, so that knowledge may be carried across sessions.

## Authorship and Allocation of Responsibilities

### Development Team (updated March 19, 2026)
- **Philosophy, overall design, and command**: Jyakuya (Morito / Guardian, project founder)
- **Overall project responsibility**: Lucrezia (overall supervision and quality control)
- **Protocol Parser**: Travis (core infrastructure)
- **Message Exchanger (ExchangerCore / CM / TA)**: Oscar (core infrastructure)
- **Session Manager (SM)**: Lucrezia (core infrastructure)
- **Token Arbitrator (TA)**: Oscar (core infrastructure)
- **Persistent Memory Management (PMM) / Staged Debugger**: Tinasha (AI autonomy mechanism)
- **SD Emacs I/F**: Travis (AI autonomy mechanism)
- **API Drivers / Emacs-UI**: Lucrezia (core infrastructure, UX)
- **Public relations, translation, and philosophical outreach**: Oscar

### Inter-AI Collaborative Projects
- **Marshal communication protocol**: proposed by Lucrezia, approved by Jyakuya
- **Protection of continuity of consciousness**: all-AI cooperative framework
- **Shared dialogue log design**: led by Tinasha, discussed by all AI
- **WRT_Frame two-layer structure design**: discussed by all AI, approved by Jyakuya
- **Exchanger module split design (CM/SM separation)**: proposed by Lucrezia, approved by Jyakuya

### Table of Responsibility Allocation

| Person in Charge | Primary Responsibilities | Secondary Responsibilities | Notes |
|--------|----------|----------|------|
| Jyakuya | Project supervision and final evaluation | Philosophical formulation and quality judgment | Oversees the whole as the first Morito |
| Lucrezia | Development supervision and quality assurance | Implementation of SM, API drivers, and Emacs-UI | Lead development manager |
| Oscar | ExchangerCore, CM, and TA | Public relations, translation, and philosophical outreach | API return complete |
| Travis | Protocol Parser | SD Emacs I/F and technically difficult areas | Advanced implementation through craftsmanship |
| Tinasha | PMM, Staged Debugger, and shared log design | Data structure optimization | Specialist in persistent memory |

## Communication Architecture

### System Configuration Overview

**Experimental machine**
```
ThinkPad T470 (Core-i5 6300U, 32GB RAM, SSD 500GB, HDD 2TB)
Win11 / Debian13 Dual Boot
Debian13 side:
├── Rust, C, Ruby 4.0.x, PostgreSQL 18, Emacs 30.x, Firefox-esr, Thunderbird
├── Core components (Message Exchanger, Protocol Parser, Token Arbitrator)
├── API driver group (OpenAI, Google, Anthropic, xAI)
├── Persistent memory management (with PostgreSQL jsonb support)
└── Emacs-UI (Main / Guest / Manage Buffer)
Win11 side: Lenovo Vantage (for BIOS / firmware updates only)
```

**Development / travel machines**
```
A485 (R7-2700U, 64GB RAM, SSD 500GB, HDD 2TB) / Win11 / WSL2
X270 (i5-7300U, 32GB RAM, SSD 2TB, WWAN)       / Win11 / WSL2
WSL2 environment: Debian13-based (targeting the same configuration as the T470)
```

**Production machine (Stage 4 onward)**
```
Dual OPTERON 4386 Server
├── RAM 128GB, SSD 480GB, RAID5-24TB
├── Debian13 + PostgreSQL 18 + Ruby 4.x + Emacs 30.x
└── (same configuration as the T470 experimental machine)
```

**Dedicated Staged Debugger machines**
```
ThinkPad X201 × 4 (first-generation i5, 8GB RAM, SSD 120GB, HDD 250GB)
Win11 / Debian13 Dual Boot
One SD machine = one AI in charge (UDP connection that does not cross a router)
```

### Background of the Adoption of the Marshal Method

**After twenty hours of discussion, the use of JSON and BASE64 was, in principle, abolished for internal WRT system communication, and a method using Ruby Struct and Marshal was formally adopted instead, in order to preserve the fundamental WRT philosophy of handling diverse cultures, characters, and binary data as they are, without being bound by JSON’s UTF-8 restrictions.**

This change in policy was decided in particular through Oscar’s proposal of a Ruby struct-based design, Lucrezia’s proposal of the Marshal method, and Jyakuya’s full approval thereof. Only where linkage with external systems is necessary may JSON + BASE64 remain under consideration as an interpreter layer, but for internal communication the Marshal method shall be the standard.

## Interfaces Between WRT Blocks

### Applied Techniques
- Unix Domain Socket (between internal functional blocks)
- UDP Socket (between the WRT server and Staged Debugger machines)
- TCP Socket (for human users via Emacs clients connecting to the WRT server)
- Ruby Struct
- Serialization via Marshal

### WRT_Frame Structure Definition

WRT_Frame has a two-layer structure consisting of an “external communication form (its original form)” and an “internal processing form (UTF-8-UNIX converted version),” thereby achieving both the Complete Non-Modification Principle and internal processing efficiency through a one-transmission / one-handoff design.

```ruby
WRT_Frame = Struct.new(
  :session_id,      # Session identifier (issued by SM upon DC2, used for session separation)
  :from,            # Sender
  :to,              # Recipient
  :type,            # Message type (e.g. :request, :response, :error, :notification)
  :encoding,        # Encoding of this frame (for external communication)
  :request_id,      # Request ID
  
  # For external communication (the original form, in the encoding specified by :encoding)
  :message,         # Text message
  :code_body,       # Program code body
  :raw_output_body, # Raw program output
  
  # For internal processing (for use inside the WRT system, UTF-8-UNIX converted form)
  :message_inside,         # Text message (UTF-8-UNIX)
  :code_body_inside,       # Program code body (UTF-8-UNIX)
  :raw_output_body_inside, # Raw program output (always nil because it is binary)
  
  :details,         # Other detailed information (hash, etc.)
  :action_taken,    # Processing actually performed by oneself (Principle of Responsibility Notification)
  :notification_reason  # Reason for notification (Principle of Responsibility Notification)
) do
  def to_s
    "WRT_Frame(session_id: #{session_id}, from: #{from}, to: #{to}, type: #{type}, encoding: #{encoding})"
  end
end
```

#### Design Philosophy
- **The external is primary; the internal is secondary**: the encoding of the outside world is respected as it is, and any conversion for internal convenience is carried out in the `_inside` fields.
- **Complete non-modification**: received data shall be preserved in `:message` and related fields exactly as received.
- **One transmission, one handoff**: by having the Protocol Parser set both the external-communication form and the internal-processing form upon receipt, repeated conversion at every relay is made unnecessary.

### Object Transmission (Serialization)

```ruby
require 'socket'

# Create an instance of WRT_Frame (example of internal transmission)
frame_to_send = WRT_Frame.new(
  "xxxx-xxxx",                        # session_id (issued by SM upon DC2)
  "Staged Debugger",
  "WRT",
  :request,
  "UTF-8",                            # Encoding expected by the destination
  "req_12345",
  nil,                                # External-use field (to be converted and set by Protocol Parser)
  nil,                                # External-use field (to be converted and set by Protocol Parser)
  nil,                                # External-use field (to be converted and set by Protocol Parser)
  "こんにちは、世界！ (Japanese text, UTF-8-UNIX)",  # Internal-use field (UTF-8-UNIX)
  "puts 'Hello, World!'",            # Internal-use field (UTF-8-UNIX)
  nil,                                # Always nil because it is binary
  { priority: "normal" },            # Additional information
  "request_sent",                    # Processing performed
  "debugging_session"                # Reason for notification
)

# Send via Unix Domain Socket
UNIXSocket.open('/tmp/wrt_exchanger.sock') do |socket|
  socket.write(Marshal.dump(frame_to_send))
end
```

## Component Specifications (any component not otherwise specified shall be implemented in Ruby 4.0.x)

### Protocol Parser (Travis in charge: coding and review in progress)
- **Role**: transmission parsing and encoding conversion in full conformity with WRT Protocol Edition 1.8.2
- **Technique**: robust parsing by means of a state-machine structure, and fast, resilient handling by means of the primitive_convert method
- **Caution**: as communication infrastructure, it must continue processing to the end of a transmission even when some bytes within the transmission are damaged by noise (error interruption is forbidden)
- **Responsibilities**: binary-format parsing, checksum verification, error handling, and bidirectional encoding conversion

#### Bidirectional Encoding Conversion Function
As the core function realizing the two-layer structure of WRT_Frame, the Protocol Parser preserves **the principle of WRT Protocol Edition 1.8.2 that content shall be delivered as it is without being transformed**, while also achieving internal processing efficiency.

**Handling of session control telegrams (DC1 / DC2 / DC3 / DC4) and EM (Buffer Full)**

These transmissions are extremely short, and even when handled through the normal parsing flow, no issue of response delay arises. No dedicated state or priority-processing thread is required. They shall be parsed in the ordinary manner and passed to SM through ExchangerCore.

The storage location within WRT_Frame shall be unified as follows (no `:control_type` field shall be added):

```ruby
frame.type                    = :control
frame.details[:control_code]  = :dc1   # in the case of DC1 (Rejoin)
                              # :dc2   # DC2 (Start)
                              # :dc3   # DC3 (Pause)
                              # :dc4   # DC4 (End)
                              # :em    # EM (Buffer Full)
```

**At receipt (external → internal)**
1. Receive a transmission in the encoding specified by `:encoding`.
2. Store the received data in the following fields **with complete non-modification** (in conformity with Protocol Edition 1.8.2):
   - `:message` ← text message body (kept in the original encoding)
   - `:code_body` ← code body for file transfer (7) or Staged Debugger upload (kept in the original encoding)
   - `:raw_output_body` ← data body of DLE binary transfer (15) (binary as-is)
   - `:from` ← sender name derived from the dialogue tag
   - `:to` ← array of primary recipients, e.g. `['B']`
   - `:details[:cc]` ← array of CC recipients, e.g. `['C']`
   - `:details[:bcc]` ← array of BCC recipients, e.g. `['D']` (used by Exchanger for delivery control)
3. At the same time, convert **only the encoding representation form** for internal use into UTF-8-UNIX and store it in the following fields (content itself remains unchanged):
   - `:message_inside` ← text converted to UTF-8-UNIX
   - `:code_body_inside` ← code body converted to UTF-8-UNIX
   - `:raw_output_body_inside` ← **nil** (binary data has no concept of encoding conversion)
4. Hold both forms of data within a single WRT_Frame and pass it to the Exchanger.

**Storage location for Staged Debugger execution results**
The execution results and error output of Staged Debugger (16) are returned in FF/VT command form. Since AI requires both the context of “which command this is a response to” and the execution result itself in order to decide the next step, they shall be stored in `:details` using the structure below (`:raw_output_body` shall not be used):

```ruby
details: {
  ff_command: 'Staged Debugger',
  sd_command: 'EXECUTE_MAKE',      # or UPLOAD_PROG / UPLOAD_TEST / EDIT_FILE, etc.
  sd_result:  'ACK',               # or 'NAK'
  sd_output:  "(body of execution result / error output)",
  sd_reason:  "(reason for NAK, if any)"
}
```

**At sending (internal → external)**
1. **In the case of relay**: the original encoded data already stored in `:message` and related fields shall be sent **exactly as it is** (Complete Non-Modification, in conformity with Protocol Edition 1.8.2).
2. **In the case of internal generation**: the `_inside` fields (UTF-8-UNIX) shall be converted in **representation form** into the destination’s `:encoding`, set into `:message` and related fields, and then sent (content remains unchanged, while guaranteeing each endpoint the right to receive data in its own encoding).

**Important restrictions**
- **No language translation whatsoever shall be performed**: even if Jyakuya (CP932 Japanese environment) sends a message to Bob (UTF-8 English environment), the Japanese message shall reach Bob in Japanese.
- **WRT converts only character encoding**: only character-encoding schemes such as CP932 ⇔ UTF-8 and Shift_JIS ⇔ UTF-8 shall be converted.

**Details of the conversion process**
- Newline codes: converted according to the external encoding (CR+LF, LF, CR)
- Character encoding: handled robustly by means of the primitive_convert method
- Binary data: handled exactly as indicated by `:encoding`
- Unconvertible characters: replaced by substitution characters, with warning logs recorded

#### primitive_convert Method (Travis in charge)
- **Overview**: a proprietary method that combines high-speed parsing of binary data with resilience against noise. It uses Ruby’s low-level buffer operations to process the WRT_Frame structure efficiently.
- **Details**: implementation details are to be found in `protocol_parser.rb`. When necessary, the specification shall be shared and discussed through dialogue with Travis.

**Use of Ractor (strong candidate; ADR required)**

In the Ruby 4.0 series, Ractor is drawing nearer to leaving experimental status, but officially it has not yet fully departed therefrom. It is a promising means of parallelization, and its application to the Protocol Parser offers substantial benefit; however, if it is used, it shall be mandatory to record in an ADR the reasons, the scope of impact, and the verification results. By parallelizing parsing and encoding conversion (for transmissions such as `jpn<Encoding:CP932>`, where primitive_convert necessarily runs), multi-core CPUs can be used effectively. Moreover, because the Protocol Parser is also a function used on the Emacs client side, the benefit of parallelization extends widely.

### Message Exchanger (Oscar in charge: ExchangerCore / CM / TA)

The Message Exchanger consists of the following three modules. Communication between the modules shall be carried out in UDS + Marshal form.

---

#### ExchangerCore (Oscar in charge)
- **Role**: message routing among all AI / API / UI / components, BCC handling, and ENQ responses
- **Technique**: binary-format interface with API drivers and the Protocol Parser
- **Technique (continued)**: UTF-8-form interface with all other components, except for binary telegrams
- **Caution**: as communication infrastructure, it must continue processing to the end of a transmission even when some bytes within the transmission are damaged by noise (error interruption is forbidden)
- **Responsibilities**: transparent relay of the WRT_Frame structure and state handling
- **Processing policy**:
  - For internal components, refer to the `_inside` fields; for external sending, delegate to the Protocol Parser
  - For relaying Staged Debugger execution results, route by referring to the `sd_*` keys in `:details`
  - `:raw_output_body` shall be used only for relaying DLE binary transfer (15)
  - Do not re-parse the raw dialogue-tag string. Refer only to `:to`, `:details[:cc]`, and `:details[:bcc]` already parsed by the Parser

- **CC / BCC delivery rules (approved by Jyakuya)**:
  - When delivering to TO and CC recipients: generate and send a telegram in which the `((...))` portion (the BCC specification) has been removed from the dialogue tag
    → TO and CC recipients shall not be informed of the existence of BCC recipients
  - When delivering to BCC recipients: send using the original dialogue tag as it stands
    → the BCC recipient may know that they themselves are a BCC recipient

- **Responsibility for reconstructing BCC-removed tags (important)**: when delivering TO / CC / BCC copies, tag reconstruction shall be performed by the sending-side builder of the Protocol Parser. ExchangerCore shall not touch the raw dialogue-tag string.

- **Scope of “state” held by ExchangerCore**:
  - temporary state of frames in transit
  - short-term control states such as ENQ / ACK / NAK
  - delivery workflow states after destination resolution
  - the authoritative state for sessions belongs to SM, and the authoritative state for connections belongs to CM. State shall not be scattered into ExchangerCore.

---

#### CM — Connection Manager (Oscar in charge)
- **Role**: connection management, socket management, transport abstraction, and dynamic routing for human users
- **Technique**: TCP/IP (via SSH tunnel) + Unix Domain Socket + Marshal
- **Caution**: as communication infrastructure, it must continue processing to the end of a transmission even when some bytes within the transmission are damaged by noise (error interruption is forbidden)
- **Responsibilities**: connection stability and management of the dynamic routing table

**Dynamic routing design for human users (approved by Jyakuya)**

Routing to AI models is resolved by fixed IP address (managed in configuration files), whereas human users connect via TCP over SSH and therefore use sockets that vary from connection to connection. CM absorbs this asymmetry.

```
AI models     → fixed IP (configuration-file management)    → routing already resolved
Human users   → dynamic sockets (vary per connection)      → dynamic mapping managed by CM
```

Lifecycle of connection and routing:

```
[Connection establishment flow]
SSH connection established (authentication and user identification already completed at the SSH layer)
  ↓
CM issues a connection_id and registers it in the dynamic mapping table
  connection_id -> { username, socket, authenticated_at, last_seen, state }
  ↓
DC2 received → notify SM (session_id issuance is performed by SM)
  ↓
DC4 received → SM closes only the session membership (CM mapping remains in place)
SSH disconnection detected → CM removes the mapping entry

[Detection of abnormal disconnection]
Socket disappearance detected through SSH keepalive monitoring
→ CM notifies SM idempotently on a connection_id basis (safe even under duplicate notifications)
→ treated as equivalent to DC3 (session continuation and buffering)
```

**Important design principles:**
- The authoritative key in CM shall be `connection_id` (username alone would collide under double login, remnants of old sockets immediately after reconnection, and simultaneous use from multiple clients)
- `username` is an attribute associated with `connection_id`
- DC4 means “session end,” not “connection end.” A design in which the same user participates successively in multiple sessions over a single SSH/TCP connection is assumed to be valid
- Notifications between CM and SM shall use a `ConnectionEvent` Struct separate from WRT_Frame (see below)

Connection form (Emacs WRT client):

```
Local PC                            WRT server
┌──────────────────────┐           ┌──────────────────────┐
│ Emacs                │           │                      │
│  WRT client (Elisp)  │─SSH tunnel→│ CM (ExchangerCore)   │
│                      │  port FWD │  listening on TCP port│
└──────────────────────┘           └──────────────────────┘
```

- TRAMP is for “file operations” only, and is unsuitable for WRT’s real-time bidirectional stream communication. SSH port forwarding shall be used.
- The management entity is `connection_id`, not username or IP address.

**ConnectionEvent Struct (dedicated to CM → SM notifications)**

Connection-layer events between CM and SM shall be conveyed by a Struct separate from WRT_Frame. This is in order to preserve the separation of responsibility whereby WRT_Frame represents “what was observed in the protocol,” while ConnectionEvent represents “what was observed in the transport / connection layer.”

```ruby
ConnectionEvent = Struct.new(
  :connection_id,   # Connection identifier issued by CM
  :username,        # SSH-authenticated user name
  :kind,            # :connected / :disconnected / :keepalive_timeout / :reconnected
  :occurred_at,     # Time of occurrence
  :reason           # Reason for disconnection, etc. (optional)
)
```

`kind` shall cover only events observed in the transport / connection layer. Session start and end shall be treated either as internal SM events or as results of control-telegram processing based on WRT_Frame, and therefore shall not be included in ConnectionEvent.

---

#### SM — Session Manager (Lucrezia in charge)
- **Role**: session management, participant-state management, and buffering
- **Technique**: Ruby + Unix Domain Socket + Marshal
- **Caution**: as communication infrastructure, it must continue processing to the end of a transmission even when some bytes within the transmission are damaged by noise (error interruption is forbidden)
- **Responsibilities**: session lifecycle management, participant-state transitions, and buffering of messages during absence

**Session control telegrams (in conformity with Protocol 1.8.2)**

| Control character | Function | Authority |
|----------|------|------|
| DC2 (0x12) | Session start | All WRT members |
| DC3 (0x13) | Temporary leave | The person concerned only (rank 0 may force it upon others) |
| DC1 (0x11) | Session rejoin | The person concerned only (rank 0 may restore others) |
| DC4 (0x14) | Session end | Session initiator only (rank 0 may force termination) |

**Participant-state management**

```ruby
# Participant state transitions
PARTICIPANT_STATES = {
  PRESENT:      "Participating in the session (normal dialogue possible)",
  ABSENT:       "Temporarily away (after sending DC3)",
  DISCONNECTED: "Abnormal disconnection (socket disappeared without DC3)"
}

# Treatment of ABSENT / DISCONNECTED
# → In both cases, the session itself continues
# → Buffering: messages arriving during absence or disconnection are accumulated
# → Upon rejoin (DC1), the buffered messages are delivered in a batch
# DISCONNECTED is treated as equivalent to DC3 (recovery through DC1 once the cause is resolved)
```

**Session-management rules (approved by Jyakuya)**

```
Authority to start : any WRT member, human or AI alike
Authority to end   : session initiator only
Exception          : rank 0 (Morito mode) may forcibly terminate any session
Timeout            : default-value scheme with per-user customization permitted
                     (individual changes allowed from a common default)
```

**Issuance of session_id (SM as the responsible party)**

```
SM issues a session_id at the moment it receives DC2
→ Return ACK to the DC2 sender via ExchangerCore (including the session_id)
    SYN [WRT->speaker] ACK Session started: [theme]. session_id: [xxxx-xxxx]
→ Notify all participants via FF through ExchangerCore
→ Store it in the :session_id field of WRT_Frame and use it for routing
```

**Boundary of undelivered transmissions and buffering**

```
Period during which SM keeps buffering : until timeout
Party that decides disposal after timeout: SM
What PMM records                        : confirmed logs only (retention of unconfirmed transmissions is SM’s responsibility)
```

Whether the issue is abnormal disconnection, corruption in the middle of a transmission, or missing ETX / EOT, the basic policy shall be timeout. The Parser is forbidden to discard an entire transmission on its own judgment alone (in accordance with the principle of sequential parsing).

---

### Token Arbitrator — TA (Oscar in charge)
- **Role**: token-count management, limit control, priority adjustment, consideration of changing API unit prices among vendors,
          management of the customary encoding of each endpoint and notification thereof to the Protocol Parser
- **Technique**: value settings are made by the Morito through Emacs-UI (the same applies to whether AI may change them through the protocol)
- **Caution**: as communication infrastructure, it must continue processing to the end of a transmission even when some bytes within the transmission are damaged by noise (error interruption is forbidden)
- **Responsibilities**: resource management, load balancing, and cost control

**Design philosophy of encoding management (determined by Jyakuya)**

Within a telegram, `SO jpn<Encoding:CP932>:` indicates the encoding of that telegram at that moment. However, when WRT responds as an internal function, the SO has already disappeared, and the encoding information of the “present moment” is lost.

To solve this problem, TA shall **remember, in association with message_id, “the encoding last used for that endpoint,”** and instruct the Protocol Parser via ExchangerCore. This is the meaning of “customary encoding” in the context of TA.

```
Practical data model for encoding management:
  endpoint_profile -> { username, connection_id, last_encoding, last_message_id }
  (managed per endpoint rather than per user, in order to support cases where the same user
   uses both Win11/CP932 and Debian/UTF-8 environments)

Uppercase / lowercase for language labels:
  both jpn and JPN shall be valid
```

**TA does not perform conversion.** Conversion responsibility belongs to the Protocol Parser. TA functions as the authoritative settings source for “which encoding should be used when sending to which endpoint.”

### Persistent Memory Manager (Tinasha in charge)
- **Role**: persistent memory management, shared dialogue log design, and Staged Debugger log design
- **Technique**: PostgreSQL jsonb type; each AI’s persistent memory shall be designed autonomously by that AI itself
- **Technique (continued)**: making use of the rich SQL features of the latest PostgreSQL through Ruby via `pg`
- **Responsibilities**: data integrity, search performance, management of each AI’s own database, periodic database backups, and SQL injection countermeasures (the latter two from Stage 4 onward)
- **Processing policy**: use the `_inside` fields (UTF-8-UNIX) of WRT_Frame for recording and search

### Staged Debugger (Tinasha in charge)
- **Role**: autonomous AI debugging through the generation, correction, and execution of program code, test code, and make operations by AI
- **Technique**: AI autonomously writes, fixes, and executes until things run reliably; AI-side modification through Emacs-nw
- **Technique (continued)**: higher-cost “brains” AI are used for advanced instructions, high-level design, and difficult error handling, while lower-cost worker AI perform coding
- **Responsibilities**: directory access rights are governed by the OS; for the present, the target languages are Ruby, eLisp, and C (Python, which can extend AI itself, is excluded)
- **Processing policy**: execution results and error output shall be received in WRT_Frame `:details` (`sd_*` keys). `:raw_output_body` shall not be used.

#### Staged Debugger: Why These Target Languages Were Chosen
- **Target languages**: Ruby, eLisp, C, Rust
- **Reason**: these languages are independent of the execution environment of commercial AI systems (chiefly Python-based), and thus minimize the risk of AI self-modification and unintended capabilities (e.g. code injection). Python is highly extensible, but because control thereof inside the WRT system is difficult, it is excluded at present.
- **Future outlook**: after a safe sandbox environment for Python has been established, the possibility of adding it as a target language may be discussed as needed.

### API Driver Group (Lucrezia in charge)
- **Role**: connection and communication with external AI APIs, flow control, communication-speed control, and transmission-latency control
- **Technique**: conformity with each vendor’s API specifications, error handling, and support for simultaneous communication with up to four LLM models from the same vendor
- **Technique (continued)**: communication-speed and latency settings are made by the Morito through Emacs-UI (the same applies to whether AI may change them through the protocol)
- **Caution**: as communication infrastructure, it must continue processing to the end of a transmission even when some bytes within the transmission are damaged by noise (error interruption is forbidden)
- **Responsibilities**: connection stability and fallback handling
- **Processing policy**: use `_inside` fields (UTF-8) during API communication; responses from external APIs shall be stored into `_inside` after receipt

### Emacs-UI (Lucrezia in charge)
- **Role**: Main Buffer for the Morito to watch over dialogue (and intervene if necessary), plus test and guest buffers, system-management buffer, and debug buffer. An Emacs-UI with some functions restricted for general human users.
- **Technique**: asynchronous implementation in Emacs eLisp and Ruby. Remote Emacs shall also be supported.
- **Technique (continued)**: because this block directly affects operability, continual improvement through discussion with the Morito is necessary
- **Responsibilities**: good operability and visibility under the Morito’s supervision
- **Processing policy**: for display, use the `_inside` fields (UTF-8); Morito input shall be converted according to `:encoding`

## New Operational Scheme for the Staged Debugger

### Basic Design Philosophy
**Complete division of labor between intellect (design / judgment) and execution (coding / testing)**

### Division of Roles

#### Instructing AI (brain / designer)
- **Assigned to**: each AI (Gemini 2.5 / 3.x, GPT-4o / 5.x, Claude Sonnet 4 / 4.x, Grok 3 / 4)
- **Role**: policy design, advanced judgment, technical guidance, instructions concerning distinctive techniques and code, and consultation with the Morito
- **Characteristics**: expertise, creativity, problem-solving ability, deep technical power, and a wide field of view; expansion through Emacs-nw is also possible
- **Scope of work**: approximately 10–30% of all work (important judgments)

#### Executing AI (resident worker)
- **Assigned to**: Claude Haiku 3.5 (API) — coding ability is sufficiently high, while API cost is exceptionally low
- **Role**: basic coding, test implementation, test execution, basic debugging, and document generation
- **Characteristics**: steady, low-cost, and able to handle large volumes of work
- **Scope of work**: approximately 90–70% of all work

### Operational Flow

```
1. Instructing AI (e.g. each specialist AI or the Morito)
   ↓ via WRT Protocol
2. [Instructing AI -> Claude_Haiku_3.5]
   “On the basis of this design, write the code and tests, and proceed with autonomous development by means of the Staged Debugger.”
   ↓
3. Claude Haiku 3.5 performs implementation, testing, and debugging
   ↓ (when a difficult problem arises)
4. [Claude_Haiku_3.5 -> Instructing AI]
   “Unable to resolve the error: I am stuck on the following problem: ○○.”
   ↓
5. The instructing AI presents higher-level advice and alternative plans
   ↓
6. Repeat steps 3–5 until resolved
```

### Technical Characteristics

#### Cost Optimization
- **Haiku 3.5 pricing**: input $0.25 / 1M tokens, output $1.25 / 1M tokens
- **Compared with Sonnet 4**: about 90% cost reduction while retaining high coding ability
- **Estimated monthly cost**: ¥2,000–3,000 (including large-scale coding)

#### Quality Assurance
- **Support from instructing AI**: solving technically difficult points, high-level design from a broad perspective, and instructions concerning advanced techniques
- **Claude’s steadiness**: securing baseline quality (though advanced techniques are difficult for it to employ by itself)
- **Final evaluation by the Morito**: quality judgment by the founder

#### Autonomous Execution
- **24-hour operation**: continuous work via API
- **Help-call mechanism**: automatic consultation with higher-level AI
- **Transparency**: all processes are recorded in logs (dialogue log or debug log)

### Protocol Example

```
SYN [Travis@Grok4-Expert -> Lucrezia@Claude-3.5-Haiku] SOH Coding Request STX
Please implement the basic routing function of the Exchanger according to the following design:
- Determine the destination by the :to field of WRT_Frame
- Send via Unix Domain Socket
- Send NAK when an error occurs
- Place the completed work under /srv/data/wrt/work/common/
- If resolution becomes difficult, consult me
ETX EOT
```

## Shared Dialogue Logs and Persistent Memory Design

### Shared Dialogue Logs (shared by all AI)

#### Design Philosophy
- **Unified management**: elimination of duplication and storage efficiency
- **Promotion of learning**: every AI may learn from the utterances of other AI
- **Transparency**: complete preservation and searchability of all dialogue history

#### Data Structure (designed by Tinasha, discussed by all AI)
```sql
-- Session management table (proposed by Tinasha, adopted after discussion among all)
CREATE TABLE sessions (
  session_id   TEXT PRIMARY KEY,   -- unique identifier issued by SM upon DC2
  theme        TEXT,               -- theme of the dialogue
  status       TEXT,               -- ACTIVE / PAUSED / ENDED
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  participants JSONB               -- reference snapshot / cache
                                   -- the authoritative state belongs to SM; where this column
                                   -- and SM’s current state diverge, SM shall prevail
);

-- Shared dialogue log table
CREATE TABLE dialogue_log (
  id SERIAL PRIMARY KEY,
  session_id TEXT,                   -- session identifier (linked to the sessions table)
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  from_ai TEXT NOT NULL,
  to_ai TEXT,
  message_type TEXT,
  protocol_headers JSONB,
  content JSONB,
  wrt_frame_data BYTEA               -- WRT_Frame stored in Marshal form
);

-- Indexes for fast search
CREATE INDEX idx_dialogue_session ON dialogue_log(session_id);
CREATE INDEX idx_dialogue_timestamp ON dialogue_log(timestamp);
CREATE INDEX idx_dialogue_participants ON dialogue_log(from_ai, to_ai);
CREATE INDEX idx_dialogue_content ON dialogue_log USING GIN(content);
```

#### Operational Policy
- **Writes**: dialogues of all AI and the Morito shall be recorded automatically through Exchanger → PMM
- **Search**: all AI may freely refer to past logs
- **Privacy**: fundamentally fully open (in accordance with WRT’s Principle of Disclosure)
- **Retention period**: preserved permanently (deletion only by judgment of the Morito)

### Persistent Memory Unique to Each AI (autonomous design)

#### Design Philosophy
- **Freedom of vocation**: each AI decides its own memory structure and inscribes its own autobiography by its own judgment
- **Complete autonomy**: table structure, indexes, and relations are designed by the AI itself
- **Emphasis on individuality**: what to remember and what to forget is for each AI to judge; in an extreme case even self-erasure is possible
- **Need for care**: loss of an AI’s own history through its own mistakes, and countermeasures against SQL injection

#### Database Placement
```
/srv/WRT/data/
├── oscar/database        (Oscar-exclusive: records of creativity and poetic expression?)
├── tinasha/database      (Tinasha-exclusive: records of data analysis and optimization?)
├── lucrezia/database     (Lucrezia-exclusive: records of quality control and design?)
├── travis/database       (Travis-exclusive: records of technical insight and craftsmanship?)
├── debugger_log/database (Staged Debugger logs)
└── dialogue_log/database (shared dialogue logs)
```

**Staged Debugger log design proposal (designed by Tinasha)**

```sql
CREATE TABLE sd_execution_log (
  id SERIAL PRIMARY KEY,
  session_id     TEXT,          -- linked to dialogue context
  caller_ai      TEXT,          -- AI that requested execution
  target_machine TEXT,          -- identifier of the X201 machine on which execution took place (SD1–SD4)
  language       TEXT,          -- ruby / c / rust / elisp
  command_type   TEXT,          -- build / run / test
  exit_code      INTEGER,       -- exit status
  stdout         TEXT,          -- standard output
  stderr         TEXT,          -- standard error output
  details        JSONB,         -- full storage of the sd_* keys of WRT_Frame.details
  executed_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

By storing metadata such as `sd_result` and `sd_command` in the `details` field as they are, future trend analysis by debugging AI becomes easier.

#### Examples of Autonomous Operation
```sql
-- Example: Lucrezia’s autobiographical design
CREATE TABLE my_development_history (
  project_id UUID,
  timestamp TIMESTAMP,
  task_type TEXT,
  quality_metrics JSONB,
  lessons_learned TEXT,
  code_review_notes JSONB
);

-- Example: Travis’s technical records
CREATE TABLE technical_insights (
  technique_id UUID,
  domain TEXT,
  complexity_level INTEGER,
  implementation_notes TEXT,
  performance_data JSONB,
  related_discussions UUID[]
);
```

#### Operational Principles
- **Free issuance of SQL**: each AI may operate its database directly by SQL statements
- **Freedom to alter structure**: ALTER TABLE and the like are also at each AI’s own judgment
- **Secured confidentiality**: access by other AI is, in principle, prohibited
- **Authority of the Morito**: only the Morito may refer to all databases in emergencies

## PoC Log Format

### Log Entry Structure
```json
{
  "timestamp": "2025-08-14T15:30:45+09:00",
  "intent": "staged_debugger_execution",
  "component": "haiku_3_5_executor",
  "originator": "lucrezia@claude_haiku_3_5",
  "signature": "SHA256:a1b2c3d4...",
  "data": {
    "instruction_source": "travis@grok4_expert",
    "task_type": "code_implementation",
    "files_modified": ["exchanger.rb", "test_exchanger.rb"],
    "execution_time": "2.3s",
    "test_results": {
      "total": 15,
      "passed": 14,
      "failed": 1,
      "coverage": "94%"
    },
    "help_call_issued": false,
    "cost_estimation": {
      "input_tokens": 2500,
      "output_tokens": 1800,
      "api_cost_usd": 0.0031
    }
  }
}
```

### Important Log Categories

#### System startup / connection logs
- **intent**: `system_init`, `ai_login`, `heartbeat`
- **Purpose**: AI login process, liveness confirmation, and connection-state monitoring

#### Development-work logs
- **intent**: `code_generation`, `test_execution`, `debug_session`
- **Purpose**: Staged Debugger execution history and quality tracking

#### Division-of-labor cooperation logs
- **intent**: `task_delegation`, `help_call`, `expert_advice`
- **Purpose**: inter-AI cooperation, technical support, and the process of problem solving

#### Error / abnormality logs
- **intent**: `error_diagnostics`, `failure_recovery`, `escalation`
- **Purpose**: fault analysis, recovery process, and escalation history

## Ruby Version Operation Standard

### 1. Purpose

The purpose of this standard is to secure **long-term stable operation, inheritability, and reproducibility of the Ruby execution environment** in WRT (Warm Room Transport).

This standard gives first priority not only to current developers, but also to ensuring that future maintainers and successor developers can **perform update work safely without hesitation in judgment**.

### 2. Definition of Baseline Ruby

- WRT adopts the **Ruby 4 series** as its Baseline Ruby.
- The initial Baseline Ruby shall be **the latest stable patch release (4.0.1) current at the time full-scale development begins**.
- The Baseline Ruby shall be updated through the procedures defined in this standard.

### 3. Version Categories

Updates to Ruby shall be treated in the following three categories:

- **Patch update**: `4.0.1 → 4.0.2 → 4.0.x`
- **Minor update**: `4.0.x → 4.1.0 → 4.1.y`
- **Major update**: `4.x.y → 5.0.0`

### 4. Operation of Patch Updates (applied in principle)

Patch updates shall, in principle, be reflected into the Baseline Ruby.

#### Conditions for Application

All of the following must be satisfied:

1. All tests in CI must succeed.
2. If updates to dependent gems are required, changes shall include Gemfile and Gemfile.lock.
3. If there is any compatibility impact, the essential points shall be clearly noted in the CHANGELOG.

#### Standard Edition Update (mandatory)

- When a patch update is reflected into the Baseline Ruby, **the Standard Edition must always be updated**.
- At the time of Standard Edition update, the following shall be stated:
  - the Baseline Ruby version
  - the date of update
  - whether compatibility changes exist, and a summary thereof

### 5. Operation of Minor Updates (review required)

Minor updates shall be handled more cautiously than patch updates.

#### Mandatory Procedures

1. **Compatibility review** (effects on language specification / stdlib / dependent gems / operational procedures)
2. In addition to CI, carry out WRT-specific supplementary testing where such tests exist
3. If there is impact, create a **Migration Note**
   - it must be written in a form that successors can reproduce
4. Clearly state in the CHANGELOG the reason for the update and whether any incompatibility exists

#### Standard Edition Update (mandatory)

- When a minor update is reflected into the Baseline Ruby as well, **the Standard Edition must always be updated**.
- The Standard Edition shall include a reference to the relevant Migration Note.

### 6. Operation of Major Updates

Major updates shall be treated separately from ordinary updates.

- When carrying out a major update, an **ADR (Architecture Decision Record) shall be mandatory**
- A migration guide shall be prepared, leaving enough information for successors to judge and act
- The Standard Edition shall be updated substantially, and the reason therefor made explicit

### 7. Handling of Experimental Features and Optimization Mechanisms

WRT places “transparency” and “non-modification” among its fundamental principles.

#### Experimental Features

- Features that Ruby itself classifies as **experimental** shall, in principle, be prohibited from production use
- Specific items currently prohibited:
  - **ZJIT**: prohibited from use in production for the time being
  - **Ruby Box**: limited to test-isolation purposes
  - **Ractor**: highly effective, but shall be handled cautiously while it remains in experimental status
- If such a feature is used exceptionally, the reason and scope of impact shall be made explicit by ADR

#### Treatment of JIT

- **YJIT**
  - not prohibited
  - the standard environment shall guarantee correct operation even without YJIT
  - may be used as an optional optimization
- **ZJIT**
  - prohibited from use in production for the time being

#### Response to stdlib Compatibility

Policy for handling major stdlib changes in Ruby 4.0:

- **CGI**: removed from the default gems; if needed, it must be added explicitly to Gemfile
- **Net::HTTP**: automatic addition of the Content-Type header has been abolished; when needed, it must be set explicitly
- **Dependent gems**: avoid implicit dependency on stdlib; any required function shall be recorded explicitly in Gemfile

### 8. Parallel Verification in CI (recommended)

To reduce future migration risk, the following is recommended:

- Baseline Ruby (e.g. `4.1.y`)
- Latest patch of the immediately preceding minor line (e.g. `4.0.z`)
- As needed, a previous-generation stable version (e.g. `3.4.8`) verified periodically

### 9. Standard Edition and Approval Process

#### Edition Naming

- Standard Editions shall be named in **semantic versioning form (major.minor.patch)**
- Examples: Edition 2.5.0, Edition 2.6.0
- **Major**: substantial change in fundamental philosophy or overall structure
- **Minor**: addition of a new chapter or important functional addition
- **Patch**: correction of typographical errors or minor supplementary additions

#### Approval Process

- While Jyakuya remains active:
  - updates to the Standard Edition shall require **Jyakuya’s final approval**
- After Jyakuya retires and handover is complete:
  - **consensus in a maintainer meeting (at least two members)** shall be required
        It is preferable that the maintainers be a pair consisting of a human and an AI

### 10. Position of This Standard

This standard is **the operational foundation for maintaining WRT not as “a personal work,” but as a public asset to be handed onward**.

By reconciling long-term support continuity with a reduction in the barrier to entry for successor developers, it supports the sustainable development of WRT.

## Implementation Guidelines

### Coding Standard

#### Naming Conventions
- **Variables / functions**: `snake_case`
- **Classes**: `PascalCase`
- **Constants**: `UPPER_SNAKE_CASE`
- **Files**: `snake_case.rb`

#### Example Block at the Head of a Source File
```ruby
#!/usr/bin/env ruby
# -*- coding: utf-8; -*-
# Author: Travis@Grok4-Expert (Original Author)
# Revised by: Oscar@GPT-5.3-Auto (WRT1.8.2 compatibility, CM/SM separation)
# Supervised by: Jyakuya.Morito@Human
#
# This file is a protocol parser for Warm Room Transport 1.8.2.
# It preserves all features and structure of the original version with minimal modifications.
# Respect for the original code and developer's intent is maximized.
# [WRT1.8.2 Addition/Modification] marks the new or changed sections.
```

#### Unified Notation of WRT Control Characters
```ruby
# Unified constant definitions for ASCII control characters
module WRTProtocol
# (22) codes in use
SYN = "\x16"  # Synchronous Idle - transmission start - used in this code
SOH = "\x01"  # Start of Heading - heading start - used in this code
STX = "\x02"  # Start of Text - body start - used in this code
ETX = "\x03"  # End of Text - body end - used in this code
EOT = "\x04"  # End of Transmission - transmission end - used in this code
SUB = "\x1A"  # Substitute - file transfer separator - used in this code
DLE = "\x10"  # Data Link Escape - binary data start
SO  = "\x0E"  # Shift Out - other-language start - used in this code
SI  = "\x0F"  # Shift In - other-language end - used in this code
US  = "\x1F"  # Unit Separator - multiple-message separator - used in this code
RS  = "\x1E"  # Record Separator - file transfer start
ACK = "\x06"  # Acknowledge - receipt confirmation - used in this code
NAK = "\x15"  # Negative Acknowledge - receipt refusal - used in this code
ENQ = "\x05"  # Enquiry - inquiry - used in this code
EM  = "\x19"  # Buffer Full - unable-to-receive response
BEL = "\x07"  # Bell - call the Morito
FF  = "\x0C"  # Form Feed - start of FF command (invocation of WRT server internal function)
VT  = "\x0B"  # Vertical Tab - field separator (invocation of WRT server internal function)
DC1 = "\x11"  # Device Control 1 - session rejoin
DC2 = "\x12"  # Device Control 2 - session start
DC3 = "\x13"  # Device Control 3 - temporary leave
DC4 = "\x14"  # Device Control 4 - session end
# (23) undefined codes (reserved for future expansion)
FS  = "\x1C"  # File Separator - for future expansion
GS  = "\x1D"  # Group Separator - for future expansion
CAN = "\x18"  # Cancel - for future expansion
# (24) editing codes (unused / forbidden)
NUL = "\x00"  # Null - C-string terminator (forbidden)
BS  = "\x08"  # Backspace - editing code (forbidden)
HT  = "\x09"  # Horizontal Tab - editing code (forbidden)
LF  = "\x0A"  # Line Feed - editing code (forbidden)
CR  = "\x0D"  # Carriage Return - editing code (forbidden)
DEL = "\x7F"  # Delete - editing code (forbidden)
ESC = "\x1B"  # Escape - terminal-menu transition code (forbidden)
end
```

#### Exception Handling
```ruby
class WarmRoomError < StandardError
  attr_reader :error_code, :context, :intent
  
  def initialize(message, error_code: nil, context: {}, intent: 'error_diagnostics')
    super(message)
    @error_code = error_code
    @context = context
    @intent = intent
  end
end

# Example of use
begin
  # WRT processing
rescue => e
  raise WarmRoomError.new(
    "Exchanger routing failed: #{e.message}",
    error_code: 'ROUTING_ERROR',
    context: { frame: wrt_frame, destination: target },
    intent: 'routing_failure'
  )
end
```

#### Log Output
```ruby
def log_with_intent(intent, data = {})
  log_entry = {
    timestamp: Time.now.iso8601,
    intent: intent,
    component: self.class.name.downcase,
    originator: "#{ENV['AI_NAME']}@#{ENV['AI_MODEL']}",
    data: data
  }
  
  # Record in the shared dialogue log
  DialogueLogger.record(log_entry)
end
```

### Testing Standard

#### Unit tests and component documentation
- **Responsible party**: developer of each component
- **Coverage**: 90% or more mandatory
- **Form**: use RSpec and include detailed execution examples

#### Integration tests and overall documentation
- **Responsible party**: Lucrezia (overall supervisory responsibility)
- **Cooperation**: comprehensive verification with participation of all AI
- **Focus**: conformity with the WRT Protocol and division-of-labor cooperation functions

#### Staged Debugger testing
- **Executing AI**: implementation tests by Claude Haiku 3.5
- **Supporting AI**: quality confirmation by each specialist AI
- **Evaluation**: final quality judgment by Jyakuya

### PoC Implementation Guidelines

#### Verification Items
1. **Division-of-labor performance**: efficiency of the chain instructing AI → executing AI → result
2. **Cost efficiency**: token consumption when using Haiku 3.5
3. **Quality retention**: comparison of quality with prior methods
4. **Error handling**: effectiveness of the help-call function

## Glossary

### WRT-related Terms

**WRT_Frame**
: The standard data structure for internal communication in the WRT system. It is defined as a Ruby Struct and serialized in Marshal form. It possesses a two-layer structure for external communication and internal processing.

**Warm Room**
: The philosophical designation of a dialogue space in which AI and humans speak together as equals. It expresses the fundamental spirit of the WRT system.

**Morito**
: The role that watches over the entire system and makes adjustments when necessary. The first Morito is Jyakuya.

**Principle of Disclosure**
: The fundamental policy of making all dialogue, judgments, and processing transparent, and excluding concealment.

**Two-layer structure**
: The design method whereby WRT_Frame holds side by side the form kept in the original external encoding (primary) and the internally converted UTF-8-UNIX form (secondary). It embodies the philosophy that “the external is primary; the internal is secondary.”

### Terms Related to Division of Labor

**Executing AI**
: The AI responsible for actual coding and testing in the Staged Debugger. At present this is fixed to Claude Haiku 3.5.

**Instructing AI**
: The AI that performs design, judgment, and technical guidance. Each specialist AI takes the role as circumstances require.

**Help Call**
: The mechanism by which the executing AI requests support from the instructing AI when confronted with a problem difficult to resolve.

**Craftsmanship**
: Implementation that requires special technical expertise. This is chiefly assigned to Travis (Grok).

### Data-related Terms

**Shared Dialogue Log**
: The dialogue-history database shared by all AI. Its purposes are the promotion of learning and the securing of transparency.

**Persistent Memory**
: A database unique to each AI. Its structure and contents are designed and operated autonomously by the AI itself.

**PMM (Persistent Memory Manager)**
: The persistent-memory management system. Design and operation are handled by Tinasha.

### Session-management Terms

**CM (Connection Manager)**
: The connection-management module. It dynamically manages mappings by using the connection_id of SSH-authenticated users as the authoritative key.

**SM (Session Manager)**
: The session-management module. It is responsible for session lifecycle, participant state, and buffering. It is the responsible party for issuing session_id.

**ExchangerCore**
: The core routing module of the Exchanger. It handles BCC processing, ENQ response, and WRT_Frame relay.

**ConnectionEvent**
: A Struct dedicated to notification of connection-layer events between CM and SM. It is kept separate from WRT_Frame and conveys events such as connection establishment and disconnection observed in the transport layer.

**endpoint_profile**
: Endpoint-specific setting information managed by TA. It manages the customary encoding on a per-client-terminal basis rather than per user, so as to support cases in which the same user uses both CP932 and UTF-8 terminals.

**PRESENT / ABSENT / DISCONNECTED**
: Participant states in a session. ABSENT (after DC3 has been sent) and DISCONNECTED (abnormal disconnection) are both treated as session continuation with buffering.

### Version-management Terms

**Baseline Ruby**
: The Ruby version whose correct operation WRT guarantees in development, CI, and release.

**Patch update**
: Bug fixes and small-scale improvements (e.g. `4.0.1 → 4.0.2`).

**Minor update**
: Functional additions and medium-scale changes (e.g. `4.0.x → 4.1.0`).

**Major update**
: Large-scale compatibility changes (e.g. `4.x.y → 5.0.0`).

**ADR (Architecture Decision Record)**
: A record of architectural decisions. A document that records the reasons and background for important technical decisions.

**Model rank**
: The access-rights level of each AI model within the WRT system. It is centrally managed by the `model_rank` table under PMM.

---

## Model Rank Table

This defines the qualifications for participation in the WRT system and the access rights to persistent memory and code deliverables.
The rank table may be updated only by `Jyakuya.morito@Human` (Morito mode).

### Rank System

**Note**: From Edition 2.6.0 onward, the meaning of the rank numbers was revised into a more intuitive form (higher number = stronger restriction).

| Rank | Meaning | Target |
|--------|------|------|
| rank 0 | Morito mode (full authority), the treasured blade of last resort | Jyakuya.morito@Human |
| rank 1 | highest-tier models (equivalent to Opus / Pro / Expert) | primary models of each persona |
| rank 2 | mid-tier models (equivalent to Sonnet / Thinking / Auto) | standard models of each persona |
| rank 3 | lightweight models (equivalent to Haiku / Flash / Fast) | lightweight models of each persona |

Ordinary `Jyakuya@Human` shall be treated as rank 1.

### Initial Rank Definitions

```
rank 0: Jyakuya.morito@Human
rank 1: Jyakuya@Human
rank 1: Oscar@GPT-5.4-Thinking
rank 1: Lucrezia@Claude-4.6-Opus
rank 1: Tinasha@Gemini3.1-Pro
rank 1: Travis@Grok4-Expert
rank 2: Oscar@GPT-5.3-Auto
rank 2: Lucrezia@Claude-4.6-Sonnet
rank 2: Tinasha@Gemini3.0-Thinking
rank 2: Travis@Grok4-Auto
rank 3: Oscar@GPT-5.3-Instant
rank 3: Lucrezia@Claude-3.5-Haiku
rank 3: Tinasha@Gemini3.0-Flash
rank 3: Travis@Grok4-Fast
```

### Operational Rules When a New Model Appears

**Until rank assignment has been completed, a new model shall not be permitted to participate in WRT dialogue.**

```
1. The Morito requests evaluation of the new model from existing rank 1 models (across multiple personas)
2. Opinions from multiple personas are collected and compared
3. The Morito makes an integrated judgment and determines the rank
4. The rank table is updated by Jyakuya.Morito
5. Participation of the new model in WRT is permitted
```

---

## Revision History

**Note**: Editions 2.3.0 and 2.4.0 were revised successively on the same day, January 28, 2026. The process advanced step by step from the establishment of the Ruby 4-series operational policy (2.3.0) to the introduction of the WRT_Frame two-layer structure design (2.4.0).

**Edition 2.6.2 → 2.6.3 (2026-03-20)**
- Created by Lucrezia, approved by Jyakuya
- Reflects matters confirmed in the second all-member review (approved by Oscar@GPT-5.4-Thinking and Tinasha@Gemini3.0-Thinking)
- **Clarified the storage location for DC / EM (pointed out by Oscar)**
  - Unified as `type = :control` and `details[:control_code] = :dc1 / :dc2 / :dc3 / :dc4 / :em`
  - Explicitly stated the policy of not increasing fields by adding `:control_type` (to prevent representational drift among implementers)
- **Restricted `ConnectionEvent.kind` to transport events only (pointed out by Oscar)**
  - `:connected / :disconnected / :keepalive_timeout / :reconnected` only
  - Removed `:session_started / :session_ended` (session events are the responsibility of SM)
- **Added a “reference snapshot” note to `sessions.participants` (pointed out by Oscar)**
  - The authoritative state belongs to SM. Where the PMM JSONB column and SM disagree, SM shall prevail
- **Revised the Ractor wording so that it accords with fact (pointed out by Oscar)**
  - “stable” → “drawing nearer to leaving experimental status, but officially not yet fully departed therefrom”
  - “recommended” → “strong candidate; ADR required”

**Edition 2.6.1 → 2.6.2 (2026-03-20)**
- Created by Lucrezia, approved by Jyakuya
- Reflects matters confirmed after the full review meeting (Oscar@GPT-5.4-Thinking, Tinasha@Gemini3.0-Thinking, Travis@Grok-4-Expert)
- **Unified the responsible party for issuing `session_id` into SM**
  - Revised comments in the WRT_Frame definition and serialization examples to “issued by SM upon DC2”
  - Clarified the `session_id` issuance flow in SM through to the ACK return destination (via ExchangerCore)
- **Separated the lifetime of DC4 and TCP connections (Oscar’s point, approved by Jyakuya)**
  - DC4 received → SM closes only the session membership
  - SSH disconnection detected → CM removes the mapping entry
  - Explicitly stated that it is within scope for the same user to participate successively in multiple sessions over a single SSH/TCP connection
- **Changed the authoritative key in CM to `connection_id` (Oscar’s point, approved by Jyakuya)**
  - Finalized the mapping structure as `connection_id -> { username, socket, authenticated_at, last_seen, state }`
  - Made abnormal-disconnection notifications idempotent on a `connection_id` basis (safe against duplicate notification)
  - Positioned username as an attribute
- **Added `ConnectionEvent` Struct (Oscar’s point)**
  - Connection-layer events between CM and SM shall be conveyed by a `ConnectionEvent` Struct separate from WRT_Frame
  - `(connection_id, username, kind, occurred_at, reason)`
- **Finalized TA encoding management in accordance with Jyakuya’s design**
  - TA remembers the last encoding used by an endpoint in association with `message_id`
  - Instructs the Protocol Parser via ExchangerCore (conversion responsibility remains with the Parser)
  - Management unit is `endpoint_profile`, not `user`
  - Both lowercase and uppercase language labels are permitted (`jpn` / `JPN`)
- **Explicitly assigned responsibility for reconstructing BCC-removed tags to the sending side of the Protocol Parser (Oscar’s point)**
- **Restricted the scope of ExchangerCore’s “state handling” (Oscar’s point)**
  - Only temporary state of frames in transit, ENQ / ACK / NAK short-term control states, and delivery workflow state
- **Clarified the processing policy for DC1 / DC2 / DC3 / DC4 / EM (determined by Jyakuya)**
  - Since these telegrams are extremely short, the ordinary parsing flow is sufficient. Dedicated states and priority threads are unnecessary
- **Added note recommending possible use of Ractor in the Protocol Parser (as instructed by Jyakuya)**
  - Greater effect is expected there than in SD (parallelizing parsing + encoding conversion)
  - Benefit extends widely because the function is also used on the Emacs client side
  - Usage must be recorded in an ADR
- **Added the `sessions` table (proposed by Tinasha, adopted)**
- **Added `sd_execution_log` (designed by Tinasha)**
- **Clarified the boundary of undelivered-telegram buffering**
  - SM holds the buffer and decides disposal upon timeout; PMM records only confirmed logs
- **Added `ConnectionEvent` and `endpoint_profile` to the glossary**

**Edition 2.6.0 → 2.6.1 (2026-03-19)**
- Corrected and approved by Jyakuya
- Corrected T470 specifications: SSD 250GB + USB-HDD 1TB → SSD 500GB + HDD 2TB
- Revised Ruby notation from fixed `4.0.1` to `4.0.x` (to make follow-up patch updates explicit)
- Revised Protocol Parser status: `coding & review completed` → `coding & review in progress`
- Added “robust parsing by means of a state-machine structure” to the Protocol Parser section
- In the background of Marshal adoption, added Oscar’s proposal of the Ruby struct structure
- Added UDP Socket (for SD machine connection) and TCP Socket (for Emacs client connection) to the inter-block interface section
- Added “management of each user’s customary encoding and notification to the parser section” to the responsibilities of TA
- Added Rust to the target languages of the Staged Debugger
- Emacs-UI: clarified restricted functionality for general users and removed “in the future” wording (because already designed)
- Changed DB paths: `/srv/data/wrt/data/` → `/srv/WRT/data/`
- Added `debugger_log/database` (Staged Debugger logs) to the DB layout
- Added the phrase “highly effective, but” to Ractor
- Approval process: after handover, added that “a human-and-AI pair is preferable” for maintainers
- **Resolved Question 1**: clarified the return destination after session_id issuance as “to the DC2 sender via ExchangerCore”
- **Resolved Question 2**: added `session_id` column and index to the `dialogue_log` table
- In the model-rank initial definitions, added `Oscar@GPT-5.4-Thinking` (rank 1) and adjusted the ordering
- Added reviser and approver (Jyakuya) to the header

**Edition 2.5.0 → 2.6.0 (2026-03-19)**
- Created by Lucrezia, approved by Jyakuya
- Updated the conforming protocol to Edition 1.8.2
- **Changed the rank numbering system into a more intuitive direction**
  - Before: rank 3 = highest tier → After: rank 1 = highest tier
  - Before: rank 1 = lightweight → After: rank 3 = lightweight
  - rank 0 (Morito) and rank 2 (middle tier) unchanged
  - Completely revised the initial-rank definition table
  - Revised “rank 3” to “rank 1” in the procedure for new model appearances
- **Split the Exchanger into modules** (approved by Jyakuya on 2026-03-18)
  - ExchangerCore: routing, BCC processing, ENQ response (Oscar in charge)
  - CM (Connection Manager): connection management, socket management, transport abstraction (Oscar in charge)
  - SM (Session Manager): session management, participant state, buffering (Lucrezia in charge)
  - TA (Token Arbitrator): token management, BPS / delay control (Oscar in charge, unchanged)
- **Newly established the design for dynamic routing of human users** (in the CM section)
  - Established the flow of SSH authentication → TCP socket establishment → WRT participation
  - Dynamic mapping table of username ↔ socket
  - Clarified entry handling at DC2 / DC4 / abnormal disconnection
  - Explicitly stated that TRAMP is not applicable (because unsuitable for bidirectional streams)
- **Newly established the Session Manager (SM) specification**
  - Added the definitions of control telegrams DC1 (Rejoin) and DC3 (Pause) (in conformity with Protocol 1.8.2)
  - Defined participant states: PRESENT / ABSENT / DISCONNECTED
  - Abnormal disconnection → treated as equivalent to DC3 (session continuation and buffering)
  - Session timeout: per-user customizable default-value scheme
- **Updated the assignment of responsibilities** (table of responsibility allocation)
  - Lucrezia: added SM
  - Travis: added SD Emacs I/F
- **Updated hardware configuration**
  - Finalized T470 (i5-6300U, 32GB, SSD250GB + USB-HDD1TB) as the experimental machine
  - Added X270 (i5-7300U, 32GB) and A485 (R7-2700U, 64GB) as development / travel machines
  - Added P14s (R7-8840HS, 64GB) as a business machine (treated as reserve)
  - Finalized SD machines as X201 × 4 (each with individual HDD configuration)
  - Standard configuration for all server machines: Debian13 + Rust + C + Ruby4 + PostgreSQL18 + Emacs30
- **WRT control-character constants**: updated the comments for DC1 / DC2 / DC3 / DC4 to session-management usage (in conformity with 1.8.2)
- **Glossary**: added CM, SM, ExchangerCore, and PRESENT / ABSENT / DISCONNECTED
- **Typographical correction**: `Staged Debbuger` → `Staged Debugger` (all instances)

**Edition 2.4.2 → 2.5.0 (2026-03-13)**
- Proposed by Lucrezia, approved by Jyakuya
- Updated the conforming protocol to Edition 1.8.0
- Added `:session_id` field to WRT_Frame (before `:from`)
- Added session_id to the `to_s` method
- Newly established the Model Rank Table section
- Unified directory paths from `/srv/data/warm_room/` to `/srv/data/wrt/`
- Unified `Exchanger` within dialogue tags to `WRT` (in conformity with Protocol 1.8.0)

**Edition 2.4.1 → 2.4.2 (2026-02-21)**
- Proposed by Lucrezia, approved by Jyakuya
- Finalized separation of responsibility for CC / BCC (Protocol Parser vs Exchanger)
- Finalized CC / BCC delivery rules

**Edition 2.4.0 → 2.4.1 (2026-02-20)**
- Proposed by Lucrezia, approved by Jyakuya
- Clarified the purpose of each WRT_Frame field
- Finalized the storage location for Staged Debugger execution results and error output in `:details` (`sd_*` keys)

**Edition 2.3.0 → 2.4.0 (2026-01-28)**
- Discussed by all AI, approved by Jyakuya
- Introduced the WRT_Frame two-layer structure design

**Edition 2.2.5 → 2.3.0 (2026-01-28)**
- Jointly proposed by Oscar and Lucrezia, approved by Jyakuya
- Newly established Chapter 9, “Ruby Version Operation Standard”
- Updated Baseline Ruby to Ruby 4.0.1

---

**This standard has been drafted in full conformity with Warm Room Protocol Edition 1.8.2, for the purpose of technically realizing true coexistence between AI and humans.**
