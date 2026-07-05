import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/trade_entry.dart';
import '../services/trade_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/trade_card.dart';
import '../widgets/stats_bar.dart';
import 'add_trade_screen.dart';
import 'logout_screen.dart';
import 'overview_screen.dart';
import 'trade_detail_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _tradeService = TradeService();
  final _authService = AuthService();
  String _filterOutcome = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  String get _userId => _authService.currentUser?.uid ?? '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TradeEntry> _applyFilters(List<TradeEntry> trades) {
    return trades.where((t) {
      final matchesOutcome =
          _filterOutcome == 'all' || t.outcome.name == _filterOutcome;
      final matchesSearch =
          _searchQuery.isEmpty ||
          t.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.setup.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.tags.any(
            (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
          );
      return matchesOutcome && matchesSearch;
    }).toList();
  }

  Future<void> _handleRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildStatsBar(),
            _buildFilters(),
            _buildTradeList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTradeScreen()),
        ),
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'Log Trade',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.bg,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TradeLog',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            DateFormat('EEEE, d MMM y').format(DateTime.now()),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded, size: 20),
          color: AppTheme.textSecondary,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OverviewScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search, size: 20),
          color: AppTheme.textSecondary,
          onPressed: () => _showSearchBar(),
        ),
        IconButton(
          icon: const Icon(Icons.logout, size: 20),
          color: AppTheme.textSecondary,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LogoutScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    return SliverToBoxAdapter(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _tradeService.getStats(_userId),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox(height: 80);
          return StatsBar(stats: snap.data!);
        },
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['all', 'win', 'loss', 'breakeven'];
    final labels = {
      'all': 'All',
      'win': 'Wins',
      'loss': 'Losses',
      'breakeven': 'B/E',
    };

    final colors = {
      'all': AppTheme.accent,
      'win': AppTheme.accent,
      'loss': AppTheme.red,
      'breakeven': AppTheme.amber,
    };

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: filters.map((f) {
            final selected = _filterOutcome == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filterOutcome = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors[f]!.withValues(alpha: 0.2)
                        : AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected
                          ? colors[f]!.withValues(alpha: 0.3)
                          : AppTheme.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    labels[f]!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTradeList() {
    return StreamBuilder<List<TradeEntry>>(
      stream: _tradeService.watchTrades(_userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                'Error loading trades',
                style: TextStyle(color: AppTheme.red),
              ),
            ),
          );
        }

        final trades = _applyFilters(snap.data ?? []);
        final isWide = MediaQuery.of(context).size.width >= 900;

        if (trades.isEmpty) {
          return SliverFillRemaining(child: _buildEmpty());
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          sliver: isWide
              ? SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 520,
                    mainAxisExtent: 260,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => TradeCard(
                      trade: trades[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TradeDetailScreen(trade: trades[i]),
                        ),
                      ),
                      onDelete: () => _confirmDelete(trades[i]),
                    ),
                    childCount: trades.length,
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TradeCard(
                        trade: trades[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TradeDetailScreen(trade: trades[i]),
                          ),
                        ),
                        onDelete: () => _confirmDelete(trades[i]),
                      ),
                    ),
                    childCount: trades.length,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.candlestick_chart_outlined,
            size: 48,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No trades yet',
            style: GoogleFonts.spaceGrotesk(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Log your first trade to start journaling',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTradeScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: Text(
              'Add your first trade',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchBar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Search Trades',
          style: GoogleFonts.spaceGrotesk(
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Symbol, setup, tag...'),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              _searchCtrl.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(TradeEntry trade) async {
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
          'Delete ${trade.symbol} trade? Screenshots will also be removed.',
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
    if (confirmed == true) {
      await _tradeService.deleteTrade(_userId, trade.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Trade deleted')));
      }
    }
  }
}
