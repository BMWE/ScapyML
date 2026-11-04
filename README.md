# ScapyML Framework - Complete Documentation

**Version:** 2.3.4  
**Date:** November 2026  
**Author:** ScapyML Development Team

---

## Quick Start

### Installation
1. Clone or download this repository
2. Add the repository folder (the one containing `ScapyML.m` and `+ScapyML/`) to the MATLAB path
3. Run `ScapyML_GUI` or use command-line interface

### Basic Example
```matlab
% Load protocol
ScapyML('load', 'protocol.h', 'big');

% Create packet
pkt = ScapyML.Packet('MyProtocol');
pkt.set('msg_id', 42);

% Send via UDP
ScapyML('send', pkt, '192.168.1.100', 5000);
```

### Using the GUI
```matlab
>> ScapyML_GUI
```

---

## Core Features

### 1. C Header Parsing

Parse C structs, unions, enums, bit-fields, arrays, and nested structures.

**Example protocol.h:**
```c
typedef enum {
    STATUS_IDLE = 0,
    STATUS_ACTIVE = 1
} Status;

typedef struct {
    uint8_t msg_id;
    uint16_t sequence;
    uint32_t timestamp;
    float temperature;
    uint8_t flags : 4;
    Status status;
    uint8_t data[10];
} SensorMessage;
```

**Load:**
```matlab
ScapyML('load', 'protocol.h', 'big');  % big-endian
```

### 2. Packet Manipulation

```matlab
% Create
pkt = ScapyML.Packet('SensorMessage');

% Set fields
pkt.set('msg_id', 42);
pkt.set('temperature', 23.5);
pkt.set('data', [1 2 3 4 5 6 7 8 9 10]);

% Get fields
value = pkt.get('msg_id');

% Encode/decode
binary = pkt.build();
pkt.parse(binary);
```

### 3. UDP Transmission

Three modes available:

```matlab
% Single send
ScapyML('send', pkt, '192.168.1.100', 5000);

% Periodic (1 second interval, Ctrl+C to stop)
ScapyML.PacketSender.sendWithTiming(pkts, '192.168.1.100', 5000, 'periodic', 1.0);

% CSV timestamp replay
timestamps = [0.0; 0.1; 0.2; 0.5; 1.0];
ScapyML.PacketSender.sendWithTiming(pkts, '192.168.1.100', 5000, 'csv', timestamps);
```

### 4. CSV Loading

```matlab
% Basic CSV loading
packets = ScapyML('fromCSV', 'SensorMessage', 'data.csv');

% With defaults
packets = ScapyML('fromCSV', 'SensorMessage', 'data.csv', 'defaults.txt');

% With physical-to-wire conversions
packets = ScapyML('fromCSV', 'SensorMessage', 'data.csv', 'defaults.txt', 'conversions.txt');
```

**Columns for fields inside nested structs.** A field of a nested struct is named
`<member>_<field>` (e.g. `pos_x` for `Pos pos;` with a member `x`). In the CSV
header you can write it as `pos_x`, `pos.x`, `Pos X` (case and punctuation are
ignored) or just the C field name `x` when that name occurs only once in the
protocol. If `x` exists in several structs (e.g. `Pos a; Pos b;`) the bare name
is ambiguous: it is skipped with warning `ScapyML:CsvLoader:AmbiguousColumn`, so
use `a_x` / `b_x`. Columns that match no field are ignored.

### 5. Wireshark Dissector Generation

```matlab
% Single protocol
ScapyML('dissector', 'SensorMessage', 'sensor.lua', 5000);

% Multi-protocol (use GUI for easy selection)
```

---

## Field Layout (always packed)

Fields are laid out back to back with **no alignment padding**, as in wire
protocols: `{ uint8_t a; uint8_t b; uint32_t c; }` puts `a` at byte 0, `b` at
byte 1 and `c` at byte 2, and the struct is 6 bytes. A struct's size is the sum
of its members; a union's size is its largest member. Encoding, decoding, field
offsets and the generated Wireshark Lua file all use this layout.

---

