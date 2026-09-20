package com.biliardino.biliardino

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.lang.ref.WeakReference
import java.util.concurrent.Executors
import java.nio.ByteBuffer
import java.nio.charset.CharacterCodingException
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets

class MainActivity: FlutterActivity() {
    private companion object {
        const val PICK_BACKUP_REQUEST = 1001
        const val PICKER_CHANNEL = "com.biliardino.biliardino/backup_file_picker"
    }

    private var pendingPickerResult: MethodChannel.Result? = null
    private var pickerChannel: MethodChannel? = null
    private val backupReader = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var isReadingBackup = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pickerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PICKER_CHANNEL)
        pickerChannel?.setMethodCallHandler { call, result ->
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
        if (isReadingBackup) return
        if (resultCode != Activity.RESULT_OK) {
            finishPicker(result, BackupRead.Success(null))
            return
        }
        val uri = data?.data
        if (uri == null) {
            finishPicker(result, BackupRead.Failure("missing_document", "The picker returned no document."))
            return
        }
        isReadingBackup = true
        val resolver = applicationContext.contentResolver
        val activity = WeakReference(this)
        val handler = mainHandler
        backupReader.execute {
            val outcome = readBackup(resolver, uri)
            handler.post { activity.get()?.finishPicker(result, outcome) }
        }
    }

    private fun finishPicker(result: MethodChannel.Result, outcome: BackupRead) {
        if (pendingPickerResult !== result) return
        pendingPickerResult = null
        isReadingBackup = false
        when (outcome) {
            is BackupRead.Success -> result.success(outcome.source)
            is BackupRead.Failure -> result.error(outcome.code, outcome.message, outcome.details)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        pickerChannel?.setMethodCallHandler(null)
        pickerChannel = null
        pendingPickerResult?.let { finishPicker(it, BackupRead.Success(null)) }
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        pendingPickerResult?.let { finishPicker(it, BackupRead.Success(null)) }
        backupReader.shutdownNow()
        mainHandler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}

private sealed class BackupRead {
    data class Success(val source: String?) : BackupRead()
    data class Failure(val code: String, val message: String, val details: String? = null) : BackupRead()
}

// No Activity or Flutter result is accessed while reading or decoding a document.
private fun readBackup(resolver: ContentResolver, uri: Uri): BackupRead {
    val maximumBytes = 10 * 1024 * 1024
    return try {
        val source = resolver.openInputStream(uri)
            ?: throw IllegalStateException("The selected document cannot be opened.")
        source.use { input ->
            val output = ByteArrayOutputStream()
            val buffer = ByteArray(8192)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                if (output.size() + count > maximumBytes) {
                    return BackupRead.Failure("backup_too_large", "The selected backup exceeds 10 MB.")
                }
                output.write(buffer, 0, count)
            }
            val decoder = StandardCharsets.UTF_8.newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT)
            BackupRead.Success(decoder.decode(ByteBuffer.wrap(output.toByteArray())).toString())
        }
    } catch (error: CharacterCodingException) {
        BackupRead.Failure("invalid_encoding", "The selected backup is not valid UTF-8 text.")
    } catch (error: Exception) {
        BackupRead.Failure("backup_read_failed", "Unable to read the selected backup.", error.message)
    }
}
