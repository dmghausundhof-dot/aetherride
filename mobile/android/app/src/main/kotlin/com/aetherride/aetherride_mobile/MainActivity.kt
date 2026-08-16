package com.aetherride.aetherride_mobile

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { it.remove() }
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(SensorCorePlugin())
        flutterEngine.plugins.add(LocationCorePlugin())
        flutterEngine.plugins.add(BoschLdiPlugin())
        flutterEngine.plugins.add(AmbientLightPlugin())
        flutterEngine.plugins.add(HudMediaPlugin())
    }
}
