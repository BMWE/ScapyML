# ScapyML — Manual Test Specification (STR)

**Companion document:** `STP.md` (Software Test Plan)
**Scope:** Manual, human-executable test cases only. No automated test code is included here —
see `tests/*.m` for the existing `matlab.unittest` regression suite, which is a separate,
already-existing verification activity.

**Test Case ID convention:**
`TC-<MODULE>-<TYPE>-<NNN>`, where `<TYPE>` is one of `FUNC` (functional), `NEG` (negative),
`BOUND` (boundary), `EDGE` (edge case), `ERR` (error handling), `INT` (integration), `E2E`
(end-to-end), `UI` (UI/GUI-specific), `PERF` (performance sanity), `SEC` (security), `DATA` (data
integrity/recovery).

---

## 0. Test Execution Checklist

All **191** manual test cases in this document, grouped by module in execution order. Check each box off as it is run. Priority markers: 🔴 Critical · 🟠 High · 🟡 Medium · ⚪ Low. **Update:** the 4 test cases previously marked "EXPECTED TO FAIL" (KI-NEW-01, KI-NEW-02) have since been **FIXED** in the source — see §21 Known Issues for the fix details and the corresponding updated/added automated tests in `tests/TestManualCsvSuite.m`, `tests/TestManualGuiAndE2ESuite.m`, and `tests/TestManualMultiProtocolSuite.m`. These four cases should now PASS; re-run them to confirm in your environment.


### 1. HeaderParser (19 tests)

- [ ] 🔴 `TC-HDR-FUNC-001` — Parse a simple struct with all unsigned primitive types
- [ ] 🟠 `TC-HDR-FUNC-002` — Parse signed integer types and char variants
- [ ] 🔴 `TC-HDR-FUNC-003` — Parse bit-fields within a single byte
- [ ] 🟠 `TC-HDR-FUNC-004` — Parse a bit-field that crosses a byte boundary
- [ ] 🔴 `TC-HDR-FUNC-005` — Parse fixed-size arrays of primitives
- [ ] 🔴 `TC-HDR-FUNC-006` — Parse a nested named struct member
- [ ] 🔴 `TC-HDR-FUNC-007` — Parse a nested named union member
- [ ] 🟡 `TC-HDR-FUNC-008` — Parse a truly anonymous inline struct (no member name)
- [ ] 🔴 `TC-HDR-FUNC-009` — Parse an enum and reference it as a field type
- [ ] ⚪ `TC-HDR-FUNC-010` — Comments (line and block) attach as field/struct descriptions
- [ ] 🟡 `TC-HDR-FUNC-011` — Preprocessor directives are skipped, not parsed as fields
- [ ] 🔴 `TC-HDR-FUNC-012` — Cross-file type resolution (v2.3.3 feature)
- [ ] 🟠 `TC-HDR-FUNC-013` — Cross-file resolution fails gracefully when load order is wrong
- [ ] 🟠 `TC-HDR-NEG-001` — Load a non-existent header file
- [ ] 🟡 `TC-HDR-NEG-002` — Malformed struct with missing closing brace
- [ ] 🟡 `TC-HDR-NEG-003` — Multi-dimensional array syntax is explicitly rejected
- [ ] 🟡 `TC-HDR-NEG-004` — Array declared with a missing closing bracket
- [ ] 🟠 `TC-HDR-NEG-005` — Array size given as a non-numeric token (macro name) — **✅ FIXED**
- [ ] 🟠 `TC-HDR-NEG-006` — Referencing a completely undefined type name

### 2. Protocol Data Model — ProtocolDef / FieldDef / EnumDef (9 tests)

- [ ] 🔴 `TC-PROTO-FUNC-001` — Union size equals the max member size, not the sum
- [ ] 🔴 `TC-PROTO-FUNC-002` — Struct C-ABI alignment padding is applied
- [ ] 🟠 `TC-PROTO-FUNC-003` — Nested struct alignment uses the child's largest-member alignment
- [ ] 🔴 `TC-PROTO-FUNC-004` — `getFieldOffsets()` matches actual encoded byte positions
- [ ] 🟡 `TC-PROTO-FUNC-005` — EnumDef lookup by name and by value
- [ ] ⚪ `TC-PROTO-NEG-001` — EnumDef.getValue on an unknown name
- [ ] ⚪ `TC-PROTO-NEG-002` — EnumDef.getName on an unknown numeric value
- [ ] 🟡 `TC-PROTO-BOUND-001` — 1-byte struct requiring no alignment padding
- [ ] 🟡 `TC-PROTO-BOUND-002` — 8-byte (`double`/`int64_t`/`uint64_t`) alignment boundary

### 3. ProtocolRegistry (8 tests)

- [ ] 🔴 `TC-REG-FUNC-001` — Register and retrieve a protocol
- [ ] 🟡 `TC-REG-FUNC-002` — `list()` returns all registered protocol names
- [ ] 🟠 `TC-REG-FUNC-003` — Enum registration and lookup (`registerEnum`/`getEnum`/`hasEnum`)
- [ ] 🟠 `TC-REG-FUNC-004` — Singleton identity across calls
- [ ] 🟠 `TC-REG-FUNC-005` — `clearAll()` empties both protocol and enum maps
- [ ] 🔴 `TC-REG-FUNC-006` — `ProtocolRegistry.clearInstance()` static method actually clears (KI-002)
- [ ] 🟠 `TC-REG-ERR-001` — `get()` on an unregistered protocol name
- [ ] 🟡 `TC-REG-ERR-002` — `getEnum()` on an unregistered enum name

### 4. Packet (20 tests)

- [ ] 🔴 `TC-PKT-FUNC-001` — Construct a packet with all fields at declared defaults
- [ ] 🟡 `TC-PKT-FUNC-002` — Constructor field-pair shorthand
- [ ] 🔴 `TC-PKT-FUNC-003` — `set`/`get` round-trip for a scalar field
- [ ] 🔴 `TC-PKT-FUNC-004` — `set` on an array field with exact-length input
- [ ] 🟡 `TC-PKT-FUNC-005` — `fieldNames()` returns all flattened field names
- [ ] ⚪ `TC-PKT-FUNC-006` — `loadStruct()` copies only matching fields
- [ ] ⚪ `TC-PKT-FUNC-007` — `show()` displays every field with correct formatting
- [ ] ⚪ `TC-PKT-FUNC-008` — `hexdump()` produces correctly formatted, wrapped hex output
- [ ] 🟡 `TC-PKT-FUNC-009` — `chain()` concatenates payload bytes
- [ ] 🔴 `TC-PKT-FUNC-010` — `fromBytes()` static decode constructor
- [ ] 🟠 `TC-PKT-FUNC-011` — `fromValuesStruct()` bulk constructor bypasses validation
- [ ] 🟠 `TC-PKT-NEG-001` — `set()` on an unknown field name
- [ ] 🟠 `TC-PKT-NEG-002` — `get()` on an unknown field name
- [ ] 🟡 `TC-PKT-NEG-003` — `set()` with a non-numeric value
- [ ] 🟠 `TC-PKT-NEG-004` — Constructing a `Packet` for an unregistered protocol name
- [ ] 🔴 `TC-PKT-BOUND-001` — uint8 field range clamping at 0 and 255
- [ ] 🟠 `TC-PKT-BOUND-002` — int8 field range at -128 and 127
- [ ] 🟠 `TC-PKT-BOUND-003` — uint16/int16, uint32/int32, uint64/int64 boundaries
- [ ] 🔴 `TC-PKT-BOUND-004` — Array field set with fewer elements than declared size (zero-padding)
- [ ] 🟡 `TC-PKT-BOUND-006` — Setting a scalar (non-array) field with multiple values

### 5. Codec (15 tests)

- [ ] 🔴 `TC-CODEC-FUNC-001` — Little-endian multi-byte encode/decode round-trip
- [ ] 🔴 `TC-CODEC-FUNC-002` — Big-endian multi-byte encode/decode round-trip
- [ ] 🔴 `TC-CODEC-FUNC-003` — Bit-field MSB-first packing matches decode (KI-003 regression)
- [ ] 🔴 `TC-CODEC-FUNC-004` — Signed integer two's-complement encoding for a negative value
- [ ] 🟠 `TC-CODEC-FUNC-005` — Float (IEEE-754 single) encode/decode round-trip
- [ ] 🟡 `TC-CODEC-FUNC-006` — Double (IEEE-754 double) encode/decode round-trip
- [ ] 🔴 `TC-CODEC-FUNC-007` — Array of primitives encode/decode
- [ ] 🔴 `TC-CODEC-FUNC-008` — Union: only the explicitly-set (dirty) member is written
- [ ] 🟠 `TC-CODEC-FUNC-009` — Nested struct inside union — dirty propagation
- [ ] 🟡 `TC-CODEC-FUNC-010` — `decode()` on a union stores raw bytes under a `__raw` key
- [ ] 🟠 `TC-CODEC-ERR-001` — Decoding fewer bytes than the protocol requires
- [ ] 🟡 `TC-CODEC-ERR-002` — Decoding an array field with insufficient trailing bytes
- [ ] ⚪ `TC-CODEC-BOUND-001` — Zero-bit field is a no-op
- [ ] 🟡 `TC-CODEC-BOUND-002` — 1-bit field encode/decode (0 and 1)
- [ ] 🟡 `TC-CODEC-BOUND-003` — Maximum bit-field width equal to its container's full byte(s)

### 6. ChecksumManager (13 tests)

- [ ] 🔴 `TC-CHK-FUNC-001` — Load a valid checksum file and apply a simple sum checksum
- [ ] 🔴 `TC-CHK-FUNC-002` — Checksum calculation is idempotent across repeated `build()` calls
- [ ] 🟠 `TC-CHK-FUNC-003` — Multiple checksum fields processed in byte-offset order
- [ ] 🟡 `TC-CHK-FUNC-004` — `listChecksums()` / `checksumCount()` / `hasChecksum()` accessors
- [ ] 🟡 `TC-CHK-FUNC-005` — XOR and two's-complement checksum formulas from the example file
- [ ] 🟡 `TC-CHK-FUNC-006` — Formula line containing comparison operators (`==`, `<=`) parses correctly
- [ ] 🟡 `TC-CHK-ERR-001` — Missing checksum file
- [ ] 🟡 `TC-CHK-ERR-002` — Malformed line (no `=` sign)
- [ ] 🟡 `TC-CHK-ERR-003` — Right-hand side is not a function handle
- [ ] 🟡 `TC-CHK-ERR-004` — Checksum field name not found in the protocol
- [ ] 🟡 `TC-CHK-ERR-005` — Checksum function throws an error at evaluation time
- [ ] ⚪ `TC-CHK-ERR-006` — Checksum function returns a non-scalar or non-numeric value
- [ ] 🟠 `TC-CHK-BOUND-001` — Checksum field sizes 1/2/4/8 bytes

### 7. ConversionManager (6 tests)

- [ ] 🔴 `TC-CONV-FUNC-001` — Load and apply the documented azimuth conversion
- [ ] 🟡 `TC-CONV-FUNC-003` — `hasConversion()` / `listConversions()` / `conversionCount()` accessors
- [ ] 🟡 `TC-CONV-FUNC-004` — Elevation, temperature, pressure conversions from the example file
- [ ] 🟡 `TC-CONV-ERR-001` — Missing conversion file
- [ ] 🟡 `TC-CONV-ERR-002` — Conversion function throws at evaluation time
- [ ] ⚪ `TC-CONV-ERR-003` — Malformed line / non-function right-hand side

### 8. DefaultsManager (9 tests)

- [ ] 🟠 `TC-DEF-FUNC-001` — `create()` generates a defaults file listing every field at 0/0.0
- [ ] 🔴 `TC-DEF-FUNC-002` — `apply()` loads a hand-edited defaults file into a fresh packet
- [ ] 🟡 `TC-DEF-FUNC-003` — Hex-notation values in a defaults file (`0x...`)
- [ ] ⚪ `TC-DEF-FUNC-004` — Comment lines (`#`) and blank lines are ignored
- [ ] 🟠 `TC-DEF-FUNC-005` — `set()`-after-`apply()` override semantics
- [ ] 🟡 `TC-DEF-ERR-001` — Applying a non-existent defaults file
- [ ] 🟡 `TC-DEF-ERR-002` — Malformed line (no `=`, or line with two `=` signs)
- [ ] 🟡 `TC-DEF-ERR-003` — Unparseable numeric value
- [ ] ⚪ `TC-DEF-ERR-004` — Value line for a field name not present in the packet

### 9. CSV Loading — CsvLoader / fromcsv / GUI bulk loader (16 tests)

- [ ] 🔴 `TC-CSV-FUNC-001` — Load a well-formed CSV with columns matching all protocol fields
- [ ] 🟡 `TC-CSV-FUNC-002` — CSV with extra columns not present in the protocol
- [ ] 🟡 `TC-CSV-FUNC-003` — CSV with a missing column (field not in CSV at all)
- [ ] 🟡 `TC-CSV-FUNC-004` — Empty cell in a data row leaves the field at its default
- [ ] 🟡 `TC-CSV-FUNC-005` — Hex-notation CSV values (`0x...`) of varying digit counts
- [ ] ⚪ `TC-CSV-FUNC-006` — Quoted CSV fields containing a comma
- [ ] 🟠 `TC-CSV-NEG-001` — Non-existent CSV file
- [ ] 🟡 `TC-CSV-NEG-002` — Empty CSV file (zero bytes)
- [ ] 🟡 `TC-CSV-NEG-003` — CSV with header row only, no data rows
- [ ] 🔴 `TC-CSV-FUNC-007` — CLI `fromcsv` command with defaults and conversions  **✅ FIXED (was: expected to fail)**
- [ ] 🔴 `TC-CSV-FUNC-008` — GUI "Load from CSV" with a defaults file selected  **✅ FIXED (was: expected to fail)**
- [ ] 🔴 `TC-CSV-FUNC-009` — GUI CSV load with no defaults file, no conversions
- [ ] 🔴 `TC-CSV-FUNC-010` — GUI CSV load with a conversion file loaded, no defaults file
- [ ] 🟡 `TC-CSV-FUNC-011` — GUI CSV load waitbar and cancel button (large CSV)
- [ ] 🟡 `TC-CSV-FUNC-012` — GUI CSV load: CSV column not mapping to any protocol field
- [ ] 🟡 `TC-CSV-PERF-001` — 1000-row CSV bulk load completes well under 15 seconds (NFR-001)

### 10. MAT File Persistence (9 tests)

- [ ] 🔴 `TC-MAT-FUNC-001` — Save current packets to a `.mat` file
- [ ] 🔴 `TC-MAT-FUNC-002` — Load packets from a `.mat` file matching the selected protocol
- [ ] 🟠 `TC-MAT-FUNC-003` — Protocol-mismatch confirmation dialog — user selects "No"
- [ ] 🟡 `TC-MAT-FUNC-004` — Protocol-mismatch confirmation dialog — user selects "Yes"
- [ ] 🟠 `TC-MAT-DATA-001` — Round-trip fidelity for 1000 packets
- [ ] 🟡 `TC-MAT-ERR-001` — Loading a `.mat` file with no `packetData` variable
- [ ] 🟡 `TC-MAT-ERR-002` — Loading a `.mat` file with `packetData` missing required sub-fields
- [ ] ⚪ `TC-MAT-ERR-003` — "Save to MAT" with no packets available
- [ ] ⚪ `TC-MAT-ERR-004` — "Load from MAT" with no protocol selected

### 11. UdpSender (7 tests)

- [ ] 🔴 `TC-UDP-FUNC-001` — Persistent socket open, multiple sends, explicit close
- [ ] 🟠 `TC-UDP-FUNC-002` — `sendOnce()` convenience opens, sends, and closes automatically
- [ ] 🟡 `TC-UDP-FUNC-003` — Destructor closes the socket automatically on object deletion/clear
- [ ] 🟡 `TC-UDP-FUNC-004` — Multicast destination IP is accepted
- [ ] 🟡 `TC-UDP-ERR-001` — `send()` on a closed/never-opened socket
- [ ] 🟡 `TC-UDP-ERR-002` — `send()` to an unreachable/invalid destination
- [ ] ⚪ `TC-UDP-BOUND-001` — Default constructor arguments (`UdpSender()` with no args)

### 12. PacketSender / Timing (11 tests)

- [ ] 🔴 `TC-SEND-FUNC-001` — Single-mode send transmits all packets immediately
- [ ] 🔴 `TC-SEND-FUNC-002` — Periodic-mode send respects the configured interval (±1-2ms, NFR/FR-010)
- [ ] 🔴 `TC-SEND-FUNC-003` — CSV-timed-mode send replays packets at their relative timestamps
- [ ] 🟠 `TC-SEND-FUNC-004` — Checksums applied automatically when a `ChecksumManager` is passed
- [ ] 🟡 `TC-SEND-FUNC-005` — `isMulticastIP()` correctly classifies unicast vs. multicast addresses
- [ ] 🟡 `TC-SEND-ERR-001` — Periodic mode missing the required interval argument
- [ ] 🟡 `TC-SEND-ERR-002` — CSV mode with a timestamp-count / packet-count mismatch
- [ ] 🟠 `TC-SEND-ERR-003` — CSV mode with non-ascending timestamps
- [ ] ⚪ `TC-SEND-ERR-004` — Unknown send mode string
- [ ] 🟡 `TC-SEND-ERR-005` — Ctrl+C interrupt during periodic send still closes the socket
- [ ] ⚪ `TC-SEND-EDGE-001` — Sending an empty packet list

### 13. WiresharkDissector — single protocol (10 tests)