## Physical-to-Wire Conversion System

### Problem

Many protocol fields encode physical values with scaling/offset:
- Azimuth: 0-359.995° → 0-65535 (16-bit)
- Temperature: -40 to +85°C with 0.1° resolution
- Pressure: 300-1100 hPa scaled to 16-bit

### Solution

Define conversions in external text file:

**conversions.txt:**
```matlab
# Azimuth: 0-360° → 0-65535 (16-bit)
# Formula: wire = physical / 360 * 2^16
# Example: 60° → 10922
azimuth = @(x) round(x / 360 * 65536)

# Elevation: -90 to +90° → 0-65535
elevation = @(x) round((x + 90) / 180 * 65536)

# Temperature: -40 to +85°C → 0-1250 (0.1° resolution)
temperature = @(x) round((x + 40) * 10)

# Pressure: 300-1100 hPa → 0-65535
pressure = @(x) round((x - 300) / 800 * 65536)

# Battery: 0-100% → 0-255 (8-bit)
battery = @(x) round(x * 255 / 100)

# Direct (no conversion)
status = @(x) x
```

### Usage

**Command Line:**
```matlab
% Load protocol
ScapyML('load', 'sensor.h', 'big');

% CSV with physical values
% data.csv:
%   azimuth, elevation, temperature
%   60.0, 45.0, 25.5
%   120.5, -30.0, 22.0

% Load with conversions
packets = ScapyML('fromCSV', 'SensorData', 'data.csv', '', 'conversions.txt');

% Verify conversion applied
packets{1}.get('azimuth')     % Returns 10922 (not 60.0)
packets{1}.get('elevation')   % Returns 49152 (not 45.0)
packets{1}.get('temperature') % Returns 655 (not 25.5)
```

**GUI:**
1. Load protocol
2. Click "🔄 Load Conversion File" → select conversions.txt
3. Click "📊 Load from CSV" → select data.csv
4. Conversions applied automatically!

### Common Patterns

**1. Scaled Range:**
```matlab
% Pressure: 300-1100 hPa → 0-65535
pressure = @(x) round((x - 300) / 800 * 65535)
```

**2. Signed to Unsigned:**
```matlab
% Elevation: -90 to +90° → 0-65535
elevation = @(x) round((x + 90) / 180 * 65535)
```

**3. Circular (0-360°):**
```matlab
% Azimuth: 0-360° → 0-65536
azimuth = @(x) round(x / 360 * 65536)
```

**4. Fixed-Point:**
```matlab
% Temperature with 0.1° LSB
temperature = @(x) round(x / 0.1)
```

**5. Percentage:**
```matlab
% Battery: 0-100% → 0-255
battery = @(x) round(x * 255 / 100)
```

**6. Clamping:**
```matlab
% With min/max limits
speed = @(x) min(max(round(x * 10), 0), 65535)
```

### Azimuth Example (Your Specification)

**Specification:**
- Physical: 0 to 359.995 degrees
- Wire: 16-bit (0 to 65535)
- LSB = 360° / 2^16 = 0.005493°

**Conversion:**
```matlab
azimuth = @(x) round(x / 360 * 65536)
```

**Verification:**
| Physical | Wire  | Back-Calc |
|----------|-------|-----------|
| 60.0°    | 10922 | 59.9976°  |
| 180.0°   | 32768 | 180.0000° |
| 300.0°   | 54613 | 299.9927° |

**Test:**
```matlab
>> cm = ScapyML.ConversionManager('conversions.txt');
>> cm.convert('azimuth', 60.0)
ans = 10922
```

### Standalone Deployment

Conversion file is external - users edit in text editor:

```
standalone_app/
  ├── ScapyML.exe
  ├── conversions_example.txt  ← Template
  └── user_files/
      └── my_conversions.txt   ← User edits
```

**No recompilation needed!**

---

## Checksum Calculation

Checksums are computed from the **encoded bytes** and written back into a
field of the packet, so they are always consistent with the other fields.

**checksums.txt** — `fieldName = @(data) expression`, where `fieldName` is the
packet field that receives the result and `data` is the packet as a `uint8`
array. The expression must return a scalar number.

