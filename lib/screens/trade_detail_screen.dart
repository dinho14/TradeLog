import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/platform_image_provider.dart';
import '../models/trade_entry.dart';
import '../services/trade_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class TradeDetailScreen extends StatefulWidget {
  final TradeEntry trade;
  const TradeDetailScreen({super.key, required this.trade});

  @override
  State<TradeDetailScreen> createState() => _TradeDetailScreenState();
}

class _TradeDetailScreenState extends State<TradeDetailScreen> {
  late TradeEntry _trade;
  final _tradeService = TradeService();
  final _authService = AuthService();
  final _commentsCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _isSaving = false;
  bool _isEditingComments = false;

  @override
  void initState() {
    super.initState();
    _trade = widget.trade;
    _commentsCtrl.text = _trade.comments;
  }

  @override
  void dispose() {
    _commentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _addScreenshot() async {
    final source = await _showSourceDialog();
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    if (_authService.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to upload screenshots.'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final url = await _tradeService.uploadScreenshot(
        userId: _authService.currentUser!.uid,
        tradeId: _trade.id,
        imageFile: picked,
      );
      final updated = _trade.copyWith(
        screenshotUrls: [..._trade.screenshotUrls, url],
      );
      await _tradeService.updateTrade(updated);
      setState(() => _trade = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot upload failed: $e'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _removeScreenshot(String url) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'Remove Screenshot',
          style: GoogleFonts.spaceGrotesk(
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Remove this screenshot?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _tradeService.deleteScreenshot(url);
    final updated = _trade.copyWith(
      screenshotUrls: _trade.screenshotUrls.where((u) => u != url).toList(),
    );
    await _tradeService.updateTrade(updated);
    setState(() => _trade = updated);
  }

  Future<void> _confirmDeleteTrade() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Trade',
          style: GoogleFonts.spaceGrotesk(
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Delete ${_trade.symbol} trade? Screenshots will also be removed.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await _tradeService.deleteTrade(_authService.currentUser!.uid, _trade.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Trade deleted')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveComments() async {
    setState(() => _isSaving = true);
    final updated = _trade.copyWith(comments: _commentsCtrl.text.trim());
    await _tradeService.updateTrade(updated);
    setState(() {
      _trade = updated;
      _isSaving = false;
      _isEditingComments = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notes saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(
          _trade.symbol,
          style: AppTheme.displayFont.copyWith(fontSize: 20),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMetrics(),
          const SizedBox(height: 20),
          _buildScreenshots(),
          const SizedBox(height: 20),
          _buildComments(),
          const SizedBox(height: 20),
          _buildTags(),
          const SizedBox(height: 20),
          _buildDeleteButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pnlColor = AppTheme.pnlColor(_trade.pnl);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge(
                _trade.direction == TradeDirection.long ? 'LONG' : 'SHORT',
                _trade.direction == TradeDirection.long
                    ? AppTheme.blue
                    : AppTheme.purple,
              ),
              const SizedBox(width: 8),
              _badge(
                _trade.outcome.name.toUpperCase(),
                AppTheme.outcomeColor(_trade.outcome.name),
              ),
              const SizedBox(width: 8),
              _badge(_trade.setup, AppTheme.textMuted),
              const Spacer(),
              Text(
                DateFormat('dd MMM yy').format(_trade.tradeDate),
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_trade.pnl >= 0 ? '+' : ''}\$${_trade.pnl.toStringAsFixed(2)}',
                style: GoogleFonts.spaceGrotesk(
                  color: pnlColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${_trade.pnlPercent >= 0 ? '+' : ''}${_trade.pnlPercent.toStringAsFixed(2)}%',
                  style: GoogleFonts.jetBrainsMono(
                    color: pnlColor.withValues(),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'METRICS',
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.textMuted,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric('Entry', '\$${_trade.entryPrice.toStringAsFixed(4)}'),
              _metric('Exit', '\$${_trade.exitPrice.toStringAsFixed(4)}'),
              _metric('Qty', _trade.quantity.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SCREENSHOTS',
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.textMuted,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _addScreenshot,
              child: Row(
                children: [
                  const Icon(Icons.add, size: 14, color: AppTheme.accent),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: GoogleFonts.inter(
                      color: AppTheme.accent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_trade.screenshotUrls.isEmpty)
          GestureDetector(
            onTap: _addScreenshot,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppTheme.textMuted,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add screenshots',
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _trade.screenshotUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _screenshotTile(_trade.screenshotUrls[i]),
            ),
          ),
      ],
    );
  }

  Widget _screenshotTile(String url) {
    return GestureDetector(
      onTap: () => _openFullScreen(url),
      onLongPress: () => _removeScreenshot(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildScreenshotPreview(url, width: 240, height: 180),
      ),
    );
  }

  Widget _buildScreenshotPreview(
    String url, {
    required double width,
    required double height,
  }) {
    if (url.startsWith('file://')) {
      return Image(
        image: platformFileImageProvider(url),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: AppTheme.surfaceAlt,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppTheme.textMuted,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: AppTheme.surfaceAlt,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      ),
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: AppTheme.surfaceAlt,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  void _openFullScreen(String url) {
    ImageProvider imageProvider;
    if (url.startsWith('file://')) {
      imageProvider = platformFileImageProvider(url);
    } else {
      imageProvider = CachedNetworkImageProvider(url);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: PhotoView(imageProvider: imageProvider),
        ),
      ),
    );
  }

  Widget _buildComments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'NOTES & ANALYSIS',
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.textMuted,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () =>
                  setState(() => _isEditingComments = !_isEditingComments),
              child: Text(
                _isEditingComments ? 'Cancel' : 'Edit',
                style: GoogleFonts.inter(color: AppTheme.accent, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isEditingComments) ...[
          TextFormField(
            controller: _commentsCtrl,
            maxLines: 8,
            autofocus: true,
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
            decoration: const InputDecoration(
              hintText: 'Add your trade analysis...',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveComments,
              child: const Text('Save Notes'),
            ),
          ),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              _trade.comments.isEmpty
                  ? 'No notes yet. Tap Edit to add analysis.'
                  : _trade.comments,
              style: GoogleFonts.inter(
                color: _trade.comments.isEmpty
                    ? AppTheme.textMuted
                    : AppTheme.textPrimary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTags() {
    if (_trade.tags.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TAGS',
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.textMuted,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _trade.tags
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    final backgroundColor = color.withValues();
    final textColor =
        ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? AppTheme.textPrimary
        : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: backgroundColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _confirmDeleteTrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.red,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('Delete trade'),
      ),
    );
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppTheme.accent,
              ),
              title: Text(
                'Gallery',
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppTheme.accent,
              ),
              title: Text(
                'Camera',
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