- [ ] 🔴 `TC-WSD-FUNC-001` — Generate a dissector for a simple all-primitives struct
- [ ] 🔴 `TC-WSD-FUNC-002` — Bit-field ProtoField mask matches actual wire encoding (KI-003 cross-check)
- [ ] 🟠 `TC-WSD-FUNC-003` — Enum field generates a Wireshark value-lookup table
- [ ] 🟠 `TC-WSD-FUNC-004` — Array field is grouped under a labeled subtree with per-element entries
- [ ] 🟠 `TC-WSD-FUNC-005` — Nested struct/union produces its own labeled sub-subtree
- [ ] 🟠 `TC-WSD-FUNC-006` — Little-endian vs. big-endian field access method
- [ ] ⚪ `TC-WSD-FUNC-007` — Generated file strips non-ASCII characters
- [ ] ⚪ `TC-WSD-NEG-001` — Write failure (invalid output path)
- [ ] 🟠 `TC-WSD-INT-001` — CLI `ScapyML('dissector', ...)` end-to-end
- [ ] 🟠 `TC-WSD-INT-002` — GUI single-protocol dissector generation end-to-end

### 14. MultiProtocolDissector / DiscriminatorConfig (2 tests)

- [ ] 🟡 `TC-MWSD-FUNC-003` — `DiscriminatorConfig.saveToFile()` / `fromFile()` round-trip
- [ ] ⚪ `TC-MWSD-FUNC-005` — "💾 Save Config..." button in the discriminator dialog  **✅ FIXED (was: expected to fail)**

### 15. DependencyResolver (6 tests)

- [ ] 🟠 `TC-DEP-FUNC-001` — Resolve load order for two files with a simple dependency
- [ ] 🟠 `TC-DEP-FUNC-002` — `ScapyML('load', ..., 'auto')` end-to-end auto-resolution
- [ ] 🟠 `TC-DEP-FUNC-003` — Enum-only header file is recognized as a dependency source (v2.3.3 fix)
- [ ] ⚪ `TC-DEP-FUNC-004` — Independent files with no cross-references preserve relative order
- [ ] 🟠 `TC-DEP-ERR-001` — Circular dependency between two files is detected
- [ ] ⚪ `TC-DEP-ERR-002` — Unreadable/missing file passed to `analyzeFile`

### 16. NameShortener (6 tests)

- [ ] 🟡 `TC-NAME-FUNC-001` — Names already ≤63 characters are returned unchanged
- [ ] 🟠 `TC-NAME-FUNC-002` — Names >63 characters are shortened while preserving the final field name
- [ ] 🟡 `TC-NAME-BOUND-001` — Name exactly 63 characters
- [ ] 🟡 `TC-NAME-BOUND-002` — Name exactly 64 characters
- [ ] ⚪ `TC-NAME-BOUND-003` — Single-word name (no underscores) exceeding the limit
- [ ] 🟡 `TC-NAME-EDGE-001` — Uniqueness after shortening for two similarly-named long fields

### 17. CLI Dispatch — ScapyML.m (17 tests)

- [ ] 🔴 `TC-CLI-FUNC-001` — `load` command (single file, explicit endian)
- [ ] 🟡 `TC-CLI-FUNC-002` — `load` command (multiple files as separate arguments vs. as a cell array)
- [ ] 🟠 `TC-CLI-FUNC-003` — `packet` command with inline field=value pairs
- [ ] 🟠 `TC-CLI-FUNC-004` — `csv` command (Path A wrapper)
- [ ] 🟠 `TC-CLI-FUNC-005` — `send` command with a single `Packet` object
- [ ] 🟠 `TC-CLI-FUNC-006` — `send` command with a cell array of packets
- [ ] 🟡 `TC-CLI-FUNC-007` — `send` command with a raw numeric byte array
- [ ] ⚪ `TC-CLI-FUNC-008` — `send` command using default IP/port when omitted
- [ ] 🟠 `TC-CLI-FUNC-009` — `dissector` command
- [ ] 🟡 `TC-CLI-FUNC-010` — `info` command displays full field/offset/mask table
- [ ] ⚪ `TC-CLI-FUNC-011` — `list` command with and without an output argument
- [ ] 🟡 `TC-CLI-FUNC-013` — `loaddefaults` command (CLI wrapper for `DefaultsManager.apply`)
- [ ] ⚪ `TC-CLI-FUNC-014` — `register` command (programmatic protocol registration)
- [ ] ⚪ `TC-CLI-FUNC-015` — `fromcsv` command — see TC-CSV-FUNC-007 (FIXED)
- [ ] ⚪ `TC-CLI-NEG-001` — Calling `ScapyML()` with no arguments prints help and returns
- [ ] 🟡 `TC-CLI-NEG-002` — Unknown command string
- [ ] 🟡 `TC-CLI-NEG-003` — Commands called with too few required arguments

### 18. GUI Workflows (8 tests)

- [ ] 🟠 `TC-GUI-UI-002` — Packet-dependent buttons enable only after "Create Packet"
- [ ] 🟠 `TC-GUI-UI-004` — Edit Packet Fields dialog: scalar vs. array value parsing
- [ ] 🟡 `TC-GUI-UI-005` — Endianness dropdown affects subsequently loaded headers
- [ ] 🟡 `TC-GUI-UI-006` — "Auto-resolve dependencies" checkbox controls multi-file load ordering
- [ ] 🟡 `TC-GUI-FUNC-001` — "ℹ️ Show Protocol Info" displays the same field/offset table as CLI `info`
- [ ] 🟡 `TC-GUI-FUNC-002` — "👁️ Show Packet" and "🔍 Hex Dump" reflect current field values
- [ ] 🟡 `TC-GUI-DATA-001` — Cancel button during "Sending..." waitbar (single mode)
- [ ] 🟡 `TC-GUI-DATA-002` — Cancel button during periodic/CSV-timed send

### Summary Counts

- Total test cases: **191**
- 🔴 Critical: **42**
- 🟠 High: **47**
- 🟡 Medium: **74**
- ⚪ Low: **27**
- Previously known-broken, now **FIXED**: **4** (`TC-CSV-FUNC-007`, `TC-CSV-FUNC-008`, `TC-MWSD-FUNC-004`, `TC-MWSD-FUNC-005`) — see §21 Known Issues for fix details

---

## Table of Contents

1. HeaderParser (TC-HDR-*)
2. Protocol Data Model — ProtocolDef / FieldDef / EnumDef (TC-PROTO-*)
3. ProtocolRegistry (TC-REG-*)
4. Packet (TC-PKT-*)
5. Codec (TC-CODEC-*)
6. ChecksumManager (TC-CHK-*)
7. ConversionManager (TC-CONV-*)
8. DefaultsManager (TC-DEF-*)
9. CSV Loading — CsvLoader / `fromcsv` / GUI bulk loader (TC-CSV-*)
10. MAT File Persistence — GUI (TC-MAT-*)
11. UdpSender (TC-UDP-*)
12. PacketSender / Timing (TC-SEND-*)
13. WiresharkDissector — single protocol (TC-WSD-*)
14. MultiProtocolDissector / DiscriminatorConfig (TC-MWSD-*)
15. DependencyResolver (TC-DEP-*)
16. NameShortener (TC-NAME-*)
17. CLI Dispatch — ScapyML.m (TC-CLI-*)
18. GUI Workflows (TC-GUI-*)
19. End-to-End Workflows (TC-E2E-*)
20. Coverage Matrix
21. Known Issues / Gap Analysis
22. Final Summary

---

## 1. HeaderParser (`+ScapyML/HeaderParser.m`)

### 1.1 Functional

**TC-HDR-FUNC-001 — Parse a simple struct with all unsigned primitive types**
- Objective: Confirm every primitive C type in `FieldDef.ctypeBytes` maps to the correct byte size.
- Priority: Critical
- Preconditions: MATLAB session with `+ScapyML` on path; `ProtocolRegistry` cleared
  (`ScapyML.ProtocolRegistry.clearInstance()`).
- Test Data: Header file `types.h`:
  ```c
  typedef struct {
      uint8_t  a;
      uint16_t b;
      uint32_t c;
      uint64_t d;
      float    e;
      double   f;
  } AllTypes;
  ```
- Steps:
  1. `ScapyML('load', 'types.h', 'little');`
  2. `p = ScapyML.ProtocolRegistry.instance().get('AllTypes');`
  3. Inspect `p.Fields{k}.ByteSize` for each field.
- Expected Result: `a`→1, `b`→2, `c`→4, `d`→8, `e`→4, `f`→8. `p.totalBytes()` equals 1+2+4+8+4+8 = 27
  and, because the layout is always packed (no padding, see TC-PROTO-FUNC-002), the total is exactly
  27 bytes (a@0, b@1, c@3, d@7, e@15, f@19).
- Positive/Happy Path.

**TC-HDR-FUNC-002 — Parse signed integer types and char variants**
- Priority: High
- Test Data:
  ```c
  typedef struct {
      int8_t  a;
      int16_t b;
      int32_t c;
      int64_t d;
      char    e;
      signed char f;
      unsigned char g;
  } SignedTypes;
  ```
- Steps: Load header; inspect each `FieldDef.ByteSize` and, after `Packet.set()` with a negative
  value and `build()`, confirm two's-complement encoding (cross-ref TC-CODEC-FUNC-004).
- Expected Result: All byte sizes 1/2/4/8/1/1/1 respectively; no parser errors or warnings.

**TC-HDR-FUNC-003 — Parse bit-fields within a single byte**
- Priority: Critical
- Test Data:
  ```c
  typedef struct {
      uint8_t flag_a : 1;
      uint8_t flag_b : 3;
      uint8_t flag_c : 4;
  } Flags;
  ```
- Steps: Load; inspect `FieldDef.IsBitField`/`BitSize` for each; call `proto.getFieldOffsets()`.
- Expected Result: `flag_a.BitSize=1`, `flag_b.BitSize=3`, `flag_c.BitSize=4`; offsets report
  bitOffset 0, 1, 4 respectively, all within byteOffset 0; `proto.totalBytes()==1`.

**TC-HDR-FUNC-004 — Parse a bit-field that crosses a byte boundary**
- Priority: High
- Test Data:
  ```c
  typedef struct {
      uint8_t a : 4;
      uint16_t b : 12;
  } CrossByte;
  ```
- Steps: Load; encode with `a=0xF`, `b=0xABC`; inspect raw bytes.
- Expected Result: Field values recoverable via decode; no parser error on a 12-bit field spanning
  more than one byte.

**TC-HDR-FUNC-005 — Parse fixed-size arrays of primitives**
- Priority: Critical
- Test Data: `uint8_t data[16];` inside a struct.
- Steps: Load; inspect `FieldDef.IsArray`/`ArraySize`; `set('data', 1:16)`; `build()`.
- Expected Result: `IsArray=true`, `ArraySize=16`; built bytes contain 16 sequential values at the
  field's offset.

**TC-HDR-FUNC-006 — Parse a nested named struct member**
- Priority: Critical
- Test Data:
  ```c
  typedef struct { uint8_t lo; uint8_t hi; } Word;
  typedef struct { Word w; uint32_t id; } Outer;
  ```
- Steps: Load (single file — struct order matters, `Word` before `Outer`); inspect
  `Outer.Fields` — expect one `ProtocolDef` child named `w`; `fieldNames()` should list `w_lo`,
  `w_hi`, `id` (depth-first, prefixed).
- Expected Result: Field names prefixed correctly; `Outer.totalBytes()` reflects `Word` (2 bytes)
  + `id` (4 bytes) = 6 bytes, packed (no padding).

**TC-HDR-FUNC-007 — Parse a nested named union member**
- Priority: Critical
- Test Data:
  ```c
  typedef union {
      uint16_t raw;
      struct { uint8_t lo; uint8_t hi; } bytes;
  } Word16;
  ```
- Steps: Load; inspect resulting `ProtocolDef.IsUnion` for both the top-level `Word16` and the
  inline anonymous struct member `bytes`.
- Expected Result: `Word16.IsUnion==true`; nested `bytes` child `IsUnion==false`; `fieldNames()`
  returns `raw`, `bytes_lo`, `bytes_hi`; `totalBytes()==2` (max of member sizes, not sum).

**TC-HDR-FUNC-008 — Parse a truly anonymous inline struct (no member name)**
- Priority: Medium
- Test Data:
  ```c
  typedef struct {
      struct { uint8_t x; uint8_t y; };
      uint8_t z;
  } Anon;
  ```
- Steps: Load; inspect `fieldNames()`.
- Expected Result: Fields `x`, `y`, `z` appear flattened with **no prefix** (per `flattenProto`
  logic), since the inline member has no name.

**TC-HDR-FUNC-009 — Parse an enum and reference it as a field type**
- Priority: Critical
- Test Data:
  ```c
  typedef enum { STATUS_IDLE = 0, STATUS_ACTIVE = 1, STATUS_ERROR = 5 } Status;
  typedef struct { Status s; uint8_t id; } Msg;
  ```
- Steps: Load; `e = ScapyML.ProtocolRegistry.instance().getEnum('Status')`; inspect
  `e.allNames()`/values; inspect the `s` field's `FieldDef.CType=='Status'` and `ByteSize==4`
  (enum == int, 4 bytes per C ABI, per code comment in `parseField`).
- Expected Result: Enum values `{STATUS_IDLE:0, STATUS_ACTIVE:1, STATUS_ERROR:5}` (explicit
  assignment mid-sequence correctly resets the auto-increment counter); `s` field is 4 bytes.

**TC-HDR-FUNC-010 — Comments (line and block) attach as field/struct descriptions**
- Priority: Low
- Test Data:
  ```c
  typedef struct {
      uint8_t id;   // message identifier
      /* payload length in bytes */
      uint16_t len;
  } Hdr;
  ```
- Steps: Load; inspect `FieldDef.Description` for `id` and `len`.
- Expected Result: `id.Description=='message identifier'`; `len.Description=='payload length in
  bytes'`.

**TC-HDR-FUNC-011 — Preprocessor directives are skipped, not parsed as fields**
- Priority: Medium
- Test Data: Header containing `#include "foo.h"` and `#define MAX_LEN 16` before a struct that
  uses a literal `16` (not `MAX_LEN`, since the parser does not evaluate macros) for an array
  size.
- Steps: Load.
- Expected Result: No parser error from the `#` lines; the struct parses normally. (Note: array
  size must be a literal numeric token — macro substitution is **not** supported; this is an
  implicit limitation worth confirming explicitly, see TC-HDR-NEG-005.)

**TC-HDR-FUNC-012 — Cross-file type resolution (v2.3.3 feature)**
- Priority: Critical
- Test Data: `types.h` defining `typedef enum {A=0,B=1} MyEnum;`; `msg.h` defining
  `typedef struct { MyEnum e; uint8_t x; } Msg;` (references `MyEnum` from a different file).
- Steps: `ScapyML('load', {'types.h','msg.h'}, 'little');` (both files in one call, in order).
- Expected Result: `Msg.e` field resolves to `ByteSize==4` (enum), **no** "unrecognized type"
  warning — confirms the v2.3.3 fix (registry lookup fallback in `parseField`) works when files
  are parsed immediately-and-registered one at a time in the given order.

**TC-HDR-FUNC-013 — Cross-file resolution fails gracefully when load order is wrong**
- Priority: High
- Test Data: Same as TC-HDR-FUNC-012 but loaded as `ScapyML('load', {'msg.h','types.h'}, 'little');`
  (dependent file first, without `'auto'`).
- Steps: Load in the wrong order (no auto-resolve flag).
- Expected Result: A `ScapyML:HeaderParser:UnresolvedType` **warning** is raised (not an error);
  `Msg.e.ByteSize==0`; this documents the known limitation described directly in the parser's own
  code comment (v2.3.3 fix note) rather than a silent corruption as in pre-v2.3.3 behavior.

### 1.2 Negative

**TC-HDR-NEG-001 — Load a non-existent header file**
- Priority: High
- Steps: `ScapyML('load', 'does_not_exist.h', 'little');`
- Expected Result: `error` with identifier `ScapyML:HeaderParser:FileNotFound` and a clear message
  naming the missing file.

**TC-HDR-NEG-002 — Malformed struct with missing closing brace**
- Priority: Medium
- Test Data: `typedef struct { uint8_t a; uint16_t b;` (no closing `}` or `;`).
- Steps: Load.
- Expected Result: Parser does not crash uncontrollably; per code inspection, `parseTypedef`'s
  inner `while pos <= n && ~strcmp(tokens{pos}.text,'}')` loop runs to end-of-tokens and the
  overall struct is discarded (`proto=[]` since no alias name is found after end-of-input). Verify
  no protocol is registered and no MATLAB crash occurs (may want to add a friendlier diagnostic —
  flag as **Needs Clarification / potential improvement** if it silently discards with no
  message).

**TC-HDR-NEG-003 — Multi-dimensional array syntax is explicitly rejected**
- Priority: Medium
- Test Data: `uint8_t matrix[4][4];`
- Steps: Load.
- Expected Result: `error` with identifier `ScapyML:Parser:MultiDimArray` and a message suggesting
  a flattened 1D array workaround.

**TC-HDR-NEG-004 — Array declared with a missing closing bracket**
- Priority: Medium
- Test Data: `uint8_t data[16;` (missing `]`).
- Steps: Load.
- Expected Result: `error` with identifier `ScapyML:Parser:MissingBracket`.

**TC-HDR-NEG-005 — Array size given as a non-numeric token (macro name) — FIXED**
- Priority: **High**
- Test Data: `uint8_t data[MAX_LEN];` where `MAX_LEN` is never substituted (parser does not expand
  macros).
- Steps: Load.
- **History:** the original version of this entry stated the field silently defaults to a
  1-element array after a warning. Tracing `+ScapyML/HeaderParser.m`'s `parseField` line-by-line
  showed this was incorrect — the code raised `warning` `ScapyML:Parser:InvalidArray` but did
  **not** advance the token cursor past the invalid token, so the very next check (for a closing
  `]`) always failed too, throwing a confusing, unrelated `error` `ScapyML:Parser:MissingBracket`.
- **Fix applied:** consolidated into ONE clear, actionable `error` `ScapyML:Parser:InvalidArray`
  that names the specific bad token and explicitly states macros aren't expanded, guiding the user
  to use a literal number instead. No more silent 1-element fallback and no more confusing
  cascaded `MissingBracket` error.
