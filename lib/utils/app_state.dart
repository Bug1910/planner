import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WorkType { monthly, daily, pt }

class CustomShift {
  final String name;
  final int colorValue;
  CustomShift({required this.name, required this.colorValue});

  Map<String, dynamic> toJson() => {'name': name, 'color': colorValue};

  static CustomShift fromJson(Map<String, dynamic> j) => CustomShift(
        name: j['name'] as String,
        colorValue: j['color'] as int,
      );
}

class IncomeEntry {
  final String id;
  final WorkType type;
  final String label;
  final double expected;
  double? actual;
  bool confirmed;
  final DateTime? payDate;
  final DateTime createdAt;

  IncomeEntry({
    required this.id,
    required this.type,
    required this.label,
    required this.expected,
    this.actual,
    this.confirmed = false,
    this.payDate,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'expected': expected,
        'actual': actual,
        'confirmed': confirmed,
        'payDate': payDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  static IncomeEntry fromJson(Map<String, dynamic> j) => IncomeEntry(
        id: j['id'] as String,
        type: WorkType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => WorkType.monthly,
        ),
        label: j['label'] as String,
        expected: (j['expected'] as num).toDouble(),
        actual: (j['actual'] as num?)?.toDouble(),
        confirmed: j['confirmed'] as bool? ?? false,
        payDate: j['payDate'] != null
            ? DateTime.parse(j['payDate'] as String)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class AppState {
  static const _kEntries = 'entries_v1';
  static const _kDayData = 'day_data_v1';
  static const _kBudget = 'month_budget_v1';
  static const _kCustomShifts = 'custom_shifts_v1';

  static SharedPreferences? _prefs;

  static final entries = ValueNotifier<List<IncomeEntry>>([]);
  static final dayData =
      ValueNotifier<Map<String, Map<String, dynamic>>>({});
  static final monthBudget = ValueNotifier<int>(0);
  static final customShifts = ValueNotifier<List<CustomShift>>([]);

  /// 啟動時呼叫一次，載入所有資料。之後變動會自動寫回。
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // entries
    final entriesJson = _prefs!.getString(_kEntries);
    if (entriesJson != null) {
      final list = jsonDecode(entriesJson) as List;
      entries.value =
          list.map((e) => IncomeEntry.fromJson(e as Map<String, dynamic>)).toList();
    }

    // dayData
    final dayJson = _prefs!.getString(_kDayData);
    if (dayJson != null) {
      final map = jsonDecode(dayJson) as Map<String, dynamic>;
      dayData.value = map.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    }

    // monthBudget
    monthBudget.value = _prefs!.getInt(_kBudget) ?? 0;

    // customShifts
    final customJson = _prefs!.getString(_kCustomShifts);
    if (customJson != null) {
      final list = jsonDecode(customJson) as List;
      customShifts.value =
          list.map((e) => CustomShift.fromJson(e as Map<String, dynamic>)).toList();
    }

    // 綁定自動存檔
    entries.addListener(_saveEntries);
    dayData.addListener(_saveDayData);
    monthBudget.addListener(_saveBudget);
    customShifts.addListener(_saveCustomShifts);
  }

  static void _saveEntries() {
    final list = entries.value.map((e) => e.toJson()).toList();
    _prefs?.setString(_kEntries, jsonEncode(list));
  }

  static void _saveDayData() {
    _prefs?.setString(_kDayData, jsonEncode(dayData.value));
  }

  static void _saveBudget() {
    _prefs?.setInt(_kBudget, monthBudget.value);
  }

  static void _saveCustomShifts() {
    final list = customShifts.value.map((e) => e.toJson()).toList();
    _prefs?.setString(_kCustomShifts, jsonEncode(list));
  }

  static void addCustomShift(CustomShift s) {
    customShifts.value = [...customShifts.value, s];
  }

  static void removeCustomShift(String name) {
    customShifts.value =
        customShifts.value.where((s) => s.name != name).toList();
    // 同步清掉 dayData 裡用到這個班別的紀錄
    final m = Map<String, Map<String, dynamic>>.from(dayData.value);
    bool changed = false;
    for (final k in m.keys.toList()) {
      final cur = Map<String, dynamic>.from(m[k]!);
      final list = cur['shifts'];
      if (list is List) {
        final filtered =
            list.whereType<String>().where((s) => s != name).toList();
        if (filtered.length != list.length) {
          if (filtered.isEmpty) {
            cur.remove('shifts');
          } else {
            cur['shifts'] = filtered;
          }
          if (cur.isEmpty) {
            m.remove(k);
          } else {
            m[k] = cur;
          }
          changed = true;
        }
      }
    }
    if (changed) dayData.value = m;
  }

  /// 更新自訂班別（可改名、改色）。若改名，會同步把 dayData 裡舊名換成新名。
  static void updateCustomShift(String oldName, CustomShift updated) {
    customShifts.value = customShifts.value
        .map((s) => s.name == oldName ? updated : s)
        .toList();
    if (oldName == updated.name) return;
    // 改名了 → 同步 dayData
    final m = Map<String, Map<String, dynamic>>.from(dayData.value);
    bool changed = false;
    for (final k in m.keys.toList()) {
      final cur = Map<String, dynamic>.from(m[k]!);
      final list = cur['shifts'];
      if (list is List) {
        final renamed = list
            .whereType<String>()
            .map((s) => s == oldName ? updated.name : s)
            .toList();
        if (!_listEq(renamed, list.whereType<String>().toList())) {
          cur['shifts'] = renamed;
          m[k] = cur;
          changed = true;
        }
      }
    }
    if (changed) dayData.value = m;
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static void addEntry(IncomeEntry e) {
    entries.value = [e, ...entries.value];
  }

  static void removeEntry(IncomeEntry e) {
    entries.value = entries.value.where((x) => x.id != e.id).toList();
  }

  static void confirmEntry(IncomeEntry e, double actual) {
    e.actual = actual;
    e.confirmed = true;
    entries.value = List.from(entries.value);
  }

  static void setDayData(String key, Map<String, dynamic> data) {
    final m = Map<String, Map<String, dynamic>>.from(dayData.value);
    m[key] = data;
    dayData.value = m;
  }

  static double get totalConfirmedIncome => entries.value
      .where((e) => e.confirmed)
      .fold(0.0, (s, e) => s + (e.actual ?? e.expected));

  static double get totalPendingIncome => entries.value
      .where((e) => !e.confirmed)
      .fold(0.0, (s, e) => s + e.expected);

  static int get totalExpense => dayData.value.entries
      .where((e) => e.value['expense'] != null)
      .fold(0, (s, e) => s + (e.value['expense'] as int));

  static double get treasury => totalConfirmedIncome - totalExpense;
}
