library chrome_ssl.util;

import 'dart:typed_data';

import 'package:chrome/chrome_app.dart' as chrome;
import 'package:forge/forge.dart' as forge;

String fromBuffer(ByteBuffer buffer) {
  Uint16List data = new Uint16List.view(buffer);
  return new String.fromCharCodes(data.toList());
}

chrome.ArrayBuffer fromString(forge.ByteBuffer buffer) {
  return new chrome.ArrayBuffer.fromString(buffer.getBytes());
}

String expand(dynamic message) =>
  message is Function
    ? message()
    : message;
