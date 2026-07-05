import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/trade_entry.dart';
import '../services/trade_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/screenshot_grid.dart';

class AddTradeScreen extends StatefulWidget {
  const AddTradeScreen({super.key});

  @override
  State<AddTradeScreen> createState() => _AddTradeScreenState();
}

class _AddTradeScreenState extends State<AddTradeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tradeService = TradeService();
  final _authService = AuthService();
  final _picker = ImagePicker();

  // Form fields
  final _symbolCtrl = TextEditingController();
  final _entryCtrl = TextEditingController();
  final _exitCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  TradeDirection _direction = TradeDirection.long;
  TradeOutcome _outcome = TradeOutcome.win;
  String _setup = 'Breakout';
  DateTime _tradeDate = DateTime.now();
  final List<XFile> _localImages = [];
  final List<String> _tags = [];
  final Map<String, double> _uploadProgress = {};
  final Set<String> _failedUploads = {};
  String? _pendingTradeId;
  bool _isSubmitting = false;

  String get _uploadStatusText {
    if (_uploadProgress.isNotEmpty) {
      final active = _uploadProgress.length;
      return 'Uploading $active screenshot${active > 1 ? 's' : ''}...';
    }
    if (_failedUploads.isNotEmpty) {
      final count = _failedUploads.length;
      return '$count screenshot${count > 1 ? 's' : ''} failed to upload. Tap retry.';
    }
    return '';
  }

  Color get _uploadStatusColor {
    if (_uploadProgress.isNotEmpty) return AppTheme.accent;
    if (_failedUploads.isNotEmpty) return AppTheme.red;
    return AppTheme.textSecondary;
  }

  final List<String> _setupOptions = [
    'Breakout',
    'Retracement',
    'OTE play',
    'FVG play',
    'Order Block(OB)',
    'Scalp',
    'Swing',
    'News Play',
    'Other',
  ];

  double get _pnl {
    final entry = double.tryParse(_entryCtrl.text) ?? 0;
    final exit = double.tryParse(_exitCtrl.text) ?? 0;
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    if (_direction == TradeDirection.long) return (exit - entry) * qty;
    return (entry - exit) * qty;
  }

  double get _pnlPercent {
    final entry = double.tryParse(_entryCtrl.text) ?? 0;
    final exit = double.tryParse(_exitCtrl.text) ?? 0;
    if (entry == 0) return 0;
    if (_direction == TradeDirection.long) {
      return ((exit - entry) / entry) * 100;
    }
    return ((entry - exit) / entry) * 100;
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _entryCtrl.dispose();
    _exitCtrl.dispose();
    _qtyCtrl.dispose();
    _commentsCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => _localImages.add(picked));
    }
  }

  void _addTag(String tag) {
    final cleaned = tag.trim().toLowerCase().replaceAll(' ', '_');
    if (cleaned.isNotEmpty && !_tags.contains(cleaned)) {
      setState(() => _tags.add(cleaned));
    }
    _tagCtrl.clear();
  }

  void _removeLocalImage(int index) {
    final file = _localImages[index];
    setState(() {
      _localImages.removeAt(index);
      _uploadProgress.remove(file.path);
      _failedUploads.remove(file.path);
    });
  }

  Future<String> _uploadScreenshotWithProgress(
    XFile file,
    String userId,
    String tradeId,
  ) async {
    _failedUploads.remove(file.path);
    _uploadProgress[file.path] = 0.0;
    setState(() {});

    try {
      final url = await _tradeService.uploadScreenshot(
        userId: userId,
        tradeId: tradeId,
        imageFile: file,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _uploadProgress[file.path] = progress);
        },
      );
      _uploadProgress.remove(file.path);
      return url;
    } catch (e) {
      _uploadProgress.remove(file.path);
      _failedUploads.add(file.path);
      rethrow;
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _retryUpload(XFile file) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in again to retry upload.'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
      return;
    }

    final tradeId = _pendingTradeId;
    if (tradeId == null) return;

    try {
      await _uploadScreenshotWithProgress(file, currentUser.uid, tradeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retry successful.'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: $e'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all required fields.'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
      return;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save - please sign in again.'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    _pendingTradeId = const Uuid().v4();

    try {
      final userId = currentUser.uid;
      final tradeId = _pendingTradeId!;

      // Upload screenshots
      final uploadedUrls = <String>[];
      for (final file in _localImages) {
        final url = await _uploadScreenshotWithProgress(file, userId, tradeId);
        uploadedUrls.add(url);
      }

      final entry = TradeEntry(
        id: tradeId,
        userId: userId,
        symbol: _symbolCtrl.text.toUpperCase(),
        direction: _direction,
        outcome: _outcome,
        entryPrice: double.parse(_entryCtrl.text),
        exitPrice: double.parse(_exitCtrl.text),
        quantity: double.parse(_qtyCtrl.text),
        pnl: _pnl,
        pnlPercent: _pnlPercent,
        setup: _setup,
        comments: _commentsCtrl.text.trim(),
        screenshotUrls: uploadedUrls,
        tags: _tags,
        tradeDate: _tradeDate,
        createdAt: DateTime.now(),
      );

      await _tradeService.createTrade(entry);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _pendingTradeId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(
          'Log Trade',
          style: AppTheme.displayFont.copyWith(fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('Trade Details', [
              _buildSymbolAndDate(),
              const SizedBox(height: 12),
              _buildDirectionOutcome(),
            ]),
            const SizedBox(height: 20),
            _buildSection('Prices', [
              _buildPriceRow(),
              const SizedBox(height: 12),
              _buildPnlPreview(),
            ]),
            const SizedBox(height: 20),
            _buildSection('Setup', [
              _buildSetupDropdown(),
              const SizedBox(height: 12),
              _buildTagsInput(),
            ]),
            const SizedBox(height: 20),
            _buildSection('Screenshots', [
              if (_uploadStatusText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _uploadStatusText,
                    style: GoogleFonts.inter(
                      color: _uploadStatusColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ScreenshotGrid(
                localImages: _localImages,
                onAdd: () => _showImageSourceDialog(),
                onRemoveLocal: _removeLocalImage,
                uploadProgress: _uploadProgress,
                failedUploads: _failedUploads,
                onRetry: _retryUpload,
              ),
            ]),
            const SizedBox(height: 20),
            _buildSection('Notes / Analysis', [
              TextFormField(
                controller: _commentsCtrl,
                maxLines: 6,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText:
                      'What was your thesis? What went right or wrong? Lessons learned...',
                ),
              ),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.bg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save Trade',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.textMuted,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSymbolAndDate() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _symbolCtrl,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.spaceGrotesk(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              labelText: 'Symbol',
              hintText: 'AAPL',
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(_tradeDate),
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionOutcome() {
    return Row(
      children: [
        Expanded(
          child: _buildToggle(
            label: 'Direction',
            options: ['Long', 'Short'],
            selected: _direction == TradeDirection.long ? 0 : 1,
            colors: [AppTheme.blue, AppTheme.purple],
            onSelect: (i) => setState(
              () => _direction = i == 0
                  ? TradeDirection.long
                  : TradeDirection.short,
            ),
          ),
        ),

        const SizedBox(width: 12),
        Expanded(
          child: _buildToggle(
            label: 'Outcome',
            options: ['Win', 'Loss', 'B/E'],
            selected: _outcome.index,
            colors: [AppTheme.accent, AppTheme.red, AppTheme.amber],
            onSelect: (i) => setState(() => _outcome = TradeOutcome.values[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String label,
    required List<String> options,
    required int selected,
    required List<Color> colors,
    required Function(int) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.textMuted,
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: List.generate(options.length, (i) {
              final isSelected = selected == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors[i].withValues()
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: isSelected
                          ? Border.all(color: colors[i], width: 1.5)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Text(
                      options[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? ThemeData.estimateBrightnessForColor(
                                        colors[i].withValues(),
                                      ) ==
                                      Brightness.dark
                                  ? AppTheme.textPrimary
                                  : Colors.black
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      children: [
        Expanded(child: _priceField(_entryCtrl, 'Entry Price')),
        const SizedBox(width: 12),
        Expanded(child: _priceField(_exitCtrl, 'Exit Price')),
        const SizedBox(width: 12),
        Expanded(child: _priceField(_qtyCtrl, 'Quantity')),
      ],
    );
  }

  Widget _priceField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: GoogleFonts.jetBrainsMono(
        color: AppTheme.textPrimary,
        fontSize: 13,
      ),
      decoration: InputDecoration(labelText: label),
      validator: (v) =>
          v == null || double.tryParse(v) == null ? 'Invalid' : null,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildPnlPreview() {
    final hasPrices =
        _entryCtrl.text.isNotEmpty &&
        _exitCtrl.text.isNotEmpty &&
        _qtyCtrl.text.isNotEmpty;

    if (!hasPrices) return const SizedBox.shrink();

    final pnlColor = AppTheme.pnlColor(_pnl);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: pnlColor.withValues(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pnlColor.withValues()),
      ),
      child: Row(
        children: [
          Text(
            'Calculated P&L ',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            '${_pnl >= 0 ? '+' : ''}\$${_pnl.toStringAsFixed(2)}',
            style: GoogleFonts.jetBrainsMono(
              color: pnlColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${_pnlPercent >= 0 ? '+' : ''}${_pnlPercent.toStringAsFixed(2)}%)',
            style: GoogleFonts.jetBrainsMono(
              color: pnlColor.withValues(),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _setup,
      dropdownColor: AppTheme.surface,
      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
      decoration: const InputDecoration(labelText: 'Setup Type'),
      items: _setupOptions
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (v) => setState(() => _setup = v!),
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagCtrl,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'earnings, gap_up...',
                ),
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _addTag(_tagCtrl.text),
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.accent,
            ),
          ],
        ),

        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tags
                .map(
                  (tag) => Chip(
                    label: Text('#$tag'),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tradeDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _tradeDate = date);
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppTheme.accent,
              ),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppTheme.accent,
              ),
              title: Text(
                'Take Screenshot',
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
