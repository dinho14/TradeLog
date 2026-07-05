import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/trade_entry.dart';
import '../services/auth_service.dart';
import '../services/trade_service.dart';
import '../theme/app_theme.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final _tradeService = TradeService();
  final _authService = AuthService();

  String get _userId => _authService.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: Text(
          'Overview',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<TradeEntry>>(
        stream: _tradeService.watchTrades(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load analytics',
                style: GoogleFonts.inter(color: AppTheme.red),
              ),
            );
          }

          final trades = snapshot.data ?? [];
          if (trades.isEmpty) {
            return _buildEmptyState();
          }

          final stats = _buildStats(trades);
          final monthlySeries = _buildMonthlySeries(trades);
          final outcomeSeries = _buildOutcomeSeries(trades);
          final topSymbols = _buildTopSymbols(trades);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(stats),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _buildStatCard(
                      title: 'Win rate',
                      value: '${(stats['winRate'] * 100).toStringAsFixed(1)}%',
                      subtitle:
                          '${stats['wins']} wins · ${stats['losses']} losses',
                      color: stats['winRate'] >= 0.5
                          ? AppTheme.accent
                          : AppTheme.red,
                    ),
                    _buildStatCard(
                      title: 'Avg win',
                      value: _money(stats['avgWin']),
                      subtitle: 'Typical winning trade',
                      color: AppTheme.accent,
                    ),
                    _buildStatCard(
                      title: 'Avg loss',
                      value: _money(stats['avgLoss']),
                      subtitle: 'Typical losing trade',
                      color: AppTheme.red,
                    ),
                    _buildStatCard(
                      title: 'Profit factor',
                      value: stats['profitFactor'].toStringAsFixed(2),
                      subtitle: 'Gross wins / gross losses',
                      color: stats['profitFactor'] >= 1.5
                          ? AppTheme.accent
                          : AppTheme.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildChartCard(monthlySeries),
                const SizedBox(height: 16),
                _buildOutcomeCard(outcomeSeries),
                const SizedBox(height: 16),
                _buildTopSymbolsCard(topSymbols),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> stats) {
    final totalPnl = (stats['totalPnl'] as double?) ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.surface, AppTheme.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance snapshot',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats['totalTrades']} trades tracked',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${totalPnl >= 0 ? '+' : ''}${_money(totalPnl)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.pnlColor(totalPnl),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Net P&L',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${(stats['winRate'] * 100).toStringAsFixed(1)}% win rate',
                  style: GoogleFonts.inter(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<_MonthlyPoint> series) {
    final maxAbs = series.fold<double>(
      0,
      (acc, item) => math.max(acc, item.value.abs()),
    );
    final maxY = maxAbs == 0 ? 1.0 : maxAbs * 1.15;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly P&L',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: -maxY,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= series.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          series[index].label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(series.length, (index) {
                  final item = series[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.value,
                        width: 16,
                        color: item.value >= 0 ? AppTheme.accent : AppTheme.red,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                          bottom: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeCard(List<_OutcomePoint> series) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outcome split',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 38,
                borderData: FlBorderData(show: false),
                sections: series.map((item) {
                  return PieChartSectionData(
                    value: item.value,
                    color: item.color,
                    title: item.label,
                    radius: 70,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: series.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.label}: ${item.value}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSymbolsCard(List<_SymbolInsight> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top symbols',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.symbol,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${item.count} trades',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _money(item.pnl),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: AppTheme.pnlColor(item.pnl),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No analytics yet',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log a few trades to see your overview charts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _buildStats(List<TradeEntry> trades) {
    final wins = trades.where((t) => t.outcome == TradeOutcome.win).toList();
    final losses = trades.where((t) => t.outcome == TradeOutcome.loss).toList();

    final totalPnl = trades.fold<double>(0, (acc, t) => acc + t.pnl);
    final grossWin = wins.fold<double>(0, (acc, t) => acc + t.pnl);
    final grossLoss = losses.fold<double>(0, (acc, t) => acc + t.pnl.abs());

    return {
      'totalTrades': trades.length,
      'wins': wins.length,
      'losses': losses.length,
      'winRate': trades.isEmpty ? 0.0 : wins.length / trades.length,
      'totalPnl': totalPnl,
      'avgWin': wins.isEmpty
          ? 0.0
          : wins.fold<double>(0, (acc, t) => acc + t.pnl) / wins.length,
      'avgLoss': losses.isEmpty
          ? 0.0
          : losses.fold<double>(0, (acc, t) => acc + t.pnl.abs()) /
                losses.length,
      'profitFactor': grossLoss == 0 ? 0.0 : grossWin / grossLoss,
    };
  }

  List<_MonthlyPoint> _buildMonthlySeries(List<TradeEntry> trades) {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      final date = DateTime(now.year, now.month - (5 - index), 1);
      return date;
    });

    final values = <String, double>{};
    for (final month in months) {
      values[DateFormat('yyyy-MM').format(month)] = 0;
    }

    for (final trade in trades) {
      final key = DateFormat('yyyy-MM').format(trade.tradeDate);
      if (values.containsKey(key)) {
        values[key] = values[key]! + trade.pnl;
      }
    }

    return months.map((month) {
      final key = DateFormat('yyyy-MM').format(month);
      return _MonthlyPoint(
        label: DateFormat('MMM').format(month),
        value: values[key] ?? 0.0,
      );
    }).toList();
  }

  List<_OutcomePoint> _buildOutcomeSeries(List<TradeEntry> trades) {
    final wins = trades.where((t) => t.outcome == TradeOutcome.win).length;
    final losses = trades.where((t) => t.outcome == TradeOutcome.loss).length;
    final breakeven = trades
        .where((t) => t.outcome == TradeOutcome.breakeven)
        .length;

    return [
      _OutcomePoint(
        label: 'Wins',
        value: wins.toDouble(),
        color: AppTheme.accent,
      ),
      _OutcomePoint(
        label: 'Losses',
        value: losses.toDouble(),
        color: AppTheme.red,
      ),
      _OutcomePoint(
        label: 'Breakeven',
        value: breakeven.toDouble(),
        color: AppTheme.amber,
      ),
    ];
  }

  List<_SymbolInsight> _buildTopSymbols(List<TradeEntry> trades) {
    final totals = <String, double>{};
    final counts = <String, int>{};

    for (final trade in trades) {
      final key = trade.symbol.toUpperCase();
      totals[key] = (totals[key] ?? 0) + trade.pnl;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final items =
        counts.entries
            .map(
              (entry) => _SymbolInsight(
                symbol: entry.key,
                count: entry.value,
                pnl: totals[entry.key] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) {
            if (a.count != b.count) {
              return b.count.compareTo(a.count);
            }
            return b.pnl.compareTo(a.pnl);
          });

    return items.take(4).toList();
  }

  String _money(double value) {
    return '${value >= 0 ? '+' : ''}\$${value.toStringAsFixed(0)}';
  }
}

class _MonthlyPoint {
  final String label;
  final double value;

  const _MonthlyPoint({required this.label, required this.value});
}

class _OutcomePoint {
  final String label;
  final double value;
  final Color color;

  const _OutcomePoint({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _SymbolInsight {
  final String symbol;
  final int count;
  final double pnl;

  const _SymbolInsight({
    required this.symbol,
    required this.count,
    required this.pnl,
  });
}
