import 'package:dartssh2/dartssh2.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SSHController {
  SSHClient? _client;
  String? _lastError;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String? get lastError => _lastError;

  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      _isConnected = false;
      _lastError = null;

      try {
        final socket = await SSHSocket.connect(host, port).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Connection timeout');
          },
        );

        _client = SSHClient(
          socket,
          username: username,
          onPasswordRequest: () => password,
        );

        _isConnected = true;
        return true;
      } catch (e) {
        _lastError = 'Connection failed: $e';
        return false;
      }
    } on TimeoutException catch (e) {
      _isConnected = false;
      _lastError = _getErrorMessage('timeout', e.toString());
      return false;
    } on SocketException catch (e) {
      _isConnected = false;
      final errorMsg = e.message.toLowerCase();

      if (errorMsg.contains('refused') || errorMsg.contains('reset')) {
        _lastError = _getErrorMessage('refused', e.toString());
      } else if (errorMsg.contains('host') || errorMsg.contains('nodename')) {
        _lastError = _getErrorMessage('host', e.toString());
      } else {
        _lastError = _getErrorMessage('socket', e.toString());
      }

      return false;
    } catch (e) {
      _isConnected = false;
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('auth') || errorStr.contains('denied') || errorStr.contains('invalid')) {
        _lastError = _getErrorMessage('auth', e.toString());
      } else if (errorStr.contains('timeout')) {
        _lastError = _getErrorMessage('timeout', e.toString());
      } else if (errorStr.contains('refused')) {
        _lastError = _getErrorMessage('refused', e.toString());
      } else {
        _lastError = _getErrorMessage('unknown', e.toString());
      }

      if (kDebugMode) {
        print('Connection error: $_lastError');
      }
      return false;
    }
  }

  Future<String> executeCommand(String command) async {
    if (!isConnected || _client == null) {
      throw Exception('Not connected to SSH server');
    }

    try {
      if (kDebugMode) {
        print('Executing command: $command');
      }

      final result = await _client!.run(command);
      final output = String.fromCharCodes(result);

      if (kDebugMode) {
        print('Command output: $output');
      }

      return output;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> uploadFile(String localPath, String remotePath) async {
    if (!isConnected || _client == null) {
      throw Exception('Not connected to SSH server');
    }

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Local file does not exist: $localPath');
      }

      final fileBytes = await file.readAsBytes();
      final sftp = await _client!.sftp();
      final remoteFile = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );
      await remoteFile.writeBytes(fileBytes);
      await remoteFile.close();

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> uploadAsset(String assetPath, String remotePath) async {
    if (!isConnected || _client == null) {
      throw Exception('Not connected to SSH server');
    }

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final fileBytes = data.buffer.asUint8List();

      final sftp = await _client!.sftp();
      final remoteFile = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );
      await remoteFile.writeBytes(fileBytes);
      await remoteFile.close();

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> uploadString(String content, String remotePath) async {
    if (_client == null) {
      throw Exception('Not connected');
    }

    try {
      final sftp = await _client!.sftp();
      final remoteFile = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );
      
      final bytes = Uint8List.fromList(utf8.encode(content));
      await remoteFile.writeBytes(bytes);
      await remoteFile.close();

      return true;
    } catch (e) {
      rethrow;
    }
  }

  void disconnect() {
    if (_client != null) {
      _client!.close();
      _client = null;
      _isConnected = false;
    }
  }

  static String _getErrorMessage(String errorType, String originalError) {
    switch (errorType) {
      case 'timeout':
        return 'Connection timeout. Check if the IP address is correct and the machine is powered on.';

      case 'refused':
        return 'Connection refused. The SSH service may not be running on the target machine.';

      case 'auth':
        return 'Authentication failed. Please check your username and password.';

      case 'host':
        return 'Cannot resolve host. Please check the IP address format.';

      case 'socket':
        return 'Network error. Please check your network connection.';

      default:
        return 'Connection failed: $originalError';
    }
  }
}
