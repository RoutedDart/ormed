import 'dart:io';
import 'dart:typed_data';

import 'package:postgres/postgres.dart';

import 'postgres_value_types.dart';

TypeRegistry createOrmedPostgresTypeRegistry() {
  return TypeRegistry(
    codecs: {
      _PostgresTypeOid.cidr: _CidrCodec(),
      _PostgresTypeOid.inet: _InetCodec(),
      _PostgresTypeOid.macaddr: _MacaddrCodec(),
      _PostgresTypeOid.macaddr8: _Macaddr8Codec(),
      _PostgresTypeOid.bit: _BitStringCodec(),
      _PostgresTypeOid.varbit: _BitStringCodec(),
      _PostgresTypeOid.money: _MoneyCodec(),
      _PostgresTypeOid.xml: _XmlCodec(),
      _PostgresTypeOid.timetz: _TimeTzCodec(),
      _PostgresTypeOid.pgLsn: _PgLsnCodec(),
      _PostgresTypeOid.pgSnapshot: _SnapshotCodec(),
      _PostgresTypeOid.txidSnapshot: _SnapshotCodec(),
    },
  );
}

abstract final class _PostgresTypeOid {
  static const cidr = 650;
  static const inet = 869;
  static const macaddr = 829;
  static const macaddr8 = 774;
  static const xml = 142;
  static const money = 790;
  static const timetz = 1266;
  static const bit = 1560;
  static const varbit = 1562;
  static const pgLsn = 3220;
  static const txidSnapshot = 2970;
  static const pgSnapshot = 5038;
}

final class _InetCodec extends Codec {
  _InetCodec();

  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) return null;
    final encoded = context.encoding.encode(value.toString());
    return EncodedValue.text(
      Uint8List.fromList(encoded),
      typeOid: input.type.oid,
    );
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) return null;
    if (input.isText) {
      return context.encoding.decode(bytes);
    }
    return _decodeInetOrCidr(bytes, isCidr: false);
  }
}

final class _CidrCodec extends Codec {
  _CidrCodec();

  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) return null;
    final encoded = context.encoding.encode(value.toString());
    return EncodedValue.text(
      Uint8List.fromList(encoded),
      typeOid: input.type.oid,
    );
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) return null;
    if (input.isText) {
      return context.encoding.decode(bytes);
    }
    return _decodeInetOrCidr(bytes, isCidr: true);
  }
}

String _decodeInetOrCidr(Uint8List bytes, {required bool isCidr}) {
  if (bytes.length < 4) {
    throw FormatException('Invalid inet/cidr binary value.');
  }

  final family = bytes[0];
  final bits = bytes[1];
  final addrLen = bytes[3];
  final addrBytes = bytes.sublist(4);

  final (maxBits, fullLength) = switch (family) {
    2 => (32, 4), // IPv4
    3 => (128, 16), // IPv6
    _ => throw FormatException('Unknown inet/cidr family $family.'),
  };

  if (addrLen > addrBytes.length || addrLen > fullLength) {
    throw FormatException('Invalid inet/cidr address length.');
  }

  final padded = Uint8List(fullLength);
  padded.setAll(0, addrBytes.take(addrLen));

  final address = InternetAddress.fromRawAddress(padded).address;
  final includeMask = isCidr || bits != maxBits;
  return includeMask ? '$address/$bits' : address;
}

final class _MacaddrCodec extends Codec {
  _MacaddrCodec();

  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) return null;
    final encoded = context.encoding.encode(value.toString());
    return EncodedValue.text(
      Uint8List.fromList(encoded),
      typeOid: input.type.oid,
    );
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) return null;
    if (input.isText) {
      return context.encoding.decode(bytes);
    }
    return _formatMac(bytes, expectedLength: 6);
  }
}

final class _Macaddr8Codec extends Codec {
  _Macaddr8Codec();

  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) return null;
    final encoded = context.encoding.encode(value.toString());
    return EncodedValue.text(
      Uint8List.fromList(encoded),
      typeOid: input.type.oid,
    );
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) return null;
    if (input.isText) {
      return context.encoding.decode(bytes);
    }
    return _formatMac(bytes, expectedLength: 8);
  }
}

String _formatMac(Uint8List bytes, {required int expectedLength}) {
  if (bytes.length != expectedLength) {
    throw FormatException('Invalid macaddr binary value.');
  }
  final parts = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .toList(growable: false);
  return parts.join(':');
}

