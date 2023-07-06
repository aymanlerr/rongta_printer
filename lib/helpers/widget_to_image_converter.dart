import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const double _kDefaultWidth = 500.0;
const double _kDefaultHeight = 3000.0;

Future<Uint8List> createImageFromWidget(
  Widget widget, {
  double docWidth = _kDefaultWidth,
  double docHeight = _kDefaultHeight,
}) async {
  final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

  final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

  final RenderObjectToWidgetElement<RenderBox> rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: IntrinsicHeight(
        child: IntrinsicWidth(
          child: Container(
            color: Colors.white,
            child: widget,
          ),
        ),
      ),
    ),
  ).attachToRenderTree(buildOwner);

  buildOwner
    ..buildScope(rootElement)
    ..finalizeTree();

  final RenderView renderView = RenderView(
    window: WidgetsBinding.instance.window,
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: repaintBoundary,
    ),
    configuration: ViewConfiguration(
      size: Size(docWidth, docHeight),
      devicePixelRatio: ui.window.devicePixelRatio,
    ),
  );

  final PipelineOwner pipelineOwner = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();

  pipelineOwner
    ..flushLayout()
    ..flushCompositingBits()
    ..flushPaint();

  ui.Image image = await repaintBoundary.toImage(pixelRatio: ui.window.devicePixelRatio);
  ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  Uint8List? result = byteData?.buffer.asUint8List();

  return result!;
}