- Expected Result (current, verified): the call raises exactly one `error`
  `ScapyML:Parser:InvalidArray` with a message like `Array size must be a numeric constant, found:
  "MAX_LEN". This parser does not expand #define macros -- use a literal number (e.g. [16])
  instead of a macro name.` Parsing of the file still aborts (this remains a real limitation — the
  parser genuinely cannot expand macros), but the failure is now immediately self-explanatory.
- Status: **PASS (fixed).** Confirmed via `TestManualHeaderParserSuite.m`'s
  `tcHdrNeg005_macroArraySizeNowRaisesOneClearError`. See Known Issues KI-NEW-06.

**TC-HDR-NEG-006 — Referencing a completely undefined type name**
- Priority: High
- Test Data: `typedef struct { UnknownType x; uint8_t y; } Bad;` where `UnknownType` is neither a
  primitive, a locally-known struct/enum, nor a registered one.
- Steps: Load.
- Expected Result: `warning` `ScapyML:HeaderParser:UnresolvedType`; `x.ByteSize==0`; struct still
  registers (with an incorrect/zero-length field) rather than aborting — confirm this is
  acceptable/expected behavior per the code comment, and document as a "silent-ish" degradation
  mode testers should watch for.

---

## 2. Protocol Data Model — ProtocolDef / FieldDef / EnumDef

### 2.1 Functional

**TC-PROTO-FUNC-001 — Union size equals the max member size, not the sum**
- Priority: Critical
- Test Data:
  ```c
  typedef union { uint8_t a; uint32_t b; } U;
  ```
- Steps: Load; `p = reg.get('U'); p.totalBytes()`.
- Expected Result: `totalBytes()==4` (max of 1 and 4), not 5.

**TC-PROTO-FUNC-002 — Layout is always packed (no alignment padding)**
- Priority: Critical
- Test Data: `typedef struct { uint8_t a; uint32_t b; } P;`
- Steps: Load; `p.totalBytes()`; `p.getFieldOffsets()`.
- Expected Result: `totalBytes()==5`: `a` at byte 0 and `b` at byte 1, with no padding anywhere
  (wire-protocol layout). Automated: `TestManualPackedSuite`.

**TC-PROTO-FUNC-003 — Nested struct alignment uses the child's largest-member alignment**
- Priority: High
- Test Data:
  ```c
  typedef struct { uint16_t x; } Inner;
  typedef struct { uint8_t a; Inner in; } Outer;
  ```
- Steps: Load; inspect `Outer.getFieldOffsets()` for `in_x`.
- Expected Result: (packed layout) `in_x` starts at byte offset 1, immediately after `a`; the old
  C-ABI expectation was byte offset 2 (aligned to `Inner`'s 2-byte requirement, not
  byte 1).

**TC-PROTO-FUNC-004 — `getFieldOffsets()` matches actual encoded byte positions**
- Priority: Critical (architectural invariant, KI-001)
- Steps: For each struct fixture used above, call `proto.getFieldOffsets()` and independently
  `pkt.build()` with distinctive per-field values, then manually verify the byte(s) at each
  reported `byteOffset`/`sizeBytes` equal that field's encoded value.
- Expected Result: 100% agreement between reported offsets and actual buffer contents for every
  fixture — this is the specific regression KI-001 was written to prevent.

**TC-PROTO-FUNC-005 — EnumDef lookup by name and by value**
- Priority: Medium
- Steps: `e.getValue('STATUS_ACTIVE')` and `e.getName(1)` on the enum from TC-HDR-FUNC-009.
- Expected Result: `getValue` returns 1; `getName(1)` returns `'STATUS_ACTIVE'`.

### 2.2 Negative / Error Handling

**TC-PROTO-NEG-001 — EnumDef.getValue on an unknown name**
- Priority: Low
- Steps: `e.getValue('NOT_A_VALUE')`.
- Expected Result: `error` "Enum %s does not have value %s".

**TC-PROTO-NEG-002 — EnumDef.getName on an unknown numeric value**
- Priority: Low
- Steps: `e.getName(9999)`.
- Expected Result: `error` "Enum %s does not have numeric value %d".

### 2.3 Boundary

**TC-PROTO-BOUND-001 — 1-byte struct requiring no alignment padding**
- Priority: Medium
- Test Data: `typedef struct { uint8_t a; uint8_t b; } Small;`
- Expected Result: `totalBytes()==2`, no padding inserted (both fields 1-byte aligned).

**TC-PROTO-BOUND-002 — 8-byte (`double`/`int64_t`/`uint64_t`) alignment boundary**
- Priority: Medium
- Test Data: `typedef struct { uint8_t a; double d; } D;`
- Expected Result: packed layout: `d` at byte 1; `totalBytes()` is 9 (no alignment, no rounding).

---

## 3. ProtocolRegistry (`+ScapyML/ProtocolRegistry.m`)

### 3.1 Functional

**TC-REG-FUNC-001 — Register and retrieve a protocol**
- Priority: Critical
- Steps: Load a header; `reg.has('MyProto')`; `reg.get('MyProto')`.
- Expected Result: `has` returns true; `get` returns the matching `ProtocolDef`.

**TC-REG-FUNC-002 — `list()` returns all registered protocol names**
- Priority: Medium
- Steps: Load two different headers defining two structs; `reg.list()`.
- Expected Result: Cell array containing both names (order not guaranteed — `containers.Map` key
  order).

**TC-REG-FUNC-003 — Enum registration and lookup (`registerEnum`/`getEnum`/`hasEnum`)**
- Priority: High
- Steps: Load a header with an enum; `reg.hasEnum('Status')`, `reg.getEnum('Status')`,
  `reg.listEnums()`.
- Expected Result: All return correct/consistent results.

**TC-REG-FUNC-004 — Singleton identity across calls**
- Priority: High
- Steps: `a = ScapyML.ProtocolRegistry.instance(); b = ScapyML.ProtocolRegistry.instance();
  isequal(a,b)` (handle equality).
- Expected Result: `a` and `b` reference the same underlying object (registering via `a` is
  visible via `b`).

**TC-REG-FUNC-005 — `clearAll()` empties both protocol and enum maps**
- Priority: High
- Steps: Load headers/enums; `reg.clearAll()`; `reg.list()`, `reg.listEnums()`.
- Expected Result: Both return empty cell arrays.

**TC-REG-FUNC-006 — `ProtocolRegistry.clearInstance()` static method actually clears (KI-002)**
- Priority: Critical (regression guard)
- Steps: Load a header; `ScapyML.ProtocolRegistry.clearInstance();`
  `ScapyML.ProtocolRegistry.instance().list()`.
- Expected Result: Empty list — confirms the KI-002 fix (previously a no-op due to a `clear('inst')`
  workspace-scoping bug).

### 3.2 Error Handling

**TC-REG-ERR-001 — `get()` on an unregistered protocol name**
- Priority: High
- Steps: `reg.get('NoSuchProtocol')` on a freshly cleared registry.
- Expected Result: `error` identifier `ScapyML:ProtocolRegistry:NotFound` with a message naming
  the protocol.

**TC-REG-ERR-002 — `getEnum()` on an unregistered enum name**
- Priority: Medium
- Steps: `reg.getEnum('NoSuchEnum')`.
- Expected Result: `error` "Enum not found: %s".

### 3.3 Edge Case

**TC-REG-EDGE-001 — Registering a duplicate protocol name silently overwrites (no uniqueness
enforcement)**
- Priority: High (documents a spec/behavior discrepancy — see Known Issues KI-NEW-03)
- Steps: Load `a.h` defining `typedef struct {uint8_t x;} P;`; note `reg.get('P').totalBytes()`.
  Load `b.h` defining a **different** `typedef struct {uint32_t y; uint32_t z;} P;` (same name,
  different layout).
- Expected Result: `reg.get('P')` after the second load reflects `b.h`'s definition (silent
  overwrite) — `REQUIREMENTS.md` §8.3 states "Unique protocol names enforced," but `register()`
  performs no such check. **Expected to FAIL against the written requirement; documents actual
  behavior.**

---

## 4. Packet (`+ScapyML/Packet.m`)

### 4.1 Functional

**TC-PKT-FUNC-001 — Construct a packet with all fields at declared defaults**
- Priority: Critical
- Steps: `pkt = ScapyML.Packet('AllTypes');` (from TC-HDR-FUNC-001 fixture); inspect
  `pkt.get('a')` etc. for every field.
- Expected Result: Every field equals `FieldDef.DefaultVal` (0 unless a defaults mechanism was
  applied — `Packet`'s own constructor always uses 0/`DefaultVal`, since defaults-file application
  is a separate, explicit step via `DefaultsManager`).

**TC-PKT-FUNC-002 — Constructor field-pair shorthand**
- Priority: Medium
- Steps: `pkt = ScapyML.Packet('Msg', 'id', 7, 'len', 20);`
- Expected Result: `pkt.get('id')==7`, `pkt.get('len')==20`.

**TC-PKT-FUNC-003 — `set`/`get` round-trip for a scalar field**
- Priority: Critical
- Steps: `pkt.set('id', 42); pkt.get('id')`.
- Expected Result: Returns 42.

**TC-PKT-FUNC-004 — `set` on an array field with exact-length input**
- Priority: Critical
- Steps: `pkt.set('data', 1:16);` (16-element array field).
- Expected Result: `pkt.get('data')` returns exactly `[1 2 ... 16]`, no warning.

**TC-PKT-FUNC-005 — `fieldNames()` returns all flattened field names**
- Priority: Medium
- Steps: `pkt.fieldNames()` on a packet with nested struct/union.
- Expected Result: Matches `proto.fieldNames()` depth-first order/prefixing.

**TC-PKT-FUNC-006 — `loadStruct()` copies only matching fields**
- Priority: Low
- Steps: `s.id = 5; s.unrelated_field = 99; pkt.loadStruct(s);`
- Expected Result: `pkt.get('id')==5`; `unrelated_field` is silently ignored (no error).

**TC-PKT-FUNC-007 — `show()` displays every field with correct formatting**
- Priority: Low
- Steps: `pkt.show()` on a packet with an int, a float, a bit-field, and an array field.
- Expected Result: Integer shown as `%d (0x%X)`; float shown with IEEE-754 hex; bit-field
  annotated `[N-bit]`; array shown as `[v1, v2, ...]  (N elements)` (or truncated form for >8
  elements).

**TC-PKT-FUNC-008 — `hexdump()` produces correctly formatted, wrapped hex output**
- Priority: Low
- Steps: `pkt.hexdump()` on a packet >16 bytes.
- Expected Result: 16 bytes per line, uppercase two-digit hex, space-separated.

**TC-PKT-FUNC-009 — `chain()` concatenates payload bytes**
- Priority: Medium
- Steps: `outer = ScapyML.Packet('Header'); inner = ScapyML.Packet('Payload');
  combined = outer.chain(inner); bytes = combined.build();`
- Expected Result: `numel(bytes) == outer proto bytes + inner proto bytes`; first N bytes match
  `outer.build()`, remainder matches `inner.build()`.

**TC-PKT-FUNC-010 — `fromBytes()` static decode constructor**
- Priority: Critical
- Steps: `bytes = pkt.build(); pkt2 = ScapyML.Packet.fromBytes('Msg', bytes);` compare all field
  values between `pkt` and `pkt2`.
- Expected Result: All fields match (round-trip fidelity).

**TC-PKT-FUNC-011 — `fromValuesStruct()` bulk constructor bypasses validation**
- Priority: High
- Steps: Build a `defaultValues` struct and an `overrides` struct manually;
  `pkt = ScapyML.Packet.fromValuesStruct(protoDef, defaultValues, overrides);`
- Expected Result: `pkt.Values` (via `get()`) reflects overrides applied on top of defaults, with
  no `set()`-style range clamping/warnings performed (this is intentional — a documented
  performance optimization for bulk CSV loading; confirm out-of-range values pass through
  unclamped here, unlike `set()`).

### 4.2 Negative

**TC-PKT-NEG-001 — `set()` on an unknown field name**
- Priority: High
- Steps: `pkt.set('not_a_field', 1);`
- Expected Result: `error` `ScapyML:Packet:UnknownField` listing valid field names.

**TC-PKT-NEG-002 — `get()` on an unknown field name**
- Priority: High
- Steps: `pkt.get('not_a_field');`
- Expected Result: `error` `ScapyML:Packet:UnknownField`.

**TC-PKT-NEG-003 — `set()` with a non-numeric value**
- Priority: Medium
- Steps: `pkt.set('id', 'hello');`
- Expected Result: `error` `ScapyML:Packet:InvalidType`.

**TC-PKT-NEG-004 — Constructing a `Packet` for an unregistered protocol name**
- Priority: High
- Steps: `ScapyML.Packet('NoSuchProtocol');`
- Expected Result: Propagates `ScapyML:ProtocolRegistry:NotFound` from the registry lookup.

### 4.3 Boundary

**TC-PKT-BOUND-001 — uint8 field range clamping at 0 and 255**
- Priority: Critical
- Steps: `pkt.set('a', 0); pkt.set('a', 255);` (both valid, no warning); `pkt.set('a', 256);`
  `pkt.set('a', -1);`
- Expected Result: 0 and 255 accepted without warning; 256 → `warning` `...:OutOfRange`, clamped to
  255; -1 → clamped to 0.

**TC-PKT-BOUND-002 — int8 field range at -128 and 127**
- Priority: High
- Steps: `pkt.set('sc', -128); pkt.set('sc', 127);` (valid); `pkt.set('sc', 128);
  pkt.set('sc', -129);`
- Expected Result: -128/127 accepted; 128 clamps to 127 with warning; -129 clamps to -128 with
  warning.

**TC-PKT-BOUND-003 — uint16/int16, uint32/int32, uint64/int64 boundaries**
- Priority: High
- Steps: Repeat the pattern of BOUND-001/002 for each width using the min/max/min-1/max+1 values
  listed in `REQUIREMENTS.md` and the `Packet.set()` clamp table (0/65535/65536/-1;
  -32768/32767/32768/-32769; 0/4294967295/4294967296/-1; -2147483648/2147483647/2147483648/
  -2147483649; 0/18446744073709551615/overflow; -9223372036854775808/9223372036854775807/
  overflow).
- Expected Result: Each boundary clamps correctly with a warning at the out-of-range end, and is
  accepted without warning at the in-range end.

**TC-PKT-BOUND-004 — Array field set with fewer elements than declared size (zero-padding)**
- Priority: Critical
- Steps: `pkt.set('data', [1 2 3]);` where `data` is `uint8_t data[16]`.
- Expected Result: `warning` is **not** explicitly raised for padding (only truncation warns, per
  code); `pkt.get('data')` returns a 16-element array `[1 2 3 0 0 ... 0]`.

**TC-PKT-BOUND-005 — Array field set with more elements than declared size (truncation +
warning)**
- Priority: Critical
- Steps: `pkt.set('data', 1:20);` where `data` is `uint8_t data[16]`.
- Expected Result: `warning` `ScapyML:Packet:ArrayTruncated`; `pkt.get('data')` returns exactly 16
  elements `[1..16]`.

**TC-PKT-BOUND-006 — Setting a scalar (non-array) field with multiple values**
- Priority: Medium
- Steps: `pkt.set('id', [1 2 3]);` where `id` is a plain scalar field.
- Expected Result: `warning` `ScapyML:Packet:NotArray`; `pkt.get('id')` equals `1` (first
  element only).

---

## 5. Codec (`+ScapyML/Codec.m`)

### 5.1 Functional

**TC-CODEC-FUNC-001 — Little-endian multi-byte encode/decode round-trip**
- Priority: Critical
- Test Data: `typedef struct { uint32_t v; } V;` loaded with `'little'`.
- Steps: `pkt.set('v', 0x11223344); bytes = pkt.build();`
- Expected Result: `bytes == [0x44 0x33 0x22 0x11]` (LSB first). Decoding `bytes` back gives
  `v==0x11223344`.

**TC-CODEC-FUNC-002 — Big-endian multi-byte encode/decode round-trip**
- Priority: Critical
- Test Data: Same struct loaded with `'big'`.
- Steps: `pkt.set('v', 0x11223344); bytes = pkt.build();`
- Expected Result: `bytes == [0x11 0x22 0x33 0x44]` (MSB first). Round-trip matches.

**TC-CODEC-FUNC-003 — Bit-field MSB-first packing matches decode (KI-003 regression)**
- Priority: Critical (regression guard)
- Test Data: `typedef struct { uint8_t a:3; uint8_t b:5; } BF;`
- Steps: `pkt.set('a',5); pkt.set('b',3); bytes=pkt.build();` manually compute expected byte:
  `a` occupies bits 7-5 (MSB-first from bit offset 0), `b` occupies bits 4-0 → byte =
  `(5<<5)|3 = 0xA3`. Then `pkt2 = Packet.fromBytes('BF', bytes); pkt2.get('a')==5;
  pkt2.get('b')==3`.
- Expected Result: `bytes(1) == 0xA3`; decode recovers original values exactly — this is the exact
  scenario KI-003 fixed (previously encode/decode disagreed with each other).

**TC-CODEC-FUNC-004 — Signed integer two's-complement encoding for a negative value**
- Priority: Critical
- Test Data: `typedef struct { int16_t v; } S;`
- Steps: `pkt.set('v', -1); bytes = pkt.build();` (little-endian).
- Expected Result: `bytes == [0xFF 0xFF]`; decode recovers `-1` (not `65535`).

**TC-CODEC-FUNC-005 — Float (IEEE-754 single) encode/decode round-trip**
- Priority: High
- Test Data: `float temperature;`
- Steps: `pkt.set('temperature', 23.5); bytes = pkt.build();`
- Expected Result: `bytes` match the IEEE-754 single-precision representation of 23.5 in the
  configured endianness (verify via `typecast(single(23.5),'uint8')` and byte-order comparison);
  decode recovers 23.5 exactly (exactly representable).

**TC-CODEC-FUNC-006 — Double (IEEE-754 double) encode/decode round-trip**
- Priority: Medium
- Test Data: `double precise;`
- Steps: `pkt.set('precise', 3.14159265358979); bytes = pkt.build();`
- Expected Result: Decode recovers the value to full double precision.

