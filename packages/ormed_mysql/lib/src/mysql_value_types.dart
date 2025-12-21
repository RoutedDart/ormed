import 'dart:typed_data';

import 'package:meta/meta.dart';

@immutable
class MySqlGeometry {
  MySqlGeometry(Uint8List bytes) : bytes = Uint8List.fromList(bytes);

  factory MySqlGeometry.fromHex(String hex) {
    final normalized = hex.trim().replaceAll(RegExp(r'^0x'), '');
    if (normalized.isEmpty) return MySqlGeometry(Uint8List(0));
    if (normalized.length.isOdd) {
      throw FormatException('Invalid hex string (odd length).');
    }
    final buffer = Uint8List(normalized.length ~/ 2);
    for (var i = 0; i < normalized.length; i += 2) {
      buffer[i ~/ 2] = int.parse(normalized.substring(i, i + 2), radix: 16);
    }
    return MySqlGeometry(buffer);
  }

  final Uint8List bytes;

  String toHex({bool prefix = false}) {
    final out = StringBuffer(prefix ? '0x' : '');
    for (final b in bytes) {
      out.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return out.toString();
  }

  @override
  String toString() => toHex(prefix: true);

  @override
  bool operator ==(Object other) =>
      other is MySqlGeometry && _bytesEqual(other.bytes, bytes);

  @override
  int get hashCode => Object.hashAll(bytes);
}

@immutable
class MySqlBitString {
  MySqlBitString(Uint8List bytes, {this.bitLength})
    : bytes = Uint8List.fromList(bytes);

  factory MySqlBitString.parse(String bits) {
    final normalized = bits.trim();
    if (normalized.isEmpty) {
      return MySqlBitString(Uint8List(0), bitLength: 0);
    }
    for (final unit in normalized.codeUnits) {
      if (unit != 0x30 && unit != 0x31) {
        throw FormatException('Invalid bit string "$bits".');
      }
    }

    final length = normalized.length;
    final byteLength = (length + 7) ~/ 8;
    final bytes = Uint8List(byteLength);
    for (var i = 0; i < length; i++) {
      if (normalized.codeUnitAt(i) != 0x31) continue;
      final byteIndex = i ~/ 8;
      final bitInByte = 7 - (i % 8);
      bytes[byteIndex] |= (1 << bitInByte);
    }
    return MySqlBitString(bytes, bitLength: length);
  }

  final Uint8List bytes;

  /// Optional bit length to preserve leading zeroes.
  final int? bitLength;

  String toBinaryString({int? length}) {
    final targetLength = length ?? bitLength ?? (bytes.length * 8);
    if (targetLength <= 0) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < targetLength; i++) {
      final byteIndex = i ~/ 8;
      final bitInByte = 7 - (i % 8);
      final bit = (bytes[byteIndex] >> bitInByte) & 1;
      buffer.write(bit == 1 ? '1' : '0');
    }
    return buffer.toString();
  }

  @override
  String toString() => toBinaryString();

  @override
  bool operator ==(Object other) =>
      other is MySqlBitString &&
      other.bitLength == bitLength &&
      _bytesEqual(other.bytes, bytes);

  @override
  int get hashCode => Object.hash(bitLength, Object.hashAll(bytes));
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (identical(a, b)) return true;
  if (a.lengthInBytes != b.lengthInBytes) return false;
  for (var i = 0; i < a.lengthInBytes; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
