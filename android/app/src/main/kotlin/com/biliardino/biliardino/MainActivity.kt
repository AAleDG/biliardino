package com.biliardino.biliardino

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.charset.CharacterCodingException
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets

class MainActivity: FlutterActivity() {
    private companion object {
        const val PICK_BACKUP_REQUEST = 1001
        const val PICKER_CHANNEL = "com.biliardino.biliardino/backup_file_picker"
        const val MAXIMUM_BACKUP_BYTES = 10 * 1024 * 1024
    }

    private var pendingPickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PICKER_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "pickJson") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                openBackupPicker(result)
            }
    }

    private fun openBackupPicker(result: MethodChannel.Result) {
        if (pendingPickerResult != null) {
            result.error("picker_busy", "A backup picker is already open.", null)
            return
        }
        pendingPickerResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
        }
        try {
            startActivityForResult(intent, PICK_BACKUP_REQUEST)
        } catch (error: Exception) {
            pendingPickerResult = null
            result.error("picker_unavailable", "The document picker cannot be opened.", error.message)
        }
    }

    @Deprecated("Deprecated in Android API; retained for the FlutterActivity result boundary.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_BACKUP_REQUEST) return
        val result = pendingPickerResult ?: return
        pendingPickerResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }
        val uri = data?.data
        if (uri == null) {
            result.error("missing_document", "The picker returned no document.", null)
            return
        }
        readBackup(uri, result)
    }

    private fun readBackup(uri: Uri, result: MethodChannel.Result) {
        try {
            val source = contentResolver.openInputStream(uri)
                ?: throw IllegalStateException("The selected document cannot be opened.")
            source.use { input ->
                val output = ByteArrayOutputStream()
                val buffer = ByteArray(8192)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    if (output.size() + count > MAXIMUM_BACKUP_BYTES) {
                        result.error("backup_too_large", "The selected backup exceeds 10 MB.", null)
                        return
                    }
                    output.write(buffer, 0, count)
                }
                val decoder = StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                try {
                    result.success(decoder.decode(ByteBuffer.wrap(output.toByteArray())).toString())
                } catch (error: CharacterCodingException) {
                    result.error("invalid_encoding", "The selected backup is not valid UTF-8 text.", null)
                }
            }
        } catch (error: Exception) {
            result.error("backup_read_failed", "Unable to read the selected backup.", error.message)
        }
    }
}
