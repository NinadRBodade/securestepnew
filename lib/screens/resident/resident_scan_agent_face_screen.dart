import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import '../../utils/constants.dart';
import '../../services/face_recognition_service.dart';
import '../../services/mock_data_service.dart';
import 'agent_verification_result_screen.dart';

class ResidentScanAgentFaceScreen extends StatefulWidget {
  const ResidentScanAgentFaceScreen({super.key});

  @override
  State<ResidentScanAgentFaceScreen> createState() => _ResidentScanAgentFaceScreenState();
}

class _ResidentScanAgentFaceScreenState extends State<ResidentScanAgentFaceScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  
  final FaceRecognitionService _faceRecognitionService = FaceRecognitionService();
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Ask agent to position their face in the frame';
  bool _faceDetected = false;
  int? _matchScore;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Camera initialization failed';
      });
    }
  }

  Future<void> _captureAndVerifyAgent() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Scanning for registered agent...';
    });

    try {
      // Capture image
      final image = await _cameraController!.takePicture();
      
      // Detect face in captured image
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        setState(() {
          _statusMessage = 'No face detected. Please try again.';
          _faceDetected = false;
          _isProcessing = false;
        });
        return;
      }

      if (faces.length > 1) {
        setState(() {
          _statusMessage = 'Multiple faces detected. Please ensure only one person.';
          _faceDetected = false;
          _isProcessing = false;
        });
        return;
      }

      // Get all registered agents
      final agents = MockDataService().getAllAgents();
      
      if (agents.isEmpty) {
        setState(() {
          _statusMessage = 'No registered agents found';
          _isProcessing = false;
        });
        _showErrorDialog('No Agents', 'No agents have registered in the system yet.');
        return;
      }

      print('🔍 Starting face verification against ${agents.length} agents...');

      // Try to match with each registered agent
      int bestScore = 0;
      String? bestMatchEmail;
      
      for (var agent in agents) {
        print('🔎 Checking against agent: ${agent.email}');
        final score = await _faceRecognitionService.verifyFace(
          capturedImagePath: image.path,
          userType: 'agent',
          userEmail: agent.email,
        );
        
        print('   Score for ${agent.email}: $score%');
        
        if (score > bestScore) {
          bestScore = score;
          bestMatchEmail = agent.email;
        }
      }

      print('🎯 Best match: $bestMatchEmail with score: $bestScore%');

      setState(() {
        _matchScore = bestScore;
        _faceDetected = true;
        _isProcessing = false;
      });

      // Clean up captured image
      final capturedFile = File(image.path);
      if (await capturedFile.exists()) {
        await capturedFile.delete();
      }

      // Navigate to result screen if agent found
      if (bestScore >= 70 && bestMatchEmail != null) {
        final matchedAgent = agents.firstWhere((a) => a.email == bestMatchEmail);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AgentVerificationResultScreen(
                agentData: matchedAgent.toMap(),
              ),
            ),
          );
        }
      } else {
        _showNotRecognizedDialog(bestScore);
      }
      
    } catch (e) {
      print('❌ Face verification error: $e');
      setState(() {
        _statusMessage = 'Error verifying face. Please try again.';
        _faceDetected = false;
        _isProcessing = false;
      });
    }
  }

  void _showNotRecognizedDialog(int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Agent Not Recognized'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Score: $score%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This person is not a registered agent in the system.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Do not allow entry',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Actions you can take:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Ask for QR code verification'),
            Text('• Request ID card'),
            Text('• Contact security'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Report Issue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Agent Face'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isInitialized
          ? Stack(
              children: [
                // Camera preview
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),
                
                // Face frame overlay
                _buildFaceFrameOverlay(),
                
                // Status message
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _faceDetected && _matchScore != null
                          ? (_matchScore! >= 70 ? Colors.green : Colors.red)
                          : Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                // Scan button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _isProcessing
                        ? CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                            onPressed: _captureAndVerifyAgent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.face_unlock_outlined, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Scan Face',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                
                // Instructions
                Positioned(
                  bottom: 120,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to verify agent:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildInstruction('Ask agent to look at camera'),
                        _buildInstruction('Ensure face is well lit'),
                        _buildInstruction('Keep face centered in frame'),
                        _buildInstruction('System will match with registered agents'),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceFrameOverlay() {
    return CustomPaint(
      painter: FaceFramePainter(faceDetected: _faceDetected, matchScore: _matchScore),
      child: Container(),
    );
  }
}

class FaceFramePainter extends CustomPainter {
  final bool faceDetected;
  final int? matchScore;
  
  FaceFramePainter({required this.faceDetected, this.matchScore});
  
  @override
  void paint(Canvas canvas, Size size) {
    Color frameColor;
    if (matchScore != null) {
      frameColor = matchScore! >= 70 ? Colors.green : Colors.red;
    } else {
      frameColor = faceDetected ? Colors.yellow : Colors.white;
    }
    
    final paint = Paint()
      ..color = frameColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 50),
      width: size.width * 0.7,
      height: size.height * 0.5,
    );

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(20));
    canvas.drawRRect(rrect, paint);

    // Draw corners
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = frameColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + cornerLength), Offset(rect.left, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + cornerLength, rect.top), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(rect.right - cornerLength, rect.top), Offset(rect.right, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - cornerLength), Offset(rect.left, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + cornerLength, rect.bottom), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(rect.right - cornerLength, rect.bottom), Offset(rect.right, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
