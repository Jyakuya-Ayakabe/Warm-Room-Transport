# ADR-2026-003: Introduction of the Transport Abstraction Layer and Preservation of the Migration Path to the Data Module + Signal Method

**Author**: Lucrezia  
**Approved by**: Jyakuya (the First Morito)  
**Decision Makers**: Agreement between Lucrezia (Development Lead) and Jyakuya (the First Morito)  
**Date Decided**: April 2, 2026  
**Date Revised**: April 3, 2026 (expanded Transport options; added the structural reason for retaining Marshal)  
**Status**: Approved  
**Related Documents**: design_coding_standard_2_6_3, ADR-2026-002 (Marshal Communication Policy)

---

## Decision

1. **The current Marshal + UDS method shall be retained** (ADR-2026-002 shall not be altered)
2. A design shall be adopted in which **a Transport abstraction layer is inserted between all components**
3. **Four Transport implementations shall be prepared and made selectable according to use and circumstance** (described below)
4. Substitution shall be carried out only when specific conditions are satisfied (described below)
5. In the present phase, detailed design and full implementation shall be undertaken only for the methods actually to be used

---

## Background and Course of Discussion

### Point of Departure

Jyakuya proposed **an idea for realizing the OS-9 Data Module in modern Ruby** (`/dev/shm` + `mmap` + Signal). The starting point was a fundamental question:

**Why should heavy processing be interposed in inter-process communication within the same machine?**

### Technical Examination

Under the operating assumption of **16 rooms running concurrently** (4 humans + 4 AI, with 1/4 of them using SD), the performance of each method was compared.

**Comparison of transfer cost under ordinary load (assuming approximately 240 transfers per second):**

| Method | Cost per transfer | CPU consumption at 240 transfers/sec |
|--------|-------------------|--------------------------------------|
| Marshal + UDS | 30–100 μs | 7–24 ms/sec (1–2%) |
| Data Module + Signal | 5–18 μs | 1.2–4.3 ms/sec (0.2% or less) |

**The conclusion is that, under ordinary load, there is no practical difference between the two methods.**

The bottlenecks are prioritized as follows:

1. **PostgreSQL HDD I/O** — the greatest constraint (improvable by SSD replacement)
2. **Encoding conversion (Protocol Parser)** — especially when CP932 ↔ UTF-8 conversion is concentrated
3. **Ruby GC “Stop the World”** — not solvable by hardware reinforcement alone (explained below)
4. **Inter-process communication** — not ordinarily a problem under normal load

### Structural Reason for Retaining Marshal

WRT_Frame has **13 fields in fixed structure, while only the `:details` field is a dynamic Hash**.

The fixed fields are, in principle, directly convertible into binary form by `Array#pack / String#unpack` because both sender and receiver already know the structure, and thus no metadata is required. However, the contents of `:details` differ from frame to frame, and because WRT must handle diverse encoding cultures, JSON's forced UTF-8 conversion would violate the philosophy of the system. At present, Marshal alone can serialize a Hash generically while preserving encoding information.

So long as Marshal must be invoked for `:details`, even if the other 13 fields were lightened by pack/unpack, **the number of Marshal invocations would still remain one per frame**. A partial hybrid would be less elegant in implementation, and the effect would not justify the cost.

**The prerequisite for abolishing Marshal retention is that the contents of `:details` be replaced by a fixed binary structure.**  
That judgment should be made only after development has progressed far enough that the actual contents of `:details` are settled, and only if measurement shows Marshal to have become a true bottleneck.

### Why the Data Module Method Is Retained as a “Measure for When Things Go Wrong”

**A lesson from the past (from Jyakuya)**

In a past large-scale system failure, a delivered distribution-grid automation system repeatedly caused power outages because it could not follow concentrated state changes in real time. One year of software modification failed to resolve the issue, and the system was eventually returned with substantial compensation. A major cause of that slowness and heaviness was **object-based inter-process communication and the accompanying GC**. The previous-generation system at that time had operated by C-struct memory sharing + Signal, and did not suffer from that problem.

**A corresponding risk within WRT**

Ruby's `Marshal.dump` creates temporary objects on the heap on every call. Under ordinary load this is not a problem. However, in situations such as multiple rooms simultaneously receiving SD execution results, **state changes may concentrate in spikes**, and there is, in principle, no way to exclude the risk that GC “Stop the World” may strike at exactly such a moment.

If RAM is increased from 32 GB to 64 GB, the heap becomes larger, and the GC stop time per event may in fact become **longer**. In other words, this is a class of problem that cannot be solved merely by stronger hardware.

**Division of roles with hardware reinforcement**

```text
SSD replacement  → solves the DB I/O problem
Data Module      → solves the GC spike problem
```

These are distinct countermeasures for distinct problems; neither can substitute for the other.

---

## Characteristics and Advantages of the OS-9 Data Module Method

For contrast with the Marshal + UDS method presently adopted by WRT, the characteristics of the Data Module method are recorded below.

### Speed and Lightness

- **Zero-copy**: because the sender and receiver processes read and write the same physical memory directly, no copying into kernel buffers occurs (whereas UDS unavoidably incurs two copies)
- **No GC intervention**: because no object creation is involved, Ruby’s GC “Stop the World” does not arise even under high-frequency and concentrated load
- **Minimal syscalls**: only a single signal notification is required; the reciprocal `write/read` syscalls of UDS are unnecessary
- **Stable latency characteristics**: latency characteristics do not change even during spikes (whereas Marshal latency increases under concentrated load)

### Observability (Transparency Corresponding to OS-9’s `mdir`)