final class _BitStringCodec extends Codec {
  _BitStringCodec();

  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) return null;
    final encoded = context.encoding.encode(value.toString());
    return EncodedValue.text(
      Uint8List.fromList(encoded),
      typeOid: input.type.oid,
    );
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) return null;
    if (input.isText) {
      return PgBitString.parse(context.encoding.decode(bytes));
    }

    if (bytes.length < 4) {
      throw FormatException('Invalid bit/varbit binary value.');
    }
    final bd = ByteData.sublistView(bytes);
    final bitLength = bd.getInt32(0);
    if (bitLength < 0) {
      throw FormatException('Invalid bit/varbit length.');
    }

    final byteLength = (bitLength + 7) ~/ 8;
    if (bytes.length < 4 + byteLength) {
      throw FormatException('Invalid bit/varbit payload length.');
    }
    final payload = bytes.sublist(4, 4 + byteLength);

    final result = Uint8List(bitLength);
    for (var i = 0; i < bitLength; i++) {
      final byteIndex = i ~/ 8;
      final bitIndex = 7 - (i % 8);
      final value = (payload[byteIndex] >> bitIndex) & 0x01;
      result[i] = value == 1 ? 0x31 : 0x30;
    }

    return PgBitString(String.fromCharCodes(result));
  }
}

final class _MoneyCodec extends Codec {
  _MoneyCodec();

  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) return null;
    final encoded = context.encoding.encode(value.toString());
    return EncodedValue.text(
      Uint8List.fromList(encoded),
      typeOid: input.type.oid,
    );
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) return null;
    if (input.isText) {
      return PgMoney.parse(context.encoding.decode(bytes));
    }
    if (bytes.length != 8) {
      throw FormatException('Invalid money binary value.');
    }
    final bd = ByteData.sublistView(bytes);
    return PgMoney.fromCents(bd.getInt64(0));
  }
}

final class _XmlCodec extends Codec {
  _XmlCodec();

  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) return null;
    final encoded = context.encoding.encode(value.toString());
    return EncodedValue.text(
      Uint8List.fromList(encoded),
      typeOid: input.type.oid,
    );
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) return null;
    return context.encoding.decode(bytes);
  }
}

final class _TimeTzCodec extends Codec {
  _TimeTzCodec();

  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) return null;
    final encoded = context.encoding.encode(value.toString());
    return EncodedValue.text(
      Uint8List.fromList(encoded),
      typeOid: input.type.oid,
    );
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) return null;
    if (input.isText) {
      return PgTimeTz.parse(context.encoding.decode(bytes));
    }
    if (bytes.length != 12) {
      throw FormatException('Invalid timetz binary value.');
    }
    final bd = ByteData.sublistView(bytes);
    final microseconds = bd.getInt64(0);
    final rawOffsetSeconds = bd.getInt32(8);
    return PgTimeTz(
      time: Time.fromMicroseconds(microseconds),
      offset: Duration(seconds: -rawOffsetSeconds),
    );
  }
}

final class _PgLsnCodec extends Codec {
  _PgLsnCodec();

  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) return null;
    final encoded = context.encoding.encode(value.toString());
    return EncodedValue.text(
      Uint8List.fromList(encoded),
      typeOid: input.type.oid,
    );
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) return null;
    if (input.isText) {
      return context.encoding.decode(bytes);
    }
    if (bytes.length != 8) {
      throw FormatException('Invalid pg_lsn binary value.');
    }
    final bd = ByteData.sublistView(bytes);
    return LSN(bd.getUint64(0)).toString();
  }
}

final class _SnapshotCodec extends Codec {
  _SnapshotCodec();

  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) return null;
    final encoded = context.encoding.encode(value.toString());
    return EncodedValue.text(
      Uint8List.fromList(encoded),
      typeOid: input.type.oid,
    );
  }

  @override
  Object? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) return null;
    if (input.isText) {
      return PgSnapshot.parse(context.encoding.decode(bytes));
    }
    if (bytes.length < 20) {
      throw FormatException('Invalid snapshot binary value.');
    }

    final bd = ByteData.sublistView(bytes);
    final count = bd.getInt32(0);
    final xmin = bd.getUint64(4);
    final xmax = bd.getUint64(12);
    if (count < 0) {
      throw FormatException('Invalid snapshot count.');
    }
    final expectedLength = 20 + count * 8;
    if (bytes.length != expectedLength) {
      throw FormatException('Invalid snapshot payload length.');
    }

    final xip = <int>[];
    for (var i = 0; i < count; i++) {
      xip.add(bd.getUint64(20 + i * 8));
    }

    return PgSnapshot(xmin: xmin, xmax: xmax, xip: xip);
  }
}