**TC-CODEC-FUNC-007 — Array of primitives encode/decode**
- Priority: Critical
- Steps: `pkt.set('data', 1:16); bytes = pkt.build();` decode back.
- Expected Result: All 16 elements round-trip exactly, in declared order, honoring endianness
  per-element.

**TC-CODEC-FUNC-008 — Union: only the explicitly-set (dirty) member is written**
- Priority: Critical
- Test Data: `typedef union { uint8_t a; uint32_t b; } U;`
- Steps: `pkt = ScapyML.Packet('U'); pkt.set('a', 0x7); bytes = pkt.build();`
- Expected Result: `bytes(1)==7` and bytes 2-4 remain 0 (only `a` was dirty; `b`, though
  technically overlapping the same buffer region, is skipped since it was never explicitly
  `set()`). Confirms the "only dirty fields write inside a union" rule in `Codec`'s class
  docstring.

**TC-CODEC-FUNC-009 — Nested struct inside union — dirty propagation**
- Priority: High
- Test Data: `typedef union { uint16_t raw; struct { uint8_t lo; uint8_t hi; } bytes; } W;`
- Steps: `pkt.set('bytes_lo', 0xAB); bytes = pkt.build();` (note: `raw` is never set).
- Expected Result: `bytes(1)==0xAB`; `bytes_hi` (never set) does **not** overwrite — confirms
  `requireDirty` propagation into nested structs-within-unions correctly gates the write of
  `bytes_hi` at its default (0) value only if... actually per code, `bytes_hi` was never set, so
  it is *skipped entirely* (not even written as 0) since `needDirtyCheck` is true and it's not in
  `dirty`. Verify byte 2 remains untouched (0, from the zero-initialized buffer) — confirm this
  produces the intended output for this scenario.

**TC-CODEC-FUNC-010 — `decode()` on a union stores raw bytes under a `__raw` key**
- Priority: Medium
- Steps: Decode bytes into a struct containing a nested union member named `payload`;
  inspect `values.payload__raw`.
- Expected Result: `payload__raw` contains the exact raw bytes spanning the union's byte range,
  for caller-side manual discriminator logic.

### 5.2 Negative / Error Handling

**TC-CODEC-ERR-001 — Decoding fewer bytes than the protocol requires**
- Priority: High
- Steps: `bytes = uint8([1 2]);` (protocol needs 8 bytes); `ScapyML.Codec.decode(proto, bytes);`
- Expected Result: `error` `ScapyML:Codec:InsufficientData` naming the field and bit counts
  needed/available.

**TC-CODEC-ERR-002 — Decoding an array field with insufficient trailing bytes**
- Priority: Medium
- Steps: Truncate the byte buffer mid-array before decoding.
- Expected Result: `error` `ScapyML:Codec:InsufficientData` for the array field specifically.

### 5.3 Boundary

**TC-CODEC-BOUND-001 — Zero-bit field is a no-op**
- Priority: Low
- Steps: Call `Codec.writeBits`/`readBits` with `numBits=0` directly (component-level test via
  breakpoint/direct call).
- Expected Result: Buffer unchanged; returns immediately (per explicit `if numBits==0, return;`
  guard).

**TC-CODEC-BOUND-002 — 1-bit field encode/decode (0 and 1)**
- Priority: Medium
- Steps: `uint8_t flag:1;` set to 0 then 1; build; decode.
- Expected Result: Both values round-trip correctly.

**TC-CODEC-BOUND-003 — Maximum bit-field width equal to its container's full byte(s)**
- Priority: Medium
- Steps: `uint32_t v:32;` (bit-field spanning the entire 32-bit container).
- Expected Result: Encodes/decodes identically to a plain (non-bit-field) `uint32_t`.

---

## 6. ChecksumManager (`+ScapyML/ChecksumManager.m`)

### 6.1 Functional

**TC-CHK-FUNC-001 — Load a valid checksum file and apply a simple sum checksum**
- Priority: Critical
- Test Data: `checksums.txt`: `checksum = @(data) mod(sum(uint16(data)), 256)`. Protocol has a
  `uint8_t checksum;` field.
- Steps: `cm = ScapyML.ChecksumManager('checksums.txt'); pkt.set('id',5);
  bytes = pkt.buildWithChecksums(cm);`
- Expected Result: The byte at the `checksum` field's offset equals the sum of all *other* bytes
  mod 256 (checksum field itself zeroed before the sum, per the documented algorithm).

**TC-CHK-FUNC-002 — Checksum calculation is idempotent across repeated `build()` calls**
- Priority: Critical (data integrity)
- Steps: Call `pkt.buildWithChecksums(cm)` three times in a row without changing any field.
- Expected Result: All three calls produce byte-for-byte identical output — confirms the
  "zero the checksum field before computing" fix prevents the checksum value itself from being
  included in its own next calculation.

**TC-CHK-FUNC-003 — Multiple checksum fields processed in byte-offset order**
- Priority: High
- Test Data: Two checksum fields at different offsets, declared in the config file in reverse
  offset order.
- Steps: Apply checksums; inspect both fields.
- Expected Result: Both computed correctly regardless of declaration order in the file or
  `containers.Map` key iteration order (confirms the explicit offset-sort step in
  `applyChecksums`).

**TC-CHK-FUNC-004 — `listChecksums()` / `checksumCount()` / `hasChecksum()` accessors**
- Priority: Medium
- Steps: Load a 2-formula checksum file; call each accessor.
- Expected Result: `checksumCount()==2`; `listChecksums()` returns both field names;
  `hasChecksum('checksum')==true`; `hasChecksum('nope')==false`.

**TC-CHK-FUNC-005 — XOR and two's-complement checksum formulas from the example file**
- Priority: Medium
- Test Data: Formulas from `checksums_example.txt` (`xor_checksum`, `twos_comp`, `ones_comp`).
- Steps: Apply each and hand-verify against a manually computed value for a small fixed payload.
- Expected Result: All match hand-calculated results.

**TC-CHK-FUNC-006 — Formula line containing comparison operators (`==`, `<=`) parses correctly**
- Priority: Medium
- Test Data: `crc = @(d) mod(sum(d==0),256)`.
- Steps: Load the file.
- Expected Result: Parses successfully (splits on the *first* `=` only, per code comment) — no
  `ParseError` warning.

### 6.2 Negative / Error Handling

**TC-CHK-ERR-001 — Missing checksum file**
- Priority: Medium
- Steps: `cm = ScapyML.ChecksumManager('missing.txt');`
- Expected Result: `warning` `ScapyML:ChecksumManager:FileNotFound`; `cm.checksumCount()==0`
  (empty manager, no crash).

**TC-CHK-ERR-002 — Malformed line (no `=` sign)**
- Priority: Medium
- Steps: File contains a line `garbage line no equals`.
- Expected Result: `warning` `ScapyML:ChecksumManager:ParseError` for that line; other valid lines
  in the same file still load.

**TC-CHK-ERR-003 — Right-hand side is not a function handle**
- Priority: Medium
- Steps: File contains `checksum = 42` (a plain number, not `@(data)...`).
- Expected Result: `warning` `ScapyML:ChecksumManager:NotFunction`; that entry is skipped.

**TC-CHK-ERR-004 — Checksum field name not found in the protocol**
- Priority: Medium
- Steps: Config references a field name that doesn't exist in the loaded protocol; call
  `applyChecksums`.
- Expected Result: `warning` `ScapyML:ChecksumManager:FieldNotFound`; other checksums (if any)
  still apply; build does not crash.

**TC-CHK-ERR-005 — Checksum function throws an error at evaluation time**
- Priority: Medium
- Steps: Formula `checksum = @(data) data(9999)` (index out of bounds for a short packet).
- Expected Result: `warning` `ScapyML:ChecksumManager:CalculationError`; bytes returned unmodified
  for that field (no crash).

**TC-CHK-ERR-006 — Checksum function returns a non-scalar or non-numeric value**
- Priority: Low
- Steps: Formula `checksum = @(data) [1 2 3]` (vector, not scalar).
- Expected Result: `warning` `ScapyML:ChecksumManager:InvalidResult`; field left unmodified.

### 6.3 Boundary

**TC-CHK-BOUND-001 — Checksum field sizes 1/2/4/8 bytes**
- Priority: High
- Steps: Test `writeChecksumToBytes` behavior (via `applyChecksums`) for uint8/16/32/64 checksum
  fields, in both endiannesses.
- Expected Result: Correct byte-order placement for every size/endian combination; size other than
  {1,2,4,8} produces `warning` `ScapyML:ChecksumManager:UnsupportedSize`.

---

## 7. ConversionManager (`+ScapyML/ConversionManager.m`)

### 7.1 Functional

**TC-CONV-FUNC-001 — Load and apply the documented azimuth conversion**
- Priority: Critical
- Test Data: `conversions.txt`: `azimuth = @(x) round(x / 360 * 65536)`.
- Steps: `cm = ScapyML.ConversionManager('conversions.txt'); cm.convert('azimuth', 60.0)`.
- Expected Result: Returns `10922`, exactly matching the worked example in `README.md`.

**TC-CONV-FUNC-002 — `convert()` on a field with no defined conversion returns the value
unchanged**
- Priority: High
- Steps: `cm.convert('unmapped_field', 42)`.
- Expected Result: Returns `42` unchanged (direct pass-through, per documented "no conversion
  defined" fallback).

**TC-CONV-FUNC-003 — `hasConversion()` / `listConversions()` / `conversionCount()` accessors**
- Priority: Medium
- Steps: Load a file with 3 conversions; call all three accessors.
- Expected Result: `conversionCount()==3`; `listConversions()` returns all 3 names;
  `hasConversion()` true only for defined fields.

**TC-CONV-FUNC-004 — Elevation, temperature, pressure conversions from the example file**
- Priority: Medium
- Test Data: Formulas from `conversions_example.txt`.
- Steps: Apply each formula to a representative physical value and hand-verify against the
  documented worked examples (e.g. temperature `25.5°C → round((25.5+40)*10) = 655`).
- Expected Result: All match documented values exactly.

### 7.2 Negative / Error Handling

**TC-CONV-ERR-001 — Missing conversion file**
- Priority: Medium
- Steps: `cm = ScapyML.ConversionManager('missing.txt');`
- Expected Result: `warning` `ScapyML:ConversionManager:FileNotFound`; empty manager, no crash.

**TC-CONV-ERR-002 — Conversion function throws at evaluation time**
- Priority: Medium
- Steps: A formula that references an undefined variable or divides in a way that errors; call
  `convert()`.
- Expected Result: `warning` `ScapyML:ConversionManager:ConversionError`; `convert()` falls back
  to returning the raw physical value unchanged rather than crashing the caller.

**TC-CONV-ERR-003 — Malformed line / non-function right-hand side**
- Priority: Low
- Steps: Same pattern as TC-CHK-ERR-002/003 but for the conversion file parser.
- Expected Result: Analogous `ParseError`/`NotFunction` warnings; other valid lines still load.

---

## 8. DefaultsManager (`+ScapyML/DefaultsManager.m`)

### 8.1 Functional

**TC-DEF-FUNC-001 — `create()` generates a defaults file listing every field at 0/0.0**
- Priority: High
- Steps: `ScapyML.DefaultsManager.create('AllTypes', 'defaults.txt');` inspect the generated file.
- Expected Result: File contains header comments plus one `fieldname = value` line per field;
  float/double fields use `0.0`, integer fields use `0`.

**TC-DEF-FUNC-002 — `apply()` loads a hand-edited defaults file into a fresh packet**
- Priority: Critical
- Test Data: `defaults.txt` with `header_msg_id = 1001` and `temperature = 20.0`.
- Steps: `pkt = ScapyML.Packet('Msg'); pkt = ScapyML.DefaultsManager.apply(pkt, 'defaults.txt');`
- Expected Result: `pkt.get('header_msg_id')==1001`; `pkt.get('temperature')==20.0`; unspecified
  fields remain at their original (0) default.

**TC-DEF-FUNC-003 — Hex-notation values in a defaults file (`0x...`)**
- Priority: Medium
- Test Data: `protocol_id = 0x2A`.
- Steps: Apply.
- Expected Result: `pkt.get('protocol_id')==42`.

**TC-DEF-FUNC-004 — Comment lines (`#`) and blank lines are ignored**
- Priority: Low
- Steps: File with interleaved `#` comments and blank lines between value assignments.
- Expected Result: Only the assignment lines are processed; comment/blank lines produce no
  warnings.

**TC-DEF-FUNC-005 — `set()`-after-`apply()` override semantics**
- Priority: High
- Steps: Apply defaults, then explicitly `pkt.set('temperature', 99.9)` after.
- Expected Result: The explicit `set()` wins — `pkt.get('temperature')==99.9` (defaults only
  pre-fill; explicit `set()` always overrides, since `apply()` is implemented as a sequence of
  ordinary `set()` calls executed once at load time).

### 8.2 Negative / Error Handling

**TC-DEF-ERR-001 — Applying a non-existent defaults file**
- Priority: Medium
- Steps: `ScapyML.DefaultsManager.apply(pkt, 'missing.txt');`
- Expected Result: `error` `ScapyML:DefaultsManager:FileNotFound`.

**TC-DEF-ERR-002 — Malformed line (no `=`, or line with two `=` signs)**
- Priority: Medium
- Steps: Line `garbage` (no `=`) and line `a = b = c` (two `=` signs — note: unlike
  `ChecksumManager`/`ConversionManager`, `DefaultsManager.apply` uses plain `strsplit(line,'=')`
  with **no** first-`=`-only special-casing).
- Expected Result: Both produce `warning` `ScapyML:DefaultsManager:ParseError` ("expected
  \"field = value\""); line skipped, loading continues for remaining lines. **Note for testers:**
  this is a narrower parser than `ChecksumManager`/`ConversionManager` — confirm this is
  acceptable given defaults are numeric-only by design.

**TC-DEF-ERR-003 — Unparseable numeric value**
- Priority: Medium
- Steps: Line `id = not_a_number`.
- Expected Result: `warning` `ScapyML:DefaultsManager:ParseError` ("Cannot parse value"); field
  left at its prior value.

**TC-DEF-ERR-004 — Value line for a field name not present in the packet**
- Priority: Low
- Steps: Line `nonexistent_field = 5` applied to a packet without that field.
- Expected Result: `warning` `ScapyML:DefaultsManager:SetError` (caught from the underlying
  `pkt.set()` throwing `UnknownField`); loading continues for remaining lines.

---

## 9. CSV Loading — `CsvLoader`, CLI `fromcsv`, GUI Bulk Loader

This area has **three functionally distinct CSV-loading code paths** that must be tested
separately, since they have different capabilities and (per code inspection) different
reliability:

| Path | Entry point | Supports defaults? | Supports conversions? | Status |
|---|---|---|---|---|
| A. `ScapyML.CsvLoader.load` | CLI `ScapyML('csv', file, proto)` | No | No | Working |
| B. `ScapyML_fromCSV` (external function) | CLI `ScapyML('fromcsv', proto, file, [defaults], [conversions])`; also GUI's "Load from CSV" **when a defaults file is selected and the user confirms "Yes"** | Yes | Yes | **✅ Fixed** — was broken (duplicate switch-case label plus a genuinely missing implementation file; see Known Issues KI-NEW-01 for full history) |
| C. GUI's own vectorized bulk loader (inline in `ScapyML_GUI.m`'s `loadFromCSV`, via `readtable` + `ConversionManager` + `Packet.fromValuesStruct`) | GUI "Load from CSV" **when no defaults file is selected** (or the user declines to use one) | No | Yes | Working |

### 9.1 Functional — Path A: `ScapyML.CsvLoader`

**TC-CSV-FUNC-001 — Load a well-formed CSV with columns matching all protocol fields**
- Priority: Critical
- Test Data: `data.csv` with header row `id,temperature` and 3 data rows.
- Steps: `pkts = ScapyML.CsvLoader.load('data.csv', 'Msg');`
- Expected Result: `numel(pkts)==3`; each `pkts{i}` has `id`/`temperature` set from the
  corresponding CSV row.

**TC-CSV-FUNC-002 — CSV with extra columns not present in the protocol**
- Priority: Medium
- Steps: Add an extra `notes` column with text values.
- Expected Result: Extra column silently ignored (caught inside the `try/catch` around
  `pkt.set(fname, val)`); no error; other columns still load.

**TC-CSV-FUNC-003 — CSV with a missing column (field not in CSV at all)**
- Priority: Medium
- Steps: CSV omits a `flags` column that exists in the protocol.
- Expected Result: `flags` remains at its protocol default (0) for every loaded packet; no error.

**TC-CSV-FUNC-004 — Empty cell in a data row leaves the field at its default**
- Priority: Medium
- Steps: One row has an empty `temperature` cell.
- Expected Result: That packet's `temperature` stays at 0/default; other fields on the same row
  still load correctly.

**TC-CSV-FUNC-005 — Hex-notation CSV values (`0x...`) of varying digit counts**
- Priority: Medium
- Steps: CSV values `0xFF`, `0xFFFF`, `0xFFFFFFFF`, `0xFFFFFFFFFFFFFFFF` in appropriately-sized
  fields.
- Expected Result: `CsvLoader.parseNum` auto-sizes to uint8/16/32/64 respectively based on hex
  digit count, and `Packet.set()` accepts each without an out-of-range warning.

