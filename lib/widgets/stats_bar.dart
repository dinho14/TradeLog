import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class StatsBar extends StatelessWidget {
  final Map<String, dynamic> stats;
  const StatsBar({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalPnl = (stats['totalPnl'] as double?) ?? 0;
    final winRate = (stats['winRate'] as double?) ?? 0;
    final profitFactor = (stats['profitFactor'] as double?) ?? 0;
    final totalTrades = (stats['totalTrades'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          _stat(
            label: 'P&L',
            value: '${totalPnl >= 0 ? '+' : ''}\$${totalPnl.toStringAsFixed(0)}',
            color: AppTheme.pnlColor(totalPnl),
          ),
          _divider(),
          _stat(
            label: 'Win Rate',
            value: '${(winRate * 100).toStringAsFixed(1)}%',
            color: winRate >= 0.5 ? AppTheme.accent : AppTheme.red,
          ),
          _divider(),
          _stat(
            label: 'Prof. Factor',
            value: profitFactor.toStringAsFixed(2),
            color: profitFactor >= 1.5 ? AppTheme.accent : AppTheme.textSecondary,
          ),
          _divider(),
          _stat(
            label: 'Trades',
            value: '$totalTrades',
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _stat({required String label, required String value, required Color color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 28, color: AppTheme.border);
  }
}
