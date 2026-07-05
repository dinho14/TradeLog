import 'package:cloud_firestore/cloud_firestore.dart';

enum TradeDirection { long, short }

enum TradeOutcome { win, loss, breakeven }

class TradeEntry {
  final String id;
  final String userId;
  final String symbol;
  final TradeDirection direction;
  final TradeOutcome outcome;
  final double entryPrice;
  final double exitPrice;
  final double quantity;
  final double pnl;
  final double pnlPercent;
  final String setup;
  final String comments;
  final List<String> screenshotUrls;
  final List<String> tags;
  final DateTime tradeDate;
  final DateTime createdAt;

  TradeEntry({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.direction,
    required this.outcome,
    required this.entryPrice,
    required this.exitPrice,
    required this.quantity,
    required this.pnl,
    required this.pnlPercent,
    required this.setup,
    required this.comments,
    required this.screenshotUrls,
    required this.tags,
    required this.tradeDate,
    required this.createdAt,
  });

  factory TradeEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TradeEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      symbol: data['symbol'] ?? '',
      direction: data['direction'] == 'long'
          ? TradeDirection.long
          : TradeDirection.short,
      outcome: _parseOutcome(data['outcome']),
      entryPrice: (data['entryPrice'] ?? 0).toDouble(),
      exitPrice: (data['exitPrice'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0).toDouble(),
      pnl: (data['pnl'] ?? 0).toDouble(),
      pnlPercent: (data['pnlPercent'] ?? 0).toDouble(),
      setup: data['setup'] ?? '',
      comments: data['comments'] ?? '',
      screenshotUrls: List<String>.from(data['screenshotUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      tradeDate: (data['tradeDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'symbol': symbol.toUpperCase(),
      'direction': direction == TradeDirection.long ? 'long' : 'short',
      'outcome': outcome.name,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'quantity': quantity,
      'pnl': pnl,
      'pnlPercent': pnlPercent,
      'setup': setup,
      'comments': comments,
      'screenshotUrls': screenshotUrls,
      'tags': tags,
      'tradeDate': Timestamp.fromDate(tradeDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static TradeOutcome _parseOutcome(String? value) {
    switch (value) {
      case 'win':
        return TradeOutcome.win;
      case 'loss':
        return TradeOutcome.loss;
      default:
        return TradeOutcome.breakeven;
    }
  }

  TradeEntry copyWith({
    String? comments,
    List<String>? screenshotUrls,
    List<String>? tags,
    String? setup,
  }) {
    return TradeEntry(
      id: id,
      userId: userId,
      symbol: symbol,
      direction: direction,
      outcome: outcome,
      entryPrice: entryPrice,
      exitPrice: exitPrice,
      quantity: quantity,
      pnl: pnl,
      pnlPercent: pnlPercent,
      setup: setup ?? this.setup,
      comments: comments ?? this.comments,
      screenshotUrls: screenshotUrls ?? this.screenshotUrls,
      tags: tags ?? this.tags,
      tradeDate: tradeDate,
      createdAt: createdAt,
    );
  }
}