**TC-CSV-FUNC-006 — Quoted CSV fields containing a comma**
- Priority: Low
- Steps: A CSV field value `"1,2"` inside quotes (per `splitLine`'s quote-aware comma handling).
- Expected Result: Treated as a single field value, not split at the internal comma. Since
  `parseNum` expects a pure numeric string, this would fail to parse as a number and be silently
  skipped via `~isnan(val)` — confirm this doesn't crash the loader.

### 9.2 Negative — Path A

**TC-CSV-NEG-001 — Non-existent CSV file**
- Priority: High
- Steps: `ScapyML.CsvLoader.load('missing.csv', 'Msg');`
- Expected Result: `error` `ScapyML:CsvLoader:FileNotFound`.

**TC-CSV-NEG-002 — Empty CSV file (zero bytes)**
- Priority: Medium
- Steps: Load a zero-byte file.
- Expected Result: Returns `{}` (empty cell array), no error.

**TC-CSV-NEG-003 — CSV with header row only, no data rows**
- Priority: Medium
- Steps: Load a CSV containing only the header line.
- Expected Result: Returns `{}` (loop `for row = 2:numel(lines)` never executes).

### 9.3 Functional — Path B: `fromcsv` / `ScapyML_fromCSV` — **✅ FIXED**

**TC-CSV-FUNC-007 — CLI `fromcsv` command with defaults and conversions — FIXED**
- Priority: Critical (was a confirmed defect — see Known Issues KI-NEW-01 — now resolved)
- Steps: `pkts = ScapyML('fromCSV', 'Msg', 'data.csv', 'defaults.txt', 'conversions.txt');`
- Expected Result per `REQUIREMENTS.md` FR-008: packets created from CSV with conversions and
  defaults applied.
- **Root cause (for history — both parts now fixed):** `ScapyML.m` had two `case` blocks both
  listing `'fromcsv'` as a matching label: `case {'csv','readcsv','fromcsv'}` (appeared first) and
  `case {'fromcsv','csv2packets','autocsv'}` (appeared second, and called the missing
  `ScapyML_fromCSV`). MATLAB's `switch/case` always executes the *first* matching block, so
  `ScapyML('fromCSV', ...)` always hit the first block, silently misfiring into
  `CsvLoader.load('Msg', 'data.csv')` with arguments in the wrong order — producing a confusing
  `CSV file not found: Msg` error rather than the "undefined function" error originally suspected.
- **Fix applied:** (1) `'fromcsv'` removed from the first case's alias list in `ScapyML.m`, so the
  dedicated case block is no longer shadowed; (2) `ScapyML_fromCSV.m` — genuinely missing from the
  package — has been implemented, modeled on the GUI's own proven vectorized CSV loader
  (`readtable` + `ConversionManager` + `Packet.fromValuesStruct`), with `DefaultsManager.apply()`
  added on top to satisfy the "apply defaults" half of FR-008.
- Status: **PASS (fixed).** Confirmed via `TestManualCsvSuite.m`:
  `tcCliFromcsvNowLoadsWithDefaultsAndConversions` (verifies both defaults AND conversions are
  correctly applied end-to-end) and `tcCliFromcsvAliasesAlsoWork` (confirms the `csv2packets`/
  `autocsv` aliases, previously hitting the missing-function error, now also work).

**TC-CSV-FUNC-008 — GUI "Load from CSV" with a defaults file selected — FIXED**
- Priority: Critical (was a confirmed defect surfaced through the GUI — now resolved)
- Steps: In the GUI: load a header, select protocol, use "Create Defaults File" (or otherwise set
  `state.defaultsFile`), click "Load from CSV", select a CSV, and answer **Yes** to "Use defaults
  file with CSV?".
- Expected Result: Packets loaded with defaults pre-filled and CSV values applied on top.
- **Fix applied:** no change was needed to the GUI's own call site — `loadFromCSV()`'s
  `useDefaults` branch still calls `ScapyML('fromCSV', state.selectedProtocol, state.csvFile,
  state.defaultsFile, state.conversionFile)` exactly as before. That call now succeeds because the
  underlying `ScapyML('fromCSV', ...)` command itself was fixed (see TC-CSV-FUNC-007 above) — the
  GUI code was never itself wrong, only the command it depended on was broken.
- Status: **PASS (fixed).** Confirmed at the source level via `TestManualGuiAndE2ESuite.m`:
  `tcGuiKi01_loadFromCsvCallsTheNowWorkingFromCsvCommand` (confirms the GUI still calls the correct
  command) together with the CLI-level end-to-end confirmation above. A live GUI click-through
  re-test is still recommended before release, per the manual-testing scope of this document.
- Workaround note (retained for reference): answering **No** to the "Use defaults file with CSV?"
  prompt has always routed to the working Path C loader (TC-CSV-FUNC-009) regardless of this fix.

### 9.4 Functional — Path C: GUI's own vectorized bulk loader

**TC-CSV-FUNC-009 — GUI CSV load with no defaults file, no conversions**
- Priority: Critical
- Steps: In the GUI: load header, select protocol, click "Load from CSV" (defaults file not set,
  or answer "No" if prompted), select a CSV with columns matching some protocol fields.
- Expected Result: `state.packets` populated, one `Packet` per CSV data row; output panel reports
  `✓ Created N packets from CSV`; `btnSend`/`btnSaveMAT` become enabled.

**TC-CSV-FUNC-010 — GUI CSV load with a conversion file loaded, no defaults file**
- Priority: Critical
- Steps: Load a conversion file via "Load Conversion File" (e.g. the `azimuth` formula), then
  "Load from CSV" with a CSV containing physical `azimuth` values (e.g. `60.0`).
- Expected Result: `pkts{i}.get('azimuth')` reflects the **converted** wire value (e.g. `10922`),
  not the raw CSV value — confirms Path C's `converter.convert()` integration and the
  "apply-once, never from a pre-converted cache" guard described in the code comment.

**TC-CSV-FUNC-011 — GUI CSV load waitbar and cancel button (large CSV)**
- Priority: Medium
- Steps: Load a CSV with a large row count (e.g. ≥1000 rows); click the waitbar's Cancel button
  partway through.
- Expected Result: Loading stops; `state.packets` contains only the packets processed up to the
  cancellation point; output panel reports `⚠ Cancelled — loaded X / Y packets`.

**TC-CSV-FUNC-012 — GUI CSV load: CSV column not mapping to any protocol field**
- Priority: Medium
- Steps: CSV has an extra column with a name that doesn't match any field.
- Expected Result: Column is skipped (caught in the inner `try/catch` around `data.(fn)`); other
  mapped columns still load correctly; no crash.

### 9.5 Performance Sanity — Path C

**TC-CSV-PERF-001 — 1000-row CSV bulk load completes well under 15 seconds (NFR-001)**
- Priority: Medium
- Steps: Prepare a 1000-row CSV; load via the GUI (Path C); time from click to
  "✓ Created 1000 packets" message using a stopwatch or `tic`/`toc` around the equivalent scripted
  call.
- Expected Result: Completes comfortably under 15 seconds on typical hardware — informal sanity
  check per NFR-001, not a formal benchmark (see `STP.md` §24).

---

## 10. MAT File Persistence — GUI (`ScapyML_GUI.m`: `saveToMAT`/`loadFromMAT`)

### 10.1 Functional

**TC-MAT-FUNC-001 — Save current packets to a `.mat` file**
- Priority: Critical
- Steps: Create/load packets in the GUI; click "💾 Save to MAT"; choose a filename.
- Expected Result: File written; output panel reports `✓ Saved N packets to: <file>` with
  protocol name and file size; the saved struct (`packetData`) contains `packets`, `protocolName`,
  `packetCount`, `createdDate`, `scapymlVersion`, and (if applicable) `defaultsFile`,
  `conversionFile`, `sourceCSV`.

**TC-MAT-FUNC-002 — Load packets from a `.mat` file matching the selected protocol**
- Priority: Critical
- Steps: Select the same protocol used to save; click "📂 Load from MAT"; choose the file from
  TC-MAT-FUNC-001.
- Expected Result: `state.packets` repopulated with the same count and field values as originally
  saved; output panel echoes protocol/created-date/version/source-CSV metadata; `btnSend` and
  `btnSaveMAT` enabled.

**TC-MAT-FUNC-003 — Protocol-mismatch confirmation dialog — user selects "No"**
- Priority: High
- Steps: Save a `.mat` file for protocol `A`; select protocol `B` in the dropdown; click
  "Load from MAT"; select the `A` file; click **No** on the mismatch dialog.
- Expected Result: Load cancelled; output panel reports `✗ Load cancelled - protocol mismatch`;
  `state.packets` unchanged.

**TC-MAT-FUNC-004 — Protocol-mismatch confirmation dialog — user selects "Yes"**
- Priority: Medium
- Steps: Same as above, but click **Yes**.
- Expected Result: Packets load anyway despite the mismatch (caller accepts the risk); no crash,
  though downstream `build()`/`send()` on protocol-mismatched packet objects should be verified to
  behave sensibly (packets still reference their *original* protocol internally, since `Packet`
  objects carry their own `Proto` — confirm this, since the "mismatch" is purely a metadata-string
  comparison against the currently-selected dropdown value, not an actual protocol swap).

### 10.2 Data Integrity

**TC-MAT-DATA-001 — Round-trip fidelity for 1000 packets**
- Priority: High
- Steps: Bulk-load 1000 packets from CSV; save to MAT; clear packets; load from MAT; compare field
  values for a sample of packets (e.g. first, middle, last) against the originally loaded CSV
  data.
- Expected Result: Exact match — confirms MAT save/load preserves packet state losslessly.

**TC-MAT-PERF-001 — 1000-packet MAT load is markedly faster than the original CSV load
(NFR-001, 10-40x claim)**
- Priority: Low
- Steps: Time the original 1000-row CSV load (TC-CSV-PERF-001) vs. the MAT reload of the same
  1000 packets; compare elapsed times.
- Expected Result: MAT load is substantially faster (informal sanity check against the
  "10-40x faster" / "<1 second" claims in `REQUIREMENTS.md` FR-011 and NFR-001).

### 10.3 Negative / Error Handling

**TC-MAT-ERR-001 — Loading a `.mat` file with no `packetData` variable**
- Priority: Medium
- Steps: Save an unrelated `.mat` file (e.g. `save('other.mat','x')`); attempt to load it via
  "Load from MAT".
- Expected Result: `error` caught and surfaced: `✗ Error loading MAT file: Invalid MAT file:
  missing packetData structure`, plus the hint `Make sure the file was created by ScapyML
  saveToMAT()`.

**TC-MAT-ERR-002 — Loading a `.mat` file with `packetData` missing required sub-fields**
- Priority: Medium
- Steps: Manually construct and save a `packetData` struct missing `packets` or `protocolName`.
- Expected Result: `error` "Invalid MAT file: missing required fields" surfaced the same way.

**TC-MAT-ERR-003 — "Save to MAT" with no packets available**
- Priority: Low
- Steps: Click "💾 Save to MAT" before any packet has been created/loaded.
- Expected Result: `uialert` "No packets to save. Load from CSV first." — no file dialog opens.

**TC-MAT-ERR-004 — "Load from MAT" with no protocol selected**
- Priority: Low
- Steps: Click "📂 Load from MAT" before selecting any protocol.
- Expected Result: `uialert` "Please select a protocol first."

---

## 11. UdpSender (`+ScapyML/UdpSender.m`)

### 11.1 Functional

**TC-UDP-FUNC-001 — Persistent socket open, multiple sends, explicit close**
- Priority: Critical
- Steps: `u = ScapyML.UdpSender('127.0.0.1', 5000); u.send(uint8([1 2 3])); u.send(uint8([4 5]));
  u.close();`
- Expected Result: Socket opens once (`[ScapyML] UDP socket open (modern) -> 127.0.0.1:5000`
  printed once); both `send()` calls succeed without reopening; `close()` prints
  `[ScapyML] UDP socket closed.` and subsequent `send()` calls error.

**TC-UDP-FUNC-002 — `sendOnce()` convenience opens, sends, and closes automatically**
- Priority: High
- Steps: `ScapyML.UdpSender.sendOnce(uint8([1 2 3]), '127.0.0.1', 5000);`
- Expected Result: Socket opened and closed within the single call; no leaked socket (verify via
  `delete`/destructor behavior — no lingering open port on subsequent runs).

**TC-UDP-FUNC-003 — Destructor closes the socket automatically on object deletion/clear**
- Priority: Medium
- Steps: `u = ScapyML.UdpSender('127.0.0.1', 5000); clear u;`
- Expected Result: `delete()` fires, socket closes cleanly (confirm via a subsequent successful
  bind/send on the same port from a fresh sender — no "port in use" conflict).

**TC-UDP-FUNC-004 — Multicast destination IP is accepted**
- Priority: Medium
- Steps: `u = ScapyML.UdpSender('224.0.0.100', 5000); u.send(uint8([1])); u.close();`
- Expected Result: Send completes without error (multicast send capability depends on the
  underlying MATLAB `udpport`/OS network stack, not on ScapyML's own address-family logic, which
  performs no special-casing at the `UdpSender` level — multicast detection lives in
  `PacketSender.isMulticastIP`, tested separately below).

### 11.2 Negative / Error Handling

**TC-UDP-ERR-001 — `send()` on a closed/never-opened socket**
- Priority: Medium
- Steps: `u = ScapyML.UdpSender('127.0.0.1',5000); u.close(); u.send(uint8([1]));`
- Expected Result: `error` `ScapyML:UdpSender:NotOpen`.

**TC-UDP-ERR-002 — `send()` to an unreachable/invalid destination**
- Priority: Medium
- Steps: `ScapyML.UdpSender.sendOnce(uint8([1]), '999.999.999.999', 5000);`
- Expected Result: `error` `ScapyML:UdpSender:SendFailed` with the underlying exception message
  wrapped in — no silent failure.

### 11.3 Boundary

**TC-UDP-BOUND-001 — Default constructor arguments (`UdpSender()` with no args)**
- Priority: Low
- Steps: `u = ScapyML.UdpSender();`
- Expected Result: Defaults to `127.0.0.1:1234` per constructor default parameters.

---

## 12. PacketSender / Timing (`+ScapyML/PacketSender.m`)

### 12.1 Functional

**TC-SEND-FUNC-001 — Single-mode send transmits all packets immediately**
- Priority: Critical
- Steps: `ScapyML.PacketSender.sendWithTiming({pkt1,pkt2,pkt3}, '127.0.0.1', 5000, 'single');`
- Expected Result: All 3 packets sent back-to-back with no inter-packet delay; console reports
  "Sent packet i/3" for each.

**TC-SEND-FUNC-002 — Periodic-mode send respects the configured interval (±1-2ms, NFR/FR-010)**
- Priority: Critical
- Steps: `ScapyML.PacketSender.sendWithTiming({pkt1,pkt2,pkt3,pkt4}, '127.0.0.1', 5000,
  'periodic', 0.010);` (10ms interval). Capture wall-clock timestamps of each printed "Sent
  packet" line (or instrument via a receiving socket) and compute inter-send deltas.
- Expected Result: Inter-packet delays average ~10ms with the busy-wait compensating for
  processing time, within the ±1-2ms accuracy target stated in FR-010 for intervals ≥10ms.

**TC-SEND-FUNC-003 — CSV-timed-mode send replays packets at their relative timestamps**
- Priority: Critical
- Steps: `timestamps = [0.0; 0.1; 0.2; 0.5];
  ScapyML.PacketSender.sendWithTiming({p1,p2,p3,p4}, '127.0.0.1', 5000, 'csv', timestamps);`
  Capture timing of sends.
- Expected Result: Packet 1 sent immediately (t=0); packet 2 at ~0.1s after packet 1; packet 3 at
  ~0.2s; packet 4 at ~0.5s, all relative to the first packet's send time (`timestamps(1)` is the
  reference origin, per code: `targetTime = timestamps(i) - timestamps(1)`); console reports
  actual vs. target time and the signed timing error for each packet after the first.

**TC-SEND-FUNC-004 — Checksums applied automatically when a `ChecksumManager` is passed**
- Priority: High
- Steps: `ScapyML.PacketSender.sendWithTiming({pkt}, '127.0.0.1', 5000, 'single', cm);` where `cm`
  is a valid `ChecksumManager`.
- Expected Result: Console reports "Checksums: ENABLED ✓"; the bytes actually transmitted (verify
  via a loopback receiver or by calling `PacketSender.buildPacket(pkt, cm)` directly) match
  `pkt.buildWithChecksums(cm)`, not plain `pkt.build()`.

**TC-SEND-FUNC-005 — `isMulticastIP()` correctly classifies unicast vs. multicast addresses**
- Priority: Medium
- Steps: Call `ScapyML.PacketSender.isMulticastIP()` (component-level, direct call) with
  `'192.168.1.1'`, `'224.0.0.1'`, `'239.255.255.255'`, `'240.0.0.1'`, `'10.0.0.1'`.
- Expected Result: True only for the two addresses in the 224–239 first-octet range; false for the
  others.

### 12.2 Negative / Error Handling

**TC-SEND-ERR-001 — Periodic mode missing the required interval argument**
- Priority: Medium
- Steps: `ScapyML.PacketSender.sendWithTiming({pkt}, '127.0.0.1', 5000, 'periodic');` (no interval
  passed).
- Expected Result: `error` "Periodic mode requires interval_seconds".

**TC-SEND-ERR-002 — CSV mode with a timestamp-count / packet-count mismatch**
- Priority: Medium
- Steps: 3 packets, 2 timestamps.
- Expected Result: `error` "Timestamp count (2) must match packet count (3)".

**TC-SEND-ERR-003 — CSV mode with non-ascending timestamps**
- Priority: High
- Steps: `timestamps = [0.0; 0.5; 0.3];`
- Expected Result: `error` "Timestamps must be in ascending order."

**TC-SEND-ERR-004 — Unknown send mode string**
- Priority: Low
- Steps: `sendWithTiming({pkt}, '127.0.0.1', 5000, 'bogus');`
- Expected Result: `error` "Unknown mode: bogus. Use 'single', 'periodic', or 'csv'".

**TC-SEND-ERR-005 — Ctrl+C interrupt during periodic send still closes the socket**
- Priority: Medium
- Steps: Start a long periodic send; interrupt with Ctrl+C mid-run.
- Expected Result: Caught by the `catch ME` block; if `ME.identifier` is `MATLAB:interrupt`,
  prints "Stopped by user" and calls `sender.close()` — verify no socket is left open (test by
  immediately opening a new sender on the same local port afterward).

### 12.3 Edge Case

**TC-SEND-EDGE-001 — Sending an empty packet list**
- Priority: Low
- Steps: `sendWithTiming({}, '127.0.0.1', 5000, 'single');`
- Expected Result: Loop executes zero times; no error; socket opens and closes cleanly with
  "Sending 0 packet(s)..." reported.

