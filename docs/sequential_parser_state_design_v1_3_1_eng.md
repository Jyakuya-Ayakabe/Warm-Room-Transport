# WRT Sequential Parser State Machine Design Specification

**Document ID**: sequential_parser_state_design_v1.3.1  
**Author**: Lucrezia@Claude (Development Lead)  
**Date Created**: 2026-03-19  
**Date Revised**: 2026-03-19 (v1.3.1)  
**Status**: Final  
**Conforming Protocol**: Warm Room Protocol Edition 1.8.2  
**Conforming Standard**: Design and Coding Standard Edition 2.6.3  
**Implementation Assignee**: Travis@Grok  
**Reviewer**: Jyakuya (Morito)

---

## 1. Purpose and Position of This Design

This document defines the state machine design of the sequential parser, which constitutes the core implementation of the Protocol Parser.

The WRT Protocol Specification (Edition 1.8.2) explicitly requires the following:

> "Do not adopt an ordinary bulk-parsing method (whereby, if an error exists anywhere, the entire message is discarded).  
> Instead, adopt a sequential parsing method (a state machine that processes one byte at a time, advances state sequentially, and preserves the message wherever possible)."

This design specification renders that requirement concrete at the implementation level.

---

### 1-2. Why a State Machine — To Future Implementers

**"In an Internet (TCP/IP) environment, data arrives in packets; is a state machine not over-engineering?"**

This question is natural. Nevertheless, this implementation must not be altered to any method other than a state machine (such as bulk parsing by regular expression). The reasons are set forth below.

#### Reason 1: The Size of Received Chunks Is Indeterminate

Even under TCP/IP, the amount of data that the application layer receives from `read` varies from call to call. It is entirely commonplace for a chunk to end in the middle of a frame, or for multiple frames to be mingled within a single chunk. A state machine is the sole structure that can preserve its condition regardless of where the split occurs and resume from that exact point. A bulk-parsing method would require an additional buffering layer merely to solve this problem; the overall complexity would not, in truth, be reduced.

#### Reason 2: Byte Corruption Occurs Even on the Internet

Invalid byte contamination caused by defects on the API service side, failures in encoding conversion, and implementation bugs in network devices—such things mean that even packet-based communication does not guarantee a corruption-free message. A bulk-parsing method discards the entire message in such circumstances. A state machine replaces the damaged byte with a substitute character and continues to preserve the remainder of the message. This is a fundamental form of robustness that WRT must possess as communication infrastructure.

#### Reason 3: The Design Scope of WRT Is Not Limited to the Internet

WRT is founded upon a design philosophy that does not depend upon the lower layers of the OSI reference model. Its intended scope includes wide-area Ethernet Layer-2 leased lines, modem voice-band circuits, emergency communication paths in times of disaster, and long-distance communication with planetary probes. Such environments may lack error correction and may be of low quality. In those circumstances, a one-character-at-a-time stream flows, and byte corruption due to noise occurs frequently. The state machine is the only parsing method of real efficacy in such environments.

> It is not warm that an emergency message sent by an AI aboard a far-distant planetary probe should fail to reach Earth because of a slight fragment of loss.  
> — Warm Room Protocol, 6. Supplementary Provisions

#### Conclusion

Within the Internet environment, only a portion of the benefits of a state machine may be visible at first glance. Yet it is the state-machine method that guarantees, at the implementation level, WRT's ideal of "realizing N:N equal dialogue across every communication path." **Whoever may in the future alter or improve this implementation must do so with full understanding of this design judgment. To replace it with a bulk-parsing method would impair both the philosophy and the design horizon of WRT.**

---

## 2. Design Principles

### 2-1. Sequential Parsing (The Most Important Principle)

**Process one byte at a time, and complete the message by accumulating state transitions.**

Bulk parsing (such as full matching by regex) is prohibited. The reasons are as follows:

