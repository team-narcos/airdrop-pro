package com.example.airdrop_app

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import com.airdrop.pro.WiFiDirectPlugin

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nardele.airdrop_app/file_opener"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register WiFi Direct Plugin
        flutterEngine.plugins.add(WiFiDirectPlugin())
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFile" -> {
                    val path = call.argument<String>("path")
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    
                    if (path != null) {
                        try {
                            openFile(path, mimeType)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "File path is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openFile(filePath: String, mimeType: String) {
        val file = File(filePath)
        
        if (!file.exists()) {
            throw Exception("File does not exist: $filePath")
        }

        // Use FileProvider to get content URI
        val authority = "$packageName.fileprovider"
        val contentUri: Uri = FileProvider.getUriForFile(this, authority, file)

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(contentUri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Check if there's an app that can handle this intent
        val packageManager = packageManager
        if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
        } else {
            // Try with a chooser if no default app
            val chooser = Intent.createChooser(intent, "Open with")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(chooser)
        }
    }
}