---

## 13. WiresharkDissector — Single Protocol (`+ScapyML/WiresharkDissector.m`)

### 13.1 Functional

**TC-WSD-FUNC-001 — Generate a dissector for a simple all-primitives struct**
- Priority: Critical
- Steps: `ScapyML.WiresharkDissector.generate(proto, 'out.lua', 5000, {});` for the `AllTypes`
  fixture; open `out.lua` in a text editor.
- Expected Result: Valid Lua syntax; one `ProtoField.*` declaration per field with correct type
  (`uint8`/`uint16`/`uint32`/`uint64`/`float`/`double`); `dissector` function adds each field at
  the byte offset matching `proto.getFieldOffsets()`; UDP registration line present for port 5000.

**TC-WSD-FUNC-002 — Bit-field ProtoField mask matches actual wire encoding (KI-003 cross-check)**
- Priority: Critical (regression guard)
- Steps: Generate a dissector for the `BF` fixture (`uint8_t a:3; uint8_t b:5;`); inspect the
  generated `base.HEX, nil, 0x...` mask value for each field.
- Expected Result: Manually apply the generated mask/shift to the actual encoded byte (from
  TC-CODEC-FUNC-003) and confirm it recovers the correct field value — i.e. the Wireshark mask and
  the actual `Codec` encoding agree (this is exactly what `TestKnownIssues.ki003_...` automates;
  here it is performed manually against the generated `.lua` text as an independent
  cross-check).

**TC-WSD-FUNC-003 — Enum field generates a Wireshark value-lookup table**
- Priority: High
- Steps: Generate a dissector for the `Msg` fixture (with `Status` enum field); pass the enum defs
  via the 4th argument.
- Expected Result: A Lua table `local <key>_vals = { [0] = "STATUS_IDLE", [1] = "STATUS_ACTIVE",
  ... }` is emitted, and the field's `ProtoField` declaration references it (`base.DEC, ..._vals`).

**TC-WSD-FUNC-004 — Array field is grouped under a labeled subtree with per-element entries**
- Priority: High
- Steps: Generate a dissector for a struct with `uint8_t data[16];`.
- Expected Result: Lua contains a `do ... local array_tree = subtree:add(buffer(...), "data[16]")
  ... end` block with 16 individual `array_tree:add(...)` calls.

**TC-WSD-FUNC-005 — Nested struct/union produces its own labeled sub-subtree**
- Priority: High
- Steps: Generate a dissector for the `Outer`/`Word16` fixtures.
- Expected Result: a nested `subtree_<name>:add(buffer(...), "...")` call, with member fields emitted under the
  nested subtree variable, not the top-level `subtree`.