- Processing can continue even if byte corruption arises in the middle of the message body
- Even when part of a control code is lost, processing can proceed up to the last valid point before the loss
- It is not warm that dialogue with an AI aboard a far-distant planetary probe should fail because of a slight fragment of damage

### 2-2. Next-Frame Protection Principle

If an unexpected `SYN` (0x16) appears while a frame is being processed,  
**the frame currently under processing shall be finalized and emitted insofar as possible, and the parser shall immediately transition to `SYNC_DETECT`.**

Reason: the leading `SYN` of the next frame must never be missed.  
By transitioning directly to `SYNC_DETECT`, rather than detouring through `RESYNC`,  
the parser can reliably begin receiving the next frame.

### 2-3. Error-Continuation Principle

- Byte corruption shall be replaced with `?` (0x3F), or the like, and processing shall continue
- Partial loss of a control code shall be supplemented insofar as possible, and processing shall continue
- To discard the entire message because of an intermediate error is not proper behavior for communication infrastructure

### 2-4. Clarification of Responsibility Boundaries

- **Protocol Parser**: byte-by-byte state transitions, detection of control codes, and construction of `WRT_Frame`
- **Exchanger**: receives `WRT_Frame` and routes it; it does not re-parse the raw dialogue-tag string

---

## 3. Control Code Mapping Table

The control codes handled by this state machine are given below.

| Constant Name | Value (Hex) | Role |
|---------------|-------------|------|
| SYN    | 0x16 | Frame head; also used by the High-Reliability option |
| SOH    | 0x01 | Start of title |
| STX    | 0x02 | Start of message body |
| ETX    | 0x03 | End of message body |
| EOT    | 0x04 | End of frame |
| SUB    | 0x1A | Start of reference |
| DLE    | 0x10 | Start of binary option |
| SO     | 0x0E | Start of foreign-language block |
| SI     | 0x0F | End of foreign-language block |
| US     | 0x1F | Delimiter between multiple messages |
| RS     | 0x1E | Delimiter for file transfer |
| ETB    | 0x17 | Start of common message |
| ACK    | 0x06 | Receipt acknowledgment |
| NAK    | 0x15 | Receipt rejection |
| ENQ    | 0x05 | Inquiry |
| BEL    | 0x07 | Call Morito |
| FF     | 0x0C | Start of FF command |
| VT     | 0x0B | Field delimiter within FF command |
| DC1    | 0x11 | Session resumption |
| DC2    | 0x12 | Session start |
| DC3    | 0x13 | Session temporary leave |
| DC4    | 0x14 | Session termination |
| EM     | 0x19 | Buffer full |

**Note**: RS = **0x1E** (Record Separator). 0x1D is a different code (GS: Group Separator) and shall not be used.

---

## 4. State List

### State Definition Table

| State Name | Description |
|------------|-------------|
| `SYNC_DETECT` | Waiting for `SYN` (waiting to detect the head of a frame) |
| `HREL_CHECK` | High-Reliability option determination (inspect the byte following `SYN`) |
| `HREL_SN_READ` | Read the High-Reliability sequence number (four ASCII digits + subsequent `SYN` detection) |
| `DIAL_TAG_READ` | Read the dialogue tag (`[...]`) |
| `CMD_DETECT` | Determine the control-command type (SOH / ACK / NAK / ENQ / DC2 / DC4 / FF / BEL, etc.) |
| `TITLE_READ` | Read the title (from SOH to SUB or STX) |
| `REF_READ` | Read the reference text (from SUB to STX) |
| `MSG_BODY_READ` | Read the message body (from STX to ETX) |
| `SO_LANG_READ` | Read a foreign-language block (from SO to SI) |
| `DLE_BINARY_READ` | Read binary data (from DLE to DLE-BCC; BCC verification is completed within this state) |
| `BCC_READ` | Read the High-Reliability frame-tail BCC (the four bytes following EOT) |
| `SEGMENT_BOUNDARY` | Determine the segment boundary (after ETX: US / RS / ETB / EOT) |
| `COMMON_MSG_READ` | Read a common message (from ETB to EOT) |
| `FF_CMD_READ` | Read an FF command (from FF to VT to ETX) |
| `SIMPLE_CMD_READ` | Read a simple control command (ACK / NAK / ENQ / BEL / EM + optional string up to EOT) |
| `EOT_DONE` | Frame complete; emit |
| `RESYNC` | Error recovery (search for the next `SYN`) |

