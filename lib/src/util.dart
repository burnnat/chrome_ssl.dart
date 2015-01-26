library chrome_ssl.util;

import 'dart:typed_data' as typed;

import 'package:chrome/chrome_app.dart' as chrome;
import 'package:forge/forge.dart' as forge;

String stringFromBytes(typed.ByteBuffer buffer) {
  return new forge.ByteBuffer.fromBuffer(buffer).getBytes();
}

chrome.ArrayBuffer arrayFromBuffer(forge.ByteBuffer buffer) {
  return new chrome.ArrayBuffer.fromString(buffer.getBytes());
}

String expand(dynamic message) =>
  message is Function
    ? message()
    : message;
