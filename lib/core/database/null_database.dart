import 'package:sqflite/sqflite.dart';

class _TableStore {
  final List<Map<String, Object?>> rows = [];
  int nextId = 1;
}

class NullDatabase implements Database {
  final Map<String, _TableStore> _tables = {};

  _TableStore _table(String name) =>
      _tables.putIfAbsent(name, () => _TableStore());

  @override
  bool get isOpen => true;

  @override
  String get path => ':memory:';

  @override
  Database get database => this;

  @override
  Future<void> close() async {
    _tables.clear();
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) fn, {
    bool? exclusive,
  }) async {
    final txn = _NullTransaction(this);
    return fn(txn);
  }

  @override
  Future<T> readTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final txn = _NullTransaction(this);
    return action(txn);
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final store = _table(table);
    if (!values.containsKey('id')) {
      values = Map<String, Object?>.from(values);
      values['id'] = store.nextId++;
    }
    store.rows.add(Map.from(values));
    return values['id'] as int;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final rows = _queryRows(table, where, whereArgs);
    for (final row in rows) {
      row.addAll(values);
    }
    return rows.length;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final store = _tables[table];
    if (store == null) return 0;
    final before = store.rows.length;
    if (where == null) {
      store.rows.clear();
      return before;
    }
    store.rows.removeWhere(
        (row) => _evaluateWhere(row, where, whereArgs ?? []));
    return before - store.rows.length;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    var rows = _queryRows(table, where, whereArgs);

    if (orderBy != null) {
      _applyOrderBy(rows, orderBy);
    }

    if (offset != null && offset < rows.length) {
      rows = rows.sublist(offset);
    }
    if (limit != null && limit < rows.length) {
      rows = rows.sublist(0, limit);
    }

    if (columns != null) {
      rows = rows
          .map((r) => Map.fromEntries(
              columns.where((c) => r.containsKey(c)).map((c) => MapEntry(c, r[c]))))
          .toList();
    }

    return rows;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? whereArgs,
  ]) async {
    final upper = sql.trim().toUpperCase();
    if (upper.startsWith('SELECT COUNT(*)')) {
      return _handleCountQuery(sql, whereArgs);
    }
    if (upper.startsWith('SELECT *')) {
      return _handleSelectAllQuery(sql, whereArgs);
    }
    return [];
  }

  List<Map<String, Object?>> _queryRows(
      String table, String? where, List<Object?>? whereArgs) {
    final store = _tables[table];
    if (store == null) return [];
    if (where == null) return List.from(store.rows);
    return store.rows
        .where((row) => _evaluateWhere(row, where, whereArgs ?? []))
        .toList();
  }

  bool _evaluateWhere(
      Map<String, Object?> row, String where, List<Object?> whereArgs) {
    final parts = where.split(' AND ');
    var argIndex = 0;
    for (final part in parts) {
      final trimmed = part.trim();
      final match = RegExp(
              r'''^\s*(\w+)\s*(=|!=|>=|<=|>|<|LIKE|IN)\s*(.+?)\s*$''',
              caseSensitive: false)
          .firstMatch(trimmed);
      if (match == null) continue;

      final column = match.group(1)!;
      final op = match.group(2)!.toUpperCase();
      var rawValue = match.group(3)!.trim();

      final colValue = row[column];

      Object? expected;
      if (rawValue == '?') {
        if (argIndex < whereArgs.length) {
          expected = whereArgs[argIndex++];
        } else {
          expected = null;
        }
      } else if (rawValue.startsWith("'") && rawValue.endsWith("'")) {
        expected = rawValue.substring(1, rawValue.length - 1);
      } else {
        expected = rawValue;
      }

      if (!_compare(colValue, op, expected)) return false;
    }
    return true;
  }

  bool _compare(Object? a, String op, Object? b) {
    switch (op) {
      case '=':
        if (a is int && b is String) b = int.tryParse(b);
        if (a is double && b is String) b = double.tryParse(b);
        return a == b;
      case '!=':
        return a != b;
      case '>':
        if (a is num && b is num) return a > b;
        if (a is String && b is String) return a.compareTo(b) > 0;
        return false;
      case '>=':
        if (a is num && b is num) return a >= b;
        if (a is String && b is String) return a.compareTo(b) >= 0;
        return false;
      case '<':
        if (a is num && b is num) return a < b;
        if (a is String && b is String) return a.compareTo(b) < 0;
        return false;
      case '<=':
        if (a is num && b is num) return a <= b;
        if (a is String && b is String) return a.compareTo(b) <= 0;
        return false;
      default:
        return false;
    }
  }

  void _applyOrderBy(List<Map<String, Object?>> rows, String orderBy) {
    final match = RegExp(r'^\s*(\w+)\s+(ASC|DESC)', caseSensitive: false)
        .firstMatch(orderBy);
    if (match == null) return;
    final col = match.group(1)!;
    final desc = match.group(2)!.toUpperCase() == 'DESC';
    rows.sort((a, b) {
      final va = a[col];
      final vb = b[col];
      if (va == null && vb == null) return 0;
      if (va == null) return desc ? 1 : -1;
      if (vb == null) return desc ? -1 : 1;
      int cmp;
      if (va is num && vb is num) {
        cmp = va.compareTo(vb);
      } else {
        cmp = va.toString().compareTo(vb.toString());
      }
      return desc ? -cmp : cmp;
    });
  }

  Future<List<Map<String, Object?>>> _handleCountQuery(
      String sql, List<Object?>? whereArgs) async {
    final tableMatch = RegExp(r'FROM\s+(\w+)', caseSensitive: false)
        .firstMatch(sql);
    if (tableMatch == null) return [];
    final table = tableMatch.group(1)!;

    String? where;
    List<Object?> args = [];
    final whereMatch =
        RegExp(r'WHERE\s+(.+?)(?:\s+ORDER\s+BY|\s+LIMIT|$)', caseSensitive: false)
            .firstMatch(sql);
    if (whereMatch != null) {
      where = whereMatch.group(1)!.trim();
      args = whereArgs ?? [];
    }

    bool? useCount;
    String? countCol;

    final countMatch =
        RegExp(r'COUNT\(\s*(\*|\w+)\s*\)', caseSensitive: false)
            .firstMatch(sql);
    if (countMatch != null) {
      useCount = true;
      countCol = countMatch.group(1);
    }

    var rows = _queryRows(table, where, args);

    if (useCount == true) {
      return [
        {'count': rows.length}
      ];
    }

    return rows;
  }

  Future<List<Map<String, Object?>>> _handleSelectAllQuery(
      String sql, List<Object?>? whereArgs) async {
    final tableMatch = RegExp(r'FROM\s+(\w+)', caseSensitive: false)
        .firstMatch(sql);
    if (tableMatch == null) return [];
    final table = tableMatch.group(1)!;

    String? where;
    List<Object?> args = [];
    String? orderBy;

    final whereMatch =
        RegExp(r'WHERE\s+(.+?)(?:\s+ORDER\s+BY|\s+LIMIT|$)', caseSensitive: false)
            .firstMatch(sql);
    if (whereMatch != null) {
      where = whereMatch.group(1)!.trim();
      args = whereArgs ?? [];
    }

    final orderMatch =
        RegExp(r'ORDER\s+BY\s+(.+?)(?:\s+LIMIT|$)', caseSensitive: false)
            .firstMatch(sql);
    if (orderMatch != null) {
      orderBy = orderMatch.group(1)!.trim();
    }

    int? limit;
    final limitMatch = RegExp(r'LIMIT\s+(\d+)', caseSensitive: false)
        .firstMatch(sql);
    if (limitMatch != null) {
      limit = int.tryParse(limitMatch.group(1)!);
    }

    var rows = _queryRows(table, where, args);

    if (orderBy != null) {
      _applyOrderBy(rows, orderBy);
    }
    if (limit != null && limit < rows.length) {
      rows = rows.sublist(0, limit);
    }

    return rows;
  }

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {}

  @override
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]) async =>
      Future.error('Not supported');

  @override
  Future<T> devInvokeSqlMethod<T>(
    String method,
    String sql, [
    List<Object?>? arguments,
  ]) async =>
      Future.error('Not supported');

  @override
  Future<QueryCursor> queryCursor(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    int? bufferSize,
  }) async =>
      Future.error('Not supported');

  @override
  Future<QueryCursor> rawQueryCursor(
    String sql,
    List<Object?>? arguments, {
    int? bufferSize,
  }) async =>
      Future.error('Not supported');

  @override
  Batch batch() => _NullBatch(this);
}

