package com.aetherride.aetherride_mobile

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.RequiresApi
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/**
 * Bosch Live Data Interface accessory (Spec V1.0).
 *
 * The eBike is BLE central: we advertise a service-solicitation UUID, the bike
 * connects, then we subscribe to Live Data notifications on eb21.
 * No invented SoC. Android 12+ (solicitation UUID API).
 */
class BoschLdiPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var method: MethodChannel
    private lateinit var events: EventChannel
    private lateinit var appContext: Context
    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null

    private var advertiser: BluetoothLeAdvertiser? = null
    private var gattServer: BluetoothGattServer? = null
    private var gatt: BluetoothGatt? = null
    private var advertiseCallback: AdvertiseCallback? = null
    private var pending: MethodChannel.Result? = null
    private var timeout: Runnable? = null
    private var previousAdapterName: String? = null
    private val merged = BoschLdiSnapshot()
    private var subscribed = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        method = MethodChannel(binding.binaryMessenger, "com.aetherride/ble_core")
        events = EventChannel(binding.binaryMessenger, "com.aetherride/ble_core/ldi")
        method.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopInternal()
        method.setMethodCallHandler(null)
        events.setStreamHandler(null)
        sink = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> {
                val pairing = call.argument<Boolean>("pairing") ?: true
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    start(pairing, result)
                } else {
                    emitStatus("ldi_need_android12")
                    result.success(false)
                }
            }
            "disconnect" -> {
                stopInternal()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    @SuppressLint("MissingPermission")
    private fun start(pairing: Boolean, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            result.success(false)
            emitStatus("ldi_need_android12")
            return
        }
        if (!hasAdvertisePermission()) {
            result.success(false)
            emitStatus("ldi_need_android12")
            return
        }
        if (subscribed && gatt != null) {
            result.success(true)
            return
        }
        if (pending != null) {
            result.success(false)
            return
        }

        val mgr = appContext.getSystemService(BluetoothManager::class.java)
        val adapter = mgr?.adapter
        if (adapter == null || !adapter.isEnabled) {
            result.success(false)
            emitStatus("Bluetooth aus")
            return
        }
        val adv = adapter.bluetoothLeAdvertiser
        if (adv == null) {
            result.success(false)
            return
        }

        pending = result
        subscribed = false
        advertiser = adv
        previousAdapterName = adapter.name
        try {
            adapter.name = LOCAL_NAME
        } catch (_: SecurityException) {
        }

        gattServer = try {
            mgr.openGattServer(appContext, serverCallback)
        } catch (_: SecurityException) {
            failPending("ldi_need_android12")
            return
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setConnectable(true)
            .setTimeout(0)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .build()
        // Solicitation UUID must stay in the primary packet on pair AND
        // reconnect — the bike (central) looks for eb20. The local name
        // ("FlowLine") goes in the scan response so Samsung does not drop it.
        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceSolicitationUuid(ParcelUuid(SERVICE_UUID))
            .build()
        val scan = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .build()

        val cb = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                emitStatus(if (pairing) "ldi_waiting_flow" else "ldi_waiting_flow")
            }

            override fun onStartFailure(errorCode: Int) {
                Log.w(TAG, "advertise failed $errorCode")
                failPending("ldi_timeout")
            }
        }
        advertiseCallback = cb
        try {
            adv.startAdvertising(settings, data, scan, cb)
        } catch (e: SecurityException) {
            Log.w(TAG, "advertise: $e")
            failPending("ldi_need_android12")
            return
        }

        val waitMs = if (pairing) PAIRING_TIMEOUT_MS else RECONNECT_TIMEOUT_MS
        val t = Runnable { failPending("ldi_timeout") }
        timeout = t
        main.postDelayed(t, waitMs)
    }

    @SuppressLint("MissingPermission")
    private fun stopInternal() {
        timeout?.let { main.removeCallbacks(it) }
        timeout = null
        failPending(null)
        try {
            advertiseCallback?.let { advertiser?.stopAdvertising(it) }
        } catch (_: SecurityException) {
        }
        advertiseCallback = null
        advertiser = null
        try {
            gatt?.disconnect()
            gatt?.close()
        } catch (_: SecurityException) {
        }
        gatt = null
        try {
            gattServer?.close()
        } catch (_: SecurityException) {
        }
        gattServer = null
        subscribed = false
        val adapter = appContext.getSystemService(BluetoothManager::class.java)?.adapter
        val prev = previousAdapterName
        if (adapter != null && prev != null) {
            try {
                adapter.name = prev
            } catch (_: SecurityException) {
            }
        }
        previousAdapterName = null
    }

    private fun failPending(status: String?) {
        status?.let { emitStatus(it) }
        val p = pending
        pending = null
        if (p != null) {
            main.post { p.success(false) }
        }
    }

    private fun succeedPending() {
        timeout?.let { main.removeCallbacks(it) }
        timeout = null
        val p = pending
        pending = null
        if (p != null) {
            main.post { p.success(true) }
        }
    }

    private fun emitStatus(status: String) {
        main.post { sink?.success(mapOf("status" to status)) }
    }

    private fun emitData() {
        val payload = merged.toEventMap()
        main.post { sink?.success(payload) }
    }

    private fun hasAdvertisePermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        val adv = ContextCompat.checkSelfPermission(
            appContext,
            android.Manifest.permission.BLUETOOTH_ADVERTISE,
        )
        val connect = ContextCompat.checkSelfPermission(
            appContext,
            android.Manifest.permission.BLUETOOTH_CONNECT,
        )
        return adv == PackageManager.PERMISSION_GRANTED &&
            connect == PackageManager.PERMISSION_GRANTED
    }

    private val serverCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                attachClient(device)
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                subscribed = false
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun attachClient(device: BluetoothDevice) {
        main.post {
            try {
                gatt?.close()
            } catch (_: SecurityException) {
            }
            gatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                device.connectGatt(appContext, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
            } else {
                device.connectGatt(appContext, false, gattCallback)
            }
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                try {
                    g.requestMtu(185)
                } catch (_: SecurityException) {
                    g.discoverServices()
                }
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                subscribed = false
            }
        }

        @SuppressLint("MissingPermission")
        override fun onMtuChanged(g: BluetoothGatt, mtu: Int, status: Int) {
            try {
                g.discoverServices()
            } catch (_: SecurityException) {
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
            val svc = g.getService(SERVICE_UUID)
            val chr = svc?.getCharacteristic(LIVE_CHAR_UUID)
            if (chr == null) {
                Log.w(TAG, "eb21 missing")
                failPending("ldi_timeout")
                return
            }
            try {
                g.setCharacteristicNotification(chr, true)
                val cccd = chr.getDescriptor(CCCD)
                if (cccd != null) {
                    cccd.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                    g.writeDescriptor(cccd)
                } else {
                    g.readCharacteristic(chr)
                }
            } catch (e: SecurityException) {
                Log.w(TAG, "notify: $e")
                failPending("ldi_need_android12")
            }
        }

        override fun onDescriptorWrite(
            g: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int,
        ) {
            subscribed = status == BluetoothGatt.GATT_SUCCESS
            if (subscribed) {
                try {
                    g.readCharacteristic(descriptor.characteristic)
                } catch (_: Exception) {
                    succeedPending()
                }
            } else {
                failPending("ldi_timeout")
            }
        }

        @Deprecated("legacy")
        override fun onCharacteristicRead(
            g: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int,
        ) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                ingest(characteristic.value)
            }
            if (subscribed || status == BluetoothGatt.GATT_SUCCESS) {
                succeedPending()
            }
        }

        override fun onCharacteristicRead(
            g: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
            status: Int,
        ) {
            if (status == BluetoothGatt.GATT_SUCCESS) ingest(value)
            if (subscribed || status == BluetoothGatt.GATT_SUCCESS) {
                succeedPending()
            }
        }

        @Deprecated("legacy")
        override fun onCharacteristicChanged(
            g: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            ingest(characteristic.value)
        }

        override fun onCharacteristicChanged(
            g: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            ingest(value)
        }
    }

    private fun ingest(value: ByteArray?) {
        if (value == null || value.isEmpty()) return
        try {
            merged.merge(BoschLdiProto.decode(value))
            emitData()
            if (!subscribed) {
                subscribed = true
                succeedPending()
            }
        } catch (e: Exception) {
            Log.w(TAG, "ldi decode: $e")
        }
    }

    companion object {
        private const val TAG = "BoschLdi"
        private const val LOCAL_NAME = "FlowLine"
        private const val PAIRING_TIMEOUT_MS = 90_000L
        private const val RECONNECT_TIMEOUT_MS = 25_000L
        val SERVICE_UUID: UUID = UUID.fromString("0000eb20-eaa2-11e9-81b4-2a2ae2dbcce4")
        val LIVE_CHAR_UUID: UUID = UUID.fromString("0000eb21-eaa2-11e9-81b4-2a2ae2dbcce4")
        private val CCCD: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }
}
