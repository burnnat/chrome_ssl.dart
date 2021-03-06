library chrome_ssl.socket;

import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:forge/forge.dart' as forge;

import 'util.dart';

final Logger logger = new Logger('chrome_ssl.socket');

abstract class SslSocket implements forge.TlsHandler {
  int _socketId;
  forge.TlsConnection _tls;

  final List<StreamController> _streams;
  final List<StreamSubscription> _subscriptions;

  StreamController _connectStream;
  Stream get onConnect => _connectStream.stream;

  StreamController _dataStream;
  Stream get onData => _dataStream.stream;

  StreamController _drainStream;
  Stream get onDrain => _drainStream.stream;

  StreamController _makeController() {
    StreamController controller = new StreamController();
    _streams.add(controller);
    return controller;
  }

  SslSocket() :
      _streams = [],
      _subscriptions = [] {

    _connectStream = _makeController();
    _dataStream = _makeController();
    _drainStream = _makeController();
  }

  void _active() {
    // reset timeout ...
  }

  void connect(String host, int port) {
    _active();

    _log(() => 'Connecting to host $host on port $port');

    chrome.sockets.tcp.create()
      .then((info) {
        _socketId = info.socketId;

        if (_socketId > 0) {
          _log(() => 'Opened socket with ID: $_socketId');

          chrome.sockets.tcp.setPaused(_socketId, true);
          chrome.sockets.tcp.connect(_socketId, host, port)
            .then(_onConnect);
        }
        else {
          _emitError('Unable to create socket');
        }
      });
  }

  void _onConnect(int status) {
    if (status < 0) {
      _emitChromeError('Unable to connect to socket', status);
      return;
    }

    _log('Connection succeeded');
    _initializeTls();

    _log('Starting TLS handshake');
    _tls.handshake(null);

    _subscriptions.add(
      chrome.sockets.tcp.onReceive.listen(this._onReceive)
    );
    _subscriptions.add(
      chrome.sockets.tcp.onReceiveError.listen(this._onReceiveError)
    );
    chrome.sockets.tcp.setPaused(_socketId, false);
  }

  void _emit(StreamController controller, [dynamic value]) {
    if (!controller.isPaused && !controller.isClosed) {
      controller.add(value);
    }
  }

  void _emitChromeError(dynamic message, int code) {
    if (!logger.isLoggable(Level.SEVERE)) {
      return;
    }

    String chromeMessage;

    if (chrome.runtime.lastError != null) {
      chromeMessage = chrome.runtime.lastError.message;
    }

    _emitError('${expand(message)}: ${chromeMessage} (error ${-code})');
  }

  void _emitError(dynamic message) {
    logger.severe(() => 'Error: ${expand(message)}');
  }

  void _log(dynamic message, [Level level=Level.FINE]) {
    logger.log(
      level,
      () =>
        _socketId != null
          ? '[$_socketId] ${expand(message)}'
          : expand(message)
    );
  }

  void _initializeTls() {
    _log('Initializing TLS connection');
    _tls = forge.tls.createConnection(this);
  }

  void close() {
    if (_tls != null) {
      _log('Closing TLS connection');
      _tls.close();
    }
  }

  void _close() {
    if (_socketId != null) {
      _subscriptions
        ..forEach((subscription) {
          subscription.cancel();
        })
        ..clear();

      chrome.sockets.tcp
        ..disconnect(_socketId)
        ..close(_socketId);

      _socketId = null;
    }

    _streams.forEach((controller) {
      controller.close();
    });
  }

  void write(ByteBuffer buffer) {
    _tls.prepare(stringFromBytes(new Uint8List.view(buffer)));
  }

  void _onReceive(chrome.ReceiveInfo info) {
    if (info.socketId != _socketId) {
      return;
    }

    _active();

    if (!_tls.open) {
      _emitError('Received data but TLS connection is no longer open');
      return;
    }

    List<int> bytes = info.data.getBytes();
    _log(() => 'Received ${bytes.length} bytes of data', Level.FINEST);

    _tls.process(
      stringFromBytes(
        new Uint8List.fromList(bytes)
      )
    );
  }

  void _onReceiveError(chrome.ReceiveErrorInfo info) {
    if (info.socketId != _socketId) {
      return;
    }

    _active();

    if (info.resultCode == -100) {
      _log('Connection terminated by server');
    }
    else {
      _emitChromeError('Read from socket', info.resultCode);
    }

    _close();
  }

  bool verify(
    forge.TlsConnection connection,
    bool verified,
    int depth,
    List<forge.Certificate> chain
  ) => true;

  void heartbeatReceived(
    forge.TlsConnection connection,
    forge.ByteBuffer payload
  ) {}

  void connected(forge.TlsConnection connection) {
    _log('Handshake successful');
    _emit(_connectStream);
  }

  void tlsDataReady(forge.TlsConnection connection) {
    forge.ByteBuffer data = connection.tlsData;
    final int total = data.length();

    _log(() => 'Sending $total bytes of data', Level.FINEST);

    chrome.ArrayBuffer buffer = arrayFromBuffer(data);

    chrome.sockets.tcp.send(
        _socketId,
        buffer
      )
      .then((info) {
        int resultCode = info.resultCode;

        if (resultCode < 0) {
          _emitChromeError('Socket error on write', resultCode);
        }

        int sent = info.bytesSent;

        if (sent == total) {
          _log(() => 'Send complete', Level.FINEST);
          _emit(_drainStream);
        }
        else {
          if (sent > 0) {
            _emitError(() => 'Incomplete write: wrote $sent of $total bytes');
          }

          _emitError(() => 'Invalid write on socket: code $resultCode');
        }
      });
  }

  void dataReady(forge.TlsConnection connection) {
    _log(() => 'Parsed ${connection.data.length()} bytes of data');
    _emit(_dataStream, arrayFromBuffer(connection.data));
  }

  void closed(forge.TlsConnection connection) {
    _close();
  }

  void error(forge.TlsConnection connection, forge.TlsError error) {
    _emitError('TLS error: ${error.message}');
    _close();
  }
}
