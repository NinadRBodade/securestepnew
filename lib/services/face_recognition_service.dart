import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:convert';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// Verify if a captured face matches a registered person's face
  /// Uses BACKEND verification for accurate face matching
  /// [capturedImagePath] - Path to the just captured face image
  /// [userType] - 'agent' or 'resident'
  /// [userEmail] - Email of the person to verify against
  /// Returns a match score from 0-100
  Future<int> verifyFaceWithBackend({
    required String capturedImagePath,
    required String userEmail,
  }) async {
    try {
      print('🔍 Verifying face using backend for: $userEmail');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/api/face/verify'),
      );
      
      request.fields['email'] = userEmail;
      request.files.add(await http.MultipartFile.fromPath(
        'capturedImage',
        capturedImagePath,
      ));
      
      print('📤 Sending verification request...');
      var response = await request.send().timeout(Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();
      
      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: $responseBody');
      
      if (response.statusCode == 200) {
        final result = json.decode(responseBody);
        final matchScore = result['matchScore'] ?? 0;
        print('✅ Backend verification complete - Score: $matchScore');
        return matchScore;
      } else {
        print('❌ Backend verification failed: $responseBody');
        return 0;
      }
    } catch (e) {
      print('❌ Backend verification error: $e');
      return 0;
    }
  }

  /// Verify if a captured face matches a registered person's face
  /// [capturedImagePath] - Path to the just captured face image
  /// [userType] - 'agent' or 'resident'
  /// [userEmail] - Email of the person to verify against
  /// Returns a match score from 0-100
  Future<int> verifyFace({
    required String capturedImagePath,
    required String userType,
    required String userEmail,
  }) async {
    try {
      // Use backend verification instead of ML Kit
      return await verifyFaceWithBackend(
        capturedImagePath: capturedImagePath,
        userEmail: userEmail,
      );
    } catch (e) {
      print('Error verifying face: $e');
      return 0;
    }
  }

  /// OLD METHOD - Uses ML Kit (not reliable for face matching)
  Future<int> verifyFaceLocal({
    required String capturedImagePath,
    required String userType,
    required String userEmail,
  }) async {
    try {
      // Get all registered face images for this user
      final registeredFaces = await _getRegisteredFaces(userType, userEmail);
      
      if (registeredFaces.isEmpty) {
        return 0; // No registered face found
      }

      // Detect face in captured image
      final capturedImage = InputImage.fromFilePath(capturedImagePath);
      final capturedFaces = await _faceDetector.processImage(capturedImage);
      
      if (capturedFaces.isEmpty) {
        return 0; // No face in captured image
      }

      final capturedFace = capturedFaces.first;
      
      // Compare with each registered face and get the best match
      int bestScore = 0;
      
      for (String registeredPath in registeredFaces) {
        final score = await _compareFaces(capturedFace, capturedImagePath, registeredPath);
        if (score > bestScore) {
          bestScore = score;
        }
      }
      
      return bestScore;
      
    } catch (e) {
      print('Error verifying face: $e');
      return 0;
    }
  }

  /// Download face from backend if not available locally
  Future<String?> downloadFaceFromBackend(String email) async {
    try {
      print('🔍 Attempting to download face from backend for: $email');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/face/image/$email'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Save image locally
        final directory = await getApplicationDocumentsDirectory();
        final facesDir = Directory('${directory.path}/agent_faces_backend');
        
        if (!await facesDir.exists()) {
          await facesDir.create(recursive: true);
        }

        final fileName = '${email.replaceAll('@', '_at_')}_backend.jpg';
        final filePath = '${facesDir.path}/$fileName';
        
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        print('✅ Face downloaded from backend: $filePath');
        return filePath;
      } else {
        print('⚠️ Backend returned status: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('⚠️ Failed to download face from backend: $e');
      return null;
    }
  }

  /// Get all registered face image paths for a user
  /// First checks backend, then falls back to local storage
  Future<List<String>> _getRegisteredFaces(String userType, String userEmail) async {
    try {
      List<String> faces = [];
      
      // 1. Try to download from backend (for agents)
      if (userType == 'agent') {
        final backendPath = await downloadFaceFromBackend(userEmail);
        if (backendPath != null) {
          faces.add(backendPath);
          return faces; // Return immediately if backend face found
        }
      }
      
      // 2. Check local storage directories
      final directory = await getApplicationDocumentsDirectory();
      final directories = [
        '${directory.path}/agent_faces',
        '${directory.path}/agent_faces_backend',
        '${directory.path}/resident_faces',
      ];
      
      for (var dirPath in directories) {
        final facesDir = Directory(dirPath);
        if (await facesDir.exists()) {
          final emailPrefix = userEmail.replaceAll('@', '_at_');
          final files = await facesDir.list().toList();
          
          final matchingFiles = files
              .where((file) => file is File && file.path.contains(emailPrefix))
              .map((file) => file.path)
              .toList();
          
          faces.addAll(matchingFiles);
        }
      }
      
      return faces;
      
    } catch (e) {
      print('❌ Error getting registered faces: $e');
      return [];
    }
  }

  /// Compare two face images and return similarity score
  Future<int> _compareFaces(
    Face capturedFace,
    String capturedPath,
    String registeredPath,
  ) async {
    try {
      // Detect face in registered image
      final registeredImage = InputImage.fromFilePath(registeredPath);
      final registeredFaces = await _faceDetector.processImage(registeredImage);
      
      if (registeredFaces.isEmpty) {
        return 0;
      }

      final registeredFace = registeredFaces.first;
      
      // Calculate similarity based on multiple factors
      double totalScore = 0.0;
      int factors = 0;

      // 1. Compare head angles (yaw, pitch, roll)
      if (capturedFace.headEulerAngleY != null && registeredFace.headEulerAngleY != null) {
        final yawDiff = (capturedFace.headEulerAngleY! - registeredFace.headEulerAngleY!).abs();
        totalScore += max(0, 100 - (yawDiff * 3));
        factors++;
      }

      if (capturedFace.headEulerAngleZ != null && registeredFace.headEulerAngleZ != null) {
        final rollDiff = (capturedFace.headEulerAngleZ! - registeredFace.headEulerAngleZ!).abs();
        totalScore += max(0, 100 - (rollDiff * 3));
        factors++;
      }

      if (capturedFace.headEulerAngleX != null && registeredFace.headEulerAngleX != null) {
        final pitchDiff = (capturedFace.headEulerAngleX! - registeredFace.headEulerAngleX!).abs();
        totalScore += max(0, 100 - (pitchDiff * 3));
        factors++;
      }

      // 2. Compare face bounds (aspect ratio)
      final capturedBounds = capturedFace.boundingBox;
      final registeredBounds = registeredFace.boundingBox;
      
      final capturedAspect = capturedBounds.width / capturedBounds.height;
      final registeredAspect = registeredBounds.width / registeredBounds.height;
      
      final aspectDiff = (capturedAspect - registeredAspect).abs();
      totalScore += max(0, 100 - (aspectDiff * 200));
      factors++;

      // 3. Compare landmarks if available
      if (capturedFace.landmarks.isNotEmpty && registeredFace.landmarks.isNotEmpty) {
        final landmarkScore = _compareLandmarks(
          capturedFace.landmarks.cast<FaceLandmarkType, FaceLandmark>(),
          registeredFace.landmarks.cast<FaceLandmarkType, FaceLandmark>(),
          capturedBounds,
          registeredBounds,
        );
        totalScore += landmarkScore;
        factors++;
      }

      // 4. Compare eye open probabilities (if smiling detection enabled)
      if (capturedFace.leftEyeOpenProbability != null && 
          registeredFace.leftEyeOpenProbability != null) {
        final eyeDiff = (capturedFace.leftEyeOpenProbability! - 
                        registeredFace.leftEyeOpenProbability!).abs();
        totalScore += max(0, 100 - (eyeDiff * 100));
        factors++;
      }

      if (capturedFace.rightEyeOpenProbability != null && 
          registeredFace.rightEyeOpenProbability != null) {
        final eyeDiff = (capturedFace.rightEyeOpenProbability! - 
                        registeredFace.rightEyeOpenProbability!).abs();
        totalScore += max(0, 100 - (eyeDiff * 100));
        factors++;
      }

      // Calculate average score
      final averageScore = factors > 0 ? totalScore / factors : 0;
      
      // Add randomness for realistic simulation (in production, use proper ML model)
      final random = Random();
      final variance = random.nextInt(10) - 5; // -5 to +5
      
      final finalScore = (averageScore + variance).clamp(0, 100).toInt();
      
      return finalScore;
      
    } catch (e) {
      print('Error comparing faces: $e');
      return 0;
    }
  }

  /// Compare facial landmarks between two faces
  double _compareLandmarks(
    Map<FaceLandmarkType, FaceLandmark> capturedLandmarks,
    Map<FaceLandmarkType, FaceLandmark> registeredLandmarks,
    Rect capturedBounds,
    Rect registeredBounds,
  ) {
    double totalScore = 0.0;
    int comparisons = 0;

    // Normalize positions relative to face size
    final capturedNorm = 1.0 / max(capturedBounds.width, capturedBounds.height);
    final registeredNorm = 1.0 / max(registeredBounds.width, registeredBounds.height);

    // Compare common landmarks
    final landmarksToCompare = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
    ];

    for (var landmarkType in landmarksToCompare) {
      final capturedLandmark = capturedLandmarks[landmarkType];
      final registeredLandmark = registeredLandmarks[landmarkType];

      if (capturedLandmark != null && registeredLandmark != null) {
        // Calculate normalized distance
        final capturedX = (capturedLandmark.position.x - capturedBounds.left) * capturedNorm;
        final capturedY = (capturedLandmark.position.y - capturedBounds.top) * capturedNorm;
        
        final registeredX = (registeredLandmark.position.x - registeredBounds.left) * registeredNorm;
        final registeredY = (registeredLandmark.position.y - registeredBounds.top) * registeredNorm;

        final distance = sqrt(
          pow(capturedX - registeredX, 2) + pow(capturedY - registeredY, 2)
        );

        // Convert distance to similarity score (closer = higher score)
        final similarity = max(0, 100 - (distance * 200));
        totalScore += similarity;
        comparisons++;
      }
    }

    return comparisons > 0 ? totalScore / comparisons : 50;
  }

  /// Check if a user has registered their face
  Future<bool> hasFaceRegistered(String userType, String userEmail) async {
    final faces = await _getRegisteredFaces(userType, userEmail);
    return faces.isNotEmpty;
  }

  /// Delete registered faces for a user
  Future<void> deleteRegisteredFaces(String userType, String userEmail) async {
    try {
      final faces = await _getRegisteredFaces(userType, userEmail);
      for (String facePath in faces) {
        final file = File(facePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error deleting faces: $e');
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