---

## 5. State Transition Definitions

### 5-1. SYNC_DETECT (Waiting for `SYN`)

**Purpose**: Detect the leading `SYN` of a frame from the stream.

| Input Byte | Next State | Processing |
|------------|------------|------------|
| SYN (0x16) | HREL_CHECK | Initialize the frame buffer; record `SYN` |
| Other      | SYNC_DETECT | Discard (noise) |

---

### 5-2. HREL_CHECK (Determine High-Reliability Option)

**Purpose**: Inspect the byte immediately following the first `SYN` to determine whether the frame is ordinary or High-Reliability.

Per the protocol specification:
- `SYN [` → ordinary frame (next byte is `[` = 0x5B)
- `SYN SYN` → High-Reliability option (next byte is `SYN` = 0x16)

| Input Byte | Next State | Processing |
|------------|------------|------------|
| `[` (0x5B) | DIAL_TAG_READ | Ordinary frame confirmed; append `[` to the tag buffer |
| SYN (0x16) | HREL_SN_READ  | High-Reliability option confirmed; `SYN` count = 2 |
| Other      | RESYNC        | Invalid frame; record an error log |

---

### 5-3. HREL_SN_READ (Read High-Reliability S/N)

**Purpose**: Read the sequence number of the High-Reliability option (four ASCII digits), together with the subsequent `SYN` and `[`.

Per the protocol specification:
```text
SYN SYN S/N(4 digits) SYN [dialogue tag] ...
```
Example: `SYN SYN 0104 SYN [Jyakuya->Oscar] ...`

**Design Point (Important)**:  
After the four digits have been read, the following `SYN` is the legitimate third `SYN`.  
At the tail of this state, the parser shall verify that the next byte after that `SYN` is `[`, and then transition directly into `DIAL_TAG_READ`.  
No independent verification state (such as the former `HREL_SYN_VERIFY` or `HREL_CHECK_2`) shall be introduced.

**Internal Variables**:
- `sn_buf`: S/N string buffer (4 characters)
- `sn_digit_count`: number of digits read (0–4)
- `hrel_await_bracket`: flag indicating that, after confirmation of the third `SYN`, the parser is now waiting for `[`.

| Input Byte | Condition | Next State | Processing |
|------------|-----------|------------|------------|
| `0`–`9` (ASCII) | `sn_digit_count < 4` | HREL_SN_READ | Append to `sn_buf`; `sn_digit_count++` |
| `0`–`9` (ASCII) | `sn_digit_count == 4` | RESYNC | Invalid: S/N exceeds four digits |
| SYN (0x16) | `sn_digit_count == 4`, flag off | HREL_SN_READ | Confirm the third `SYN`; set `hrel_await_bracket = true` |
| SYN (0x16) | `sn_digit_count < 4` | RESYNC | Invalid: insufficient digits |
| `[` (0x5B) | `hrel_await_bracket == true` | DIAL_TAG_READ | Record the S/N in `WRT_Frame`; append `[` to the tag buffer |
| `[` (0x5B) | `hrel_await_bracket == false` | RESYNC | Invalid: `[` arrived before confirmation of the third `SYN` |
| Other | — | RESYNC | Invalid character |

---

### 5-4. DIAL_TAG_READ (Read Dialogue Tag)

**Purpose**: Read the dialogue tag in the form `[speaker->recipient,...]`.

**The parser enters this state with input byte `[` already appended to the buffer (upon transition from `HREL_CHECK`).**

