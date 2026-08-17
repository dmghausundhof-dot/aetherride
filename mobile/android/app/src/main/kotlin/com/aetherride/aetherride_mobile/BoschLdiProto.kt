package com.aetherride.aetherride_mobile

/**
 * Bosch LDI LiveData protobuf (Spec V1.0, Apache-2.0). Sparse fields.
 * Does not invent SoC / power — omitted keys stay absent.
 */
internal data class BoschLdiSnapshot(
    var speedKmh: Double? = null,
    var cadenceRpm: Double? = null,
    var riderPowerW: Double? = null,
    var ambientBrightness: Double? = null,
    var batterySocPercent: Double? = null,
    var odometerKm: Double? = null,
    var lightStatus: Boolean? = null,
    var systemLock: Boolean? = null,
    var chargerConnected: Boolean? = null,
    var bikeNotDriving: Boolean? = null,
) {
    fun merge(frame: BoschLdiSnapshot) {
        frame.speedKmh?.let { speedKmh = it }
        frame.cadenceRpm?.let { cadenceRpm = it }
        frame.riderPowerW?.let { riderPowerW = it }
        frame.ambientBrightness?.let { ambientBrightness = it }
        frame.batterySocPercent?.let { batterySocPercent = it }
        frame.odometerKm?.let { odometerKm = it }
        frame.lightStatus?.let { lightStatus = it }
        frame.systemLock?.let { systemLock = it }
        frame.chargerConnected?.let { chargerConnected = it }
        frame.bikeNotDriving?.let { bikeNotDriving = it }
    }

    fun toEventMap(): Map<String, Any?> {
        val m = HashMap<String, Any?>()
        speedKmh?.let { m["speedKmh"] = it }
        cadenceRpm?.let { m["cadenceRpm"] = it }
        odometerKm?.let { m["odometerKm"] = it }
        lightStatus?.let { m["lightStatus"] = it }
        ambientBrightness?.let { m["ambientBrightness"] = it }
        systemLock?.let { m["systemLock"] = it }
        bikeNotDriving?.let { m["bikeNotDriving"] = it }
        chargerConnected?.let { m["chargerConnected"] = it }
        batterySocPercent?.let { m["batterySocPercent"] = it }
        riderPowerW?.let { m["riderPowerW"] = it }
        m["timestampMs"] = System.currentTimeMillis()
        return m
    }
}

internal object BoschLdiProto {
    fun decode(bytes: ByteArray): BoschLdiSnapshot {
        val out = BoschLdiSnapshot()
        var i = 0
        fun u8(): Int {
            if (i >= bytes.size) throw IllegalArgumentException("truncated")
            return bytes[i++].toInt() and 0xff
        }
        fun varint(): Long {
            var shift = 0
            var n = 0L
            while (true) {
                val b = u8()
                n = n or ((b and 0x7f).toLong() shl shift)
                if (b and 0x80 == 0) return n
                shift += 7
                if (shift > 63) throw IllegalArgumentException("varint")
            }
        }
        fun skip(wire: Int) {
            when (wire) {
                0 -> varint()
                1 -> i += 8
                2 -> {
                    val n = varint().toInt()
                    i += n
                }
                5 -> i += 4
                else -> throw IllegalArgumentException("wire $wire")
            }
        }
        while (i < bytes.size) {
            val tag = varint().toInt()
            val field = tag ushr 3
            val wire = tag and 7
            if (wire != 0) {
                skip(wire)
                continue
            }
            val n = varint()
            when (field) {
                1 -> out.speedKmh = n / 100.0
                2 -> {
                    val u = n and 0xffffffffL
                    out.cadenceRpm = if (u <= 0x7fffffffL) {
                        u.toDouble()
                    } else {
                        (u - 0x100000000L).toDouble()
                    }
                }
                5 -> out.riderPowerW = n.toDouble()
                9 -> out.ambientBrightness = n / 1000.0
                10 -> out.batterySocPercent = n.coerceIn(0L, 100L).toDouble()
                12 -> out.odometerKm = n / 1000.0
                17 -> out.lightStatus = n.toInt() == 2
                21 -> out.systemLock = n != 0L
                22 -> out.chargerConnected = n != 0L
                25 -> out.bikeNotDriving = n != 0L
            }
        }
        return out
    }
}
