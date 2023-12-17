import 'dart:collection';
import 'package:clipboard/clipboard.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:perfect_pdf_renderer/PerfectPdfRenderer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';

class PdfScreen extends StatefulWidget {
  final int? currentPage;
  final String filePath;
  final PageChangedCallback? onPageChanged;

  @override
  _PdfScreenState createState() => _PdfScreenState();
  PdfScreen({super.key, required this.filePath,this.currentPage, this.onPageChanged});
}

class _PdfScreenState extends State<PdfScreen> {
  late PerfectPdfController _controller;
  int page = 0;
  int handleMargin = 50;
  final HashMap<int, List<TextLine>> cache = HashMap();
  late PdfDocument document;
  late PdfTextExtractor extractor;
  List<List<double>> offsets = List.empty();
  bool isExtraction = false;
  double screenWidth = 0;
  double screenHeight = 0;
  double opacity = 0;
  double x1 = 0;
  double x2 = 0;
  double y1 = 0;
  double y2 = 0;
  bool isCharFull1 = false;
  bool isCharFull2 = false;
  bool isExchanged = false;
  double handleWidth = 30;
  double handleHeight = 30;
  double initZoom = 1.0;
  int fromPage1 = 0;
  int fromLine1 = 0;
  int fromLine2 = 0;
  int fromWord1 = 0;
  int fromWord2 = 0;
  int fromChar1 = 0;
  int fromChar2 = 0;
  bool isDragging = false;
  double draggingX = 0;
  double draggingY = 0;