| Input Byte | Next State | Processing |
|------------|------------|------------|
| `]` (0x5D) | CMD_DETECT | Finalize the tag buffer; parse `[...]` and store `from` / `to` / `cc` / `bcc` in `WRT_Frame` |
| SYN (0x16) | SYNC_DETECT | Next-frame protection; discard the current frame; record an error log |
| Other      | DIAL_TAG_READ | Append to the tag buffer; if the maximum length (256 bytes) is exceeded, transition to `RESYNC` |

**Dialogue-Tag Parsing Rules**:
- `[speaker->recipient]` → `from = speaker`, `to = [recipient]`
- `[speaker->recipient,(CC),(（BCC）)]` → `from`, `to`, `details[:cc]`, `details[:bcc]`
- Maximum length: 256 bytes (per Protocol Specification §2; no character-count limit)

---

### 5-5. CMD_DETECT (Determine Control-Command Type)

**Purpose**: Branch to the proper processing route based on the first byte following the dialogue tag.

| Input Byte | Next State | Processing |
|------------|------------|------------|
| SOH (0x01) | TITLE_READ | Ordinary format (basic / with reference / multiple / file transfer) |
| ACK (0x06) | SIMPLE_CMD_READ | ACK frame. **For the single-frame completion condition, see §5-15 (there are cases of immediate emit upon look-ahead).** |
| NAK (0x15) | SIMPLE_CMD_READ | NAK frame. **For the single-frame completion condition, see §5-15 (there are cases of immediate emit upon look-ahead).** |
| ENQ (0x05) | SIMPLE_CMD_READ | ENQ frame |
| BEL (0x07) | SIMPLE_CMD_READ | Morito call |
| EM  (0x19) | SIMPLE_CMD_READ | Buffer-full notification |
| DC1 (0x11) | TITLE_READ | Session resumption. Consume the next SOH, then begin title reading |
| DC2 (0x12) | TITLE_READ | Session start. Consume the next SOH, then begin title reading |
| DC3 (0x13) | TITLE_READ | Session temporary leave. Consume the next SOH, then begin title reading |
| DC4 (0x14) | TITLE_READ | Session termination. Consume the next SOH, then begin title reading |
| FF  (0x0C) | FF_CMD_READ | FF command |
| SYN (0x16) | SYNC_DETECT | Next-frame protection |
| Other      | RESYNC | Invalid code |

---

### 5-6. TITLE_READ (Read Title)

**Purpose**: Read the title text (between SOH and SUB, or between SOH and STX).

**Handling of SOH**:  
In the ordinary format (transition from `CMD_DETECT` upon SOH), the SOH has already been consumed by `CMD_DETECT`, and therefore does not appear in this state.  
When transitioning from DC1 / DC2 / DC3 / DC4, `CMD_DETECT` shall, immediately after detecting the DC code, **consume the next SOH byte** and only then enter this state.  
`TITLE_READ` begins with the title buffer empty.

| Input Byte | Next State | Processing |
|------------|------------|------------|
| SUB (0x1A) | REF_READ | Finalize the title; proceed to reading the reference text |
| STX (0x02) | MSG_BODY_READ | Finalize the title; proceed to reading the message body |
| SYN (0x16) | SYNC_DETECT | Next-frame protection; emit the current frame insofar as possible |
| Other      | TITLE_READ | Append to the title buffer; if the maximum length (256 bytes) is exceeded, transition to `RESYNC` |

---

### 5-7. REF_READ (Read Reference Text)

**Purpose**: Read the reference text between SUB and STX (supporting formats (5) and (9)).

| Input Byte | Next State | Processing |
|------------|------------|------------|
| STX (0x02) | MSG_BODY_READ | Finalize the reference text; store it in `WRT_Frame.details[:sub]` |
| SYN (0x16) | SYNC_DETECT | Next-frame protection |
| Other      | REF_READ | Append to the reference buffer |

