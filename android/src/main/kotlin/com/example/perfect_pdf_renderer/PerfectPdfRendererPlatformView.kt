package com.example.perfect_pdf_renderer

import android.content.Context
import android.graphics.Color
import android.view.View
import clone.com.github.barteksc.pdfviewer.PDFView
import clone.com.github.barteksc.pdfviewer.listener.*
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView
import java.io.File

class PerfectPdfRenderer(
    private val context: Context,
    private val id: Int,
    private val binaryMessenger: BinaryMessenger,
    val params: Map<String, Any>
) : PlatformView, MethodCallHandler {
    private lateinit var pdfView: PDFView
    private lateinit var methodChannel: MethodChannel

    init {
        methodChannel = MethodChannel(binaryMessenger, "perfect_pdf_renderer$id")
        methodChannel.setMethodCallHandler(this)
    }

    override fun getView(): View {
        // Check if pdfView is already initialized
        if (!::pdfView.isInitialized) {
            if (params["filePath"] != null) {
                val filePath = params["filePath"] as String
                val defaultPage = params["defaultPage"] as Int
                val onPageChangeListener = object : OnPageChangeListener {
                    override fun onPageChanged(page: Int, total: Int) {
                        val args = hashMapOf<String, Any>()
                        args["page"] = page
                        args["total"] = total
                        methodChannel.invokeMethod("onPageChanged", args)
                    }
                }

                pdfView = PDFView(context, null)
                pdfView.methodChannel = methodChannel
                pdfView.setBackgroundColor(Color.BLACK)
                pdfView.setFile(filePath)
                pdfView.minZoom = 0.5F
                pdfView.maxZoom = 5.0F
                pdfView.page = defaultPage
                pdfView.pages = params["pages"] as Int
                pdfView.setOnClickListener{
                    methodChannel.invokeMethod("endExtraction", null);
                    pdfView.rects = ArrayList()
                    pdfView.handle1.set(0, 0f);
                    pdfView.handle1.set(1, 0f);
                    pdfView.handle2.set(0, 0f);
                    pdfView.handle2.set(1, 0f);
                    pdfView.invalidate();
                }
                pdfView.fromFile(File(filePath))
                    .autoSpacing(false)
                    .spacing(10)
                    .enableAntialiasing(true)
                    .pageFling(false)
                    .defaultPage(defaultPage)
                    .onPageChange(onPageChangeListener)
                    .load()
            }
        }
        return pdfView
    }

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setRects" -> {
                val rects = call.argument<List<Double>>("rects")
                this.pdfView.setRects(rects)
            }
            "drawLine" -> {
                val color = call.argument<List<Double>>("color")
                this.pdfView.drawLine(color)
            }
            "drawRect" -> {
                val color = call.argument<List<Double>>("color")
                this.pdfView.drawRect(color)
            }
        }
    }
}