  @override
  void initState() {
    document = PdfDocument(inputBytes: File(widget.filePath).readAsBytesSync());
    extractor = PdfTextExtractor(document);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    page = widget.currentPage ?? 0;
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: Colors.black.withOpacity(opacity),
        appBar: isExtraction ? AppBar(
          actions: [
            IconButton(onPressed: (){
              FlutterClipboard.copy(getText());
            }, icon: const Icon(Icons.ac_unit)),
          ],
        ) : null,
        body: GestureDetector(
          onLongPressStart: (details){
            double x = details.globalPosition.dx;
            double y = details.globalPosition.dy;

            if (!setInitHandlePosition(x, y)){
              return;
            }

            setState(() {
              isExtraction = true;
            });
          },
          child: Stack(
              children: [PerfectPdfRenderer(
                filePath: widget.filePath,
                defaultPage: widget.currentPage ?? 0,
                pages: document.pages.count,
                onMaxWidthSet: (int maxWidthInt){
                  this.initZoom = screenWidth/document.pages[maxWidthInt].size.width;
                },
                extractionEnd: (){
                  isExtraction = false;
                },
                setOffsets: (List<Object?> yOffsets){
                  this.offsets = List.filled(yOffsets.length, List.empty());
                  double ratio = MediaQuery.of(context).devicePixelRatio;
                  for (int i = 0; i < yOffsets.length; i++){
                    List<Object?> array1 = (yOffsets[i] as List<Object?>);
                    List<double> array = List.filled(array1.length, 0);

                    for (int j = 0; j < array1.length; j++){
                      if (j < 2){
                        array[j] = (array1[j] as double)/ratio;
                      }
                      else{
                        array[j] = array1[j] as double;
                      }
                    }

                    if (array.length == 2) {
                      if (i != offsets.length - 1) {
                        x1 = array[0];
                        y1 = array[1];
                      }
                      else {
                        x2 = array[0];
                        y2 = array[1];
                      }

                      setState(() {
                      });
                      continue;
                    }
                    offsets[i] = array;
                  }
                },
                onPageChanged: widget.onPageChanged,
                onViewCreated: (PerfectPdfController controller){
                  _controller = controller;
                },
              ),
                isExtraction ?
                Positioned(
                    left: isExchanged ? x1-handleMargin/2 : x1-handleWidth-handleMargin/2,
                    top: y1-handleMargin/2,
                    child:
                    GestureDetector(
                      onPanUpdate: (details){
                        draggingX += details.delta.dx;
                        draggingY += details.delta.dy;
                        recalculate(1);
                      },
                      onPanStart: (details){
                        draggingX = x1;
                        draggingY = y1;
                      },
                      child: Container(
                          height:handleHeight+handleMargin,
                          width: handleWidth+handleMargin,
                          color: Colors.transparent
                      ),
                    )
                ) :
                const SizedBox(
                    width: 0,
                    height: 0
                ),
                isExtraction ?
                Positioned(
                  left: isExchanged ? x2-handleWidth-handleMargin/2 : x2-handleMargin/2,
                  top: y2-handleMargin/2,
                  child: GestureDetector(
                    onPanUpdate: (details){
                      draggingX += details.delta.dx;
                      draggingY += details.delta.dy;
                      recalculate(2);
                    },
                    onPanStart: (details){
                      draggingX = x2;
                      draggingY = y2;
                    },
                    child: Container(
                        height:handleHeight+handleMargin,
                        width: handleWidth+handleMargin,
                        color: Colors.transparent
                    ),
                  ),
                ) :
                const SizedBox(
                    width: 0,
                    height: 0
                ),
              ]
          ),
        )
    );
  }

  bool setInitHandlePosition(double x, double y){
    int page = 0;
    int pageInd = 0;
    for (int i = 0; i < offsets.length-2; i ++){
      if (i == offsets.length - 3 || y > offsets[i][0] && y <= offsets[i+1][0]){
        page = offsets[i][2].round();
        pageInd = i;
        cache[page] = extractor.extractTextLines(startPageIndex: page, endPageIndex: page);
        break;
      }
    }

    List<TextLine> textLines = cache[page]!;
    TextLine textLine = textLines[0];
    double right = 0;
    double left = 0;
    double bottom = 0;
    double top = 0;

    for (int j = 0; j < textLines.length; j ++) {
      textLine = textLines[j];
      right = min(textLine.bounds.right * offsets[0][3] * initZoom + offsets[pageInd][1], screenWidth);
      left = max(textLine.bounds.left * offsets[0][3] * initZoom + offsets[pageInd][1], 0);
      top = max(textLine.bounds.top * offsets[0][3] * initZoom + offsets[pageInd][0], 0);
      bottom = min(textLine.bounds.bottom * offsets[0][3] * initZoom + offsets[pageInd][0], screenHeight);

      if (left <= x && x <= right && y >= top && y <= bottom){
        fromLine1 = j;
        fromLine2 = j;
        break;
      }

      if (j == textLines.length - 1){
        return false;
      }
    }

    TextWord word;
    List<TextWord> words = textLine.wordCollection;

    for (int j = 0; j < words.length; j++){
      word = words[j];
      right = min(word.bounds.right * offsets[0][3] * initZoom + offsets[pageInd][1], screenWidth);
      left = max(word.bounds.left * offsets[0][3] * initZoom + offsets[pageInd][1], 0);
      top = max(word.bounds.top * offsets[0][3] * initZoom + offsets[pageInd][0], 0);
      bottom = min(word.bounds.bottom * offsets[0][3] * initZoom + offsets[pageInd][0], screenHeight);

      if (left <= x && x <= right && y >= top && y <= bottom){
        fromWord1 = j;
        fromWord2 = j;
        fromChar1 = 0;
        fromChar2 = word.glyphs.length - 1;
        break;
      }

      if (j == words.length - 1){
        return false;
      }
    }

    fromPage1 = page;
    x1 = left;
    y1 = bottom;
    x2 = right;
    y2 = bottom;
    isCharFull1 = true;
    isCharFull2 = true;
    setState(() {

    });
    calculateRects();
    return true;
  }

  void recalculate(int handle){
    double prevX = 0;
    double prevY = 0;
    int prevPage = 0;
    int prevLine = 0;
    int prevWord = 0;
    int prevChar = 0;
    double prevXOffset = 0;
    double prevYOffset = 0;
    double prevX1 = 0;
    double prevY1 = 0;

    if ((handle == 1 && !isExchanged) || (handle == 2 && isExchanged)){
      prevPage = fromPage1;
      prevLine = fromLine1;
      prevWord = fromWord1;
      prevChar = fromChar1;
    }
    else{
      prevPage = fromPage1;
      prevLine = fromLine2;
      prevWord = fromWord2;
      prevChar = fromChar2;
    }

    if (handle == 1){
      int page = findPage(fromPage1);
      prevXOffset = offsets[page][1];
      prevYOffset = offsets[page][0];
      prevX = (x1-prevXOffset)/(initZoom*offsets[0][3]);
      prevY = (y1-prevYOffset)/(initZoom*offsets[0][3]) - (cache[prevPage]![prevLine].bounds.height)/2;
      prevX1 = x1;
      prevY1 = y1;
    }
    else{
      int page = findPage(fromPage1);
      prevXOffset = offsets[page][1];
      prevYOffset = offsets[page][0];
      prevX = (x2-prevXOffset)/(initZoom*offsets[0][3]);
      prevY = (y2-prevYOffset)/(initZoom*offsets[0][3]) - (cache[prevPage]![prevLine].bounds.height)/2;
      prevX1 = x2;
      prevY1 = y2;
    }

    double draggingX = (this.draggingX-prevXOffset)/(initZoom*offsets[0][3]);
    double draggingY = (this.draggingY-prevYOffset)/(initZoom*offsets[0][3]) - (cache[prevPage]![prevLine].bounds.height)/2;
    List<TextLine> textLines = cache[prevPage]!;
    int left = prevLine - 1;
    int right = prevLine + 1;
    double diffY = (prevY - draggingY).abs();
    bool isLeft = true;
    bool isLineFound = false;

    while (left >= 0 || right < textLines.length){
      int current = 0;
      if ((isLeft && left >= 0) || right == textLines.length){
        isLeft = false;
        current = left;
        left -= 1;
      }
      else{
        isLeft = true;
        current = right;
        right += 1;
      }

      if ((textLines[current].bounds.top+(cache[prevPage]![current].bounds.height)/2 - draggingY).abs() <= diffY && doLinesIntersectY(textLines[prevLine], textLines[current])){
        isLineFound = true;
        if (handle == 1){
          y1 = textLines[current].bounds.bottom*initZoom*offsets[0][3]+prevYOffset;
        }
        else{
          y2 = textLines[current].bounds.bottom*initZoom*offsets[0][3]+prevYOffset;
        }
        if ((handle == 1 && !isExchanged) || (handle == 2 && isExchanged)){
          prevLine = current;
          break;
        }
        else{
          prevLine = current;
          break;
        }
      }
    }

    if (!isLineFound && textLines[prevLine].bounds.left > draggingX){
      for (int i = 0; i < textLines.length; i++){
        if (textLines[prevLine].bounds.left - draggingX > (textLines[i].bounds.right-draggingX).abs() && doLinesIntersectX(textLines[prevLine], textLines[i])){
          prevLine = i;
        }
      }
    }
    else if (!isLineFound && textLines[prevLine].bounds.right < draggingX){
      for (int i = 0; i < textLines.length; i++){
        if (draggingX - textLines[prevLine].bounds.left > (textLines[i].bounds.left-draggingX).abs() && doLinesIntersectX(textLines[prevLine], textLines[i])){
          prevLine = i;
        }
      }
    }

    if (handle == 1){
      y1 = textLines[prevLine].bounds.bottom*initZoom*offsets[0][3]+prevYOffset;
    }
    else{
      y2 = textLines[prevLine].bounds.bottom*initZoom*offsets[0][3]+prevYOffset;
    }

    if ((handle == 1 && !isExchanged) || (handle == 2 && isExchanged)){
      fromLine1 = prevLine;
    }
    else{
      fromLine2 = prevLine;
    }

    List<TextWord> words = textLines[prevLine].wordCollection;
    bool isWordFound = false;
    double differ = 0;
    double current = 0;

    for (int i = 0; i < words.length; i++){
      if (words[i].bounds.left < draggingX && draggingX <= words[i].bounds.right) {
        isWordFound = true;
        if ((handle == 1 && !isExchanged) || (handle == 2 && isExchanged)) {
          prevWord = i;
          fromWord1 = i;
        }
        else {
          fromWord2 = i;
          prevWord = i;
        }
        break;
      }
      current = min((draggingX-words[i].bounds.left).abs(), (draggingX-words[i].bounds.right).abs());
      if (i == 0){
        differ = current;
        prevWord = i;
      }
      else if(current<differ){
        differ = current;
        prevWord = i;
      }
    }

    if (isWordFound){
      List<TextGlyph> glyphs = words[prevWord].glyphs;

      for (int i = 0; i < glyphs.length; i++){
        prevChar = i;
        if (glyphs[i].bounds.left < draggingX && draggingX <= glyphs[i].bounds.right){
          break;
        }
      }

      if (prevX>draggingX){
        if (handle == 1){
          x1 = glyphs[prevChar].bounds.right*initZoom*offsets[0][3]+prevXOffset;
        }
        else{
          x2 = glyphs[prevChar].bounds.right*initZoom*offsets[0][3]+prevXOffset;
        }

        if ((handle == 1 && !isExchanged) || (handle == 2 && isExchanged)){
          fromChar1 = prevChar;
          isCharFull1 = false;
        }
        else{
          fromChar2 = prevChar;
          isCharFull2 = true;
        }
      }

      if (prevX<draggingX){
        if ((handle == 1 && !isExchanged) || (handle == 2 && isExchanged)){
          fromChar1 = prevChar;
          isCharFull1 = true;
        }
        else{
          fromChar2 = prevChar;
          isCharFull2 = false;
        }

        if (handle == 1){
          x1 = glyphs[prevChar].bounds.left*initZoom*offsets[0][3]+prevXOffset;
        }
        else{
          x2 = glyphs[prevChar].bounds.left*initZoom*offsets[0][3]+prevXOffset;
        }
      }
    }
    else{
      double leftDiff = (words[prevWord].bounds.left - draggingX).abs();
      double rightDiff = (words[prevWord].bounds.right - draggingX).abs();
      List<TextGlyph> glyphs = words[prevWord].glyphs;

      if (leftDiff <= rightDiff){
        prevChar = 0;
      }
      else{
        prevChar = words[prevWord].glyphs.length - 1;
      }

      if (prevChar == 0){
        if ((handle == 1 && !isExchanged) || (handle == 2 && isExchanged)){
          fromChar1 = prevChar;
          isCharFull1 = true;
          fromWord1 = prevWord;
        }
        else{
          fromChar2 = prevChar;
          fromWord2 = prevWord;
          isCharFull2 = false;
        }
      }
      else{
        if ((handle == 1 && !isExchanged) || (handle == 2 && isExchanged)){
          fromWord1 = prevWord;
          fromChar1 = prevChar;
          isCharFull1 = false;
        }
        else{
          fromChar2 = prevChar;
          fromWord2 = prevWord;
          isCharFull2 = true;
        }
      }

      if (handle == 1){
        x1 = glyphs[prevChar].bounds.left*initZoom*offsets[0][3]+prevXOffset;
      }
      else{
        x2 = glyphs[prevChar].bounds.left*initZoom*offsets[0][3]+prevXOffset;
      }
    }

    int v = 0;

    if (fromLine2 < fromLine1 || (fromLine1 == fromLine2 && fromWord2 < fromWord1) || (fromLine1 == fromLine2 && fromWord1 == fromWord2 && fromChar2 <= fromChar1)){
      v = fromChar1;
      fromChar1 = fromChar2;
      fromChar2 = v;
      isExchanged = !isExchanged;
    }

    if (fromLine2 < fromLine1 || (fromLine1 == fromLine2 && fromWord2 < fromWord1)){
      v = fromWord1;
      fromWord1 = fromWord2;
      fromWord2 = v;
    }

    if (fromLine2 < fromLine1){
      v = fromLine1;
      fromLine1 = fromLine2;
      fromLine2 = v;
    }

    if (handle == 1 && (prevX1 != x1 || prevY1 != y1)){
      setState(() {
        this.draggingY = y1;
        this.draggingX = x1;
        calculateRects();
      });
    }
    else if (handle == 2 && (prevX1 != x2 || prevY1 != y2)) {
      setState(() {
        this.draggingY = y2;
        this.draggingX = x2;
        calculateRects();
      });
    }
  }

  int findPage(int page){
    int output = 0;

    for (int i = 0; i < offsets.length-2; i++){
      if (offsets[i][2].round() == page){
        output = i;
        break;
      }
    }

    return output;
  }

  bool doLinesIntersectY(TextLine line1, TextLine line2){
    double totalWidth = line1.bounds.width+line2.bounds.width;

    if (totalWidth > (line1.bounds.left - line2.bounds.right).abs() && totalWidth > (line2.bounds.left - line1.bounds.right).abs()){
      return true;
    }

    return false;
  }

  void calculateRects(){
    double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    List<double> rects = List.filled(4*(fromLine2-fromLine1+1)+1, 0);
    List<TextLine> textLines = cache[fromPage1]!;
    double left, top, right, bottom;
    rects[0] = fromPage1.toDouble();
    int ind = 1;

    if (fromLine2 - fromLine1 + 1 >= 2){
      left = isCharFull1 ? textLines[fromLine1].wordCollection[fromWord1].glyphs[fromChar1].bounds.left : textLines[fromLine1].wordCollection[fromWord1].glyphs[fromChar1].bounds.right;
      right = textLines[fromLine1].bounds.right;
      top = textLines[fromLine1].bounds.top;
      bottom = textLines[fromLine1].bounds.bottom;
      rects[ind++] = left*devicePixelRatio*initZoom;
      rects[ind++] = top*devicePixelRatio*initZoom;
      rects[ind++] = right*devicePixelRatio*initZoom;
      rects[ind++] = bottom*devicePixelRatio*initZoom;
      for (int j = fromLine1+1; j < fromLine2; j ++){
        TextLine textLine = textLines[j];
        right = textLine.bounds.right;
        left = textLine.bounds.left;
        top = textLine.bounds.top;
        bottom = textLine.bounds.bottom;
        rects[ind++] = left*devicePixelRatio*initZoom;
        rects[ind++] = top*devicePixelRatio*initZoom;
        rects[ind++] = right*devicePixelRatio*initZoom;
        rects[ind++] = bottom*devicePixelRatio*initZoom;
      }
      right = isCharFull2 ? textLines[fromLine2].wordCollection[fromWord2].glyphs[fromChar2].bounds.right : textLines[fromLine2].wordCollection[fromWord2].glyphs[fromChar2].bounds.left;
      left = textLines[fromLine2].bounds.left;
      top = textLines[fromLine2].bounds.top;
      bottom = textLines[fromLine2].bounds.bottom;
      rects[ind++] = left*devicePixelRatio*initZoom;
      rects[ind++] = top*devicePixelRatio*initZoom;
      rects[ind++] = right*devicePixelRatio*initZoom;
      rects[ind++] = bottom*devicePixelRatio*initZoom;
    }

    if (fromLine1 == fromLine2){
      left = isCharFull1 ? textLines[fromLine1].wordCollection[fromWord1].glyphs[fromChar1].bounds.left : textLines[fromLine1].wordCollection[fromWord1].glyphs[fromChar1].bounds.right;
      right = isCharFull2 ? textLines[fromLine2].wordCollection[fromWord2].glyphs[fromChar2].bounds.right : textLines[fromLine2].wordCollection[fromWord2].glyphs[fromChar2].bounds.left;
      top = textLines[fromLine1].bounds.top;
      bottom = textLines[fromLine1].bounds.bottom;
      rects[ind++] = left*devicePixelRatio*initZoom;
      rects[ind++] = top*devicePixelRatio*initZoom;
      rects[ind++] = right*devicePixelRatio*initZoom;
      rects[ind++] = bottom*devicePixelRatio*initZoom;
    }

    _controller.setRects(rects);
  }

  bool doLinesIntersectX(TextLine line1, TextLine line2){
    double totalHeight = line1.bounds.height+line2.bounds.height;

    if (totalHeight > (line1.bounds.top-line2.bounds.bottom).abs() && totalHeight > (line2.bounds.bottom-line1.bounds.top)){
      return true;
    }

    return false;
  }

  double getDiffX(double x, TextLine line){
    return min((line.bounds.left-x).abs(), (line.bounds.right-x).abs());
  }

  double getDist(double x, double y, TextLine line){
    return (line.bounds.centerLeft.dy - y).abs() + (line.bounds.topCenter.dx - x).abs();
  }

  String getText(){
    String extractedText = "";
    List<TextLine> textlines = cache[fromPage1]!;
    List<TextWord> words1 = textlines[fromLine1].wordCollection;
    List<TextWord> words2 = textlines[fromLine2].wordCollection;
    List<TextGlyph> glyphs1 = textlines[fromLine1].wordCollection[fromWord1].glyphs;
    List<TextGlyph> glyphs2 = textlines[fromLine2].wordCollection[fromWord2].glyphs;

    for (int i = 0; i < glyphs1.length; i++){
      if (i == 0 && !isCharFull1){
        continue;
      }

      extractedText += glyphs1[i].text;
    }

    if (fromLine1 == fromLine2){
      for (int i = fromWord1+1; i < fromWord2-1; i++){
        extractedText += words1[i].text;
      }
    }
    else{
      for (int i = fromWord1+1; i < words1.length; i++){
        extractedText += words1[i].text;
      }
      extractedText += "\n";

      for (int i = fromLine1+1; i < fromLine2-1; i++){
        extractedText += textlines[i].text;
        extractedText += "\n";
      }

      for (int i = 0; i < fromWord2-1; i++){
        extractedText += words2[i].text;
      }
    }

    for (int i = 0; i < glyphs2.length; i++){
      if (i == glyphs2.length && !isCharFull1){
        continue;
      }

      extractedText += glyphs2[i].text;
    }

    return extractedText;
  }
}