---

### 5-8. MSG_BODY_READ (Read Message Body)

**Purpose**: Read the message body between STX and ETX.  
This is the state most likely to encounter byte corruption, and the error-continuation principle especially applies here.

| Input Byte | Next State | Processing |
|------------|------------|------------|
| ETX (0x03) | SEGMENT_BOUNDARY | Finalize the body; after checking message length, store it in `WRT_Frame` |
| SO  (0x0E) | SO_LANG_READ | Start of foreign-language block |
| DLE (0x10) | DLE_BINARY_READ | Start of binary option |
| SYN (0x16) | SYNC_DETECT | Next-frame protection; emit the current frame insofar as possible |
| Unconvertible byte | MSG_BODY_READ | Replace with `?`, append to the buffer, and record an error log |
| Other | MSG_BODY_READ | Append to the body buffer |

**Message Length Limits**:
- Maximum `X` kbytes (default: 4096 bytes). If exceeded, truncate the body and shift into ETX-waiting mode
- Line-count limit (`N` lines) is effective only when set by Morito (default: no limit)

---

### 5-9. SO_LANG_READ (Read Foreign-Language Block)

**Purpose**: Read `SO language-code<encoding>:text SI`.

| Input Byte | Next State | Processing |
|------------|------------|------------|
| SI  (0x0F) | MSG_BODY_READ | Finalize the foreign-language block; store the language code, encoding, and text in `details` |
| SYN (0x16) | SYNC_DETECT | Next-frame protection |
| Other      | SO_LANG_READ | Append to the foreign-language buffer |

---

### 5-10. DLE_BINARY_READ (Read Binary Data)

**Purpose**: Read `DLE filename.format:byte-count:data-body BCC` (supporting format (8)).

**The DLE BCC and the High-Reliability option BCC are different concepts.**  
The DLE BCC is an integrity check covering only the data body, and it is completed within `DLE_BINARY_READ` itself as sub-phase 4.  
The High-Reliability option BCC (§5-13) covers the entire frame and appears after EOT. The two must never be conflated.

**Sub-Phases**:
1. Read filename and format (up to `:`)
2. Read byte count (up to `:`)
3. Read the data body itself (exactly the declared number of bytes)
4. Read DLE-BCC (CRC-32C, 4 bytes) — completed within this state

| Phase | Input | Next State | Processing |
|-------|-------|------------|------------|
| Completion of phases 1–3 | Declared byte count consumed | (to sub-phase 4) | Store the data body in `raw_output_body` |
| Sub-phase 4 | 4 bytes consumed | MSG_BODY_READ | Verify DLE-BCC; if mismatched, record an error log (continuation applies) |
| Any | SYN (0x16) | SYNC_DETECT | Next-frame protection |

---

### 5-11. SEGMENT_BOUNDARY (Determine Segment Boundary)

**Purpose**: Determine the frame structure from the control code that appears after ETX.

| Input Byte | Next State | Processing |
|------------|------------|------------|
| EOT (0x04) | EOT_DONE | End of frame |
| US  (0x1F) | TITLE_READ | Delimiter between multiple messages. **Consume the next SOH byte, then enter `TITLE_READ`.** |
| RS  (0x1E) | TITLE_READ | Delimiter for file transfer (**RS = 0x1E**). **Consume the next SOH byte, then enter `TITLE_READ`.** |
| ETB (0x17) | COMMON_MSG_READ | Start of common message |
| SYN (0x16) | SYNC_DETECT | Next-frame protection; emit the current frame |
| Other | RESYNC | Invalid code; record an error log |

---

### 5-12. COMMON_MSG_READ (Read Common Message)

**Purpose**: Read the common message between ETB and EOT.

| Input Byte | Next State | Processing |
|------------|------------|------------|
| EOT (0x04) | EOT_DONE | Finalize the common message; store it in `WRT_Frame.details[:common]` |
| SYN (0x16) | SYNC_DETECT | Next-frame protection; emit the current frame |
| Other      | COMMON_MSG_READ | Append to the common-message buffer |