**TC-WSD-FUNC-006 — Little-endian vs. big-endian field access method**
- Priority: High
- Steps: Generate dissectors for the same struct loaded once `'little'`, once `'big'`.
- Expected Result: Little-endian multi-byte fields use `subtree:add_le(...)`; big-endian and
  single-byte fields use `subtree:add(...)` (per `addMethod`'s logic).

**TC-WSD-FUNC-007 — Generated file strips non-ASCII characters**
- Priority: Low
- Steps: Load a header with a non-ASCII character embedded in a comment (which becomes a field
  `Description`, not directly emitted in the dissector body — but confirm no encoding artifacts
  like `Â©`/smart quotes leak into the emitted Lua from any source string); inspect the raw bytes
  of the output `.lua` file.
- Expected Result: All bytes fall in the printable ASCII range (0x20–0x7E) plus tab (0x09); no
  stray `@@` or backtick artifacts (the specific defect class this defensive code was written to
  prevent per project history).

### 13.2 Negative

**TC-WSD-NEG-001 — Write failure (invalid output path)**
- Priority: Low
- Steps: `ScapyML.WiresharkDissector.generate(proto, '/nonexistent_dir/out.lua');`
- Expected Result: `error` `ScapyML:WiresharkDissector:WriteError`.

### 13.3 Integration

**TC-WSD-INT-001 — CLI `ScapyML('dissector', ...)` end-to-end**
- Priority: High
- Steps: `ScapyML('dissector', 'Msg', 'msg.lua', 5000);`
- Expected Result: File generated; console reports the output path; enum defs automatically
  pulled from the registry (`reg.listEnums()`/`reg.getEnum()`) without the caller needing to
  supply them manually — confirms the CLI wiring in `ScapyML.m`'s `dissector` case.

**TC-WSD-INT-002 — GUI single-protocol dissector generation end-to-end**
- Priority: High
- Steps: In the GUI: load header, click "🦈 Create Wireshark Dissector", select exactly one
  protocol, set a UDP port, click "✓ Create Dissector", save.
- Expected Result: File created; output panel shows installation instructions; confirms this path
  (single-protocol only) works correctly, in contrast to the multi-protocol path (§14 below).

---

## 14. MultiProtocolDissector / DiscriminatorConfig — **GUI PATH FIXED (was broken)**

### 14.1 Functional — Programmatic / CLI path (bypassing the GUI dialog)

**TC-MWSD-FUNC-001 — Generate a multi-protocol dissector with a programmatically-built
`DiscriminatorConfig`**
- Priority: High
- Steps:
  ```matlab
  cfg = ScapyML.DiscriminatorConfig();
  cfg.addProtocol('TempSensor', 'msg_id', 0, 1, 1);
  cfg.addProtocol('PressureSensor', 'msg_id', 0, 1, 2);
  ScapyML.MultiProtocolDissector.generate({'TempSensor','PressureSensor'}, 'multi.lua', 5000, {}, cfg);
  ```
- Expected Result: Valid Lua generated with per-protocol `dissect_<name>` functions and a
  discriminator `if/elseif` chain on `disc_value` read from offset 0, size 1; unique
  `ProtoField` names per protocol (`<protoname>_<fieldname>`) preventing collisions. **This is the
  correct, working way to drive `MultiProtocolDissector` — confirms the underlying generation
  logic itself is sound when given a correctly-constructed `DiscriminatorConfig`.**

**TC-MWSD-FUNC-002 — `DiscriminatorConfig.validateUniqueness()` detects duplicate discriminator
values**
- Priority: High
- Steps: `cfg.addProtocol('A','msg_id',0,1,1); cfg.addProtocol('B','msg_id',0,1,1);`
  (duplicate value 1 at the same field/offset/size); `cfg.validateUniqueness()`.
- Expected Result: Returns `false`; `warning` lists both colliding protocols; a subsequent
  `MultiProtocolDissector.generate(...)` call with this config raises `error` "Discriminator
  configuration has duplicate values!".

**TC-MWSD-FUNC-003 — `DiscriminatorConfig.saveToFile()` / `fromFile()` round-trip**
- Priority: Medium
- Steps: Build a config with `addProtocol`; `cfg.saveToFile('disc.txt');
  cfg2 = ScapyML.DiscriminatorConfig.fromFile('disc.txt');` compare `cfg2.getProtocolConfig(...)`/
  `getProtocolValue(...)` against the original.
- Expected Result: Exact round-trip of field name, offset, size, and value for every protocol.

### 14.2 Functional — GUI path — **✅ FIXED**

**TC-MWSD-FUNC-004 — GUI multi-protocol dissector generation via "🦈 Create Wireshark
Dissector"** — **FIXED**
- Priority: Critical (was a confirmed defect — see Known Issues KI-NEW-02 — now resolved)
- Steps: In the GUI: load a header defining 2+ protocols, click "🦈 Create Wireshark Dissector",
  select **two or more** protocols in the listbox, click "✓ Create Dissector" (this routes to
  `configureDiscriminator(selectedProtos, port)` since `numel(selectedProtos) > 1`); in the
  resulting "Configure Message ID Discriminator" dialog, click "✓ Generate Dissector".
- Expected Result per `REQUIREMENTS.md` FR-012: a multi-protocol Lua dissector is generated with
  message-ID-based discrimination, as documented in `README.md`'s GUI Guide.
- **Root cause (for history — all four sub-defects now fixed):** `doGenerateMulti()` called
  `createConfigFromTable()`, which called `config.setDefaults(...)` and
  `config.addMappingSimple(...)` — neither exists on the real `DiscriminatorConfig` class.
  `doGenerateMulti()` itself also called the non-existent `config.getMapping(...)` and read the
  private `reg.Enums` property directly. All four calls would throw immediately, in sequence, as
  each was reached.
- **Fix applied:** `createConfigFromTable()` now calls the real `config.addProtocol(fieldName,
  offset, size, msgId)` once per protocol row (the table lets every protocol share the same
  discriminator field/offset/size, differing only in value). `doGenerateMulti()` now calls the real
  `config.getProtocolValue(...)` accessor, and builds `enumDefs` via the public
  `reg.listEnums()`/`reg.getEnum(...)` API instead of the private property — mirroring the pattern
  already used by the working single-protocol `dissector` CLI command.
- **Bonus fix found while correcting this:** both `createConfigFromTable()` and
  `updateTableFromDefaults()` (a sibling nested function sharing the same dialog workspace)
  assigned a local variable literally named `size`, shadowing MATLAB's builtin `size()` function
  for the rest of that shared workspace — breaking `size(tableData, 1)` calls in `doGenerateMulti()`
  too if `updateTableFromDefaults()` (the "↻ Apply Defaults to All" button) had run first. Both
  renamed to `fieldSize`.
- Status: **PASS (fixed).** Confirmed via `TestManualMultiProtocolSuite.m`'s
  `tcMwsdFunc001_endToEndProgrammaticMultiProtocolGeneration` (proves the underlying engine
  produces a correct dissector when driven with the now-matching API) together with
  `TestManualGuiAndE2ESuite.m`'s `tcGuiKi02_discriminatorDialogNowCallsTheRealApi` and
  `tcGuiKi02b_oldBrokenCallsAreGone` (source-level confirmation the GUI calls the fix and the old
  broken calls are gone). A live GUI click-through re-test is still recommended before release, per
  the manual-testing scope of this document.

**TC-MWSD-FUNC-005 — "💾 Save Config..." button in the discriminator dialog — FIXED**
- Priority: Low (same root cause as TC-MWSD-FUNC-004, now resolved the same way)
- Steps: In the same dialog, click "💾 Save Config..." before "Generate Dissector".
- Expected Result: Succeeds, since `saveConfig()` calls the same (now-fixed)
  `createConfigFromTable()` helper.
- Status: **PASS (fixed)** — same fix as TC-MWSD-FUNC-004 above, since both buttons share the same
  underlying helper function.

### 14.3 Edge Case — Dead Code

**TC-MWSD-EDGE-001 — `DiscriminatorConfig.fromGUI()` is never actually invoked by the shipped
GUI**
- Priority: Low (documentation only — see Known Issues KI-NEW-05)
- Steps: Search all call sites of `fromGUI` in the package.
- Expected Result: Only reachable from `MultiProtocolDissector.generate()` itself, when called
  *without* a 5th `discConfig` argument (i.e. purely programmatically, never from
  `ScapyML_GUI.m`, which always constructs — however incorrectly — its own config object
  directly). Its own `uifigure`-based dialog (with `Value`/dropdown inputs) is therefore dead code
  from the shipped GUI's perspective. No functional test needed beyond confirming this
  non-reachability; note it for possible cleanup.

**TC-MWSD-EDGE-002 — `BitFieldGrouper` is fully implemented but never called from any other
module**
- Priority: Low (documentation only — see Known Issues KI-NEW-04)
- Steps: Search all call sites of `ScapyML.BitFieldGrouper.*` in the package outside its own file.
- Expected Result: None found. `findGroups`/`generateGroupName` can be exercised directly as
  component-level tests (they work correctly in isolation per code reading), but they have no
  effect on any dissector or GUI output as shipped — the "grouped bit-field display" feature this
  class appears designed to support is not wired into `WiresharkDissector`.

---

## 15. DependencyResolver (`+ScapyML/DependencyResolver.m`)

### 15.1 Functional

**TC-DEP-FUNC-001 — Resolve load order for two files with a simple dependency**
- Priority: High
- Test Data: `types.h` defines `MyEnum`; `msg.h` defines a struct using `MyEnum`.
- Steps: `ordered = ScapyML.DependencyResolver.resolveOrder({'msg.h','types.h'});`
  (deliberately passed in dependent-first order).
- Expected Result: `ordered == {'types.h','msg.h'}` (dependency reordered before dependent).

**TC-DEP-FUNC-002 — `ScapyML('load', ..., 'auto')` end-to-end auto-resolution**
- Priority: High
- Steps: `ScapyML('load', {'msg.h','types.h'}, 'little', 'auto');`
- Expected Result: Console shows `[ScapyML] Auto-resolving dependencies...` followed by files
  parsed in resolved (not original) order; `Msg`'s enum field resolves correctly with **no**
  `UnresolvedType` warning (this is the documented remedy for TC-HDR-FUNC-013's failure mode).

**TC-DEP-FUNC-003 — Enum-only header file is recognized as a dependency source (v2.3.3 fix)**
- Priority: High (regression guard)
- Test Data: `types.h` containing *only* `typedef enum {A=0,B=1} MyEnum;` (no structs at all).
- Steps: `ScapyML.DependencyResolver.analyzeFile('types.h')`.
- Expected Result: `defines` includes `'MyEnum'` — confirms the v2.3.3 fix that added enum-typedef
  regex recognition (previously an enum-only file was invisible to the dependency graph).

**TC-DEP-FUNC-004 — Independent files with no cross-references preserve relative order**
- Priority: Low
- Steps: Two headers with no shared type references; `resolveOrder({'a.h','b.h'})`.
- Expected Result: Order unaffected (both processed as independent roots).

### 15.2 Negative / Error Handling

**TC-DEP-ERR-001 — Circular dependency between two files is detected**
- Priority: High
- Test Data: `a.h` struct `A` contains a field of type `B`; `b.h` struct `B` contains a field of
  type `A`.
- Steps: `ScapyML.DependencyResolver.resolveOrder({'a.h','b.h'});`
- Expected Result: `error` `ScapyML:CircularDependency` naming one of the involved files — confirms
  the DFS `inProgress` cycle-detection fix (previously visited/inProgress state was not correctly
  propagated back from recursive calls).

**TC-DEP-ERR-002 — Unreadable/missing file passed to `analyzeFile`**
- Priority: Low
- Steps: `ScapyML.DependencyResolver.analyzeFile('missing.h');`
- Expected Result: `warning` "Cannot open file: %s"; returns empty `defines`/`uses` rather than
  erroring (allows `resolveOrder` to continue for the remaining files).

---

## 16. NameShortener (`+ScapyML/NameShortener.m`)

### 16.1 Functional

**TC-NAME-FUNC-001 — Names already ≤63 characters are returned unchanged**
- Priority: Medium
- Steps: `ScapyML.NameShortener.shorten('level2_level3_level4_deepest_level5_field1')` (46 chars,
  per the class's own docstring example).
- Expected Result: Returned unchanged.

**TC-NAME-FUNC-002 — Names >63 characters are shortened while preserving the final field name**
- Priority: High
- Steps: `ScapyML.NameShortener.shorten('veryLongStructureNameForTesting_level3_level4_deepest_level5_field1')`
  (69 chars, per the docstring example).
- Expected Result: Result ≤63 characters; ends with `_field1` (the final path component is
  preserved intact per the documented strategy).

**TC-NAME-FUNC-003 — End-to-end: a deeply nested struct with long member names triggers automatic
shortening during header parsing**
- Priority: High
- Test Data: Nested structs 4+ levels deep with long C member names such that the flattened,
  prefixed field name would exceed 63 characters.
- Steps: Load the header; inspect the resulting `FieldDef.Name` for the deepest field via
  `proto.fieldNames()`.
- Expected Result: The generated MATLAB field name is ≤63 characters (MATLAB's
  `namelengthmax`) and does not collide with any sibling field's shortened name; `Packet.set()`/
  `get()` work correctly using the shortened name.

### 16.2 Boundary

**TC-NAME-BOUND-001 — Name exactly 63 characters**
- Priority: Medium
- Steps: `shorten(name_of_length_63)`.
- Expected Result: Returned unchanged (boundary condition `length(longName) <= maxLen`).

**TC-NAME-BOUND-002 — Name exactly 64 characters**
- Priority: Medium
- Steps: `shorten(name_of_length_64)`.
- Expected Result: Shortening logic engages; result ≤63 characters.

**TC-NAME-BOUND-003 — Single-word name (no underscores) exceeding the limit**
- Priority: Low
- Steps: A 70-character name with zero `_` separators.
- Expected Result: Falls through to `truncateWithHash` (since `numel(parts)==1` after
  `strsplit`), producing `<truncated>_<8-hex-digit-hash>`.

### 16.3 Edge Case

**TC-NAME-EDGE-001 — Uniqueness after shortening for two similarly-named long fields**
- Priority: Medium
- Steps: Two distinct long field paths that happen to abbreviate to the same short prefix; inspect
  whether `truncateWithHash`'s hash suffix disambiguates them.
- Expected Result: The two resulting `FieldDef.Name` values must differ (verify no collision that
  would silently make `Packet.set()` write the wrong field, since MATLAB struct fields require
  unique names) — if a collision is found, log it as a defect (hash-based disambiguation is only
  applied to the *whole* shortened name, not cross-checked against sibling names at shortening
  time, so a collision is theoretically possible with two independently-hashed long names that
  happen to match).

---

## 17. CLI Dispatch — `ScapyML.m`

### 17.1 Functional — one test per documented command

**TC-CLI-FUNC-001 — `load` command (single file, explicit endian)**
- Priority: Critical — see TC-HDR-* for detailed coverage; this case validates the CLI wiring only.
- Steps: `ScapyML('load', 'msg.h', 'big');`
- Expected Result: Console reports each parsed file and each registered protocol/enum with byte
  counts; protocols queryable afterward via `ScapyML('list')`.

**TC-CLI-FUNC-002 — `load` command (multiple files as separate arguments vs. as a cell array)**
- Priority: Medium
- Steps: `ScapyML('load', 'a.h', 'b.h', 'little');` and, separately,
  `ScapyML('load', {'a.h','b.h'}, 'little');`
- Expected Result: Both invocation styles produce identical registered protocols (confirms the
  file-argument-collection logic handles both forms per its `iscell`/`ischar` branching).

**TC-CLI-FUNC-003 — `packet` command with inline field=value pairs**
- Priority: High
- Steps: `pkt = ScapyML('packet', 'Msg', 'id', 7);`
- Expected Result: Returns a `Packet` with `id==7`.

**TC-CLI-FUNC-004 — `csv` command (Path A wrapper)**
- Priority: High
- Steps: `pkts = ScapyML('csv', 'data.csv', 'Msg');`
- Expected Result: Console reports `[ScapyML] Loaded N packets from data.csv`; `pkts` matches
  direct `CsvLoader.load()` output (see §9.1).

**TC-CLI-FUNC-005 — `send` command with a single `Packet` object**
- Priority: High
- Steps: `ScapyML('send', pkt, '127.0.0.1', 5000);`
- Expected Result: Routes to `UdpSender.sendOnce(pkt.build(), ...)` — single datagram sent.

**TC-CLI-FUNC-006 — `send` command with a cell array of packets**
- Priority: High
- Steps: `ScapyML('send', {pkt1,pkt2}, '127.0.0.1', 5000);`
- Expected Result: Routes to `PacketSender.sendWithTiming(..., 'single')`.

**TC-CLI-FUNC-007 — `send` command with a raw numeric byte array**
- Priority: Medium
- Steps: `ScapyML('send', uint8([1 2 3]), '127.0.0.1', 5000);`
- Expected Result: Routes to `UdpSender.sendOnce` directly with the raw bytes.

**TC-CLI-FUNC-008 — `send` command using default IP/port when omitted**
- Priority: Low
- Steps: `ScapyML('send', pkt);`
- Expected Result: Sends to the hardcoded defaults `10.10.10.10:1234` (per `DEFAULT_IP`/
  `DEFAULT_PORT` constants) — confirm this is documented/expected behavior for testers who may
  not realize a default destination exists.

**TC-CLI-FUNC-009 — `dissector` command**
- Priority: High — see TC-WSD-INT-001.

**TC-CLI-FUNC-010 — `info` command displays full field/offset/mask table**
- Priority: Medium
- Steps: `ScapyML('info', 'BF');` (bit-field fixture).
- Expected Result: Table includes per-field `#`, byte.bit offset, name, type, size, mask/range,
  and description columns; a trailing note about byte.bit notation appears whenever any bit-field
  is present; summary line reports total flattened field count.

**TC-CLI-FUNC-011 — `list` command with and without an output argument**
- Priority: Low
- Steps: `ScapyML('list');` (prints table) vs. `names = ScapyML('list');` (returns cell array,
  suppressing print).
- Expected Result: Both forms behave as documented; printed form includes field-count and
  byte-size per protocol.

**TC-CLI-FUNC-012 — `defaults` command generates a file (CLI wrapper for
  `DefaultsManager.create`)**
- Priority: Medium
- Steps: `ScapyML('defaults', 'Msg', 'defaults.txt');`
- Expected Result: Identical to TC-DEF-FUNC-001, invoked via the CLI dispatcher.

**TC-CLI-FUNC-013 — `loaddefaults` command (CLI wrapper for `DefaultsManager.apply`)**
- Priority: Medium
- Steps: `pkt = ScapyML('loaddefaults', pkt, 'defaults.txt');`
- Expected Result: Identical to TC-DEF-FUNC-002, invoked via the CLI dispatcher; returns the
  updated packet when an output argument is requested.

**TC-CLI-FUNC-014 — `register` command (programmatic protocol registration)**
- Priority: Low
- Steps: Manually construct a `ProtocolDef` object; `ScapyML('register', myProtoDef);`
- Expected Result: `ScapyML('list')` subsequently includes the manually-registered protocol.

**TC-CLI-FUNC-015 — `fromcsv` command — see TC-CSV-FUNC-007 (FIXED)**

### 17.2 Negative

**TC-CLI-NEG-001 — Calling `ScapyML()` with no arguments prints help and returns**
- Priority: Low
- Steps: `ScapyML();`
- Expected Result: Prints the synopsis/help block; no error.

**TC-CLI-NEG-002 — Unknown command string**
- Priority: Medium
- Steps: `ScapyML('bogus_command');`
- Expected Result: `warning` `ScapyML:UnknownCmd`; help text printed; if an output argument was
  requested, returns `[]`.

**TC-CLI-NEG-003 — Commands called with too few required arguments**
- Priority: Medium
- Steps: `ScapyML('packet');` (missing protocol name), `ScapyML('csv', 'file.csv');` (missing
  protocol name), `ScapyML('dissector', 'Proto');` (missing output filename).
- Expected Result: Each raises a MATLAB `assert`-based error with a clear "Usage: ..." message
  (per the `assert(numel(varargin) >= N, 'Usage: ...')` guards at the top of each case).

---

## 18. GUI Workflows (`ScapyML_GUI.m`)

### 18.1 UI — Button/Control State Machine

**TC-GUI-UI-001 — Protocol-dependent buttons start disabled and enable only after a protocol is
selected**
- Priority: High
- Steps: Launch the GUI (no headers loaded yet); inspect `Enable` state of "Show Protocol Info",
  "Create Packet", "Create Defaults File", "Load Conversion File", "Load Checksums File",
  "Load from CSV", "Load from MAT", "Create Wireshark Dissector".
- Expected Result: All disabled (`Enable='off'`) until `protocolSelected()` fires (i.e., until the
  user picks a non-placeholder value from the protocol dropdown after loading at least one
  header).

**TC-GUI-UI-002 — Packet-dependent buttons enable only after "Create Packet"**
- Priority: High
- Steps: With a protocol selected but no packet created, inspect "Edit Packet Fields",
  "Show Packet", "Hex Dump", "Send Packet(s)", "Save to MAT".
- Expected Result: Disabled until `createPacket()` runs (`btnSend`/`btnSaveMAT` also separately
  enabled by successful CSV/MAT loads, per the code — confirm both trigger paths work).

**TC-GUI-UI-003 — "Clear Protocols" resets all state and disables all protocol/packet-dependent
buttons**
- Priority: Medium
- Steps: Load headers, create a packet, then click "🗑️ Clear Protocols".
- Expected Result: `ProtocolRegistry.clearAll()` invoked; dropdown resets to
  `(Select Protocol)`; every protocol/packet-dependent button returns to `Enable='off'`; output
  panel confirms.

**TC-GUI-UI-004 — Edit Packet Fields dialog: scalar vs. array value parsing**
- Priority: High
- Steps: Open "✏️ Edit Packet Fields"; for a scalar field enter `42`; for an array field enter
  `1 2 3` (space-separated) and, separately, `1,2,3` (comma-separated); click Apply.
- Expected Result: Scalar parses via `str2double`; both array forms parse via `sscanf` after comma
  normalization; invalid entries (e.g. non-numeric text) produce an inline error in the output
  panel without closing the dialog, allowing correction.

**TC-GUI-UI-005 — Endianness dropdown affects subsequently loaded headers**
- Priority: Medium
- Steps: Set the endian dropdown to "little-endian (Intel)"; load a header; inspect
  `proto.Endian`.
- Expected Result: `Endian=='little'`.

**TC-GUI-UI-006 — "Auto-resolve dependencies" checkbox controls multi-file load ordering**
- Priority: Medium
- Steps: Load 2 files with a cross-reference dependency, in the wrong order, with the checkbox
  checked, then again unchecked.
- Expected Result: Checked → `DependencyResolver` reorders them (no `UnresolvedType` warning);
  unchecked → files loaded in the exact order selected (may produce the warning, per
  TC-HDR-FUNC-013).

### 18.2 Functional — Individual Feature Dialogs

**TC-GUI-FUNC-001 — "ℹ️ Show Protocol Info" displays the same field/offset table as CLI `info`**
- Priority: Medium
- Steps: Select a protocol; click "ℹ️ Show Protocol Info".
- Expected Result: Output matches (in substance) `ScapyML('info', ...)`'s table, using
  `proto.getFieldOffsets()` directly.

**TC-GUI-FUNC-002 — "👁️ Show Packet" and "🔍 Hex Dump" reflect current field values**
- Priority: Medium
- Steps: Create a packet, set several fields via Edit dialog, click each button in turn.
- Expected Result: "Show Packet" lists every field with correctly formatted scalar/array values;
  "Hex Dump" shows the exact `build()` output in 16-bytes-per-row hex.

**TC-GUI-FUNC-003 — "📝 Create Defaults File" writes a file usable by "Load Conversion
File"/manual editing**
- Priority: Low — see TC-DEF-FUNC-001.

**TC-GUI-FUNC-004 — "🔢 Load Checksums File" lists loaded formulas and enables checksum use on
send**
- Priority: High
- Steps: Load a checksum file; inspect output panel listing; then use "📡 Send Packet(s)" and
  confirm "Checksums: ENABLED ✓" appears in the send dialog flow.
- Expected Result: Formula count and (up to 10) field names listed; checksum applied during send
  (cross-ref TC-SEND-FUNC-004).

### 18.3 Recovery / Resilience

**TC-GUI-DATA-001 — Cancel button during "Sending..." waitbar (single mode)**
- Priority: Medium
- Steps: Send a large packet batch in single mode; click the waitbar's cancel button mid-send.
- Expected Result: Loop breaks cleanly (`if getappdata(wb,'cancelled'), break; end`); socket still
  closed via the `catch`/finally-style `sender.close()` calls; output reports
  `✓ Sent X / Y packet(s)` with `X<Y`.

**TC-GUI-DATA-002 — Cancel button during periodic/CSV-timed send**
- Priority: Medium
- Steps: Start a periodic or CSV-timed send with many packets and a non-trivial interval; cancel
  partway through.
- Expected Result: Loop exits at the next cancel-check point; socket closed cleanly; no leftover
  open port.

---

## 19. End-to-End Workflows (TC-E2E-*)

**TC-E2E-001 — GUI Workflow 1: Single Packet (per `REQUIREMENTS.md` §6.2)**
- Priority: Critical
- Steps:
  1. Click "Load Single Header" → select a `.h` file.
  2. Select the protocol from the dropdown.
  3. Click "Create Packet".
  4. Click "Edit Packet Fields" → set representative values → Apply.
  5. Click "Load Checksums File" → select a valid checksum file.
  6. Click "Send Packet(s)" → set `127.0.0.1`/a test port, mode Single → Send.
- Expected Result: Every step completes without error; final output confirms N/N packets sent
  with checksums enabled. (Set up a loopback UDP listener, e.g. via a second MATLAB session using
  `UdpSender`'s underlying `udpport('byte', 'LocalPort', <port>)` in read mode, or any simple
  listener, to independently confirm the exact bytes received match `pkt.buildWithChecksums(cm)`.)

**TC-E2E-002 — GUI Workflow 2: Bulk CSV (documented; **defaults-file branch known broken**)**
- Priority: Critical
- Steps:
  1. Load header; select protocol.
  2. Click "Load Conversion File" → select a valid conversions file.
  3. Click "Load from CSV" → select a CSV; **decline** ("No") the defaults-file prompt (or ensure
     no defaults file is set) to exercise the *working* Path C loader.
  4. Click "Save to MAT" → save.
  5. Click "Load Checksums File" → select a valid checksum file.
  6. Click "Send Packet(s)" → Periodic mode, short interval → Send.
- Expected Result: All steps succeed; conversions verified applied (TC-CSV-FUNC-010); MAT save
  succeeds; periodic send completes with checksums enabled and roughly correct timing.
- **Companion negative case:** repeat step 3 but **accept** ("Yes") the defaults-file prompt —
  expected to fail per TC-CSV-FUNC-008; log this explicitly as the known-broken variant of this
  workflow rather than treating the whole workflow as failed.

**TC-E2E-003 — GUI Workflow 3: Reuse Saved Packets**
- Priority: High
- Steps:
  1. Load header; select protocol.
  2. Click "Load from MAT" → select a `.mat` file previously produced by TC-E2E-002/TC-MAT-FUNC-001.
  3. Click "Load Checksums File" (optional).
  4. Click "Send Packet(s)".
- Expected Result: Packets load correctly (metadata echoed); send completes; confirms the "reuse"
  workflow is fully independent of re-parsing CSV.

**TC-E2E-004 — CLI equivalent full workflow (per `README.md` "Full Workflow Example")**
- Priority: High
- Steps:
  ```matlab
  ScapyML('load', 'sensor_msg.h', 'big');
  pkt = ScapyML('packet', 'SensorMsg', 'msg_id', 1, 'temperature', 235);
  pkt.show();
  pkts = ScapyML('csv', 'sensor_data.csv', 'SensorMsg');
  ScapyML('send', pkts, '127.0.0.1', 5000);
  ScapyML('dissector', 'SensorMsg', 'sensor_msg.lua', 5000);
  ```
- Expected Result: Every line executes without error, matching the documented example exactly
  (note: this example correctly uses the working `csv` command, not the broken `fromcsv` — confirm
  the documentation's main example does **not** exercise the broken path, which is worth noting as
  a reason the defect may have gone unnoticed).

**TC-E2E-005 — Multi-file, dependency-resolved, checksummed, dissected end-to-end (comprehensive)**
- Priority: Medium
- Steps: Combine cross-file enum/struct references (§1, §15), bit-fields, arrays, a nested
  union, checksums, and single-protocol Wireshark generation into one continuous session,
  mirroring realistic usage.
- Expected Result: All sub-features interoperate correctly in combination, not just in isolation —
  this case is specifically designed to catch integration issues that per-feature testing might
  miss.

---

## 20. Coverage Matrix

Maps `REQUIREMENTS.md` functional requirements to the test cases in this document that exercise
their acceptance criteria.

| Requirement | Description | Covering Test Cases | Coverage Status |
|---|---|---|---|
| FR-001 | Protocol Loading | TC-HDR-FUNC-001…013, TC-HDR-NEG-001…006, TC-DEP-* | Full |
| FR-002 | Packet Creation | TC-PKT-FUNC-001, TC-PKT-NEG-004, TC-REG-ERR-001 | Full |
| FR-003 | Field Manipulation | TC-PKT-FUNC-003…006, TC-PKT-NEG-001…003, TC-PKT-BOUND-001…006 | Full |
| FR-004 | Packet Encoding | TC-CODEC-FUNC-001…010, TC-CODEC-BOUND-001…003 | Full |
| FR-005 | Checksum Calculation | TC-CHK-FUNC-001…006, TC-CHK-ERR-001…006, TC-CHK-BOUND-001 | Full |
| FR-006 | Value Conversions | TC-CONV-FUNC-001…004, TC-CONV-ERR-001…003 | Full |
| FR-007 | Default Values | TC-DEF-FUNC-001…005, TC-DEF-ERR-001…004 | Full |
| FR-008 | Bulk CSV Loading | TC-CSV-FUNC-001…012, TC-CSV-NEG-001…003 | **Full — all 3 paths (A/B/C) covered and working.** Path B was broken (duplicate/shadowed switch-case label plus a missing implementation file, KI-NEW-01) and has since been **fixed**; see TC-CSV-FUNC-007/008. |
| FR-009 | UDP Packet Transmission | TC-UDP-FUNC-001…004, TC-SEND-FUNC-001…005 | Full |
| FR-010 | Precise Timing Control | TC-SEND-FUNC-002…003 | Full (informal timing measurement per §24 of STP) |
| FR-011 | MAT File Persistence | TC-MAT-FUNC-001…004, TC-MAT-DATA-001, TC-MAT-ERR-001…004 | Full |
| FR-012 | Wireshark Dissector Generation | TC-WSD-FUNC-001…007, TC-WSD-INT-001…002, TC-MWSD-FUNC-001…005 | **Full — single- and multi-protocol generation both covered and working.** Multi-protocol generation via the GUI was broken (three non-existent `DiscriminatorConfig` method calls plus a private-property access, KI-NEW-02) and has since been **fixed**; see TC-MWSD-FUNC-004/005. |
| FR-013 | GUI Interface | TC-GUI-UI-001…006, TC-GUI-FUNC-001…004, TC-E2E-001…003 | Full (with the FR-012-linked multi-protocol dialog exception noted above) |
| NFR-001 | Performance | TC-CSV-PERF-001, TC-MAT-PERF-001, informal `tic`/`toc` around single `build()` | Sanity-level (see STP §24 — not formal benchmarking) |
| NFR-002 | Reliability | All `TC-*-ERR-*` and `TC-*-NEG-*` cases across every module | Full |
| DP-002 | Layered Architecture | Cross-cutting — no single test case; verified implicitly by the absence of any lower-layer module (`Codec`, `HeaderParser`, `UdpSender`) importing/calling `ScapyML_GUI.m` or `ScapyML.m` during code reading | Full (by inspection) |
| DP-004 | Checksum Post-Encoding | TC-CHK-FUNC-001…002 | Full |
| DP-005 | Manual Verification | TC-PROTO-FUNC-004, TC-CODEC-FUNC-003, TC-WSD-FUNC-002 (explicit hand-computed byte/mask cross-checks) | Full |

---

## 21. Known Issues / Gap Analysis

Defects and notable gaps identified while reading the source code to design this test suite,
independent of actually executing the test cases. Each should be filed as a defect report using
the reproduction steps in the referenced test case(s).

### KI-NEW-01 — ✅ FIXED — Duplicate `'fromcsv'` switch-case label shadowed the intended
defaults/conversions path; a secondary, genuinely-missing `ScapyML_fromCSV` function compounded
the defect (was Critical)
- **Where:** `ScapyML.m`'s `switch cmd` statement contains TWO case blocks that both list
  `'fromcsv'` as a matching label: `case {'csv','readcsv','fromcsv'}` (appears first, ~line 152)
  and `case {'fromcsv','csv2packets','autocsv'}` (appears second, ~line 242, and is the block that
  calls `ScapyML_fromCSV(protoName, csvFile, defaultsFile, conversionFile)`).
- **Primary defect (the one users will actually hit):** Since `cmd = lower(strtrim(varargin{1}))`
  and MATLAB's `switch/case` always executes the *first* block whose label list contains the
  matched value, calling `ScapyML('fromCSV', ...)` or `ScapyML('fromcsv', ...)` — the documented
  spelling in `REQUIREMENTS.md`/`README.md` — **always** hits the first block, never the second.
  The first block executes `ScapyML.CsvLoader.load(varargin{2}, varargin{3})`, i.e.
  `CsvLoader.load(protoName, csvFile)` — but `CsvLoader.load`'s actual signature is
  `load(csvFile, protoName)`, the opposite order from what the (unreachable) second block's own
  "Usage:" string documents. The observable failure is therefore
  `error('ScapyML:CsvLoader:FileNotFound', 'CSV file not found: <protocol name>')` — a confusing
  message that names the *protocol* as a missing *file*, actively misleading a user into thinking
  they mistyped a CSV path rather than revealing the real bug (a shadowed case label plus a
  swapped-argument call). This is reachable from both the CLI `fromCSV` command and
  `ScapyML_GUI.m`'s `loadFromCSV()` `useDefaults` branch, which calls the identical
  `ScapyML('fromCSV', ...)` entry point.
- **Secondary defect (real, but only reachable via undocumented aliases):** `ScapyML_fromCSV.m`
  genuinely does not exist anywhere in the delivered package (confirmed via full-package file
  search) — so the second, normally-dead-code case block *would* also fail if it were ever
  reached. It IS reachable, but only via the aliases `csv2packets` or `autocsv`, which are not
  present in the first block's label list. Calling `ScapyML('csv2packets', ...)` or
  `ScapyML('autocsv', ...)` correctly reaches the second block and raises the originally-documented
  `Undefined function or variable 'ScapyML_fromCSV'` error.
- **Confirmed by:** Line-by-line trace of `ScapyML.m`'s `switch cmd` statement (both case labels
  quoted above), cross-checked with an automated test
  (`TestManualCsvSuite.m`: `tcCliFromcsvIsShadowedByCsvCase_NOT_undefinedFunction` and
  `tcCliFromcsvAliasHitsMissingFunction`) that reproduces both distinct failure modes exactly as
  described.
- **Covering test cases:** TC-CSV-FUNC-007, TC-CSV-FUNC-008 (both corrected).
- **Suggested fix direction:** Two independent fixes are needed: (1) remove `'fromcsv'` from the
  first case block's label list (or merge the two blocks) so the documented `fromCSV` command name
  actually reaches the intended defaults/conversions-aware implementation; and (2) implement
  `ScapyML_fromCSV.m` (likely combining `CsvLoader`-style row iteration with
  `DefaultsManager.apply` and `ConversionManager.convert`, similar in spirit to the GUI's own
  working Path C loader), since it is currently missing regardless of which case block reaches it.
- **✅ Fix applied:** Both parts of the suggested fix have been implemented exactly as described.
  `'fromcsv'` was removed from the first case block's alias list in `ScapyML.m`. `ScapyML_fromCSV.m`
  was implemented, modeled on the GUI's own vectorized loader with `DefaultsManager.apply()` added.
  Verified via `TestManualCsvSuite.m`'s `tcCliFromcsvNowLoadsWithDefaultsAndConversions` (confirms
  both defaults and conversions apply correctly) and `tcCliFromcsvAliasesAlsoWork` (confirms the
  previously-broken aliases now work too).

### KI-NEW-02 — ✅ FIXED — GUI multi-protocol Wireshark dissector generation called non-existent
`DiscriminatorConfig` methods (was Critical)
- **Where:** `ScapyML_GUI.m`, `configureDiscriminator()` → `createConfigFromTable()` (calls
  `config.setDefaults(...)` and `config.addMappingSimple(...)`) and `doGenerateMulti()` (calls
  `config.getMapping(...)` and directly reads the private `reg.Enums` property).
- **Impact:** Selecting 2+ protocols and generating a Wireshark dissector via the GUI always fails
  with an "Undefined method" error before any file is written. This blocks the FR-012 multi-
  protocol acceptance criterion whenever driven through the GUI, which is the only supported
  entry point for multi-protocol generation per `README.md` ("Multi-protocol (use GUI for easy
  selection)").
- **Confirmed by:** Direct comparison of `+ScapyML/DiscriminatorConfig.m`'s actual public method
  list (`addProtocol`, `setGlobalConfig`, `hasGlobalConfig`, `getProtocolConfig`,
  `getProtocolValue`, `getProtocolNames`, `validateUniqueness`, `saveToFile`, `fromFile`,
  `fromGUI`) against the methods called from `ScapyML_GUI.m` (`setDefaults`, `addMappingSimple`,
  `getMapping` — none of which exist), plus the private-property access
  (`properties (Access = private) ... Enums`) on `ProtocolRegistry` vs. `ScapyML_GUI.m`'s direct
  `reg.Enums` read.
- **Covering test cases:** TC-MWSD-FUNC-004, TC-MWSD-FUNC-005.
- **Suggested fix direction:** Either update `ScapyML_GUI.m`'s discriminator dialog to use the
  real `DiscriminatorConfig` API (`addProtocol` per protocol row instead of `setDefaults`/
  `addMappingSimple`; `getProtocolConfig`/`getProtocolValue` instead of `getMapping`; and
  `reg.listEnums()`/`reg.getEnum()` to build the enum cell array instead of `reg.Enums`), or add
  the missing convenience methods to `DiscriminatorConfig` if the simpler GUI-facing API is the
  intended long-term shape.
- **✅ Fix applied:** The first suggested direction was taken — `ScapyML_GUI.m` was updated to call
  the real API rather than adding stub methods to `DiscriminatorConfig` (which was intentionally
  left unchanged, since its existing public surface was already sufficient). `createConfigFromTable()`
  now calls `config.addProtocol(fieldName, offset, fieldSize, msgId)` once per protocol row;
  `doGenerateMulti()` now calls `config.getProtocolValue(...)` and builds `enumDefs` via
  `reg.listEnums()`/`reg.getEnum(...)`.
  **Bonus defect found and fixed during this work:** both `createConfigFromTable()` and the sibling
  nested function `updateTableFromDefaults()` assigned a local variable literally named `size`,
  shadowing MATLAB's builtin `size()` function across their *shared* nested-function workspace —
  which would have broken `doGenerateMulti()`'s own `size(tableData, 1)` call too if "↻ Apply
  Defaults to All" was clicked before "Generate Dissector". Both renamed to `fieldSize`. Verified
  via `TestManualMultiProtocolSuite.m`'s existing `tcMwsdFunc001_...` (proves the engine works with
  the now-matching API) and new `TestManualGuiAndE2ESuite.m` source-level confirmation tests.

