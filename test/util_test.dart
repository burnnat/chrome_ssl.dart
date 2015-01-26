library chrome_ssl.util_test;

import 'dart:typed_data';

import 'package:chrome/chrome_app.dart' as chrome;
import 'package:chrome_ssl/src/util.dart' as util;
import 'package:forge/forge.dart' as forge;
import 'package:unittest/unittest.dart';

void runTests() {
  group('Utilities', () {
    List<int> raw = [
      0x70, 0xca, 0x0f, 0x7a, 0xcb, 0xa1, 0x06, 0x6e, 0x71
    ];

    ByteBuffer buffer;

    setUp(() {
      buffer = new Uint8List.fromList(raw).buffer;
    });

    test('convert to ArrayBuffer', () {
      chrome.ArrayBuffer chromeBuffer = util.arrayFromBuffer(new forge.ByteBuffer.fromBuffer(buffer));
      expect(chromeBuffer.getBytes(), orderedEquals(raw));
    });
  });
}