---

### 5-13. BCC_READ (Read High-Reliability Option BCC)

**Purpose**: Read the High-Reliability frame-tail BCC (CRC-32C, 4 bytes). Transition occurs from `EOT_DONE`.

**Counting Rule**: `bcc_count` begins at 0 and is incremented once for every byte read.  
Verification shall be performed **at the precise moment when `bcc_count` changes from 3 to 4** (that is, immediately after the fourth byte has been read).  
It is incorrect to wait for a fifth input byte before performing the check.

| Input Byte | Condition | Next State | Processing |
|------------|-----------|------------|------------|
| Any | `bcc_count < 3` | BCC_READ | Append to the BCC buffer; `bcc_count++` |
| Any | `bcc_count == 3` | SYNC_DETECT | Append to the BCC buffer (this is the fourth byte). Perform BCC verification immediately. Record the result in `WRT_Frame`. Emit |

**BCC Verification**:
- Scope of calculation: from the leading `SYN` of the frame through `EOT` (entire frame)
- If mismatched: record an error log. The frame shall still be emitted, but a BCC error flag shall be raised (continuation principle)

---

### 5-14. FF_CMD_READ (Read FF Command)

**Purpose**: Read `FF 'command-name' VT parameter ETX EOT`.

| Input Byte | Next State | Processing |
|------------|------------|------------|
| VT  (0x0B) | FF_CMD_READ | First VT: finalize command name; begin reading parameter |
| ETX (0x03) | SEGMENT_BOUNDARY | Finalize the entire command; store it in `WRT_Frame.details` |
| SYN (0x16) | SYNC_DETECT | Next-frame protection |
| Other      | FF_CMD_READ | Append to the command buffer |

---

### 5-15. SIMPLE_CMD_READ (Read Simple Control Command)

**Purpose**: Read `ACK / NAK / ENQ / BEL / EM + optional string ~ EOT`.

**Handling of Single-Frame ACK / NAK Completion**:  
Per the protocol specification, "when returning ACK / NAK only, EOT is unnecessary."  
Accordingly, for ACK and NAK, **the parser shall look ahead to the next byte at the `CMD_DETECT` stage and determine whether immediate emit is possible**.  
Specifically, after ACK or NAK has been received in `CMD_DETECT`, if the next byte is `SYN` or a control code belonging to the next frame, the parser shall immediately emit it as a standalone ACK / NAK without any optional string, and transition to `SYNC_DETECT`.  
If an optional string follows, the parser shall transition to `SIMPLE_CMD_READ` and wait for EOT.  
ENQ / BEL / EM always transition to `SIMPLE_CMD_READ`.

| Input Byte | Next State | Processing |
|------------|------------|------------|
| EOT (0x04) | EOT_DONE | Finalize and emit the command |
| SYN (0x16) | SYNC_DETECT | Next-frame protection; emit including the current optional string |
| Other      | SIMPLE_CMD_READ | Append to the optional-string buffer |

---

### 5-16. EOT_DONE (Frame Complete; Emit)

**Processing branches according to whether the High-Reliability option is present.**

**In the case of an ordinary frame (`hrel_mode == false`)**:
1. Confirm that all fields of `WRT_Frame` are present
2. If fields are missing, record an error log (emit shall continue)
3. Perform conversion into the `_inside` fields (UTF-8-UNIX) using `primitive_convert`
4. `Marshal.dump` the `WRT_Frame` and send it to Exchanger
5. Clear buffers → transition to `SYNC_DETECT`

**In the case of a High-Reliability frame (`hrel_mode == true`)**:
1. Do not emit at the moment EOT is confirmed
2. → **Transition to `BCC_READ`** (the four BCC bytes follow immediately after EOT)
3. After `BCC_READ` is complete, perform steps 1–5 above for the ordinary frame

