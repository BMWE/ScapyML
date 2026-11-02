# ScapyML - Requirements & Functional Specification

**Version:** 2.3.3  
**Last Updated:** October 21, 2026  
**Author:** Michael (SW Architect, Verification Manager, Implementer)

---

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Functional Requirements](#functional-requirements)
4. [Non-Functional Requirements](#non-functional-requirements)
5. [Design Principles](#design-principles)
6. [Interface Specifications](#interface-specifications)
7. [Data Flow](#data-flow)
8. [Configuration Management](#configuration-management)
9. [Verification & Testing](#verification--testing)
10. [Version History](#version-history)

---

## 1. Overview

### 1.1 Purpose

ScapyML is a MATLAB framework for network packet definition, encoding, and transmission. It enables users to define protocol structures using C header files and generate compliant binary packets without recompilation.

### 1.2 Scope

- **Protocol Definition:** Parse C header files to define packet structures
- **Packet Building:** Construct packets with field-level control
- **Data Encoding:** Convert structured data to binary representation
- **Checksum Calculation:** Apply configurable checksum algorithms
- **Network Transmission:** Send packets via UDP with precise timing
- **Bulk Operations:** Process CSV files for batch packet generation
- **Persistence:** Save/load packet collections for reuse
- **Integration:** Generate Wireshark dissectors for analysis

### 1.3 Target Users

- Network protocol developers
- Test engineers
- Embedded systems developers
- Protocol verification engineers

---

## 2. System Architecture

### 2.1 Layer Architecture

The framework implements a 5-layer architecture:

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 1: Presentation                                      │
│  - ScapyML_GUI.m (Graphical Interface)                     │
│  - ScapyML.m (Command-Line Interface)                      │
├─────────────────────────────────────────────────────────────┤
│  Layer 2: Application                                       │
│  - Workflow Coordination                                    │
│  - Entry Points                                             │
├─────────────────────────────────────────────────────────────┤
│  Layer 3: Business Logic                                    │
│  - Packet.m (Packet Building)                              │
│  - Codec.m (Encoding/Decoding)                             │
│  - ChecksumManager.m (Checksum Calculation)                │
│  - ConversionManager.m (Value Conversion)                  │
│  - DefaultsManager.m (Default Values)                      │
├─────────────────────────────────────────────────────────────┤
│  Layer 4: Protocol                                          │
│  - HeaderParser.m (C Header Parsing)                       │
│  - ProtocolRegistry.m (Protocol Storage)                   │
│  - ProtocolDef.m (Protocol Definition)                     │
│  - FieldDef.m (Field Definition)                           │
│  - EnumDef.m (Enumeration Definition)                      │
├─────────────────────────────────────────────────────────────┤
│  Layer 5: Network                                           │
│  - PacketSender.m (Transmission Control)                   │
│  - UdpSender.m (UDP Communication)                         │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Design Patterns

- **Singleton:** ProtocolRegistry (single instance)
- **Builder:** Packet (fluent interface)
- **Strategy:** ChecksumManager (pluggable algorithms)
- **Factory:** HeaderParser (creates protocol objects)
- **Static Utility:** Codec, PacketSender

### 2.3 External Dependencies

- **Input Files:**
  - `.h` - C header files (protocol definitions)
  - `.csv` - Data files (bulk packet values)
  - `.txt` - Configuration files (checksums, conversions, defaults)

- **Output Files:**
  - `.mat` - Saved packet collections
  - `.lua` - Wireshark dissector scripts

---

## 3. Functional Requirements

### FR-001: Protocol Loading

**Description:** Load protocol definitions from C header files  
**Priority:** Critical  
**Input:** C header file path, endianness specification  
**Output:** Protocol registered in ProtocolRegistry  
**Acceptance Criteria:**
- Parse `typedef struct` declarations
- Support `uint8_t`, `uint16_t`, `uint32_t`, `uint64_t`
- Support `int8_t`, `int16_t`, `int32_t`, `int64_t`
- Support bitfield syntax (e.g., `uint8_t flag:1`)
- Support nested structures
- Support arrays (e.g., `uint8_t data[16]`)
- Support enumerations
- Handle big-endian and little-endian

**Status:** ✅ Implemented v1.0

---

### FR-002: Packet Creation

**Description:** Create packet instances from loaded protocols  
**Priority:** Critical  
**Input:** Protocol name  
**Output:** Packet object with initialized fields  
**Acceptance Criteria:**
- All fields initialized to zero or default values
- Support field access by name
- Validate protocol exists before creation
- Return error if protocol not found

**Status:** ✅ Implemented v1.0

---

### FR-003: Field Manipulation

**Description:** Set and get field values in packets  
**Priority:** Critical  
**Input:** Field name, value  
**Output:** Updated packet state  
**Acceptance Criteria:**
- Set scalar fields
- Set array fields
- Set bitfield fields
- Set nested structure fields
- Validate field names
- Type conversion where applicable
- Return current field value on get

**Status:** ✅ Implemented v1.0

---

### FR-004: Packet Encoding

**Description:** Convert packet to binary representation  
**Priority:** Critical  
**Input:** Packet object  
**Output:** `uint8` byte array  
**Acceptance Criteria:**
- Encode all field types correctly
- Apply specified endianness
- Handle bitfield packing
- Handle array encoding
- Handle nested structure encoding
- Return bytes matching protocol size

**Status:** ✅ Implemented v1.0

---

### FR-005: Checksum Calculation

**Description:** Apply user-defined checksum formulas  
**Priority:** High  
**Input:** Checksum configuration file, encoded packet  
**Output:** Packet with calculated checksums  
**Acceptance Criteria:**
- Load formulas from external file
- Support MATLAB anonymous function syntax
- Operate on raw bytes post-encoding
- Support multiple checksum fields
- Write checksum back to designated field
- Validate formula syntax on load
- Zero the target checksum field before each calculation, so rebuilding a
  packet always gives the same result (idempotent)
- Apply multiple checksums in byte-offset order (a later checksum may cover
  an earlier one)
- Entry point: `Packet.buildWithChecksums(cm)`; plain `build()` does not apply checksums
- Warn (do not fail) on: missing file (`ScapyML:ChecksumManager:FileNotFound`),
  unknown field (`...:FieldNotFound`), non-function right-hand side
  (`...:NotFunction`), non-scalar result (`...:InvalidResult`)
- Result written big/little endian per protocol, truncated to the field size
  (1, 2, 4 or 8 bytes); formulas must return a non-negative number
- Ship a library of standard algorithms, `ScapyML.Crc`: `crc8`,
  `crc16ccitt`, `crc16modbus`, `crc32`, `internetChecksum` (RFC 1071),
  `fletcher16`; verified against the published check values for `123456789`
  (0xF4, 0x29B1, 0x4B37, 0xCBF43926, 0x1EDE)

**Configuration Format:**
```matlab
fieldName = @(data) expression
```

**Example:**
```matlab
checksum = @(data) mod(sum(uint16(data)), 256)
crc16 = @(data) ScapyML.Crc.crc16ccitt(data(1:end-2))   % CRC in the last 2 bytes
xor_check = @(data) sum(arrayfun(@(k) mod(sum(bitget(data, k)), 2) * 2^(k-1), 1:8))
```

**Status:** ✅ Implemented v1.5 (CLI), v2.0 (GUI); idempotent zeroing v2.3.1;
`ScapyML.Crc` library v2.3.3

---

### FR-006: Value Conversions

**Description:** Apply field value transformations  
**Priority:** Medium  
**Input:** Conversion configuration file, field values  
**Output:** Converted values  
**Acceptance Criteria:**
- Load conversions from external file
- Support formula-based conversions
- Apply during packet creation
- Support selective field conversion

**Configuration Format:**
```matlab
fieldName = @(value) expression
```

**Example:**
```matlab
temperature = @(x) x * 0.1 - 40
pressure = @(x) x / 100
```

**Status:** ✅ Implemented v1.3

---

### FR-007: Default Values

**Description:** Apply default field values  
**Priority:** Medium  
**Input:** Defaults configuration file  
**Output:** Packets with pre-filled values  
**Acceptance Criteria:**
- Load defaults from external file
- Apply during packet creation
- Allow override by explicit set()
- Support all field types

**Configuration Format:**
```
fieldName = value
```

**Example:**
```
version = 1
protocol_id = 42
```

**Status:** ✅ Implemented v1.2

---

### FR-008: Bulk CSV Loading

**Description:** Create multiple packets from CSV data  
**Priority:** High  
**Input:** CSV file with column headers matching field names  
**Output:** Cell array of packet objects  
**Acceptance Criteria:**
- Parse CSV file
- Map columns to fields by name
- Create one packet per row
- Apply conversions if specified
- Apply defaults if specified
- Report row count
- Available from the command line as `ScapyML('fromCSV', protocol, csv, [defaults], [conversions])`
  (aliases `csv2packets`, `autocsv`) and through `ScapyML_fromCSV`; a missing
  defaults file gives warning `ScapyML:fromCSV:DefaultsFileNotFound` and loading continues
- Conversions are applied once per raw column (no double scaling)
- Wide-file performance: read only the CSV columns that map to protocol
  fields, build packets in blocks through a fast internal constructor, and
  convert whole columns at once (`ConversionManager.convertVector`), falling
  back to element-wise conversion when a formula is not vectorizable

**Status:** ✅ Implemented v1.1; CLI path fixed and bulk loading accelerated v2.3.3

---

### FR-009: UDP Packet Transmission

**Description:** Send packets over UDP  
**Priority:** High  
**Input:** Packet(s), destination IP, port, send mode  
**Output:** Transmitted packets  
**Acceptance Criteria:**
- Support unicast IP addresses
- Support multicast IP addresses (224.0.0.0 - 239.255.255.255)
- Support three send modes:
  - **Single:** Send all packets immediately
  - **Periodic:** Send with fixed interval
  - **CSV-timed:** Send with timestamps from CSV
- Apply checksums before sending (if configured)

**Status:** ✅ Implemented v1.0, Enhanced v2.0

---

### FR-010: Precise Timing Control

**Description:** Accurate packet transmission timing  
**Priority:** High  
**Input:** Time interval or timestamp  
**Output:** Packets sent at specified times  
**Acceptance Criteria:**
- Periodic mode: ±1-2ms accuracy for intervals ≥10ms
- CSV mode: ±0.1ms accuracy using busy-wait
- Compensate for processing time
- Report timing errors
- Warn if processing too slow

**Implementation:**
- Use `tic`/`toc` for timing
- Subtract processing time from interval
- Busy-wait for sub-millisecond precision

**Status:** ✅ Implemented v2.0

---

### FR-011: MAT File Persistence

**Description:** Save/load packet collections  
**Priority:** High  
**Input:** Packet collection or MAT file path  
**Output:** MAT file or loaded packets  
**Acceptance Criteria:**
- Save packets with metadata
- Load packets with validation
- Validate protocol compatibility
- Track source CSV (if applicable)
- Store version information
- 10-40x faster loading than CSV

**MAT File Structure:**
```matlab
packetData.packets        % Cell array of Packet objects
packetData.protocolName   % String
packetData.packetCount    % Integer
packetData.createdDate    % String (optional)
packetData.scapymlVersion % String (optional)
packetData.sourceCSV      % String (optional)
```

**Status:** ✅ Implemented v2.1

---

### FR-012: Wireshark Dissector Generation

**Description:** Generate Lua dissectors for Wireshark  
**Priority:** Medium  
**Input:** Protocol definition, UDP port  
**Output:** Lua dissector script  
**Acceptance Criteria:**
- Generate dissector for single protocol
- Generate multi-protocol discriminator
- Support all field types
- Support nested structures
- Support arrays
- Support bitfields
- Install instructions included

**Status:** ✅ Implemented v1.4

---

### FR-013: GUI Interface

**Description:** Graphical user interface for all operations  
**Priority:** High  
**Input:** User interactions  
**Output:** Visual feedback and results  
**Acceptance Criteria:**
- Load protocol files
- Create packets
- Edit packet fields
- Load CSV data
- Save/load MAT files
- Load configuration files (checksums, conversions, defaults)
- Send packets with timing control
- Display output messages
- Generate Wireshark dissectors

**GUI Layout:**
```
┌─────────────────────────────────────────────────────┐
│ ScapyML - Protocol Packet Framework                 │
├──────────────┬──────────────────────────────────────┤
│  Controls    │  Output                              │
│              │                                       │
│ LOAD HEADERS │  [Messages and results display here] │
│ PROTOCOL     │                                       │
│ PACKET       │                                       │
│ DATA         │                                       │
│ ACTIONS      │                                       │
│              │                                       │
└──────────────┴──────────────────────────────────────┘
```

**Status:** ✅ Implemented v1.0, Enhanced v2.0, v2.1

---

## 4. Non-Functional Requirements

### NFR-001: Performance

**Requirement:** Efficient packet processing  
**Metrics:**
- Single packet encoding: <10ms
- 1000 packet CSV load: <15 seconds
- 1000 packet MAT load: <1 second
- Timing precision: ±1ms for intervals ≥10ms

**Status:** ✅ Met

---

### NFR-002: Reliability

**Requirement:** Robust error handling  
**Criteria:**
- All file operations wrapped in try-catch
- Validate all user inputs
- Clear error messages
- No silent failures
- Graceful degradation

**Status:** ✅ Met

---

### NFR-003: Maintainability

**Requirement:** Clean, documented code  
**Criteria:**
- Consistent coding style
- Comprehensive comments
- Separation of concerns
- Modular design
- Single Responsibility Principle

**Status:** ✅ Met

---

### NFR-004: Extensibility

**Requirement:** Easy to add features  
**Criteria:**
- External configuration files
- No recompilation for protocol changes
- Pluggable checksum algorithms
- Pluggable conversions
- Open for extension, closed for modification

**Status:** ✅ Met

---

### NFR-005: Usability

**Requirement:** User-friendly interface  
**Criteria:**
- Clear button labels
- Helpful error messages
- Logical workflow
- Tooltips where needed
- Consistent behavior

**Status:** ✅ Met

---

### NFR-006: Compatibility

**Requirement:** Backward compatibility  
**Criteria:**
- No breaking changes between versions
- Old scripts continue to work
- File format stability
- API stability

**Status:** ✅ Met (v1.x → v2.x)

---

## 5. Design Principles

### DP-001: External Configuration Over Recompilation

**Principle:** All protocol definitions, checksums, conversions, and defaults must be in external configuration files.

**Rationale:** 
- Enables non-programmers to modify behavior
- No MATLAB recompilation needed
- Faster iteration during development
- Clear separation of data and code

**Implementation:**
- `.h` files for protocols
- `.txt` files for checksums/conversions/defaults
- `.csv` files for packet data
- `.mat` files for packet persistence

**Status:** ✅ Enforced

---

### DP-002: Layered Architecture

**Principle:** Maintain strict separation between layers.

**Rules:**
- Upper layers may call lower layers
- Lower layers never call upper layers
- No cross-layer dependencies
- Each layer has single responsibility

**Status:** ✅ Enforced

---

### DP-003: Fail-Fast Validation

**Principle:** Validate inputs early and provide clear errors.

**Implementation:**
- Check file existence before parsing
- Validate field names before setting
- Check protocol registration before use
- Clear error messages with context

**Status:** ✅ Enforced

---

### DP-004: Checksum Post-Encoding

**Principle:** Checksums must be calculated on raw bytes after encoding.

**Rationale:**
- Checksums depend on exact byte representation
- Endianness affects byte order
- Bitfield packing affects layout
- Only post-encoding bytes are accurate

**Status:** ✅ Enforced (critical architectural requirement)

---

### DP-005: Manual Verification Over Automation

**Principle:** Automated tests are necessary but insufficient. Manual verification catches bugs automated tests miss.

**Implementation:**
- Manual byte-level comparison
- Expected vs. actual validation
- Field-level verification
- Visual inspection of outputs

**Examples of bugs found manually:**
- GUI byte offset miscalculation
- Enum ByteSize = 0 assignment
- Array size not multiplied in totalBytes()
- ChecksumManager interface access

**Status:** ✅ Practiced

---

## 6. Interface Specifications

### 6.1 Command-Line Interface

#### Load Protocol
```matlab
ScapyML('load', 'protocol.h', 'big');  % big-endian
ScapyML('load', 'protocol.h', 'little');  % little-endian
```

#### List Protocols
```matlab
protocols = ScapyML('list');
```

#### Create Packet
```matlab
pkt = ScapyML.Packet('ProtocolName');
```

#### Set Fields
```matlab
pkt.set('field_name', value);
pkt.set('array_field', [1, 2, 3]);
pkt.set('nested.field', value);
```

#### Build Packet
```matlab
bytes = pkt.build();  % Without checksums
```

#### Build with Checksums
```matlab
cm = ScapyML.ChecksumManager('checksums.txt');
bytes = pkt.buildWithChecksums(cm);
```

#### Load from CSV
```matlab
packets = ScapyML('fromCSV', 'ProtocolName', 'data.csv');
packets = ScapyML('fromCSV', 'ProtocolName', 'data.csv', ...
                  'defaults.txt', 'conversions.txt');
```

#### Send Packets
```matlab
ScapyML.PacketSender.sendWithTiming(packets, '192.168.1.100', 5000, ...
                                    'periodic', 0.010);  % 10ms interval
```

---

### 6.2 GUI Interface

#### Workflow 1: Single Packet
1. Click **"Load Single Header"** → Select `.h` file
2. Select protocol from list
3. Click **"Create Packet"**
4. Click **"Edit Packet Fields"** → Set values
5. Click **"Load Checksums File"** (optional)
6. Click **"Send Packet(s)"** → Configure and send

#### Workflow 2: Bulk CSV
1. Click **"Load Single Header"** → Select `.h` file
2. Select protocol from list
3. Click **"Load Conversion File"** (optional)
4. Click **"Create Defaults File"** or **"Load Conversion File"** (optional)
5. Click **"Load from CSV"** → Select `.csv` file
6. Click **"Save to MAT"** (optional, for reuse)
7. Click **"Load Checksums File"** (optional)
8. Click **"Send Packet(s)"** → Configure and send

#### Workflow 3: Reuse Saved Packets
1. Click **"Load Single Header"** → Select `.h` file
2. Select protocol from list
3. Click **"Load from MAT"** → Select `.mat` file
4. Click **"Load Checksums File"** (optional)
5. Click **"Send Packet(s)"** → Configure and send

---

### 6.3 Configuration File Formats

#### Checksum Configuration (`checksums.txt`)
```matlab
% Format: fieldName = @(data) expression
% data is uint8 array of encoded packet

checksum = @(data) mod(sum(uint16(data)), 256)
crc16 = @(data) mod(sum(uint16(data)), 65536)
xor_check = @(data) sum(arrayfun(@(k) mod(sum(bitget(data, k)), 2) * 2^(k-1), 1:8))
```

#### Conversion Configuration (`conversions.txt`)
```matlab
% Format: fieldName = @(value) expression
% value is the input value before encoding

temperature = @(x) x * 0.1 - 40
pressure = @(x) x / 100
voltage = @(x) x * 1000
```

#### Defaults Configuration (`defaults.txt`)
```
# Format: fieldName = value
# Simple key-value pairs

version = 1
protocol_id = 42
reserved = 0
```

---

## 7. Data Flow

### 7.1 Packet Creation Flow

```
C Header File (.h)
       ↓
HeaderParser.parse()
       ↓
ProtocolDef created
       ↓
ProtocolRegistry.register()
       ↓
User: Packet('ProtocolName')
       ↓
ProtocolRegistry.get()
       ↓
Packet initialized with ProtocolDef
       ↓
User: set('field', value)
       ↓
Values stored in containers.Map
```

### 7.2 Encoding Flow

```
User: packet.build()
       ↓
Codec.encode(Proto, Values, Dirty)
       ↓
For each field:
  - Get field value
  - Convert to bytes (based on type and endianness)
  - Write to byte array at field offset
       ↓
Return uint8 byte array
```

### 7.3 Checksum Flow

```
User: packet.buildWithChecksums(cm)
       ↓
Step 1: packet.build() → bytes (checksum = 0)
       ↓
Step 2: cm.applyChecksums(bytes, packet)
       ↓
For each checksum field:
  - formula = getFormula(fieldName)
  - value = formula(bytes)
  - offset = getFieldOffset(fieldName)
  - Write value to bytes at offset
       ↓
Return bytes (with checksums calculated)
```

### 7.4 Send Flow

```
User: PacketSender.sendWithTiming(packets, ...)
       ↓
For each packet:
  - If ChecksumManager exists:
      bytes = packet.buildWithChecksums(cm)
    Else:
      bytes = packet.build()
  - UdpSender.send(bytes, ip, port)
  - Apply timing (if periodic or CSV mode)
       ↓
Complete
```

---

## 8. Configuration Management

### 8.1 Version Control

**Framework Version:** Tracked in code comments and release notes  
**File Format Versions:** Stable across v1.x and v2.x  
**API Versioning:** Semantic versioning (major.minor.patch)

### 8.2 Configuration File Management

**Location:** User-specified, loaded at runtime  
**Validation:** On load, with clear error messages  
**Reload:** Supported without restart  
**Syntax:** MATLAB-compatible expressions

### 8.3 Protocol Registry

**Storage:** In-memory containers.Map  
**Lifetime:** Session-based (cleared on restart)  
**Reload:** Supported via clearAll() method  
**Validation:** Unique protocol names enforced

---

## 9. Verification & Testing

### 9.1 Test Strategy

**Unit Tests:** Test individual classes in isolation  
**Integration Tests:** Test interactions between components  
**System Tests:** Test complete workflows end-to-end  
**Manual Verification:** Byte-level comparison of expected vs. actual

### 9.2 Critical Test Cases

#### TC-001: Protocol Loading
- Load valid .h file
- Load invalid .h file
- Load non-existent file
- Load both endianness modes

#### TC-002: Packet Encoding
- All primitive types
- Arrays
- Bitfields
- Nested structures
- Enumerations
- Both endianness modes

#### TC-003: Checksum Calculation
- Simple sum
- CRC-like algorithms
- XOR checksums
- Multiple checksum fields
- Invalid formulas

#### TC-004: Timing Precision
- 10ms periodic (target: ±1ms)
- 1ms periodic (target: ±2ms)
- CSV-timed (target: ±0.1ms)
- Fast intervals (warning if too slow)

#### TC-005: MAT File Persistence
- Save single packet
- Save 1000 packets
- Load and verify integrity
- Protocol mismatch handling
- Invalid MAT file handling

### 9.3 Known Limitations

1. **Bitfield Alignment:** Assumes byte-aligned groups
2. **Maximum Field Size:** Limited by MATLAB memory
3. **Timing Precision:** OS-dependent, best on low-load systems
4. **MAT File Size:** Large collections (>100MB) may be slow
5. **Protocol Changes:** Changing .h file requires reload
6. **Macros:** `#define` constants are not expanded; an array size given as a
   macro name raises `ScapyML:Parser:InvalidArray` (use a literal number)
7. **Cross-call type resolution:** a type is resolved only if its defining file
   was parsed earlier in the same `load` call (or `'auto'` ordering is used)
8. **Unused code:** `BitFieldGrouper`, `WiresharkDissector.emitOneBitField`
   and the `DiscriminatorConfig.fromGUI` fallback are not reached by any
   shipped entry point
9. **Verification:** the v2.3.3 fixes and additions were verified by code
   review; a full MATLAB test run is still required

---

## 10. Version History

### v2.3.3 (Current) — Cross-File Type Resolution
**Changes:**
- Fixed multi-file loading order: previously all files were parsed first and
  registered only afterward, so a struct in one file referencing a type
  defined in a later file in the same `load` call would fail to resolve even
  when both files were provided together. Files are now parsed and
  registered one at a time, in the order given, so earlier files' types are
  visible to later files.
- Fixed `DependencyResolver` to recognize enum-only header files as
  dependency sources: previously a file containing only a
  `typedef enum {...} Name;` (no structs) was invisible to the dependency
  graph, so `'auto'` load ordering could not correctly place it before
  files that referenced its enum.
- Changed unresolved cross-file type references from a silent 0-byte field
  (no diagnostic at all) to a `ScapyML:HeaderParser:UnresolvedType` warning,
  so a wrong load order is now visible to the user instead of silently
  corrupting a field's size.
- Known limitation (documented, not fixed in this version): a type
  reference is still only resolved if its defining file was already parsed
  *earlier in the same `load` call* (or `'auto'` ordering is used). Loading
  the dependent file in a separate, later `ScapyML('load', ...)` call than
  its dependency will still warn `UnresolvedType`.

**Files Modified:** ScapyML.m, ProtocolRegistry.m, HeaderParser.m,
DependencyResolver.m

**Also in v2.3.3 (fixes and additions, October 2026):**
- Fixed: `ScapyML('fromCSV', ...)` was unreachable because the `csv` case
  shadowed it; added `ScapyML_fromCSV.m` (defaults + conversions)
- Fixed: GUI "Load from CSV" and the multi-protocol discriminator dialog
  called functions/methods that did not exist; fixed a local variable `size`
  that shadowed the MATLAB builtin
- Added: `ScapyML:ProtocolRegistry:Overwrite` warning when a protocol name is
  re-registered
- Added: clear `ScapyML:Parser:InvalidArray` error for macro array sizes
- Performance: CSV loading of wide files (column-selective read, block-built
  packets, vectorized conversions)
- Added: `ScapyML.Crc` checksum library and README checksum examples
- Fixed: documentation examples used an invalid XOR formula
  (`xor(data(2:end))` needs two arguments); replaced by a bit-parity formula
- Fixed: anonymous `struct`/`union` blocks of the opposite kind to their parent
  (e.g. an anonymous bit-field struct inside a union next to a `uint8_t`) were
  flattened into the parent, so their members got the wrong overlap/offset
  semantics and the generated Lua placed them at shifted positions. They are
  now kept as nested blocks; the Lua bit-field masks are also computed
  union-aware (`WiresharkDissector.collectFieldsWithMeta`)
- Removed: per-field `-- [struct]/[union]/[array]/[bit-field]` comments from generated Lua
- Changed: the layout is now ALWAYS PACKED (wire-protocol layout, no alignment
  padding): `uint8, uint8, uint32` puts the `uint32` at byte 2 and the struct is 6 bytes.
  The C-ABI padding introduced in v2.3.1 is removed. All layout code (`ProtocolDef.recompute`,
  `getFieldOffsets`, `Codec`, Wireshark generator) goes through one function,
  `ProtocolDef.fieldAlignBytes`, which returns 1.
- Fixed: CSV columns of fields inside nested structs did not load unless the header was the exact
  internal name (`pos_x`). Headers may now be `pos_x`, `pos.x`, `Pos X` (case/punctuation ignored)
  or the bare C field name `x` when unique; an ambiguous bare name warns
  `ScapyML:CsvLoader:AmbiguousColumn` and is skipped
- Added: QA package (`qa/`: test plan, test specification, 16 automated suites)

**Files Modified (additions):** ScapyML_fromCSV.m (new), ScapyML_GUI.m,
CsvLoader.m, ConversionManager.m, Packet.m, Crc.m (new), README.md

### v2.3.1 — Critical Bit-Field & Alignment Fixes
**Changes (all discovered via matlab.unittest regression testing against this spec):**
- **CRITICAL:** Fixed bit-field encoding — `Codec.writeBits` previously used a
  non-standard LSB-reversal placement scheme for bit-fields that disagreed
  with `Codec.readBits` (decode), causing an internal encode/decode
  round-trip failure, and disagreed with `WiresharkDissector`'s mask
  formula, causing every auto-generated dissector to display wrong values
  for any bit-field. Bit-fields now use the same MSB-first placement as
  normal fields, matching `Codec`'s own documented design intent.
- Fixed field-placement / C ABI alignment inconsistency: `ProtocolDef.recompute()`
  computed alignment-padded `TotalBits`, but `Codec.encodeFields`,
  `Codec.decodeFields`, `ProtocolDef.getFieldOffsets`, and
  `WiresharkDissector.emitFieldList`/`collectFieldsWithMeta` placed fields
  without padding. All five now share a single `ProtocolDef.alignBitPos()`
  helper and are fully consistent.
- Fixed `ProtocolRegistry.clearInstance()`, which was a silent no-op
  (`clear('inst')` cleared the wrong workspace's variable). Now correctly
  delegates to `instance().clearAll()`.
- Added a `tests/` folder: 17 `matlab.unittest.TestCase` classes mapped to
  every FR/NFR in this document, plus `runAllTests.m`.

**Files Modified:** Codec.m, ProtocolDef.m, ProtocolRegistry.m,
WiresharkDissector.m, ScapyML_GUI.m (version string only)

**Note:** intermediate versions v2.1.2 through v2.3.0 (checksum
idempotency, CSV bulk-load vectorisation, UdpSender persistent socket,
enum parsing fixes, Wireshark naming model, C ABI alignment in
`recompute()`, etc.) are tracked in the project's change log but are not
individually detailed in this section, which predates them.

---

### v2.1.1 (March 25, 2026) - Bug Fix Release
**Changes:**
- Fixed ChecksumManager interface access in GUI
- GUI now uses checksumCount() and listChecksums() public methods
- No functional changes, interface correction only

**Files Modified:** ScapyML_GUI.m

---

### v2.1 (March 18, 2026) - MAT File Persistence
**New Features:**
- Save packets to MAT files (💾 Save to MAT button)
- Load packets from MAT files (📂 Load from MAT button)
- Full metadata tracking
- Protocol validation on load

**Performance:**
- 20x faster loading compared to CSV

**Files Modified:** ScapyML_GUI.m (+130 lines)

---

### v2.0 (March 18, 2026) - Checksums & Timing
**New Features:**
- GUI checksum support (🔢 Load Checksums File button)
- Precise timing control (tic/toc based)
- Timing error reporting
- Processing time compensation

**Bug Fixes:**
- Fixed periodic send infinite loop
- Fixed timing precision (700% error → 10% error)

**Files Modified:** ScapyML_GUI.m, PacketSender.m (+190 lines)

---

### v1.9 and Earlier
- Base framework implementation
- Protocol parsing
- Packet building
- CSV loading
- Wireshark dissectors
- Multi-protocol support
- Bitfield structures

---

## Appendix A: Design Decisions

### Why External Configuration Files?

**Decision:** Use .txt files for checksums, conversions, defaults instead of hardcoded values.

**Rationale:**
- Non-programmers can modify behavior
- No MATLAB recompilation
- Clear separation of concerns
- Easy to version control configurations separately

**Trade-offs:**
- More files to manage
- Runtime parsing overhead (minimal)
- Syntax errors possible in config files

**Conclusion:** Benefits outweigh costs. External configuration is core principle.

---

### Why Checksums Post-Encoding?

**Decision:** Calculate checksums on raw bytes after encoding, not on field values.

**Rationale:**
- Checksums depend on exact byte representation
- Endianness affects byte order
- Bitfield packing is complex
- Only encoded bytes are accurate

**Alternative Considered:** Calculate during encoding

**Rejection Reason:** Would require Codec to know about checksums, violating separation of concerns.

**Conclusion:** Post-encoding is architecturally correct.

---

### Why MAT Files for Persistence?

**Decision:** Use .mat files instead of CSV or custom format.

**Rationale:**
- MATLAB native format (fast save/load)
- Supports complex objects (Packet instances)
- Built-in compression
- Metadata support
- No custom parser needed

**Performance:** 20-40x faster than CSV

**Trade-off:** Binary format, not human-readable

**Conclusion:** Speed benefit justifies binary format. Keep CSV for data input.

---

## Appendix B: Glossary

**Artifact:** Output file or deliverable  
**Big-Endian:** Most significant byte first  
**Bitfield:** Field using partial byte (e.g., 3 bits)  
**Checksum:** Calculated value for error detection  
**Codec:** Encoder/decoder component  
**CSV:** Comma-Separated Values file  
**Endianness:** Byte order in multi-byte values  
**Little-Endian:** Least significant byte first  
**MAT File:** MATLAB binary data file  
**Protocol:** Structured definition of packet format  
**Registry:** Central storage for protocols  
**Scalar:** Single value (not array)  
**UDP:** User Datagram Protocol (network layer)  
**Wireshark:** Network protocol analyzer tool

---

**END OF REQUIREMENTS & FUNCTIONAL SPECIFICATION**
