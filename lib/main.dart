import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_detection_flutter/frame_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() {
  runApp(const FaceDetectionApp());
}

class FaceDetectionApp extends StatefulWidget {
  const FaceDetectionApp({super.key});

  @override
  State<FaceDetectionApp> createState() => _FaceDetectionAppState();
}

class _FaceDetectionAppState extends State<FaceDetectionApp> {
  CameraController? _cameraController;
  bool _isInitCamera = false;
  FaceDetector? _faceDetector;
  late List<CameraDescription> _cameras;
  Rect? _boundingBox;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((value) async {
      _cameras = await availableCameras();
      FaceDetectorOptions options = FaceDetectorOptions(
        enableTracking: true,
      );
      _faceDetector = FaceDetector(options: options);

      _startLiveFeed();
    });
  }

  @override
  void dispose() {
    _stopLiveFeed();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Face Detection'),
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            if (_isInitCamera) ...[
              Center(
                child: CustomPaint(
                  size: const Size(300,300),
                  foregroundPainter: FramePainter(
                    text: 'Please place your face\ninside this circle',
                    boundingBox: _boundingBox,
                  ),
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        rotation: InputImageRotation.rotation0deg, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  Future _startLiveFeed() async {
    _cameraController = CameraController(
      _cameras.last,
      // Set to ResolutionPreset.high. Do NOT set it to ResolutionPreset.max because for some phones does NOT work.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController?.initialize();
    _isInitCamera = _cameraController!.value.isInitialized;
    if (!mounted) return;

    await _cameraController?.startImageStream(_processCameraImage);

    setState(() {});
  }

  void _processCameraImage(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      return;
    }

    final faces = await _faceDetector?.processImage(inputImage);
    if(faces == null) return;

    setState(() {
      _boundingBox = faces.lastOrNull?.boundingBox;
    });
  }

  Future _stopLiveFeed() async {
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;
  }
}
