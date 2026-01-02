import 'package:flutter/material.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  Map<String, UploadedDocument?> documents = {
    'id_proof': null,
    'photograph': null,
    'certificate': null,
  };

  bool _isSubmitting = false;

  int get uploadedCount {
    return documents.values.where((doc) => doc != null).length;
  }

  double get progress {
    return uploadedCount / 3.0;
  }

  bool get canSubmit {
    return uploadedCount == 3;
  }

  void _selectDocument(String type) {
    // Simulate file selection
    setState(() {
      documents[type] = UploadedDocument(
        fileName: _getFileName(type),
        fileSize: '2.4 MB',
        isImage: type == 'photograph',
      );
    });
  }

  void _removeDocument(String type) {
    setState(() {
      documents[type] = null;
    });
  }

  void _previewImage(UploadedDocument doc) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _buildImagePreviewDialog(doc),
    );
  }

  String _getFileName(String type) {
    switch (type) {
      case 'id_proof':
        return 'aadhaar_card_front.jpg';
      case 'photograph':
        return 'profile_photo.jpg';
      case 'certificate':
        return 'security_training_cert.pdf';
      default:
        return 'document.pdf';
    }
  }

  Future<void> _handleSubmit() async {
    if (!canSubmit) return;

    setState(() => _isSubmitting = true);

    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSubmitting = false);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
              ),
              const SizedBox(width: 12),
              const Text('Documents Submitted!'),
            ],
          ),
          content: const Text(
            'Your documents have been submitted successfully. Admin will review them shortly.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: Color(0xFF4F46E5))),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF2563EB), Color(0xFF0891B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Documents',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$uploadedCount/3 documents uploaded',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Indicator
                _buildProgressIndicator(),

                const SizedBox(height: 24),

                // Info Card
                _buildInfoCard(),

                const SizedBox(height: 24),

                // Document Upload Cards
                _buildUploadCard(
                  type: 'id_proof',
                  title: 'ID Proof',
                  description: 'Aadhaar, PAN, Driving License, or Passport',
                  icon: Icons.badge,
                ),

                const SizedBox(height: 16),

                _buildUploadCard(
                  type: 'photograph',
                  title: 'Photograph',
                  description: 'Recent passport-size photograph',
                  icon: Icons.photo_camera,
                ),

                const SizedBox(height: 16),

                _buildUploadCard(
                  type: 'certificate',
                  title: 'Certificate',
                  description: 'Qualification or Training Certificate',
                  icon: Icons.workspace_premium,
                ),

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomSection(),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upload Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F46E5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: progress),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4F46E5).withOpacity(0.1),
            const Color(0xFF2563EB).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4F46E5).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF4F46E5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Required Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoBullet('Valid Government ID Proof'),
          const SizedBox(height: 8),
          _buildInfoBullet('Recent Photograph'),
          const SizedBox(height: 8),
          _buildInfoBullet('Qualification / Training Certificate'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'After submission, documents will be reviewed by admin.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF4F46E5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF4B5563),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard({
    required String type,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final doc = documents[type];
    final isUploaded = doc != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isUploaded ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUploaded ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          width: isUploaded ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isUploaded
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                    ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isUploaded ? Icons.check_circle : icon,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                if (isUploaded) ...[
                  Text(
                    doc.fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doc.fileSize,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Action Buttons
          if (isUploaded)
            Column(
              children: [
                if (doc.isImage)
                  _buildActionButton(
                    icon: Icons.visibility,
                    color: const Color(0xFF3B82F6),
                    onTap: () => _previewImage(doc),
                  ),
                if (doc.isImage) const SizedBox(height: 8),
                _buildActionButton(
                  icon: Icons.close,
                  color: const Color(0xFFEF4444),
                  onTap: () => _removeDocument(type),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () => _selectDocument(type),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Select',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Helper Text
            if (!canSubmit)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFF6B7280)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Please upload all required documents to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canSubmit && !_isSubmitting ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF9CA3AF),
                  disabledBackgroundColor: const Color(0xFF9CA3AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: canSubmit ? 2 : 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        _isSubmitting ? 'Submitting...' : 'Submit Documents',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewDialog(UploadedDocument doc) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Backdrop
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // Image
          Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          doc.fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 80,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UploadedDocument {
  final String fileName;
  final String fileSize;
  final bool isImage;

  const UploadedDocument({
    required this.fileName,
    required this.fileSize,
    this.isImage = false,
  });
}
