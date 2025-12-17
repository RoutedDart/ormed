import 'dart:io';
import 'dart:typed_data';

import 'package:postgres/postgres.dart';

TypeRegistry createOrmedPostgresTypeRegistry() {
  return TypeRegistry(
    codecs: {
      _PostgresTypeOid.cidr: _CidrCodec(),
      _PostgresTypeOid.inet: _InetCodec(),
      _PostgresTypeOid.macaddr: _MacaddrCodec(),
      _PostgresTypeOid.macaddr8: _Macaddr8Codec(),
    },
  );
}

abstract final class _PostgresTypeOid {
  static const cidr = 650;
  static const inet = 869;
  static const macaddr = 829;
  static const macaddr8 = 774;
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
