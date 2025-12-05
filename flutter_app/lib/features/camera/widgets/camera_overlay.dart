import 'package:flutter/material.dart';

class CameraOverlay extends StatelessWidget {
  final int frameCount;
  final int keyframeCount;
  final String lastOcrText;

  const CameraOverlay({
    super.key,
    required this.frameCount,
    required this.keyframeCount,
    required this.lastOcrText,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Panel
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatRow(Icons.camera, 'Frames', frameCount.toString()),
                  const SizedBox(height: 4),
                  _buildStatRow(Icons.key, 'Keyframes', keyframeCount.toString()),
                  const SizedBox(height: 4),
                  _buildStatRow(
                    Icons.analytics,
                    'Detection',
                    frameCount > 0
                        ? '${(keyframeCount / frameCount * 100).toStringAsFixed(1)}%'
                        : '0%',
                  ),
                ],
              ),
            ),

            const Spacer(),

            // OCR Text Display
            if (lastOcrText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.text_fields, color: Colors.blue[300], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Detected Text',
                          style: TextStyle(
                            color: Colors.blue[300],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lastOcrText.length > 100
                          ? '${lastOcrText.substring(0, 100)}...'
                          : lastOcrText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