```
checksum = @(data) mod(sum(uint16(data)), 256)
```

**Example: calculate, then update after a field changes**

```matlab
% sensor.h:  typedef struct SensorMsg {
%              uint8_t msg_id; uint8_t sensor_id; uint8_t value; uint8_t checksum;
%            } SensorMsg;
ScapyML('load', 'sensor.h', 'big');
cm  = ScapyML.ChecksumManager('checksums.txt');

pkt = ScapyML.Packet('SensorMsg');
pkt.set('msg_id', 42);
pkt.set('sensor_id', 7);
pkt.set('value', 100);

bytes = pkt.buildWithChecksums(cm);   % checksum = mod(42+7+100, 256) = 149
bytes(4)                              % -> 149

% Change a field and rebuild: the checksum is recalculated automatically
pkt.set('value', 200);
bytes = pkt.buildWithChecksums(cm);   % checksum = mod(42+7+200, 256) = 249
bytes(4)                              % -> 249

% Verify a received packet
rx = ScapyML.Packet.fromBytes('SensorMsg', bytes);
rx.get('checksum')                    % -> 249
```

**Rules**
- Use `pkt.buildWithChecksums(cm)`; plain `pkt.build()` does not apply checksums,
  so the checksum field is sent as set (0 by default).
- The checksum field is zeroed before each calculation, so rebuilding always
  gives the same result and the old value is never included in the sum.
- With several checksums, they are calculated in order of byte offset; a later
  checksum can therefore cover an earlier one.
- A name in the file that is not a field of the protocol gives the warning
  `ScapyML:ChecksumManager:FieldNotFound`; a missing file gives
  `ScapyML:ChecksumManager:FileNotFound` and an empty manager.
- More formulas are in `checksums_example.txt` and in the examples below.
- In the GUI use **Load Checksums File** before generating packets.

---

### Popular checksum examples

Copy the lines you need into `checksums.txt`. The name on the left must be the
packet field that stores the result. Inside the formula, `data` is the whole
packet with that field zeroed.

**Simple sums and XOR** (one-liners; `double(...)` avoids integer overflow):

```
# 8-bit sum
checksum = @(data) mod(sum(double(data)), 256)

# 8-bit two's complement (sum of all bytes incl. checksum == 0 mod 256)
checksum = @(data) mod(-sum(double(data)), 256)

# XOR of all bytes (LRC) - parity of each bit position
checksum = @(data) sum(arrayfun(@(k) mod(sum(bitget(data, k)), 2) * 2^(k-1), 1:8))
```

**CRCs and standard checksums** (ready-made in `ScapyML.Crc`):

| Name | Field size | Formula in `checksums.txt` |
|---|---|---|
| CRC-8 (poly 0x07) | 1 byte | `crc = @(data) ScapyML.Crc.crc8(data)` |
| CRC-16/CCITT-FALSE | 2 bytes | `crc = @(data) ScapyML.Crc.crc16ccitt(data)` |
| CRC-16/MODBUS | 2 bytes | `crc = @(data) ScapyML.Crc.crc16modbus(data)` |
| CRC-32 (Ethernet/zip) | 4 bytes | `crc = @(data) ScapyML.Crc.crc32(data)` |
| Internet checksum (RFC 1071, IP/UDP/TCP style) | 2 bytes | `checksum = @(data) ScapyML.Crc.internetChecksum(data)` |
| Fletcher-16 | 2 bytes | `checksum = @(data) ScapyML.Crc.fletcher16(data)` |

Check values for the ASCII text `123456789`: CRC-8 `0xF4`, CRC-16/CCITT-FALSE
`0x29B1`, CRC-16/MODBUS `0x4B37`, CRC-32 `0xCBF43926`, Fletcher-16 `0x1EDE`.
These are the published standard values, so you can verify with
`dec2hex(ScapyML.Crc.crc32(uint8('123456789')))`.

**Covering only part of the packet:**

