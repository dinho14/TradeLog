import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/trade_entry.dart';
import '../utils/local_file.dart';

class TradeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _tradesRef(String userId) =>
      _db.collection('users').doc(userId).collection('trades');

  // ── Trades CRUD ─────────────────────────────────────────────────────────────

  Stream<List<TradeEntry>> watchTrades(String userId) {
    return _tradesRef(userId)
        .orderBy('tradeDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TradeEntry.fromFirestore).toList());
  }

  Future<TradeEntry> createTrade(TradeEntry trade) async {
    final ref = _tradesRef(trade.userId).doc();
    final entry = TradeEntry(
      id: ref.id,
      userId: trade.userId,
      symbol: trade.symbol,
      direction: trade.direction,
      outcome: trade.outcome,
      entryPrice: trade.entryPrice,
      exitPrice: trade.exitPrice,
      quantity: trade.quantity,
      pnl: trade.pnl,
      pnlPercent: trade.pnlPercent,
      setup: trade.setup,
      comments: trade.comments,
      screenshotUrls: trade.screenshotUrls,
      tags: trade.tags,
      tradeDate: trade.tradeDate,
      createdAt: DateTime.now(),
    );
    await ref.set(entry.toFirestore());
    return entry;
  }

  Future<void> updateTrade(TradeEntry trade) async {
    await _tradesRef(trade.userId).doc(trade.id).update(trade.toFirestore());
  }

  Future<void> deleteTrade(String userId, String tradeId) async {
    // Also delete screenshots from storage or local fallback storage
    final doc = await _tradesRef(userId).doc(tradeId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final urls = List<String>.from(data['screenshotUrls'] ?? []);
      for (final url in urls) {
        try {
          if (_isRemoteUrl(url)) {
            await _storage.refFromURL(url).delete();
          } else {
            final path = localPathFromUrl(url);
            await deleteLocalFilePath(path);
          }
        } catch (_) {}
      }
    }
    await _tradesRef(userId).doc(tradeId).delete();
  }

  // ── Screenshot Upload ────────────────────────────────────────────────────────

  Future<String> uploadScreenshot({
    required String userId,
    required String tradeId,
    required XFile imageFile,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = imageFile.name;
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final storageFileName = '${_uuid.v4()}.$ext';
    final ref = _storage.ref().child(
      'users/$userId/trades/$tradeId/$storageFileName',
    );

    final bytes = await imageFile.readAsBytes();
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/$ext'),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final bytesTransferred = snapshot.bytesTransferred;
        final totalBytes = snapshot.totalBytes;
        if (totalBytes > 0) {
          onProgress(bytesTransferred / totalBytes);
        }
      });
    }

    final taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> deleteScreenshot(String url) async {
    try {
      if (_isRemoteUrl(url)) {
        await _storage.refFromURL(url).delete();
      } else {
        final path = localPathFromUrl(url);
        await deleteLocalFilePath(path);
      }
    } catch (_) {}
  }

  bool _isRemoteUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  // ── Stats / Aggregation ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStats(String userId) async {
    final snap = await _tradesRef(userId).get();
    final trades = snap.docs.map(TradeEntry.fromFirestore).toList();

    if (trades.isEmpty) {
      return {
        'totalTrades': 0,
        'wins': 0,
        'losses': 0,
        'winRate': 0.0,
        'totalPnl': 0.0,
        'avgWin': 0.0,
        'avgLoss': 0.0,
        'profitFactor': 0.0,
      };
    }

    final wins = trades.where((t) => t.outcome == TradeOutcome.win).toList();
    final losses = trades.where((t) => t.outcome == TradeOutcome.loss).toList();

    final totalPnl = trades.fold(0.0, (acc, t) => acc + t.pnl);
    final avgWin = wins.isEmpty
        ? 0.0
        : wins.fold(0.0, (acc, t) => acc + t.pnl) / wins.length;
    final avgLoss = losses.isEmpty
        ? 0.0
        : losses.fold(0.0, (acc, t) => acc + t.pnl.abs()) / losses.length;

    final grossWin = wins.fold(0.0, (acc, t) => acc + t.pnl);
    final grossLoss = losses.fold(0.0, (acc, t) => acc + t.pnl.abs());

    return {
      'totalTrades': trades.length,
      'wins': wins.length,
      'losses': losses.length,
      'winRate': wins.length / trades.length,
      'totalPnl': totalPnl,
      'avgWin': avgWin,
      'avgLoss': avgLoss,
      'profitFactor': grossLoss == 0 ? 0.0 : grossWin / grossLoss,
    };
  }
}
