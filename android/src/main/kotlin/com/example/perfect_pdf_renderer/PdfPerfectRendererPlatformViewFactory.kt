package com.example.perfect_pdf_renderer
import android.content.Context
import com.example.perfect_pdf_renderer.PerfectPdfRenderer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class PerfectPdfRendererFactory(private val binaryMessenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as Map<String, Any>
        val pdfRenderer = PerfectPdfRenderer(context, viewId, binaryMessenger, params)
        // Return the created platform view
        return pdfRenderer
    }
}