```
# CRC-16 stored in the LAST 2 bytes, covering everything before it
crc = @(data) ScapyML.Crc.crc16ccitt(data(1:end-2))

# Checksum over the header only (first 8 bytes)
hdr_sum = @(data) mod(sum(double(data(1:8))), 256)

# Skip a 4-byte preamble, checksum the rest
checksum = @(data) mod(sum(double(data(5:end))), 256)
```

**Two checksums in one packet** (e.g. a header CRC and a payload CRC) - give
each its own line; they are applied in byte-offset order:

```
hdr_crc     = @(data) ScapyML.Crc.crc16ccitt(data(1:6))
payload_crc = @(data) ScapyML.Crc.crc32(data(9:end-4))
```

Notes: the result is written big- or little-endian according to the protocol's
endianness and truncated to the field size (1, 2, 4 or 8 bytes), so choose the
field width that matches the algorithm (e.g. a `uint16_t` field for CRC-16).
Formulas must return a non-negative number (use `mod(..., 2^bits)`). Custom
checksums that need loops can be written as an ordinary `.m` function on the
MATLAB path and called from the formula, like `ScapyML.Crc` is.

---

## GUI Guide

### Main Interface

```
┌─────────────────────────────────────┐
│ ═══ LOAD HEADERS ═══                │
│ [📂 Load Single Header]             │
│ [📚 Load Multiple Headers]          │
│                                      │
│ ═══ SELECT PROTOCOL ═══             │
│ [Dropdown ▼]                        │
│ [ℹ️ Show Protocol Info]             │
│                                      │
│ ═══ PACKET OPERATIONS ═══           │
│ [📦 Create Packet]                  │
│ [✏️ Edit Packet Fields]             │
│ [👁️ Show Packet]                    │
│ [🔢 Hex Dump]                       │
│                                      │
│ ═══ FILE OPERATIONS ═══             │
│ [📝 Create Defaults File]           │
│ [🔄 Load Conversion File]           │
│ [📊 Load from CSV]                  │
│                                      │
│ ═══ ACTIONS ═══                     │
│ [📡 Send Packet(s)]                 │
│ [🦈 Create Wireshark Dissector]    │
└─────────────────────────────────────┘
```

### Typical Workflow

1. Load Protocol: Click "📂" → select .h file
2. Explore: Click "ℹ️" to see fields/offsets
3. Create Packet: Click "📦"
4. Edit Fields: Click "✏️" → set values
5. Send: Click "📡" → enter IP/port

---

## API Reference

### Main Commands

```matlab
% Load header
ScapyML('load', 'file.h', 'big|little')

% Create packet
pkt = ScapyML.Packet('ProtocolName')

% Send packet
ScapyML('send', pkt, ip, port)

% Load from CSV
pkts = ScapyML('fromCSV', protocol, csv)
pkts = ScapyML('fromCSV', protocol, csv, defaults)
pkts = ScapyML('fromCSV', protocol, csv, defaults, conversions)

% Generate dissector
ScapyML('dissector', protocol, 'out.lua', port)

% List protocols
names = ScapyML('list')
```

### Packet Class

```matlab
pkt.set(field, value)      % Set field
value = pkt.get(field)     % Get field
binary = pkt.build()       % Encode
pkt.parse(binary)          % Decode
names = pkt.fieldNames()   % List fields
```

### ConversionManager

```matlab
cm = ScapyML.ConversionManager('file.txt')
wire = cm.convert(field, physical)
hasConv = cm.hasConversion(field)
names = cm.listConversions()
count = cm.conversionCount()
```

### ProtocolDef

```matlab
proto = reg.get('ProtocolName')
bytes = proto.totalBytes()
offsets = proto.getFieldOffsets()
```

---

## Testing

This release contains the source only; the automated test suites are not
included. Tests use `matlab.unittest` and are run with `runtests` / `runAllTests`
from the folder that contains the `tests/` directory. Note: the fixes in v2.3.4
have been verified by static review only and still need a live MATLAB test run.

---

## Troubleshooting

### Header won't load
- Check C syntax (use typedef)
- Remove C++ features
- Verify file is accessible

