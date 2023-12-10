package com.example.perfect_pdf_renderer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** PerfectPdfRendererPlugin */
class PerfectPdfRendererPlugin: FlutterPlugin{
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      "perfect_pdf_renderer",
      PerfectPdfRendererFactory(flutterPluginBinding.binaryMessenger)
    )
  }

   override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
   }
}