import 'package:rinne_graph/src/database/transaction_impl.dart';
import 'package:rinne_graph/src/database/transaction_intf.dart';
import 'package:rinne_graph/src/graph/event_manager.dart';
import 'package:rinne_graph/src/graph/graph_intf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

abstract class Database {
  Future<void> close();

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action);

  /// Get the event manager
  GraphEventManager get eventManager;

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]);

  /// Set the Graph object (for transaction-aware traversal)
  void setGraph(Graph graph);
}

class SQLiteDatabase implements Database {
  SQLiteDatabase(this._db, this._eventManager);

  final ffi.Database _db;
  final GraphEventManager _eventManager;
  Graph? _graph;

  @override
  GraphEventManager get eventManager => _eventManager;

  @override
  Future<void> close() async {
    await _db.close();
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    return _db.transaction((txn) async {
      final graphTxn = SQLiteTransaction(txn, _eventManager, _graph);
      return action(graphTxn);
    });
  }

  @override
  void setGraph(Graph graph) {
    _graph = graph;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    return _db.rawQuery(sql, arguments);
  }
}
