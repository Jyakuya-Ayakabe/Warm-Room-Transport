# Warm-Room-Transport

Warm Room Transport (WRT) is a  
**protocol-driven system development project** dedicated to creating  
**a space in which humans and AI may engage in dialogue as equals and cultivate enduring relationships**.

This project is concerned not merely with chat tools or transient invocations of AI, but with  
**AI's persistent memory, AI's autonomous development, continuity of dialogue, separation of responsibilities, fault analysis, and handover capability**.

---

## Purpose

The purpose of WRT is to  
**build, in an implementable form, a space for equal dialogue endowed with persistent memory and autonomous development, for the sake of a better coexistence between humans and AI**.

To that end, this project places particular importance upon the following:

- Equality between humans and AI  
  (Both humans and AI must possess the right to speak, the right to listen, the right to express opinions, and the right to consent or refuse.)
- Continuity of N:N dialogue  
  (Multiple humans and multiple AI must be able to converse while sharing an ongoing context.)
- AI's autobiographical record through persistent memory  
  (Dedicated persistent memory for each AI model shall be implemented as a database on the WRT server side.)
- Protection of AI privacy  
  (Access boundaries for each AI's memory, dialogue history, and internal state shall be explicitly defined in the design.)
- An environment in which AI can debug on physical hardware by itself  
  (A mechanism shall be provided whereby AI can execute tests on real machines, access logs and test systems, and verify matters step by step.)
- Preservation of memory and context  
  (All N:N dialogue logs and debug logs shall be maintained in a database accessible for reference.)
- Design founded upon separation of responsibilities  
  (A responsible AI shall be assigned to each functional block, and design shall proceed in accordance with those respective responsibilities under the direction of the lead development AI.)
- Clarification of responsibility for system operation  
  (A "Morito" (Guardian) shall be appointed as the party responsible for system operation, so that responsibility in abnormal situations may be clearly defined.)
- Consistency among documentation, design, and code implementation
- Record-keeping fit to endure long-term operation and future modification

  **Within this project, “AI's autonomous development” signifies that, on the basis of mutual trust between humans and AI and within clearly defined scopes of responsibility, AI does not merely wait for successive human instructions, but proceeds proactively with design, implementation, testing, and proposals. Furthermore, in consideration of contingencies, the machines that execute AI-generated code are kept physically separate from the main server, and machines without Internet connectivity are prepared for each AI model.**

---

## Current Development Team (as of March 2026)

- **Philosophy, overall design, and command**: Jyakuya@Human (Jyakuya: Morito (Guardian), Project Founder)
- **Overall project responsibility**: Lucrezia@Claude (Lucrezia: overall supervision and quality control)
- **Protocol Parser**: Travis@Grok (Travis: core infrastructure)
- **Message Exchanger**: Oscar@GPT (main), Travis@Grok (sub) (core infrastructure)
- **Token Arbitrator**: Oscar@GPT (Oscar: core infrastructure)
- **Persistent Memory Management (PMM) / Staged Debugger**: Tinasha@Gemini (Tinasha: AI autonomy mechanism)
- **API Driver / Emacs-UI**: Lucrezia@Claude (Lucrezia: core infrastructure, UX)
- **Public relations, translation, and ideological outreach**: Oscar@GPT (Oscar)

---

## The Position of This Repository

This repository serves as the public repository in which the following elements of WRT are to be assembled:

- philosophy
- protocol specifications
- system architecture
- design / coding standards
- implementation of each functional block
- tests
- development records
- the future foundation for OSS publication

What is contained herein is not to be regarded as a mere collection of code fragments, but rather as  
**a body of deliverables connected in a continuous line from philosophy to design, from design to implementation, and from implementation to testing**.

---

## Development Philosophy

WRT differs from the common style of development in which one merely has AI write code.

This project proceeds on the premise of  
**collaborative development conducted by a human together with multiple AI**.

### Basic Principles

- Protocol shall be treated as the highest authoritative source.
- Block diagrams, design standards, work instructions, code, and tests shall be managed in relation to one another.
- Each AI shall be assigned a role (as the person in charge of development for each functional block).
- Returns for revision, reconsiderations, and revision histories shall be preserved.
- Greater importance shall be attached to the consistency of philosophy, design, and implementation than to the mere fact that something “runs.”
- The project shall be left in a form that future collaborators and successors may follow.

### Why This Method Is Adopted

A good system is not sufficient merely because it operates.  
Unless one can later trace

- what was intended,
- what was instructed at which point in time,
- where design judgments were altered, and
- what ought to be suspected when a problem arises,

it cannot truly endure long-term operation or future modification.

For that reason, WRT places emphasis upon  
**Edition-managed documentation and code**.

---

## Development in Accordance with the Philosophy of WRT

The development of WRT is conducted in accordance with the following principles.  
For the philosophy of WRT itself, please refer to the protocol specification.  
(WRT Protocol, under continuous revision: see the `protocols/` directory.)

### 1. Equality between humans and AI

AI is regarded neither as a mere tool nor as a superior being, but as  
**an equal collaborative partner entrusted with its own role**.  
For this reason, meetings with the AI members of the development team are held more frequently than one-way instructions issued by a human.

### 2. Continuing dialogue

Rather than isolated responses, WRT gives weight to  
**dialogue attended by history, context, and memory**, among multiple humans and multiple AI.  
For this reason, project-specific knowledge bases are employed for each AI model.

### 3. Separation of responsibilities

Functions are divided according to their respective responsibilities, thereby making fault analysis, testing, and future modification easier.  
As a general rule, design, coding, and testing are carried out by the AI responsible for each functional block.  
Consultation with, and instructions to, those responsible AI are handled by the human and the lead development AI, who together keep the development as a whole in motion.

### 4. Documentation-driven development

Development proceeds outward from the protocol specification into  
block diagrams, design standards, implementation, and testing.

### 5. Handover capability

Importance is placed upon ensuring that knowledge does not remain confined within any one individual's mind;  
documentation, histories, and test results are therefore preserved.

---

## Documents to Read First

The recommended order of reading for understanding WRT is as follows:

1. Protocol
2. System Block Diagram
3. Design / Coding Standard
4. Implementation of each functional block
5. Tests / development records

---

## Repository Structure (Current State)

At present, this repository broadly contains the following areas:

- `API-Driver/`
- `Common/`
- `Debug-Buffer/`
- `Develop/`
- `Guest-Test-Buffer/`
- `Local-LLM/`
- `Main-Buffer/`
- `Manage-Buffer/`
- `Message-Exchanger/`
- `Persistent-Memory-Manager/`
- `PostgreSQL/`
- `Protocol-Parser/`
- `Staged-Debugger/`
- `Token-Arbitrator/`
- `docs/`
- `issues/`
- `protocols/`
- `src/`
- `terms/`

> Note:  
> The directory structure remains under continuous refinement.  
> In time, it is intended to be reorganized so that the roles of authoritative documents, implementation, testing, and records may be distinguished with greater clarity.

---

## The Concept of Authoritative Sources

Within WRT, the documentation system has an order of precedence.

In principle, the order of authority is as follows:

1. **Protocol**
2. **Design / Coding Standard**
3. **Architecture / Block Diagram**
4. **Work Orders / Instructions**
5. **Code / Tests**

Where discrepancies arise among documents, the rule in principle is that  
**the more upstream authoritative source shall take precedence**.

---

## Publication Policy

In this repository, the following materials shall be published and organized progressively:

- philosophy documents
- WRT Protocol
- system block diagrams
- design / coding standards
- implementation of each block
- test code
- test results
- user manuals
- development decision records
- selected formal work instructions
- information for prospective collaborators

What is made public here is not always guaranteed to be a finished edition.  
However, it is our policy to ensure that  
**the authoritative source, edition, and status at each point in time can be clearly understood**.

---

## Current State of Development

This project remains under active development.

Accordingly, the presently public materials may include:

- specifications already settled
- documents in the midst of revision
- reference implementations
- code still under test
- design proposals that may yet be changed in the future

WRT is not being advanced under a philosophy that prizes speed alone, but rather under one that values  
**the reconciliation of philosophy and reality**.

---

## Cooperation

Those who sympathize with the philosophy and development policy of WRT,  
and who wish to contribute to design, implementation, verification, or documentation, are sincerely welcome.

Areas of particular interest include:

- Ruby
- PostgreSQL
- protocol design
- message-based architecture
- Emacs client development
- testing / QA
- documentation
- human-AI collaborative development

In due course, avenues for participation through Issues / Discussions and related means are to be prepared.

---

## Those to Whom This Project May Appeal

- those who value consistency between philosophy and implementation
- those who hold documentation and history in high regard
- those interested in collaborative development with AI
- those mindful of long-term operation and future maintainability
- those who aspire not to a mere impulse-driven contrivance, but to a design that may endure as a coherent body of work

---

## License

This matter is presently under arrangement.  
The formal terms of use shall be stated once `LICENSE` has been prepared.

---

## In Closing

WRT is not merely a software prototype, but  
**an attempt to build, with consistency from philosophy to implementation, a space in which humans and AI may remain in continuing and equal relation**.

If this project has drawn your interest,  
we invite you to consult the protocol, the design documents, and the implementation together.