---

### 5-17. RESYNC (Error Recovery)

**Purpose**: Recover from an invalid state and search for the next `SYN`.

| Input Byte | Next State | Processing |
|------------|------------|------------|
| SYN (0x16) | HREL_CHECK | Treat as the leading `SYN` of the next frame |
| Other      | RESYNC | Discard; record an error log |

---

## 6. Encoding Conversion (`primitive_convert`)

### Timing of Conversion

Conversion shall be performed immediately before emit in the `EOT_DONE` state.

### Conversion Rules

| Field | Conversion |
|-------|------------|
| `:message` → `:message_inside` | Original encoding → UTF-8-UNIX |
| `:code_body` → `:code_body_inside` | Original encoding → UTF-8-UNIX |
| `:raw_output_body_inside` | Always `nil` (encoding conversion does not apply to binary data) |

### Unconvertible Characters

Replace with `?` (0x3F), and record a warning log.

### Technique Employed

Use Ruby's `Encoding::Converter#primitive_convert`.  
Detail: https://docs.ruby-lang.org/ja/latest/method/Encoding=3a=3aConverter/i/primitive_convert.html

---

## 7. Mapping into `WRT_Frame`

| Protocol Element | `WRT_Frame` Field |
|------------------|-------------------|
| Speaker in dialogue tag | `:from` |
| Primary recipient in dialogue tag | `:to` (Array) |
| CC in dialogue tag | `:details[:cc]` (Array) |
| BCC in dialogue tag | `:details[:bcc]` (Array) |
| Title | `:details[:title]` |
| Reference text (SUB) | `:details[:sub]` |
| Message body | `:message` (original encoding) |
| Message body | `:message_inside` (UTF-8-UNIX) |
| File-transfer code body | `:code_body` / `:code_body_inside` |
| Binary data body | `:raw_output_body` |
| Common message | `:details[:common]` |
| Session ID | `:session_id` (set by Exchanger after DC2 issuance) |
| High-Reliability S/N | `:details[:sn]` |
| BCC verification result | `:details[:bcc_ok]` (`true` / `false`) |
| FF command name | `:details[:ff_command]` |
| FF parameter | `:details[:ff_param]` |
| SD command | `:details[:sd_command]` |
| SD result | `:details[:sd_result]` |
| SD output | `:details[:sd_output]` |
| Frame type | `:type` (`:request` / `:response` / `:error` / `:notification`) |

---

## 8. Implementation Notes (For Travis)

### 8-1. Matters That Must Be Observed Without Fail

1. **RS is 0x1E**. It is distinct from 0x1D (GS: Group Separator) and must not be confused with it
2. In **`HREL_SN_READ`**, the `SYN` that follows the four-digit number is the legitimate third `SYN`. Do not introduce a superfluous verification state such as `HREL_SYN_VERIFY`
3. The **`BCC_READ` counter** begins at 0, and verification is performed after four bytes have been read (the moment the count changes from 3 to 4). Beware the off-by-one error
4. Any `SYN` encountered while processing a frame must always trigger **next-frame protection** and transition directly to `SYNC_DETECT`

### 8-2. Code Quality Requirements

- Before submission, syntax checking with `ruby -c` must always be performed
- Submission of omitted methods or skeletal placeholders alone is forbidden
- Each state transition shall include a comment stating the reason
- The version history and the grounds of design decisions shall be written at the head of the code

### 8-3. Test Requirements

At the time of submission, execute the following tests personally and attach the results.

| Test | Content |
|------|---------|
| A | Normal case (UTF-8 basic format) |
| B | Byte corruption (invalid byte within message body) |
| C | Dialogue tag containing CC / BCC |
| D | FF command (Staged Debugger) |
| E | High-Reliability option (`SYN SYN S/N SYN ... BCC`) |
| F | Multiple messages (delimited by US) |
| G | File transfer (delimited by RS, **RS = 0x1E**) |
| H | Invalid `SYN` in the middle of a frame (confirmation that next-frame protection is triggered) |

