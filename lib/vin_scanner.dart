import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class VinScannerScreen extends StatefulWidget {
  const VinScannerScreen({super.key});
  @override
  State<VinScannerScreen> createState() => _VinScannerScreenState();
}

class _VinScannerScreenState extends State<VinScannerScreen> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);
    await _controller?.initialize();
    if (!mounted) return;
    setState(() {});
    _controller?.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isScanning) return;
    _isScanning = true;
    try {
      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation90deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
      final recognizedText = await _textRecognizer.processImage(inputImage);
      RegExp vinRegex = RegExp(r'[A-HJ-NPR-Z0-9]{17}');

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String text = line.text.replaceAll(' ', '').toUpperCase();
          if (vinRegex.hasMatch(text)) {
            _controller?.stopImageStream();
            if (mounted) Navigator.pop(context, vinRegex.stringMatch(text));
            return;
          }
        }
      }
    } catch (_) {}
    _isScanning = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Center(child: Container(width: 320, height: 80, decoration: BoxDecoration(border: Border.all(color: Colors.cyan, width: 3), borderRadius: BorderRadius.circular(12)))),
          const Positioned(bottom: 40, left: 0, right: 0, child: Text('Наведіть рамку на VIN-код', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, backgroundColor: Colors.black54)))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }
}