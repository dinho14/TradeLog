import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/platform_image_provider.dart';
import '../models/trade_entry.dart';
import '../theme/app_theme.dart';

class TradeCard extends StatelessWidget {
  final TradeEntry trade;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TradeCard({
    super.key,
    required this.trade,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pnlColor = AppTheme.pnlColor(trade.pnl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.accent.withValues(alpha: 0.15),
        highlightColor: AppTheme.accent.withValues(alpha: 0.08),
        onTap: onTap,
        onLongPress: onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (trade.screenshotUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: _buildScreenshotPreview(trade.screenshotUrls.first),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trade.symbol,
                            style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                          color: AppTheme.red,
                          tooltip: 'Delete trade',
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _directionBadge(),
                        const SizedBox(width: 6),
                        _outcomeBadge(),
                        const Spacer(),
                        Text(
                          '${trade.pnl >= 0 ? '+' : ''}\$${trade.pnl.toStringAsFixed(2)}',
                          style: GoogleFonts.jetBrainsMono(
                            color: pnlColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          trade.setup,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (trade.screenshotUrls.isNotEmpty) ...[
                          Icon(
                            Icons.image_outlined,
                            size: 12,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${trade.screenshotUrls.length}',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (trade.comments.isNotEmpty)
                          Icon(
                            Icons.notes,
                            size: 12,
                            color: AppTheme.textSecondary,
                          ),
                        const Spacer(),
                        Text(
                          DateFormat('dd MMM').format(trade.tradeDate),
                          style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (trade.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: trade.tags
                            .take(3)
                            .map(
                              (tag) => Text(
                                '#$tag',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenshotPreview(String url) {
    if (url.startsWith('file://')) {
      if (kIsWeb) {
        return Container(
          height: 140,
          width: double.infinity,
          color: AppTheme.surfaceAlt,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppTheme.textMuted,
          ),
        );
      }
      return Image(
        image: platformFileImageProvider(url),
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 140,
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
      height: 140,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        height: 140,
        color: AppTheme.surfaceAlt,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      ),
      errorWidget: (_, __, ___) => Container(
        height: 140,
        color: AppTheme.surfaceAlt,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _directionBadge() {
    final isLong = trade.direction == TradeDirection.long;
    final color = isLong ? AppTheme.blue : AppTheme.purple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues()),
      ),
      child: Text(
        isLong ? 'LONG' : 'SHORT',
        style: GoogleFonts.jetBrainsMono(
          color: AppTheme.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _outcomeBadge() {
    final colors = {
      'win': AppTheme.accent,
      'loss': AppTheme.red,
      'breakeven': AppTheme.amber,
    };
    final color = colors[trade.outcome.name] ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues()),
      ),
      child: Text(
        trade.outcome.name.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          color: AppTheme.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
