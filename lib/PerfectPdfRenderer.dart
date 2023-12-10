import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

typedef PageChangedCallback = void Function(int? page, int? total);
typedef PDFViewCreatedCallback = void Function(PerfectPdfController controller);
typedef OffsetSetter = void Function(List<Object?> offsets);
typedef MaxWidthSetter = void Function(int maxWidthInt);
typedef ExtractionEnd = void Function();

class PerfectPdfRenderer extends StatefulWidget{
  final String? filePath;
  final Uint8List? fileData;
  final PageChangedCallback? onPageChanged;
  final PDFViewCreatedCallback? onViewCreated;
  final OffsetSetter? setOffsets;
  final MaxWidthSetter? onMaxWidthSet;
  final ExtractionEnd? extractionEnd;
  final int? defaultPage;
  final int pages;

  const PerfectPdfRenderer({super.key, this.filePath, this.fileData,
    this.onPageChanged, this.onViewCreated, this.defaultPage, this.setOffsets,
    required this.pages, this.onMaxWidthSet, this.extractionEnd});

  @override
  State<StatefulWidget> createState() {
    return PerfectPdfRendererState();
  }
}

class PerfectPdfRendererState extends State<PerfectPdfRenderer>{
  final Completer<PerfectPdfController> _controller =
  Completer<PerfectPdfController>();

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
        surfaceFactory: (
            BuildContext context,
            PlatformViewController controller,
            ) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        viewType: "perfect_pdf_renderer",
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: 'perfect_pdf_renderer',
          layoutDirection: TextDirection.rtl,
          creationParams: {"filePath": widget.filePath, "fileData": widget.fileData, "defaultPage": widget.defaultPage, "pages": widget.pages},
          creationParamsCodec: const StandardMessageCodec(),
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..addOnPlatformViewCreatedListener((int id) {
            _onPlatformViewCreated(id);
          })
          ..create();
      },
    );
  }

  void _onPlatformViewCreated(int id) {
    final PerfectPdfController controller = PerfectPdfController._(id, widget);
    _controller.complete(controller);
    if (widget.onViewCreated != null) {
      widget.onViewCreated!(controller);
    }
  }
}

class PerfectPdfController {
  PerfectPdfController._(
      int id,
      this._widget,

      ) : _channel = MethodChannel('perfect_pdf_renderer$id') {
    _channel.setMethodCallHandler(_onMethodCall);
  }


  final MethodChannel _channel;
  final PerfectPdfRenderer _widget;


  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPageChanged':
        if (_widget.onPageChanged != null) {
          _widget.onPageChanged!(
              call.arguments['page'], call.arguments['total']);
        }
        return null;
      case 'setCurrentOffsets':
        try{
          List<Object?> offsets = call.arguments['offsets'];
          _widget.setOffsets!(offsets);
        }
        catch (e){
          print(e.toString());
        }
        return null;
      case 'setMaxWidth':
        if (_widget.onMaxWidthSet != null){
          _widget.onMaxWidthSet!(call.arguments['maxWidthInt'] as int);
        }
      case 'endExtraction':
        if (_widget.extractionEnd != null){
          _widget.extractionEnd!();
        }
    }
    throw MissingPluginException(
        '${call.method} was invoked but has no handler');
  }

  Future<bool?> setPage(int page) async {
    final bool? isSet =
    await _channel.invokeMethod('setPage', <String, dynamic>{
      'page': page,
    });
    return isSet;
  }

  Future<bool?> setRects(List<double> rects) async {
    final bool? isSet = await _channel.invokeMethod("setRects", <String, dynamic>{
      'rects': rects
    });
    return isSet;
  }

  Future<bool?> drawLine(List<double> color) async{
    final bool? isDrawn = await _channel.invokeMethod("drawLine", <String, dynamic>{
      'color': color
    });
  }

  Future<bool?> drawRect(List<double> color) async{
    final bool? isDrawn = await _channel.invokeMethod("drawRect", <String, dynamic>{
      'color': color
    });
  }
}