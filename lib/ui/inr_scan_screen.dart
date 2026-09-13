/// Kamera ile INR ölçüm cihazı ekranını tarayıp OCR ile değeri otomatik
/// yakalayan ekran.
///
/// Akış: canlı kamera frame'leri -> ML Kit `TextRecognizer` -> ham metin ->
/// `InrOcrService.extractInrValue` (saf regex mantığı) -> eşleşme bulununca
/// kamera durur, sonuç kartı gösterilir, kullanıcı onaylar/yeniden dener.
///
/// Gerekli paketler (pubspec.yaml): camera, google_mlkit_text_recognition.
/// Android: `imageFormatGroup: ImageFormatGroup.nv21`, iOS: `.bgra8888`
/// ML Kit ile uyumludur; `camera` paketi platforma göre otomatik seçer.
library;

import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../l10n/domain_labels.dart';
import '../services/inr_ocr_service.dart';

/// Taranan değeri `Navigator.pop(value)` ile çağırana döndürür
/// (bulunamaz/iptal edilirse `null`).
class InrScanScreen extends StatefulWidget {
  const InrScanScreen({super.key});

  @override
  State<InrScanScreen> createState() => _InrScanScreenState();
}

class _InrScanScreenState extends State<InrScanScreen> {
  CameraController? _controller;
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _ocrService = const InrOcrService();

  bool _isProcessingFrame = false;
  bool _isPaused = false;
  double? _capturedValue;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );

      await controller.initialize();
      if (!mounted) return;

      await controller.startImageStream(_processCameraImage);
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFrame || _isPaused) return;
    _isProcessingFrame = true;

    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;

      final result = await _textRecognizer.processImage(inputImage);
      final value = _ocrService.extractInrValue(result.text);

      if (value != null && mounted) {
        setState(() {
          _capturedValue = value;
          _isPaused = true;
        });
        await _controller?.stopImageStream();
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _controller!.description;
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _retry() {
    setState(() {
      _capturedValue = null;
      _isPaused = false;
    });
    _controller?.startImageStream(_processCameraImage);
  }

  void _confirm() {
    final value = _capturedValue;
    if (value != null) {
      Navigator.of(context).pop(value);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_initError != null)
            _CameraUnavailable(
              detail: _initError!,
              onManualEntry: () => Navigator.of(context).pop(),
            )
          else if (controller != null && controller.value.isInitialized)
            CameraPreview(controller)
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    loc.l10n.cameraPreparing,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          // Nişangah yalnızca canlı önizleme varken anlamlı.
          if (_initError == null) const _ScanOverlay(),
          if (_capturedValue != null)
            _ResultCard(
              value: _capturedValue!,
              onConfirm: _confirm,
              onRetry: _retry,
            ),
          Positioned(
            top: 48,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kamera açılamadığında (izin yok, simülatör, donanım hatası) gösterilir.
/// Kullanıcı çıkmaza düşmesin diye elle girişe yönlendirir.
class _CameraUnavailable extends StatelessWidget {
  final String detail;
  final VoidCallback onManualEntry;

  const _CameraUnavailable({required this.detail, required this.onManualEntry});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                size: 56, color: Colors.white70),
            const SizedBox(height: 20),
            Text(
              loc.l10n.cameraFailedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              loc.l10n.cameraFailedMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onManualEntry,
              icon: const Icon(Icons.keyboard),
              label: const Text('Elle gir'),
            ),
            const SizedBox(height: 20),
            // Teknik ayrıntı, hata bildirimi için görünür ama öne çıkmaz.
            Text(
              detail,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white70, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final double value;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  const _ResultCard({
    required this.value,
    required this.onConfirm,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${value.toStringAsFixed(1)} INR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: onRetry,
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600),
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Onayla'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