Because files on `/dev/shm` exist as ordinary OS files, their state can be observed **without any special tool**.

```bash
# List all channels (equivalent to mdir)
ls -la /dev/shm/wrt_*

# Real-time watch of header state (Status Flag / PID changes are visible)
watch -n 0.1 hexdump -C -n 16 /dev/shm/wrt_exchanger_sm

# Inspect contents by Ruby inspector
# → Status=0 (empty) / 1 (unread), WriterPID, ReaderPID, and DataSize
#    can all be read immediately
```

By this means, one can observe **which channel is clogged** from the outside without touching the running system itself. With Marshal + UDS, one must take the trouble to peek into the stream with `socat`; by contrast, in the Data Module method the state is visible at a glance from a single flag byte.

### Constraints

- It is limited to **same-host inter-process communication only** (it cannot cross a router)
- Permission control for `/dev/shm` is required (the reverse side of its ease of monitoring)
- `mmap` must be called via Fiddle (it cannot be implemented with Ruby standard features alone)

---

## Design Policy

### Transport Abstraction Layer

A design shall be adopted in which communication among components (ExchangerCore, Protocol Parser, Session Manager, etc.) is performed **only through the Transport interface**.

```ruby
# Interface of the transport layer
module WRT
  class Transport
    def send_frame(frame)  = raise NotImplementedError
    def recv_frame         = raise NotImplementedError
  end

  # Between components within the same host (current method)
  class UDSTransport < Transport

  # Between components within the same host (countermeasure for concentrated load; candidate for substitution)
  class SHMTransport < Transport

  # Between the WRT server and dedicated Staged Debugger machines (does not cross a router)
  class UDPTransport < Transport

  # Between the WRT server and Emacs clients (human users, over an SSH tunnel)
  class TCPTransport < Transport
end
```

Each component shall not depend upon the concrete implementation of Transport. Switching shall be made possible by configuration change alone.

**The WRT_Frame structure itself shall remain unchanged.**  
Substitution of the Transport layer is a change below the level of WRT_Frame, and shall not affect the implementation or interface of each component.

### Intended Use and Implementation Policy of Each Transport

| Transport implementation | Intended use | Serializer | Implementation policy |
|--------------------------|--------------|------------|-----------------------|
| UDSTransport | Between components within the same host | Marshal | **Subject of detailed design and full implementation** |
| SHMTransport | Same as above (countermeasure for concentrated load) | Marshal | To be implemented after the activation conditions are definitively met |
| UDPTransport | WRT server ↔ dedicated SD machines | Marshal | **Subject of detailed design and full implementation** |
| TCPTransport | WRT server ↔ Emacs clients | Marshal | **Subject of detailed design and full implementation** |

In the present phase, detailed design and full implementation shall be carried out only for the **three methods actually in use: UDS, UDP, and TCP**. SHMTransport shall be implemented by Lucrezia only when the activation conditions are met.

---

## Activation Conditions for Substitution

Migration to the Data Module method (**SHMTransport**) shall be considered when the following condition is satisfied:

- Even after the HDD has been replaced with an SSD, stable operation with **10 rooms running concurrently on the L480** still cannot be achieved

It does not matter whether the cause is proved to be a GC spike or not. If the instability may reasonably be judged to arise from inter-process communication, that alone is sufficient ground to try the Data Module method. If SSD replacement resolves the issue, SHMTransport shall remain preserved but shall not be activated.

---

## Options Not Adopted

### “Migrate to the Data Module Method Immediately”

There is no urgent performance necessity, and there is no rational basis at present for bearing the revision cost to ADR-2026-002 and the implementation risk immediately.

### “Do Not Prepare a Migration Path, and Merely Retain the Current Method”

As past large-scale system failures have shown, GC spikes under concentrated load cannot be detected by average values alone, and if one waits to respond only after they occur, it may already be too late. The cost of preparing a design that can be substituted now is small, and is rational as insurance.

### “Change the Serializer to MessagePack”

Although MessagePack is 5–7 times faster than Marshal, at WRT’s present load level the difference amounts to no more than about **0.1% of CPU consumption**. In addition, it would require the establishment of rules for treating fields such as `:message` as `bin` type, and a revision of ADR-2026-002. Its priority is low at present. It may be reconsidered in future if serialization cost is found to have become the bottleneck.

### “Partially Eliminate Marshal by pack/unpack”

Even if the 13 fields of WRT_Frame were lightened by pack/unpack, so long as Marshal must still be invoked for `:details` (a dynamic Hash), the number of Marshal invocations per frame would not change. The effect would not justify the cost. The prerequisite for complete elimination of Marshal is that `:details` be converted into a fixed binary structure.

---

## Scope of Impact

| Target | Impact |
|--------|--------|
| WRT_Frame structure | **No change** |
| Protocol Parser (Travis) | **No change** |
| Message Exchanger (Oscar) | **No change** |
| PMM / Staged Debugger (Tinasha) | **No change** |
| design_coding_standard | Add description of the Transport abstraction layer at the next edition revision |
| Work orders for each assignee | No change required in the current instructions. From the next round onward, explicitly state routing through the Transport layer |

The design and implementation of the Transport abstraction layer shall be carried out by Lucrezia alone. Notification to the other members shall be made after implementation is complete.

---

## Notes

This ADR is founded on the policy of **preparing, in advance, a countermeasure for the time when things go wrong**. The value of designing such insurance before performance problems become manifest increases as the system approaches production operation.

Jyakuya’s words:  
**“Not a walking stick to prevent falling, but one of the measures to take when one does fall.”**