### Size mismatch
```matlab
proto = reg.get('MyProtocol');
offsets = proto.getFieldOffsets();
for i = 1:numel(offsets)
    fprintf('%s: byte %d\n', offsets{i}.name, offsets{i}.byteOffset);
end
```

### Conversion not applied
```matlab
cm = ScapyML.ConversionManager('conversions.txt');
cm.listConversions()  % Check loaded
cm.convert('field', testValue)  % Test manually
```

### UDP not sending
- Test with localhost: '127.0.0.1'
- Check firewall
- Verify port not in use
- Use Wireshark to confirm

---

## Examples Included

- `conversions_example.txt` - Physical-to-wire conversion templates
- `checksums_example.txt` - Checksum definitions

---

## File Structure

```
ScapyML/
├── README.md                    ← This file
├── REQUIREMENTS.md              ← Requirements and full change history
├── ScapyML.m                    ← Main command-line interface
├── ScapyML_GUI.m                ← GUI
├── ScapyML_fromCSV.m            ← CSV loader (defaults + conversions)
├── conversions_example.txt      ← Conversion templates
├── checksums_example.txt        ← Checksum templates
└── +ScapyML/                    ← Core classes
    ├── HeaderParser.m, DependencyResolver.m, NameShortener.m
    ├── ProtocolRegistry.m, ProtocolDef.m, FieldDef.m, EnumDef.m
    ├── Packet.m, Codec.m
    ├── DefaultsManager.m, ConversionManager.m, ChecksumManager.m
    ├── CsvLoader.m
    ├── PacketSender.m, UdpSender.m
    └── WiresharkDissector.m, MultiProtocolDissector.m, DiscriminatorConfig.m
```

---

## Version History

**v2.3.4 (November 2026)**
- ✅ Fixed: `ScapyML('fromCSV', ...)` was unreachable (the `csv` case shadowed it); now works with defaults and conversion files
- ✅ Fixed: GUI "Load from CSV" and the multi-protocol discriminator dialog called non-existent functions/methods; GUI local variable `size` shadowed the builtin
- ✅ Fixed: CSV columns of fields inside nested structs (`pos_x`, `pos.x`, `Pos X` or bare `x`)
- ✅ Fixed: anonymous struct/union blocks of the opposite kind were flattened, shifting union layouts in the Lua output
- ✅ Changed: field layout is always packed (no alignment padding)
- ✅ Added: `ScapyML.Crc` (CRC-8/16/32, Internet checksum, Fletcher-16) and checksum examples
- ✅ Added: GUI scroll bar on the Controls panel; CSV loading speed-up for wide files
- ✅ Added: `ScapyML:ProtocolRegistry:Overwrite` warning; clear `ScapyML:Parser:InvalidArray` error for `#define` array sizes
- ✅ Removed: per-field struct/union/array/bit-field comments from generated Lua
- ⚠ Not fixed: `BitFieldGrouper` and `DiscriminatorConfig.fromGUI()` are unused (dead code)

**v2.3.3 (October 2026)**
- ✅ Cross-file type resolution: files are parsed/registered in order; enum-only headers are dependency sources; unresolved types raise `ScapyML:HeaderParser:UnresolvedType`
- ⚠ Known limitation: a type is resolved only if its defining file was parsed earlier in the same `load` call (or `'auto'` ordering is used)

**v1.2 (March 2026)**
- ✅ Physical-to-wire conversion system
- ✅ Fixed byte offset calculation
- ✅ Comprehensive test suite (19 tests)
- ✅ Enhanced GUI

**v1.1 (March 2026)**
- ✅ Multi-protocol Wireshark dissectors
- ✅ Bit-field grouping
- ✅ Multi-file header support

**v1.0 (February 2026)**
- ✅ Initial release

---

## License

MIT License

---

**For detailed documentation on all features, see sections above.**

**Quick Reference:**
- Quick Start → Basic usage
- Physical-to-Wire Conversion → conversions.txt format
- GUI Guide → Button functions
- API Reference → Function signatures

**End of README**