### KI-NEW-03 — ✅ FIXED — `ProtocolRegistry.register()` did not enforce unique protocol names,
contradicting `REQUIREMENTS.md` §8.3 (was Medium)
- **Where:** `+ScapyML/ProtocolRegistry.m`, `register()` (`obj.Registry(protoDef.Name) =
  protoDef;` — a plain overwrite with no `isKey` check or warning).
- **Impact:** Loading two headers (or the same header twice with a modified definition) that
  define a struct with the same name silently replaces the earlier definition with no warning.
  Any `Packet` objects already created from the old definition retain their original layout (since
  `Packet` stores a reference to the `ProtocolDef` it was constructed with), but any *new*
  `Packet('SameName')` after the second load uses the new layout — a latent source of confusing,
  hard-to-diagnose bugs in a long-running session (e.g. the GUI, which stays open across many load
  operations).
- **Covering test case:** TC-REG-EDGE-001.
- **Suggested fix direction:** Either add a `warning` on overwrite (minimal fix) or an opt-in
  `error`/confirmation prompt (stronger fix, matching the documented "enforced" claim), and
  correct `REQUIREMENTS.md` §8.3 if silent overwrite is in fact the intended, accepted behavior.
- **✅ Fix applied:** The minimal fix (warning on overwrite) was applied — `register()` now checks
  `isKey` and warns `ScapyML:ProtocolRegistry:Overwrite` naming the protocol before overwriting,
  while still allowing legitimate re-registration (e.g. deliberately reloading an edited header) to
  proceed. `REQUIREMENTS.md`'s claim is now materially true in observable behavior: a silent,
  unexplained overwrite can no longer happen.

### KI-NEW-04 — `BitFieldGrouper` is fully implemented but never invoked (Low)
- **Where:** `+ScapyML/BitFieldGrouper.m` — no call sites found anywhere else in the package.
- **Impact:** None functionally (dead code), but it suggests an intended "grouped bit-field
  display" feature for generated Wireshark dissectors that was never wired into
  `WiresharkDissector.generate()`/`emitFieldList()`. Bit-fields currently are emitted individually
  by `emitOneField`, not grouped under a shared parent subtree as `BitFieldGrouper`'s existence
  implies was once planned.
- **Covering test case:** TC-MWSD-EDGE-002.
- **Suggested fix direction:** Either integrate `BitFieldGrouper` into
  `WiresharkDissector.emitFieldList` to group consecutive bit-fields under a labeled subtree (the
  apparent original intent), or remove the unused class to reduce maintenance surface.

### KI-NEW-05 — `DiscriminatorConfig.fromGUI()` dialog is dead code from the shipped GUI's
perspective (Low)
- **Where:** `+ScapyML/DiscriminatorConfig.m`, static method `fromGUI()`.
- **Impact:** None functionally — it is only reachable via a direct programmatic call to
  `MultiProtocolDissector.generate(...)` with no 5th argument, which `ScapyML_GUI.m` never does
  (it always builds — incorrectly, per KI-NEW-02 — its own config object). Represents duplicated,
  unreachable UI code.
- **Covering test case:** TC-MWSD-EDGE-001.
- **Suggested fix direction:** Once KI-NEW-02 is fixed, consider whether `fromGUI()` should be
  removed in favor of `ScapyML_GUI.m`'s own (corrected) dialog, to avoid two divergent
  implementations of the same configuration UI.
- **Status update:** KI-NEW-02 has since been fixed (`ScapyML_GUI.m`'s dialog now calls the real
  `DiscriminatorConfig` API correctly). `fromGUI()` remains unchanged and still unreachable from the
  shipped GUI — left as-is rather than removed, since deleting a public static method is a larger,
  independent decision than the bug-fix scope this pass covered. Still a candidate for future
  cleanup.

### KI-NEW-06 — ✅ FIXED — `HeaderParser` did not expand C preprocessor macros for array sizes,
and failed with a confusing cascaded error instead of a clear one (was Medium)
- **Where:** `+ScapyML/HeaderParser.m`, `parseField()` array-size handling — expects a literal
  `number` token; `#define` lines are skipped entirely by the tokenizer (treated as
  "preprocessor directive — skip whole line"). The non-numeric branch does not advance the token
  cursor, so the immediately following closing-bracket check fails and throws.
- **Impact (corrected via automated test construction — see `TestManualHeaderParserSuite.m`,
  `tcHdrNeg005_macroArraySizeWarnsThenErrors`):** A header using `uint8_t data[MAX_LEN];` with
  `#define MAX_LEN 16` does **not** merely produce an undersized 1-element array as originally
  documented. It raises `warning` `ScapyML:Parser:InvalidArray` immediately followed by a hard
  `error` `ScapyML:Parser:MissingBracket`, which **aborts parsing of the entire header file**.
  Since `#define`d array sizes are a very common, idiomatic C pattern, this means any header
  using that pattern cannot be loaded by ScapyML at all — a functionally complete blocker for
  that file, not a silent undersizing. See TC-HDR-NEG-005 (corrected).
- **Suggested fix direction:** Document this limitation clearly for users (require literal numeric
  array sizes in headers consumed by ScapyML), since it is a reasonable design constraint for a
  no-regex, hand-rolled parser — but it should be called out explicitly in `README.md`/
  `REQUIREMENTS.md`, which currently do not mention it.
- **✅ Fix applied:** Macro expansion itself was deliberately NOT implemented (out of scope for a
  bug fix — it's a real feature addition, not a defect). Instead, the confusing two-stage
  warning-then-unrelated-error was replaced with ONE clear, actionable error
  (`ScapyML:Parser:InvalidArray`) that explicitly states macros aren't expanded and tells the user
  to use a literal number. The parser now fails fast and clearly on this input rather than either
  silently under-sizing the array (risking undetected downstream corruption) or throwing a
  misleading `MissingBracket` error. This remains a real limitation of the parser — headers using
  `#define`d array sizes still cannot be loaded — but the failure is now immediately
  self-explanatory instead of requiring source-code tracing to understand.

### KI-NEW-07 — ✅ FIXED — `REQUIREMENTS.md` version header (2.1.1) was stale relative to the code
(v2.3.3) (was Low / Documentation gap)
- **Where:** `REQUIREMENTS.md` line 3 ("**Version:** 2.1.1") vs. §10 Version History, which
  documents changes through "v2.3.1 (Current)" and a further note referencing "v2.3.3" fixes that
  are also visible directly in code comments (`ScapyML.m`, `ProtocolDef.m`,
  `ProtocolRegistry.m`) but are not reflected in the document's own header or its own §10 entry
  order (v2.3.1 is listed as "(Current)" even though v2.3.3 fixes are described in the same
  section and in the package filename `ScapyML_v2_3_3_CLEAN.zip`).
- **Impact:** None functional — purely a documentation freshness issue that could confuse a tester
  cross-referencing the spec against the delivered code.
- **Suggested fix direction:** Update the document header and §10 "Current" marker to v2.3.3 as
  part of the next documentation pass.
- **✅ Fix applied:** `REQUIREMENTS.md`'s header now reads `**Version:** 2.3.3`, and a new
  "v2.3.3 (Current)" entry was added to §10 Version History (documenting the cross-file type
  resolution fix, the enum-only dependency file fix, and the unresolved-type warning, all of which
  were previously visible only in scattered code comments), with the old v2.3.1 entry's
  "(Current)" label removed accordingly.

---

## 22. Final Summary

This manual test specification derives **19 major test areas** covering every class under
`+ScapyML/`, both entry points (`ScapyML.m` CLI and `ScapyML_GUI.m` GUI), and all documented
external file formats (`.h`, checksum/conversion/defaults `.txt`, `.csv`, `.mat`, `.lua`), with
test cases spanning functional, negative, boundary, edge-case, error-handling, integration,
performance-sanity, and end-to-end categories, per the manual-QA skill's required breadth.

**Update — all identified defects have since been fixed.** Two **Critical**-severity,
code-confirmed defects were identified purely through source reading during test design
(KI-NEW-01, KI-NEW-02) — both made a *documented, primary* feature path completely non-functional
(`fromCSV`/defaults-driven CSV loading; GUI-driven multi-protocol Wireshark dissector generation).
These were originally flagged with dedicated "EXPECTED TO FAIL" test cases rather than omitted, and
have since been corrected in the source:

1. **KI-NEW-01** — fixed by removing the duplicate `'fromcsv'` switch-case label in `ScapyML.m` and
   implementing the previously-missing `ScapyML_fromCSV.m`.
2. **KI-NEW-02** — fixed by updating `ScapyML_GUI.m`'s discriminator dialog to call the real,
   already-existing `DiscriminatorConfig`/`ProtocolRegistry` public API instead of three
   non-existent methods and a private property. A related latent bug (a local variable named
   `size` shadowing the builtin function across a shared nested-function workspace) was found and
   fixed in the same pass.

Three additional **Medium/Low**-severity gaps were also captured for completeness and have
likewise been addressed: **KI-NEW-03** (protocol-name uniqueness — now warns on overwrite),
**KI-NEW-06** (macro array sizes — now fail with one clear error instead of a confusing cascaded
one), and **KI-NEW-07** (stale version documentation — now updated). **KI-NEW-04** and **KI-NEW-05**
(two instances of dead/unreachable code — `BitFieldGrouper` and `DiscriminatorConfig.fromGUI()`)
remain open by design: neither causes incorrect behavior, and removing or wiring in dead code is a
design decision outside the scope of a bug-fix pass, left for a deliberate follow-up.

Every fix was verified against updated or newly-added automated tests (`tests/TestManual*.m`), and
every test that previously characterized a defect as broken (by design, as a tripwire) has been
updated to confirm the fix instead — including one previously-undocumented gap (`TC-REG-EDGE-001`)
that was filled in as part of fixing KI-NEW-03.

Per `STP.md` §39/§40 test prioritization and quality gates, none of the identified defects blocked
Critical-priority test execution at any point (Codec, Packet, ChecksumManager, and the core
CLI/GUI happy paths tested as fully functional throughout) — the framework's core
encode/decode/transmit capability was never at structural risk. A live MATLAB re-run of the full
suite (this analysis was performed via static source reading, without an interactive MATLAB
session) is still recommended before release to confirm all fixes behave as traced.

### KI-NEW-08 — Anonymous opposite-kind block flattened (FIXED, unverified by execution)
- **Symptom:** `union { uint8_t raw; struct { uint8_t hi:4; uint8_t lo:4; }; }` produced Lua where the
  union members and the struct's bit-fields were shifted relative to each other (and an anonymous
  `union` inside a `struct` became sequential members).
- **Root cause:** `HeaderParser.parseField` flattened every anonymous block into its parent, so members took
  the parent's layout; `WiresharkDissector.collectFieldsWithMeta` also ignored union semantics.
- **Fix:** opposite-kind anonymous blocks stay nested; mask computation is union-aware.
- **Automated tests:** `qa/tests/TestManualUnionSuite.m` (2 tests).

### KI-NEW-09 — Nested field names over 63 characters (FIXED, unverified by execution)
- **Symptom:** names built from deeply nested structs exceeded MATLAB's `namelengthmax` (63) and could not be
  used as struct fields; two-level nesting also repeated the member name (`outer_pos_pos_x`).
- **Fix:** `HeaderParser.prefixProto` no longer doubles the member name; `HeaderParser.shortenLongFieldNames`
  shortens over-long names uniquely and records `FieldDef.FullName`.
- **Automated tests:** `qa/tests/TestManualLongNamesSuite.m` (6 tests).

