package com.example.inr_takip

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val nfcChannel = "inr_takip/nfc_hce"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, nfcChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updatePayload" -> {
                        val text = call.argument<String>("text") ?: ""
                        InrHceService.updatePayload(text)
                        result.success(null)
                    }
                    "stop" -> {
                        InrHceService.updatePayload(
                            "INR Takip: acil bilgi paylaşımı durduruldu."
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
