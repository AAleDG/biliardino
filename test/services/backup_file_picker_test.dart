import 'package:biliardino/services/backup_file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/backup_picker');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('returns selected JSON and preserves cancellation as null', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => '{"version":1}');
    const picker = BackupFilePicker(channel: channel);
    expect(await picker.pickJson(), '{"version":1}');

    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(await picker.pickJson(), isNull);
  });

  test('converts platform failures into a typed error', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(
            code: 'backup_read_failed',
            message: 'Cannot read file.',
          ),
        );

    expect(
      () => const BackupFilePicker(channel: channel).pickJson(),
      throwsA(
        isA<BackupFilePickerException>()
            .having((error) => error.code, 'code', 'backup_read_failed')
            .having((error) => error.message, 'message', 'Cannot read file.'),
      ),
    );
  });
}
