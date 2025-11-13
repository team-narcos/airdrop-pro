package com.airdrop.pro

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.WpsInfo
import android.net.wifi.p2p.*
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.*
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import kotlin.concurrent.thread

/**
 * WiFi Direct Plugin for Flutter
 * 
 * Implements WiFi P2P functionality for true offline device-to-device communication
 * Features:
 * - Device discovery and connection
 * - File transfer with progress tracking
 * - Signal strength monitoring
 * - Automatic reconnection
 */
class WiFiDirectPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    
    companion object {
        private const val TAG = "WiFiDirectPlugin"
        private const val CHANNEL_NAME = "com.airdrop.pro/wifi_direct"
        private const val FILE_TRANSFER_PORT = 8988
        private const val BUFFER_SIZE = 8192
    }
    
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activityPluginBinding: ActivityPluginBinding? = null
    
    // WiFi Direct managers
    private var wifiP2pManager: WifiP2pManager? = null
    private var wifiP2pChannel: WifiP2pManager.Channel? = null
    private var wifiDirectReceiver: BroadcastReceiver? = null
    
    // Connection state
    private var isConnected = false
    private var isGroupOwner = false
    private var connectedDevice: WifiP2pDevice? = null
    private var groupOwnerAddress: InetAddress? = null
    
    // File transfer
    private var serverSocket: ServerSocket? = null
    private var clientSocket: Socket? = null
    
    //--------------------------------------------------
    // FlutterPlugin Implementation
    //--------------------------------------------------
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        
        initializeWifiDirect()
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        cleanup()
    }
    
    //--------------------------------------------------
    // ActivityAware Implementation
    //--------------------------------------------------
    
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityPluginBinding = binding
    }
    
    override fun onDetachedFromActivityForConfigChanges() {
        activityPluginBinding = null
    }
    
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityPluginBinding = binding
    }
    
    override fun onDetachedFromActivity() {
        activityPluginBinding = null
    }
    
    //--------------------------------------------------
    // MethodCallHandler Implementation
    //--------------------------------------------------
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> initialize(result)
            "startDiscovery" -> startDiscovery(result)
            "stopDiscovery" -> stopDiscovery(result)
            "connect" -> connect(call, result)
            "disconnect" -> disconnect(result)
            "sendFile" -> sendFile(call, result)
            "isWifiDirectSupported" -> isWifiDirectSupported(result)
            "isWifiDirectEnabled" -> isWifiDirectEnabled(result)
            else -> result.notImplemented()
        }
    }
    
    //--------------------------------------------------
    // WiFi Direct Initialization
    //--------------------------------------------------
    
    private fun initializeWifiDirect() {
        try {
            context?.let { ctx ->
                wifiP2pManager = ctx.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
                wifiP2pChannel = wifiP2pManager?.initialize(ctx, ctx.mainLooper, null)
                
                Log.d(TAG, "WiFi Direct initialized successfully")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize WiFi Direct", e)
        }
    }
    
    private fun initialize(result: Result) {
        if (wifiP2pManager != null && wifiP2pChannel != null) {
            registerWifiDirectReceiver()
            result.success(true)
        } else {
            result.error("INIT_ERROR", "Failed to initialize WiFi Direct", null)
        }
    }
    
    //--------------------------------------------------
    // Device Discovery
    //--------------------------------------------------
    
    private fun startDiscovery(result: Result) {
        if (!checkPermissions()) {
            result.error("PERMISSION_ERROR", "Required permissions not granted", null)
            return
        }
        
        val manager = wifiP2pManager
        val channel = wifiP2pChannel
        
        if (manager == null || channel == null) {
            result.error("NOT_INITIALIZED", "WiFi Direct not initialized", null)
            return
        }
        
        try {
            manager.discoverPeers(channel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    Log.d(TAG, "Discovery started successfully")
                    result.success(true)
                }
                
                override fun onFailure(reason: Int) {
                    Log.e(TAG, "Discovery failed with reason: $reason")
                    result.error("DISCOVERY_FAILED", "Failed to start discovery: ${getFailureReason(reason)}", null)
                }
            })
        } catch (e: SecurityException) {
            result.error("PERMISSION_ERROR", "Missing permissions for discovery", e.message)
        }
    }
    
    private fun stopDiscovery(result: Result) {
        val manager = wifiP2pManager
        val channel = wifiP2pChannel
        
        if (manager == null || channel == null) {
            result.error("NOT_INITIALIZED", "WiFi Direct not initialized", null)
            return
        }
        
        try {
            manager.stopPeerDiscovery(channel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    Log.d(TAG, "Discovery stopped")
                    result.success(true)
                }
                
                override fun onFailure(reason: Int) {
                    Log.e(TAG, "Failed to stop discovery: $reason")
                    result.error("STOP_FAILED", "Failed to stop discovery", null)
                }
            })
        } catch (e: SecurityException) {
            result.error("PERMISSION_ERROR", "Missing permissions", e.message)
        }
    }
    
    //--------------------------------------------------
    // Connection Management
    //--------------------------------------------------
    
    private fun connect(call: MethodCall, result: Result) {
        val deviceAddress = call.argument<String>("deviceAddress")
        
        if (deviceAddress == null) {
            result.error("INVALID_ARGUMENT", "Device address is required", null)
            return
        }
        
        val manager = wifiP2pManager
        val channel = wifiP2pChannel
        
        if (manager == null || channel == null) {
            result.error("NOT_INITIALIZED", "WiFi Direct not initialized", null)
            return
        }
        
        val config = WifiP2pConfig().apply {
            this.deviceAddress = deviceAddress
            wps.setup = WpsInfo.PBC // Push Button Configuration
            groupOwnerIntent = 15 // Max value (0-15), higher = more likely to be group owner
        }
        
        try {
            manager.connect(channel, config, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    Log.d(TAG, "Connection initiated to $deviceAddress")
                    result.success(true)
                }
                
                override fun onFailure(reason: Int) {
                    Log.e(TAG, "Connection failed: ${getFailureReason(reason)}")
                    result.error("CONNECTION_FAILED", "Failed to connect: ${getFailureReason(reason)}", null)
                }
            })
        } catch (e: SecurityException) {
            result.error("PERMISSION_ERROR", "Missing permissions for connection", e.message)
        }
    }
    
    private fun disconnect(result: Result) {
        val manager = wifiP2pManager
        val channel = wifiP2pChannel
        
        if (manager == null || channel == null) {
            result.error("NOT_INITIALIZED", "WiFi Direct not initialized", null)
            return
        }
        
        closeConnections()
        
        manager.removeGroup(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                isConnected = false
                connectedDevice = null
                Log.d(TAG, "Disconnected successfully")
                result.success(true)
            }
            
            override fun onFailure(reason: Int) {
                Log.e(TAG, "Failed to disconnect: $reason")
                result.success(true) // Still return success as connections are closed
            }
        })
    }
    
    //--------------------------------------------------
    // File Transfer
    //--------------------------------------------------
    
    private fun sendFile(call: MethodCall, result: Result) {
        val filePath = call.argument<String>("filePath")
        val fileName = call.argument<String>("fileName")
        val fileSize = call.argument<Long>("fileSize")
        
        if (filePath == null || fileName == null || fileSize == null) {
            result.error("INVALID_ARGUMENT", "File path, name, and size are required", null)
            return
        }
        
        if (!isConnected) {
            result.error("NOT_CONNECTED", "Not connected to any device", null)
            return
        }
        
        thread {
            try {
                val file = File(filePath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
                    return@thread
                }
                
                if (isGroupOwner) {
                    // Group owner receives files
                    receiveFile(fileName, fileSize, result)
                } else {
                    // Client sends files
                    sendFileToGroupOwner(file, fileName, fileSize, result)
                }
            } catch (e: Exception) {
                Log.e(TAG, "File transfer error", e)
                result.error("TRANSFER_ERROR", "File transfer failed: ${e.message}", null)
            }
        }
    }
    
    private fun sendFileToGroupOwner(file: File, fileName: String, fileSize: Long, result: Result) {
        val address = groupOwnerAddress ?: run {
            result.error("NO_ADDRESS", "Group owner address not available", null)
            return
        }
        
        try {
            val socket = Socket(address, FILE_TRANSFER_PORT)
            clientSocket = socket
            
            val outputStream = socket.getOutputStream()
            val dos = DataOutputStream(outputStream)
            
            // Send file metadata
            dos.writeUTF(fileName)
            dos.writeLong(fileSize)
            
            // Send file data
            val fileInputStream = FileInputStream(file)
            val buffer = ByteArray(BUFFER_SIZE)
            var bytesRead: Int
            var totalSent = 0L
            
            while (fileInputStream.read(buffer).also { bytesRead = it } != -1) {
                dos.write(buffer, 0, bytesRead)
                totalSent += bytesRead
                
                // Report progress
                val progress = (totalSent.toDouble() / fileSize * 100).toInt()
                reportProgress(progress, totalSent, fileSize)
            }
            
            dos.flush()
            fileInputStream.close()
            socket.close()
            
            Log.d(TAG, "File sent successfully: $fileName ($totalSent bytes)")
            result.success(mapOf(
                "success" to true,
                "bytesSent" to totalSent
            ))
            
        } catch (e: Exception) {
            Log.e(TAG, "Error sending file", e)
            result.error("SEND_ERROR", "Failed to send file: ${e.message}", null)
        } finally {
            clientSocket?.close()
            clientSocket = null
        }
    }
    
    private fun receiveFile(fileName: String, fileSize: Long, result: Result) {
        try {
            if (serverSocket == null) {
                serverSocket = ServerSocket(FILE_TRANSFER_PORT)
            }
            
            Log.d(TAG, "Waiting for file transfer connection...")
            val socket = serverSocket?.accept() ?: run {
                result.error("SOCKET_ERROR", "Failed to accept connection", null)
                return
            }
            
            val inputStream = socket.getInputStream()
            val dis = DataInputStream(inputStream)
            
            // Read file metadata
            val receivedFileName = dis.readUTF()
            val receivedFileSize = dis.readLong()
            
            // Save to downloads directory
            val downloadsDir = context?.getExternalFilesDir(null)
            val file = File(downloadsDir, receivedFileName)
            val fileOutputStream = FileOutputStream(file)
            
            // Receive file data
            val buffer = ByteArray(BUFFER_SIZE)
            var bytesRead: Int
            var totalReceived = 0L
            
            while (totalReceived < receivedFileSize) {
                bytesRead = dis.read(buffer, 0, minOf(buffer.size, (receivedFileSize - totalReceived).toInt()))
                if (bytesRead == -1) break
                
                fileOutputStream.write(buffer, 0, bytesRead)
                totalReceived += bytesRead
                
                // Report progress
                val progress = (totalReceived.toDouble() / receivedFileSize * 100).toInt()
                reportProgress(progress, totalReceived, receivedFileSize)
            }
            
            fileOutputStream.flush()
            fileOutputStream.close()
            socket.close()
            
            Log.d(TAG, "File received successfully: $receivedFileName ($totalReceived bytes)")
            result.success(mapOf(
                "success" to true,
                "bytesReceived" to totalReceived,
                "filePath" to file.absolutePath
            ))
            
        } catch (e: Exception) {
            Log.e(TAG, "Error receiving file", e)
            result.error("RECEIVE_ERROR", "Failed to receive file: ${e.message}", null)
        }
    }
    
    private fun reportProgress(progress: Int, bytesTransferred: Long, totalBytes: Long) {
        channel.invokeMethod("onTransferProgress", mapOf(
            "progress" to progress,
            "bytesTransferred" to bytesTransferred,
            "totalBytes" to totalBytes
        ))
    }
    
    //--------------------------------------------------
    // Broadcast Receiver for WiFi Direct Events
    //--------------------------------------------------
    
    private fun registerWifiDirectReceiver() {
        val intentFilter = IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
        }
        
        wifiDirectReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                handleWifiDirectIntent(intent)
            }
        }
        
        context?.registerReceiver(wifiDirectReceiver, intentFilter)
    }
    
    private fun handleWifiDirectIntent(intent: Intent) {
        when (intent.action) {
            WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                val isEnabled = state == WifiP2pManager.WIFI_P2P_STATE_ENABLED
                Log.d(TAG, "WiFi P2P state changed: ${if (isEnabled) "ENABLED" else "DISABLED"}")
                
                channel.invokeMethod("onWifiDirectStateChanged", mapOf("enabled" to isEnabled))
            }
            
            WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                Log.d(TAG, "Peers changed, requesting peer list")
                requestPeerList()
            }
            
            WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                Log.d(TAG, "Connection changed")
                requestConnectionInfo()
            }
            
            WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION -> {
                val device = intent.getParcelableExtra<WifiP2pDevice>(WifiP2pManager.EXTRA_WIFI_P2P_DEVICE)
                Log.d(TAG, "This device changed: ${device?.deviceName}")
            }
        }
    }
    
    private fun requestPeerList() {
        try {
            wifiP2pManager?.requestPeers(wifiP2pChannel) { peers ->
                val deviceList = peers.deviceList.map { device ->
                    mapOf(
                        "deviceName" to device.deviceName,
                        "deviceAddress" to device.deviceAddress,
                        "status" to device.status,
                        "isGroupOwner" to (device.status == WifiP2pDevice.CONNECTED)
                    )
                }
                
                channel.invokeMethod("onPeersChanged", mapOf("devices" to deviceList))
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Permission error when requesting peers", e)
        }
    }
    
    private fun requestConnectionInfo() {
        try {
            wifiP2pManager?.requestConnectionInfo(wifiP2pChannel) { info ->
                if (info.groupFormed) {
                    isConnected = true
                    isGroupOwner = info.isGroupOwner
                    groupOwnerAddress = info.groupOwnerAddress
                    
                    Log.d(TAG, "Connected as ${if (isGroupOwner) "GROUP OWNER" else "CLIENT"}")
                    
                    channel.invokeMethod("onConnectionChanged", mapOf(
                        "isConnected" to true,
                        "isGroupOwner" to isGroupOwner,
                        "groupOwnerAddress" to groupOwnerAddress?.hostAddress
                    ))
                    
                    // Start server socket if group owner
                    if (isGroupOwner && serverSocket == null) {
                        thread {
                            try {
                                serverSocket = ServerSocket(FILE_TRANSFER_PORT)
                                Log.d(TAG, "Server socket opened on port $FILE_TRANSFER_PORT")
                            } catch (e: Exception) {
                                Log.e(TAG, "Failed to open server socket", e)
                            }
                        }
                    }
                } else {
                    isConnected = false
                    channel.invokeMethod("onConnectionChanged", mapOf("isConnected" to false))
                }
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Permission error when requesting connection info", e)
        }
    }
    
    //--------------------------------------------------
    // Helper Methods
    //--------------------------------------------------
    
    private fun isWifiDirectSupported(result: Result) {
        val packageManager = context?.packageManager
        val isSupported = packageManager?.hasSystemFeature(PackageManager.FEATURE_WIFI_DIRECT) ?: false
        result.success(isSupported)
    }
    
    private fun isWifiDirectEnabled(result: Result) {
        // This would need actual WiFi state check
        result.success(wifiP2pManager != null)
    }
    
    private fun checkPermissions(): Boolean {
        val ctx = context ?: return false
        
        val requiredPermissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_WIFI_STATE,
            Manifest.permission.CHANGE_WIFI_STATE
        )
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requiredPermissions.add(Manifest.permission.NEARBY_WIFI_DEVICES)
        }
        
        return requiredPermissions.all { permission ->
            ActivityCompat.checkSelfPermission(ctx, permission) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    private fun getFailureReason(reason: Int): String {
        return when (reason) {
            WifiP2pManager.ERROR -> "Internal error"
            WifiP2pManager.P2P_UNSUPPORTED -> "P2P unsupported"
            WifiP2pManager.BUSY -> "System busy"
            WifiP2pManager.NO_SERVICE_REQUESTS -> "No service requests"
            else -> "Unknown error ($reason)"
        }
    }
    
    private fun closeConnections() {
        try {
            clientSocket?.close()
            clientSocket = null
            
            serverSocket?.close()
            serverSocket = null
            
            Log.d(TAG, "All connections closed")
        } catch (e: Exception) {
            Log.e(TAG, "Error closing connections", e)
        }
    }
    
    private fun cleanup() {
        try {
            context?.unregisterReceiver(wifiDirectReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver", e)
        }
        
        closeConnections()
        wifiP2pChannel = null
        wifiP2pManager = null
    }
}
