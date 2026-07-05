import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/local_image_widget.dart';

class ScreenshotGrid extends StatelessWidget {
  final List<XFile> localImages;
  final VoidCallback onAdd;
  final Function(int) onRemoveLocal;
  final Map<String, double> uploadProgress;
  final Set<String> failedUploads;
  final void Function(XFile)? onRetry;

  const ScreenshotGrid({
    super.key,
    required this.localImages,
    required this.onAdd,
    required this.onRemoveLocal,
    this.uploadProgress = const {},
    this.failedUploads = const {},
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (localImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: localImages.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == localImages.length) return _addButton();
                return _imageTile(i);
              },
            ),
          )
        else
          GestureDetector(
            onTap: onAdd,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppTheme.textMuted,
                      size: 28,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add screenshots',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _imageTile(int index) {
    final file = localImages[index];
    final progress = uploadProgress[file.path];
    final hasFailed = failedUploads.contains(file.path);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: buildLocalImageWidget(
            file,
            width: 120,
            height: 100,
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 120,
              height: 100,
              color: AppTheme.surfaceAlt,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ),
        if (progress != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(
                        value: progress,
                        color: AppTheme.accent,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (hasFailed)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Failed',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      onPressed: onRetry == null ? null : () => onRetry!(file),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        minimumSize: const Size(72, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => onRemoveLocal(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Icon(Icons.add, color: AppTheme.textMuted, size: 24),
      ),
    );
  }
}