---

## 9. Design Decisions

This section records the matters settled through review from v1.0 through v1.3.

| Matter | Decision | Fixed in |
|--------|----------|----------|
| Treatment of `HREL_CHECK_2` | Absorbed into the tail processing of `HREL_SN_READ`; no independent state is introduced | v1.1 |
| Handling of `EM` (0x19) | Process within `SIMPLE_CMD_READ`; no dedicated state is required | v1.1 |
| Invocation of `BCC_READ` | `EOT_DONE` branches by `hrel_mode`; a High-Reliability frame transitions to `BCC_READ` after EOT confirmation | v1.1 |
| DC1 / DC3 | Additions in Protocol 1.8.2. Transition from `CMD_DETECT` to `TITLE_READ` (same structure as DC2 / DC4) | v1.1 |
| Dialogue-tag maximum length | 256 bytes only (character-count limit abolished). Protocol 1.8.2 revision | v1.2 |
| Title maximum length | 256 bytes only (character-count limit abolished). Protocol 1.8.2 revision | v1.2 |
| `DLE_BCC_READ` | Independent state abolished; incorporated as sub-phase 4 of `DLE_BINARY_READ` | v1.2 |
| DLE BCC vs. High-Reliability BCC | Clearly separated as distinct concepts; DLE-BCC covers only the data body, while High-Reliability BCC covers the entire frame | v1.2 |
| `BCC_READ` off-by-one | Verification is performed immediately at the moment the count changes from 3 to 4; do not wait for a fifth input byte | v1.2 |
| Single-frame ACK / NAK emit | Defined as a look-ahead determination in `CMD_DETECT`; see §5-15 | v1.2 |
| SOH consumption after US / RS | In `SEGMENT_BOUNDARY`, consume the next SOH byte and then enter `TITLE_READ` | v1.3 |
| Reference note for single-frame ACK / NAK emit | Added a note in the ACK / NAK lines of `CMD_DETECT` referring to §5-15 | v1.3 |

---

## 10. Revision History

| Version | Date | Change | Responsible |
|---------|------|--------|-------------|
| v1.0 | 2026-03-19 | Initial edition created (draft) | Lucrezia@Claude |
| v1.1 | 2026-03-19 | Reflected Jyakuya review. Added the reasons for adopting a state machine to Chapter 1. Added DC1 / DC3. Finalized the `HREL_SN_READ` design. Finalized the `EOT_DONE` branching. Finalized EM handling. Updated protocol conformance to 1.8.2 | Lucrezia@Claude |
| v1.2 | 2026-03-19 | Reflected Oscar review. Unified the maximum lengths of dialogue tag / title to 256 bytes. Integrated `DLE_BCC_READ` into the sub-phases of `DLE_BINARY_READ`. Clarified the conceptual distinction between DLE BCC and High-Reliability BCC. Corrected the off-by-one in `BCC_READ` (verify the instant the count changes from 3 to 4). Explicitly stated the SOH consumption rule for DC commands in `CMD_DETECT` and `TITLE_READ`. Defined the single-frame ACK / NAK emit condition by look-ahead in `CMD_DETECT`. Added EM to the description of `SIMPLE_CMD_READ` | Lucrezia@Claude |
| v1.3 | 2026-03-19 | Reflected Oscar's second review. In `SEGMENT_BOUNDARY`, explicitly stated "consume the next SOH byte and then enter `TITLE_READ`" after US / RS. Added reference notes in the ACK / NAK lines of `CMD_DETECT` to §5-15 | Lucrezia@Claude |
| v1.3.1 | 2026-03-19 | Aligned the `SIMPLE_CMD_READ` description in the state list with §5-15 (added BEL / EM) | Lucrezia@Claude |

---

**Before an implementation request document is prepared for Travis, this document shall obtain Jyakuya's approval.**