class _NullTransaction implements Transaction {
  final NullDatabase _db;

  _NullTransaction(this._db);

  @override
  Database get database => _db;

  @override
  Future<void> commit() async {}

  @override
  Future<void> rollback() async {}

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) =>
      _db.insert(table, values,
          nullColumnHack: nullColumnHack,
          conflictAlgorithm: conflictAlgorithm);

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) =>
      _db.update(table, values,
          where: where,
          whereArgs: whereArgs,
          conflictAlgorithm: conflictAlgorithm);

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      _db.delete(table, where: where, whereArgs: whereArgs);

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) =>
      _db.query(table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset);

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? whereArgs,
  ]) =>
      _db.rawQuery(sql, whereArgs);

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {}

  @override
  Future<QueryCursor> queryCursor(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    int? bufferSize,
  }) async =>
      Future.error('Not supported');

  @override
  Future<QueryCursor> rawQueryCursor(
    String sql,
    List<Object?>? arguments, {
    int? bufferSize,
  }) async =>
      Future.error('Not supported');

  @override
  Batch batch() => _NullBatch(_db);
}

class _NullBatch implements Batch {
  final NullDatabase _db;
  final _operations = <void Function()>[];

  _NullBatch(this._db);

  @override
  int get length => _operations.length;

  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    _operations.add(() {
      _db.insert(table, values,
          nullColumnHack: nullColumnHack,
          conflictAlgorithm: conflictAlgorithm);
    });
  }

  @override
  void update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    _operations.add(() {
      _db.update(table, values,
          where: where,
          whereArgs: whereArgs,
          conflictAlgorithm: conflictAlgorithm);
    });
  }

  @override
  void delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    _operations.add(() {
      _db.delete(table, where: where, whereArgs: whereArgs);
    });
  }

  @override
  void execute(String sql, [List<Object?>? arguments]) {}

  @override
  void rawInsert(String sql, [List<Object?>? arguments]) {}

  @override
  void rawUpdate(String sql, [List<Object?>? arguments]) {}

  @override
  void rawDelete(String sql, [List<Object?>? arguments]) {}

  @override
  void query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    _operations.add(() {
      _db.query(table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset);
    });
  }

  @override
  void rawQuery(String sql, [List<Object?>? arguments]) {}

  @override
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    for (final op in _operations) {
      op();
    }
    return [];
  }

  @override
  Future<List<Object?>> apply({bool? noResult, bool? continueOnError}) async {
    for (final op in _operations) {
      op();
    }
    return [];
  }
}
