import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/local_data_service.dart';
import '../../services/gamification_service.dart';

class FocusSessionScreen extends StatefulWidget {
  final String subject;
  final int durationMin;

  const FocusSessionScreen({
    super.key,
    required this.subject,
    required this.durationMin,
  });

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  CameraController? _camera;
  FaceDetector? _detector;
  bool _cameraReady = false;
  bool _cameraError = false;
  String _status = 'Requesting camera...';

  int _secondsLeft = 0;
  Timer? _timer;
  Timer? _detectTimer;
  bool _running = false;
  bool _facePresent = true;
  int _awayCount = 0;
  bool _currentlyAway = false;
  List<int> _concentration = []; // per minute: 0 low 1 mid 2 high
  int _faceHitsInMinute = 0;
  int _checksInMinute = 0;
  final _data = LocalDataService();
  final _game = GamificationService();

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationMin * 60;
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _cameraError = true;
          _status = 'Camera permission denied';
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = true;
          _status = 'No camera found';
        });
        return;
      }

      // Prefer front camera
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _camera = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await _camera!.initialize();

      _detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableTracking: true,
        ),
      );

      if (mounted) {
        setState(() {
          _cameraReady = true;
          _status = 'Face detected — ready';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = true;
          _status = 'Camera error: $e';
        });
      }
    }
  }

  Future<void> _checkFace() async {
    if (_camera == null || !_camera!.value.isInitialized || _detector == null) {
      return;
    }
    if (_camera!.value.isTakingPicture) return;

    try {
      final file = await _camera!.takePicture();
      final input = InputImage.fromFilePath(file.path);
      final faces = await _detector!.processImage(input);
      final present = faces.isNotEmpty;

      if (!mounted) return;
      setState(() {
        _facePresent = present;
        _checksInMinute++;
        if (present) _faceHitsInMinute++;
        _status = present
            ? '✅ Face detected — stay focused'
            : '⚠️ No face — look at the camera!';
      });

      if (!present) {
        if (!_currentlyAway) {
          _currentlyAway = true;
          _awayCount++;
          if (_awayCount >= 3) {
            _endSession(success: false);
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Face missing! Warning $_awayCount/3'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        _currentlyAway = false;
      }
    } catch (_) {
      // ignore frame errors
    }
  }

  void _start() {
    setState(() {
      _running = true;
      _awayCount = 0;
      _currentlyAway = false;
      _concentration = [];
      _faceHitsInMinute = 0;
      _checksInMinute = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        _endSession(success: true);
        return;
      }
      setState(() => _secondsLeft--);

      // every minute store concentration based on face presence ratio
      if (_secondsLeft % 60 == 0 && _checksInMinute > 0) {
        final ratio = _faceHitsInMinute / _checksInMinute;
        int level;
        if (ratio >= 0.75) {
          level = 2; // high
        } else if (ratio >= 0.4) {
          level = 1; // mid
        } else {
          level = 0; // low
        }
        _concentration.add(level);
        _faceHitsInMinute = 0;
        _checksInMinute = 0;
      }
    });

    // face check every 3 seconds
    _detectTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkFace();
    });
    _checkFace();
  }

  Future<void> _endSession({required bool success}) async {
    _timer?.cancel();
    _detectTimer?.cancel();

    while (_concentration.length < widget.durationMin) {
      _concentration.add(success ? 1 : 0);
    }

    final record = SessionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: widget.subject,
      durationMin: widget.durationMin,
      success: success,
      date: DateTime.now(),
      concentration: List.from(_concentration),
    );
    await _data.load();
    await _data.addSession(record);

    await _game.load();
    final successCount =
        _data.sessions.where((s) => s.success).length;
    final msgs = await _game.onSessionComplete(
      successCount: successCount,
      success: success,
    );

    if (!mounted) return;
    setState(() => _running = false);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(success ? 'Session Complete 🎉' : 'Session Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(success
                ? 'Great focus on ${widget.subject} for ${widget.durationMin} min!'
                : 'You left the camera 3 times. Session failed.'),
            if (msgs.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...msgs.map((m) => Text(m,
                  style: const TextStyle(color: Color(0xFF6C63FF)))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context, true); // screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _detectTimer?.cancel();
    _camera?.dispose();
    _detector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = _secondsLeft ~/ 60;
    final secs = _secondsLeft % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Session',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _timer?.cancel();
            _detectTimer?.cancel();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              widget.subject,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
            Text('Warnings: $_awayCount / 3',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            // Camera preview
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 280,
                width: double.infinity,
                color: Colors.black,
                child: _cameraReady && _camera != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_camera!),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: (_facePresent
                                        ? Colors.green
                                        : Colors.orange)
                                    .withOpacity(0.85),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _status,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Text(
                          _cameraError ? _status : 'Starting camera...',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Real face detection is active. Keep your face in frame.\nLeave 3 times → session fails.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 24),

            if (!_running)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _cameraReady ? _start : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => _endSession(success: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('End Session Early'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
