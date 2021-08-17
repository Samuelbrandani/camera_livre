import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:camera/camera.dart';
import 'package:camera_livre/base_page_minix.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';

class CameraExampleHome extends StatefulWidget {
  @override
  _CameraExampleHomeState createState() {
    return _CameraExampleHomeState();
  }
}

void logError(String code, String? message) {
  if (message != null) {
    print('Error: $code\nError Message: $message');
  } else {
    print('Error: $code');
  }
}

class _CameraExampleHomeState extends State<CameraExampleHome> with WidgetsBindingObserver, TickerProviderStateMixin, BasePage {
  CameraController? controller;

  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  int _pointers = 0;

  @override
  void initState() {
    super.initState();
    _ambiguate(WidgetsBinding.instance)?.addObserver(this);
  }

  @override
  void dispose() {
    _ambiguate(WidgetsBinding.instance)?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      key: _scaffoldKey,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.loose,
          children: <Widget>[
            Column(
              children: [
                Container(
                  child: Expanded(
                    child: Container(
                      child: Center(
                        child: _cameraPreviewWidget(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              child: Container(
                height: 100,
                width: MediaQuery.of(context).size.width,
                color: Color.fromRGBO(0, 0, 0, .75),
              ),
            ),
            Positioned(
              top: 0,
              child: Container(
                height: 100,
                width: MediaQuery.of(context).size.width,
                color: Color.fromRGBO(0, 0, 0, .75),
              ),
            ),
            Positioned(
              top: 25,
              left: 20,
              child: IconButton(
                color: Colors.white,
                icon: Icon(Icons.arrow_back_ios_new),
                onPressed: () {},
              ),
            ),
            Positioned(
              bottom: 25,
              right: 20,
              child: _iconsCamera(),
            ),
            Positioned(
              bottom: 32,
              child: _captureControlRowWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconsCamera() {
    return Container(
      child: IconButton(
        icon: Icon(
          Icons.cameraswitch_outlined,
          color: Colors.white,
        ),
        color: Colors.white,
        onPressed: () {
          CameraLensDirection back = CameraLensDirection.back;
          CameraLensDirection front = CameraLensDirection.front;
          for (CameraDescription cameraDescription in cameras) {
            if (cameraDescription.lensDirection == back && controller?.description.lensDirection == front) {
              onNewCameraSelected(cameraDescription);
              return;
            } else if (cameraDescription.lensDirection == front && controller?.description.lensDirection == back) {
              onNewCameraSelected(cameraDescription);
              return;
            }
          }
        },
      ),
    );
  }

  Widget _cameraPreviewWidget() {
    CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return InkWell(
        onTap: () {
          for (CameraDescription cameraDescription in cameras) {
            if (cameraDescription.lensDirection == CameraLensDirection.back) {
              onNewCameraSelected(cameraDescription);
              return;
            }
          }
        },
        child: Center(
          child: Text(
            'Toque para ligar a camera',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          controller!,
          child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapDown: (details) => onViewFinderTap(details, constraints),
            );
          }),
        ),
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  Widget _captureControlRowWidget() {
    final CameraController? cameraController = controller;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        InkWell(
          child: Container(
            child: CircularProgressIndicator(
              value: 100,
              color: Colors.white,
            ),
          ),
          onTap: cameraController != null && cameraController.value.isInitialized && !cameraController.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
      ],
    );
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final CameraController cameraController = controller!;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    controller = cameraController;

    cameraController.addListener(() {
      if (mounted) setState(() {});
      if (cameraController.value.hasError) {
        showInSnackBar('Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait([
        cameraController.getMaxZoomLevel().then((value) => _maxAvailableZoom = value),
        cameraController.getMinZoomLevel().then((value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((XFile? file) {
      if (mounted) {
        if (file != null) showInSnackBar('Picture saved to ${file.path}');
      }
    });
  }

  Future<XFile?> takePicture() async {
    this.showLoading();
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      this.hideLoading();
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      this.hideLoading();
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      await GallerySaver.saveImage(file.path);
      this.hideLoading();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      this.hideLoading();
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: BotToastInit(),
      debugShowCheckedModeBanner: false,
      home: CameraExampleHome(),
      navigatorObservers: [BotToastNavigatorObserver()],

    );
  }
}

List<CameraDescription> cameras = [];

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(CameraApp());
}

T? _ambiguate<T>(T? value) => value;
