import 'package:flutter/services.dart';

class BackupFilePickerException implements Exception {
  const BackupFilePickerException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'BackupFilePickerException($code): $message';
}

class BackupFilePicker {
  const BackupFilePicker({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.biliardino.biliardino/backup_file_picker';
  final MethodChannel _channel;

  Future<String?> pickJson() async {
    try {
      return await _channel.invokeMethod<String>('pickJson');
    } on PlatformException catch (error) {
      throw BackupFilePickerException(
        code: error.code,
        message: error.message ?? 'Unable to read the selected backup.',
      );
    }
  }
}
