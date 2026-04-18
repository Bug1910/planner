import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../utils/responsive.dart';
import '../utils/locale_notifier.dart';
import '../utils/app_state.dart';
import '../l10n/strings.dart';
import '../theme/app_colors.dart';

// 別名：讓現有程式碼指向 AppColors
const _indigo = AppColors.primary;
const _indigoDark = AppColors.primaryDark;
const _sage = AppColors.accent;
const _mustard = AppColors.warning;
const _rose = AppColors.danger;
const _amberWarm = AppColors.shiftMorningDot;
const _bg = AppColors.background;
const _bg2 = AppColors.backgroundAlt;
const _card = AppColors.surface;
const _card2 = AppColors.surfaceAlt;
const _text = AppColors.textPrimary;
const _text2 = AppColors.textSecondary;
const _text3 = AppColors.textMuted;
const _border = AppColors.divider;

const _purple = _indigo;
const _blue = _indigoDark;
const _pink = _rose;
const _green = _sage;
const _amber = _mustard;

const _shiftColors = {
  '早班': AppColors.shiftMorningDot,
  '晚班': AppColors.shiftEveningDot,
  '休假': AppColors.shiftOffDot,
};

Color _customShiftColor(String? s) {
  if (s == null) return AppColors.primary;
  final match = AppState.customShifts.value.where((c) => c.name == s);
  if (match.isEmpty) return AppColors.primary;
  return Color(match.first.colorValue);
}

Color _shiftDotColor(String? s) {
  if (_shiftColors.containsKey(s)) return _shiftColors[s]!;
  return _customShiftColor(s);
}

Color _shiftTextColor(String? s) {
  switch (s) {
    case '早班': return AppColors.shiftMorningText;
    case '晚班': return AppColors.shiftEveningText;
    case '休假': return AppColors.shiftOffText;
    default: return _customShiftColor(s);
  }
}

Color _shiftBgColor(String? s) {
  switch (s) {
    case '早班': return AppColors.shiftMorningBg;
    case '晚班': return AppColors.shiftEveningBg;
    case '休假': return AppColors.shiftOffBg;
    default:
      if (s == null) return Colors.transparent;
      final match =
          AppState.customShifts.value.where((c) => c.name == s);
      if (match.isEmpty) return Colors.transparent;
      return Color(match.first.colorValue).withValues(alpha: 0.18);
  }
}

String _shiftShort(String s) {
  switch (s) {
    case '早班': return '早';
    case '晚班': return '晚';
    case '休假': return '休';
    default: return s;
  }
}

/// 統一讀取班別：支援舊格式 shift: String 與新格式 shifts: List<String>
List<String> _getShifts(Map<String, dynamic>? data) {
  if (data == null) return const [];
  final list = data['shifts'];
  if (list is List) return list.whereType<String>().toList();
  final single = data['shift'];
  return single is String && single.isNotEmpty ? [single] : const [];
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DateTime _today = DateTime.now();
  late DateTime _focusedMonth;
  bool _showDonut = true;

  Map<String, Map<String, dynamic>> get _dayData => AppState.dayData.value;
  int get _monthBudget => AppState.monthBudget.value;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_today.year, _today.month);
    localeNotifier.addListener(_rebuild);
    AppState.dayData.addListener(_rebuild);
    AppState.entries.addListener(_rebuild);
    AppState.monthBudget.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    AppState.dayData.removeListener(_rebuild);
    AppState.entries.removeListener(_rebuild);
    AppState.monthBudget.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  List<DateTime> _daysInMonth(DateTime m) {
    final last = DateTime(m.year, m.month + 1, 0);
    return List.generate(last.day, (i) => DateTime(m.year, m.month, i + 1));
  }

  int get _totalExpense {
    final prefix = '${_focusedMonth.year}-${_focusedMonth.month}-';
    return _dayData.entries
        .where((e) => e.key.startsWith(prefix) && e.value['expense'] != null)
        .fold(0, (s, e) => s + (e.value['expense'] as int));
  }

  int get _workDays {
    final prefix = '${_focusedMonth.year}-${_focusedMonth.month}-';
    int count = 0;
    for (final e in _dayData.entries) {
      if (!e.key.startsWith(prefix)) continue;
      final shifts = _getShifts(e.value);
      if (shifts.any((s) => s == '早班' || s == '晚班')) count++;
    }
    return count;
  }

  double get _estimatedSalary =>
      AppState.totalConfirmedIncome + AppState.totalPendingIncome;

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth(_focusedMonth);
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;
    R.init(context);

    return Container(
      color: _bg,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: R.sp(12)),
            _buildTreasuryHeader(),
            SizedBox(height: R.sp(8)),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildCalendar(days, firstWeekday),
                  Positioned(
                    top: -R.sp(6),
                    right: R.sp(6),
                    child: _buildStickyNoteButton(),
                  ),
                ],
              ),
            ),
            SizedBox(height: R.sp(12)),
            _buildBottomStats(),
            SizedBox(height: R.sp(16)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(height: R.sp(8));
  }

  Widget _buildTreasuryHeader() {
    final treasury = AppState.treasury;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.sp(24)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.t('treasury'),
                  style: TextStyle(
                    fontSize: R.fs(12),
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.8,
                  ),
                ),
                SizedBox(height: R.sp(4)),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: treasury),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'NT\$',
                        style: GoogleFonts.fraunces(
                          fontSize: R.fs(17),
                          color: AppColors.danger.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: R.sp(6)),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            v.toStringAsFixed(0),
                            style: GoogleFonts.fraunces(
                              fontSize: R.fs(56),
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1.6,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: R.sp(10)),
          GestureDetector(
            onTap: _openSettingsSheet,
            child: Container(
              width: R.sp(38),
              height: R.sp(34),
              decoration: BoxDecoration(
                color: AppColors.backgroundAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: R.fs(18),
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStats() {
    final workDays = _workDays;
    final salary = _estimatedSalary;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.sp(20)),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: R.sp(18), vertical: R.sp(14)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '本月上班',
                    style: TextStyle(
                      fontSize: R.fs(11),
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                    ),
                  ),
                  SizedBox(height: R.sp(2)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$workDays',
                        style: GoogleFonts.fraunces(
                          fontSize: R.fs(24),
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: R.sp(3)),
                      Text(
                        '天',
                        style: TextStyle(
                          fontSize: R.fs(11),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(width: 1, height: R.sp(40), color: AppColors.divider),
            SizedBox(width: R.sp(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '預估薪資',
                    style: TextStyle(
                      fontSize: R.fs(11),
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                    ),
                  ),
                  SizedBox(height: R.sp(2)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'NT\$',
                        style: GoogleFonts.fraunces(
                          fontSize: R.fs(11),
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(width: R.sp(3)),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            salary.toStringAsFixed(0),
                            style: GoogleFonts.fraunces(
                              fontSize: R.fs(24),
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.5,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 便利貼風格的「快速排班」按鈕，貼在日曆右上角外面
  Widget _buildStickyNoteButton() {
    return GestureDetector(
      onTap: _openQuickSchedule,
      child: Transform.rotate(
        angle: 0.06, // 約 3.4 度，模擬便利貼歪斜
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: R.sp(14), vertical: R.sp(9)),
          decoration: BoxDecoration(
            color: AppColors.onPrimary, // 偏白米色
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 10,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded,
                  color: AppColors.primary, size: R.fs(14)),
              SizedBox(width: R.sp(4)),
              Text(
                '快速排班',
                style: TextStyle(
                  fontSize: R.fs(12),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthStats() {
    final workDays = _workDays;
    final salary = _estimatedSalary;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.sp(24)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本月上班',
                  style: TextStyle(
                    fontSize: R.fs(11),
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: R.sp(2)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$workDays',
                      style: GoogleFonts.fraunces(
                        fontSize: R.fs(24),
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                    SizedBox(width: R.sp(3)),
                    Text(
                      '天',
                      style: TextStyle(
                        fontSize: R.fs(11),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: R.sp(34),
            color: AppColors.divider,
          ),
          SizedBox(width: R.sp(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '預估薪資',
                  style: TextStyle(
                    fontSize: R.fs(11),
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: R.sp(2)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'NT\$',
                      style: GoogleFonts.fraunces(
                        fontSize: R.fs(11),
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(width: R.sp(3)),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          salary.toStringAsFixed(0),
                          style: GoogleFonts.fraunces(
                            fontSize: R.fs(24),
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickScheduleButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(R.sp(28), R.sp(24), R.sp(28), 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _openQuickSchedule,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: R.sp(14)),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_outlined,
                        color: AppColors.onPrimary, size: R.fs(16)),
                    SizedBox(width: R.sp(8)),
                    Text(
                      '快速排班',
                      style: TextStyle(
                        fontSize: R.fs(14),
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: R.sp(10)),
          GestureDetector(
            onTap: _copyLastWeek,
            child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: R.sp(14), horizontal: R.sp(16)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Icon(Icons.content_copy_outlined,
                  color: AppColors.textSecondary, size: R.fs(16)),
            ),
          ),
        ],
      ),
    );
  }

  void _openQuickSchedule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickScheduleSheet(
        focusedMonth: _focusedMonth,
        existingData: Map.of(_dayData),
        onApply: (assignments) {
          final m = Map<String, Map<String, dynamic>>.from(_dayData);
          assignments.forEach((date, shift) {
            final k = _key(date);
            final cur = Map<String, dynamic>.from(m[k] ?? {});
            cur.remove('shift'); // 清除舊格式
            cur['shifts'] = [shift];
            m[k] = cur;
          });
          AppState.dayData.value = m;
        },
        onClear: (days) {
          final m = Map<String, Map<String, dynamic>>.from(_dayData);
          for (final d in days) {
            final k = _key(d);
            final cur = Map<String, dynamic>.from(m[k] ?? {});
            cur.remove('shift');
            cur.remove('shifts');
            if (cur.isEmpty) {
              m.remove(k);
            } else {
              m[k] = cur; // 保留花費等其他欄位
            }
          }
          AppState.dayData.value = m;
        },
      ),
    );
  }

  String _monthLabelEn(int m) {
    const names = [
      'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'
    ];
    return names[(m - 1).clamp(0, 11)];
  }

  Widget _buildWeekStrip() {
    final base = _today.month == _focusedMonth.month &&
            _today.year == _focusedMonth.year
        ? _today
        : DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final weekStart = base.subtract(Duration(days: base.weekday % 7));
    int m = 0, e = 0, o = 0, exp = 0;
    for (int i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      if (d.month != _focusedMonth.month) continue;
      final data = _dayData[_key(d)];
      if (data == null) continue;
      final s = data['shift'] as String?;
      if (s == '早班') m++;
      else if (s == '晚班') e++;
      else if (s == '休假') o++;
      exp += (data['expense'] as int?) ?? 0;
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(R.sp(20), R.sp(12), R.sp(20), 0),
      child: SizedBox(
        height: R.sp(58),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          children: [
            _WeekChip(label: '本週', value: '${m + e} 天', highlight: true),
            SizedBox(width: R.sp(8)),
            _WeekChip(label: '早', value: '$m', dot: _purple),
            SizedBox(width: R.sp(8)),
            _WeekChip(label: '晚', value: '$e', dot: _blue),
            SizedBox(width: R.sp(8)),
            _WeekChip(label: '休', value: '$o', dot: _green),
            SizedBox(width: R.sp(8)),
            _WeekChip(label: '花費', value: 'NT\$$exp'),
          ],
        ),
      ),
    );
  }


  Widget _buildCalendar(List<DateTime> days, int firstWeekday) {
    final totalCells = days.length + firstWeekday;
    final rows = (totalCells / 7).ceil();
    return Padding(
      padding: EdgeInsets.fromLTRB(R.sp(20), R.sp(16), R.sp(20), 0),
      child: Container(
        padding: EdgeInsets.fromLTRB(
            R.sp(20), R.sp(22), R.sp(20), R.sp(22)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  S.monthYear(_focusedMonth.year, _focusedMonth.month),
                  style: GoogleFonts.fraunces(
                    fontSize: R.fs(22),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                _ChevronBtn(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => setState(() => _focusedMonth = DateTime(
                      _focusedMonth.year, _focusedMonth.month - 1)),
                ),
                SizedBox(width: R.sp(6)),
                _ChevronBtn(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => setState(() => _focusedMonth = DateTime(
                      _focusedMonth.year, _focusedMonth.month + 1)),
                ),
              ],
            ),
            SizedBox(height: R.sp(18)),
            Row(
              children: S.weekdayHeaders
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            SizedBox(height: R.sp(10)),
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, c) {
                  const spacing = 4.0;
                  final cellW = (c.maxWidth - spacing * 6) / 7;
                  final cellH = (c.maxHeight - spacing * (rows - 1)) / rows;
                  final aspect = cellW / cellH;
                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: aspect,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                    ),
                    itemCount: totalCells,
                    itemBuilder: (ctx, index) {
                      if (index < firstWeekday) return const SizedBox();
                      final day = days[index - firstWeekday];
                      return _DayCell(
                        day: day,
                        today: _today,
                        data: _dayData[_key(day)],
                        onTap: () => _openDaySheet(day),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    final spent = _totalExpense;
    final remain = (_monthBudget - spent).clamp(0, _monthBudget);
    final pct = _monthBudget > 0 ? spent / _monthBudget : 0.0;
    final centerColor = pct > 1
        ? _pink
        : pct > 0.8
            ? _amber
            : _green;

    return Padding(
      padding: EdgeInsets.fromLTRB(R.sp(20), R.sp(16), R.sp(20), 0),
      child: Container(
        padding: EdgeInsets.all(R.sp(20)),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.t('finance_analysis'),
                    style: TextStyle(
                        fontSize: R.fs(16),
                        fontWeight: FontWeight.w700,
                        color: _text)),
                GestureDetector(
                  onTap: _openBudgetDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(S.t('set_budget'),
                        style: TextStyle(
                            fontSize: R.fs(12),
                            color: _indigo,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _ToggleBtn(
                    label: S.t('donut_chart'),
                    active: _showDonut,
                    onTap: () => setState(() => _showDonut = true),
                  ),
                  _ToggleBtn(
                    label: S.t('line_chart'),
                    active: !_showDonut,
                    onTap: () => setState(() => _showDonut = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_showDonut)
              _buildDonut(spent, remain, centerColor)
            else
              _buildLineChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildDonut(int spent, int remain, Color centerColor) {
    final hasData = spent > 0 || _monthBudget > 0;
    return Row(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 3,
                  centerSpaceRadius: 42,
                  sections: hasData
                      ? [
                          PieChartSectionData(
                            value: spent.toDouble().clamp(1, double.infinity),
                            color: _purple,
                            radius: 18,
                            showTitle: false,
                          ),
                          if (_monthBudget > 0 && remain > 0)
                            PieChartSectionData(
                              value: remain.toDouble(),
                              color: _green.withValues(alpha: 0.5),
                              radius: 14,
                              showTitle: false,
                            ),
                        ]
                      : [
                          PieChartSectionData(
                            value: 1,
                            color: _card2,
                            radius: 14,
                            showTitle: false,
                          ),
                        ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _monthBudget > 0 ? S.t('remaining') : S.t('expense'),
                    style: const TextStyle(fontSize: 11, color: _text3),
                  ),
                  Text(
                    _monthBudget > 0
                        ? 'NT\$${(_monthBudget - spent).abs()}'
                        : 'NT\$$spent',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: centerColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendRow(
                  color: _purple,
                  label: S.t('spent'),
                  value: 'NT\$$spent'),
              const SizedBox(height: 10),
              _LegendRow(
                  color: _green,
                  label: S.t('remaining_budget'),
                  value: _monthBudget > 0 ? 'NT\$$remain' : '—'),
              const SizedBox(height: 10),
              _LegendRow(
                  color: _card2,
                  label: S.t('monthly_budget'),
                  value: _monthBudget > 0
                      ? 'NT\$$_monthBudget'
                      : S.t('not_set')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final lastDay =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final spots = <FlSpot>[];
    for (int d = 1; d <= lastDay; d++) {
      final k = _key(DateTime(_focusedMonth.year, _focusedMonth.month, d));
      final exp = (_dayData[k]?['expense'] as int?) ?? 0;
      if (exp > 0) spots.add(FlSpot(d.toDouble(), exp.toDouble()));
    }
    if (spots.isEmpty) {
      spots.addAll([FlSpot(1, 0), FlSpot(lastDay.toDouble(), 0)]);
    }

    return SizedBox(
      height: 130,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFF1E1E2E),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (lastDay / 4).ceilToDouble(),
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}${S.t('day_label')}',
                  style: const TextStyle(fontSize: 10, color: _text3),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(colors: [_purple, _blue]),
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
                  radius: 3.5,
                  color: _purple,
                  strokeWidth: 1.5,
                  strokeColor: _bg,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _purple.withValues(alpha: 0.3),
                    _purple.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyLastWeek() {
    final base = _today.month == _focusedMonth.month &&
            _today.year == _focusedMonth.year
        ? _today
        : DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final weekStart = base.subtract(Duration(days: base.weekday % 7));
    int copied = 0;
    final m = Map<String, Map<String, dynamic>>.from(_dayData);
    for (int i = 0; i < 7; i++) {
      final cur = weekStart.add(Duration(days: i));
      final prev = cur.subtract(const Duration(days: 7));
      if (cur.month != _focusedMonth.month) continue;
      final srcKey = _key(prev);
      final dstKey = _key(cur);
      final src = _dayData[srcKey];
      if (src != null) {
        final copy = Map<String, dynamic>.from(src)..remove('expense');
        m[dstKey] = copy;
        copied++;
      }
    }
    AppState.dayData.value = m;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已複製上週 $copied 天'),
        backgroundColor: _purple,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  void _openDaySheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DaySheet(
        day: day,
        data: Map<String, dynamic>.from(_dayData[_key(day)] ?? {}),
        onSave: (data) => AppState.setDayData(_key(day), data),
      ),
    );
  }

  void _openBudgetDialog() {
    final ctrl =
        TextEditingController(text: _monthBudget > 0 ? '$_monthBudget' : '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(S.t('set_monthly_budget'),
            style: TextStyle(
                color: _text,
                fontSize: R.fs(18),
                fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _text, fontSize: 16),
          decoration: InputDecoration(
            prefixText: 'NT\$ ',
            prefixStyle: const TextStyle(color: _text2),
            hintText: S.t('budget_hint'),
            hintStyle: const TextStyle(color: _text3),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.t('cancel'),
                  style: const TextStyle(color: _text2))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _purple),
            onPressed: () {
              AppState.monthBudget.value = int.tryParse(ctrl.text) ?? 0;
              Navigator.pop(context);
            },
            child: Text(S.t('confirm')),
          ),
        ],
      ),
    );
  }

  void _openLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguageSheet(current: localeNotifier.value),
    );
  }

  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettingsSheet(
        onLanguage: () {
          Navigator.pop(context);
          _openLanguageSheet();
        },
      ),
    );
  }
}

// ── Language Sheet ───────────────────────────────────────────────────────────

class _LanguageSheet extends StatelessWidget {
  final String current;
  const _LanguageSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final langs = [
      ('zh', '繁體中文', '🇹🇼'),
      ('en', 'English', '🇺🇸'),
      ('ja', '日本語', '🇯🇵'),
    ];
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _text3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(S.t('language'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _text)),
            const SizedBox(height: 20),
            ...langs.map((lang) {
              final selected = current == lang.$1;
              return GestureDetector(
                onTap: () {
                  localeNotifier.value = lang.$1;
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? _purple.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? _purple : _border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang.$3, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Text(lang.$2,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selected ? _purple : _text,
                          )),
                      const Spacer(),
                      if (selected)
                        const Icon(Icons.check_circle,
                            color: _purple, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Settings Sheet ───────────────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  final VoidCallback onLanguage;
  const _SettingsSheet({required this.onLanguage});

  @override
  Widget build(BuildContext context) {
    final currentLangLabel = localeNotifier.value == 'zh'
        ? '繁體中文'
        : localeNotifier.value == 'ja'
            ? '日本語'
            : 'English';

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _text3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                S.t('settings'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SettingsRow(
              icon: Icons.language_rounded,
              label: S.t('language'),
              value: currentLangLabel,
              onTap: onLanguage,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _card2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _text2),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _text,
              ),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 13,
                  color: _text2,
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 20, color: _text3),
          ],
        ),
      ),
    );
  }
}

// ── Sub Widgets ───────────────────────────────────────────────────────────────

class _DayCell extends StatefulWidget {
  final DateTime day, today;
  final Map<String, dynamic>? data;
  final VoidCallback onTap;
  const _DayCell(
      {required this.day,
      required this.today,
      required this.data,
      required this.onTap});

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final shifts = _getShifts(widget.data);
    final hasExpense = widget.data?['expense'] != null;
    final isToday = widget.day.year == widget.today.year &&
        widget.day.month == widget.today.month &&
        widget.day.day == widget.today.day;
    final isWeekend = widget.day.weekday == DateTime.sunday ||
        widget.day.weekday == DateTime.saturday;

    // 決定背景
    Decoration bgDecoration;
    if (isToday) {
      bgDecoration = BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      );
    } else if (shifts.length >= 2) {
      // 雙班：左右分色
      bgDecoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _shiftBgColor(shifts[0]),
            _shiftBgColor(shifts[0]),
            _shiftBgColor(shifts[1]),
            _shiftBgColor(shifts[1]),
          ],
          stops: const [0, 0.5, 0.5, 1],
        ),
        borderRadius: BorderRadius.circular(12),
      );
    } else if (shifts.length == 1) {
      bgDecoration = BoxDecoration(
        color: _shiftBgColor(shifts.first),
        borderRadius: BorderRadius.circular(12),
      );
    } else {
      bgDecoration = BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      );
    }

    // 數字顏色（雙班時用主文字黑）
    final Color numberColor;
    if (isToday) {
      numberColor = AppColors.onPrimary;
    } else if (shifts.length == 1) {
      numberColor = _shiftTextColor(shifts.first);
    } else if (shifts.length >= 2) {
      numberColor = AppColors.textPrimary;
    } else if (isWeekend) {
      numberColor = AppColors.textMuted;
    } else {
      numberColor = AppColors.textPrimary;
    }

    // 班別標籤文字
    String? shiftLabel;
    Color labelColor = AppColors.textPrimary;
    if (shifts.length == 1) {
      shiftLabel = S.shift(shifts.first);
      labelColor = isToday
          ? AppColors.onPrimary.withValues(alpha: 0.85)
          : _shiftTextColor(shifts.first);
    } else if (shifts.length >= 2) {
      shiftLabel = '${_shiftShort(shifts[0])}·${_shiftShort(shifts[1])}';
      labelColor = isToday
          ? AppColors.onPrimary.withValues(alpha: 0.85)
          : AppColors.textPrimary;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: bgDecoration,
          child: Stack(
            children: [
              // 日期數字：永遠在上方 12px 處（不受有無班別影響）
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${widget.day.day}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: numberColor,
                      letterSpacing: -0.3,
                      height: 1,
                    ),
                  ),
                ),
              ),
              // 班別標籤：永遠貼底 10px
              if (shiftLabel != null)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      shiftLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                        letterSpacing: 0.4,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              // 花費小點：右上
              if (hasExpense)
                Positioned(
                  top: 7,
                  right: 8,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.onPrimary
                          : AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  final String emoji, label;
  final Color color;
  const _TinyChip(
      {required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekChip extends StatelessWidget {
  final String label, value;
  final Color? dot;
  final bool highlight;
  const _WeekChip({
    required this.label,
    required this.value,
    this.dot,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                colors: [
                  _purple.withValues(alpha: 0.28),
                  _blue.withValues(alpha: 0.15),
                ],
              )
            : null,
        color: highlight ? null : _card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? _indigo.withValues(alpha: 0.35)
              : _border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _text3,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: highlight ? const Color(0xFFEDE8FF) : _text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _card2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _text2, size: 20),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji, label, value;
  final Color accent;
  const _StatChip(
      {required this.emoji,
      required this.label,
      required this.value,
      required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? _card2 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? _indigo : _text3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label, value;
  const _LegendRow(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: _text3)),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
      ],
    );
  }
}

// ── Day Bottom Sheet ──────────────────────────────────────────────────────────

class _DaySheet extends StatefulWidget {
  final DateTime day;
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onSave;
  const _DaySheet(
      {required this.day, required this.data, required this.onSave});

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  final List<String> _shifts = [];
  late TextEditingController _timeCtrl;
  late TextEditingController _expCtrl;

  @override
  void initState() {
    super.initState();
    _shifts.addAll(_getShifts(widget.data));
    _timeCtrl = TextEditingController(text: widget.data['workTime'] ?? '');
    _expCtrl = TextEditingController(
        text: widget.data['expense']?.toString() ?? '');
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    _timeCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _text3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${S.dateHeader(widget.day.month, widget.day.day)}　${S.weekdayName(widget.day.weekday)}',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _text),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(S.t('shift'),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _text3,
                        letterSpacing: 0.8)),
                const SizedBox(width: 6),
                Text('（可複選，最多 2 班）',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: _shiftColors.entries.map((e) {
                final selected = _shifts.contains(e.key);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _shifts.remove(e.key);
                        } else if (_shifts.length < 2) {
                          _shifts.add(e.key);
                        } else {
                          // 已選兩個，替換最早的
                          _shifts.removeAt(0);
                          _shifts.add(e.key);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? e.value.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? e.value : _border,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected) ...[
                                Icon(Icons.check_rounded,
                                    size: 14, color: e.value),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                S.shift(e.key),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? e.value : _text2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(S.t('work_time'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _text3,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            _SheetInput(
              controller: _timeCtrl,
              hint: S.t('work_time_hint'),
              icon: Icons.access_time_rounded,
              iconColor: _purple,
              fillColor: _card2,
            ),
            const SizedBox(height: 16),
            Text(S.t('today_expense'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _text3,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            _SheetInput(
              controller: _expCtrl,
              hint: '0',
              icon: Icons.payments_outlined,
              iconColor: _pink,
              fillColor: _card2,
              prefix: 'NT\$ ',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  backgroundColor: _purple,
                  shadowColor: _purple.withValues(alpha: 0.4),
                  elevation: 8,
                ),
                onPressed: () {
                  widget.onSave({
                    if (_shifts.isNotEmpty) 'shifts': List<String>.from(_shifts),
                    if (_timeCtrl.text.isNotEmpty)
                      'workTime': _timeCtrl.text,
                    if (_expCtrl.text.isNotEmpty)
                      'expense': int.tryParse(_expCtrl.text) ?? 0,
                  });
                  Navigator.pop(context);
                },
                child: Text(S.t('save'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor, fillColor;
  final String? prefix;
  final TextInputType keyboardType;

  const _SheetInput({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.fillColor,
    this.prefix,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _text, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _text3),
        prefixText: prefix,
        prefixStyle: const TextStyle(color: _text2, fontSize: 16),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
      ),
    );
  }
}

// ignore: unused_element
double _toRad(double deg) => deg * math.pi / 180;

class _MiniStatRow extends StatelessWidget {
  final Color dot;
  final String label, value;
  const _MiniStatRow({
    required this.dot,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              letterSpacing: -0.2
            ),
          ),
        ],
      ),
    );
  }
}

class _ChevronBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ChevronBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  final String label, value;
  final bool smallValue;
  const _GlassStat({
    required this.label,
    required this.value,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: smallValue ? 15 : 20,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Schedule Sheet ──────────────────────────────────────────────────────
class _QuickScheduleSheet extends StatefulWidget {
  final DateTime focusedMonth;
  final Map<String, Map<String, dynamic>> existingData;
  final void Function(Map<DateTime, String> assignments) onApply;
  final void Function(List<DateTime> days) onClear;

  const _QuickScheduleSheet({
    required this.focusedMonth,
    required this.existingData,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_QuickScheduleSheet> createState() => _QuickScheduleSheetState();
}

class _QuickScheduleSheetState extends State<_QuickScheduleSheet> {
  String? _shift = '早班';
  // 每一天各自記它被選成哪個班 — 切換班別不影響已點的天
  final Map<int, String> _assignments = {};

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  void initState() {
    super.initState();
    AppState.customShifts.addListener(_onCustomShiftsChanged);
  }

  @override
  void dispose() {
    AppState.customShifts.removeListener(_onCustomShiftsChanged);
    super.dispose();
  }

  void _onCustomShiftsChanged() => setState(() {});

  List<String> _getShiftsLocal(Map<String, dynamic>? data) {
    if (data == null) return const [];
    final list = data['shifts'];
    if (list is List) return list.whereType<String>().toList();
    final single = data['shift'];
    return single is String && single.isNotEmpty ? [single] : const [];
  }

  /// 複製上個月同樣天號的班別到這個月
  void _copyPrevMonth() {
    final m = widget.focusedMonth;
    final prev = DateTime(m.year, m.month - 1);
    final daysInPrev = DateTime(prev.year, prev.month + 1, 0).day;
    final daysInThis = DateTime(m.year, m.month + 1, 0).day;
    int copied = 0;
    setState(() {
      for (int d = 1; d <= daysInPrev && d <= daysInThis; d++) {
        final k = '${prev.year}-${prev.month}-$d';
        final shifts = _getShiftsLocal(widget.existingData[k]);
        if (shifts.isEmpty) continue;
        _assignments[d] = shifts.first;
        copied++;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(copied == 0
              ? '上個月沒有排班紀錄'
              : '已複製上月 $copied 天（記得按「套用」儲存）'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openShiftDialog({CustomShift? existing}) async {
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    const palette = [
      Color(0xFF7B8F6B), // sage
      Color(0xFFB8974E), // mustard
      Color(0xFFB5685D), // rose
      Color(0xFF6B8FA6), // slate blue
      Color(0xFF8E6FA3), // dusty purple
      Color(0xFF4B7A66), // forest
      Color(0xFFA37260), // terracotta
      Color(0xFF5C6E7F), // storm
    ];
    int selectedColor = existing?.colorValue ?? palette.first.value;

    final result = await showDialog<Object>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isEdit ? '編輯班別' : '新增班別'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtl,
                maxLength: 4,
                decoration: const InputDecoration(
                  hintText: '例：大夜、加班',
                  labelText: '班別名稱',
                ),
              ),
              const SizedBox(height: 12),
              const Text('選顏色',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: palette.map((c) {
                  final active = c.value == selectedColor;
                  return GestureDetector(
                    onTap: () => setS(() => selectedColor = c.value),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active
                              ? AppColors.textPrimary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger),
                child: const Text('刪除'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtl.text.trim();
                if (name.isEmpty) return;
                if (['早班', '晚班', '休假'].contains(name)) return;
                if (AppState.customShifts.value.any(
                    (c) => c.name == name && c.name != existing?.name)) {
                  return;
                }
                Navigator.pop(
                    ctx,
                    CustomShift(name: name, colorValue: selectedColor));
              },
              child: Text(isEdit ? '儲存' : '新增'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    if (result == 'delete' && existing != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('刪除「${existing.name}」？'),
          content: const Text('已排這個班別的日子會一併清除。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('確認刪除')),
          ],
        ),
      );
      if (ok == true) {
        AppState.removeCustomShift(existing.name);
        if (_shift == existing.name) setState(() => _shift = null);
      }
      return;
    }
    if (result is CustomShift) {
      if (isEdit) {
        AppState.updateCustomShift(existing.name, result);
        if (_shift == existing.name) setState(() => _shift = result.name);
      } else {
        AppState.addCustomShift(result);
        setState(() => _shift = result.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.focusedMonth;
    final daysInMonth = DateTime(m.year, m.month + 1, 0).day;
    final firstWd = DateTime(m.year, m.month, 1).weekday % 7;
    final customs = AppState.customShifts.value;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('快速排班',
                            style: TextStyle(
                                fontSize: R.fs(22),
                                fontWeight: FontWeight.w800,
                                color: _text)),
                        const SizedBox(height: 4),
                        Text('選班別 → 點天，可再換班別點其它天',
                            style: TextStyle(
                                fontSize: R.fs(13), color: _text2)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _copyPrevMonth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _card2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.content_copy_outlined,
                              size: R.fs(12), color: _text2),
                          const SizedBox(width: 4),
                          Text('複製上月',
                              style: TextStyle(
                                  fontSize: R.fs(12),
                                  color: _text2,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _qsShiftPill(
                      '早班', _amberWarm, AppColors.shiftMorningBg, '☀️'),
                  _qsShiftPill('晚班', _indigo, AppColors.shiftEveningBg, '🌙'),
                  _qsShiftPill('休假', _sage, AppColors.shiftOffBg, '🌿'),
                  for (final c in customs)
                    _qsCustomPill(c),
                  _qsAddPill(),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _card2,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${m.year} 年 ${m.month} 月',
                                style: TextStyle(
                                    fontSize: R.fs(15),
                                    fontWeight: FontWeight.w700,
                                    color: _text),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: ['日', '一', '二', '三', '四', '五', '六']
                                .map((d) => Expanded(
                                      child: Center(
                                        child: Text(d,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: (d == '日' || d == '六')
                                                  ? _rose
                                                  : _text3,
                                            )),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 4),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1,
                            ),
                            itemCount: daysInMonth + firstWd,
                            itemBuilder: (_, i) {
                              if (i < firstWd) return const SizedBox();
                              final day = i - firstWd + 1;
                              final dt = DateTime(m.year, m.month, day);
                              final existingShifts =
                                  _getShifts(widget.existingData[_key(dt)]);
                              final existing = existingShifts.isNotEmpty
                                  ? existingShifts.first
                                  : null;
                              final assignedShift = _assignments[day];
                              final selected = assignedShift != null;

                              // 預覽色：用該日「被指定的」班別，而非當前 pill
                              final previewColor = selected
                                  ? (_shiftColors[assignedShift] ??
                                      AppColors.primary)
                                  : AppColors.primary;
                              return GestureDetector(
                                onTap: () {
                                  if (_shift == null) return;
                                  setState(() {
                                    if (assignedShift == _shift) {
                                      _assignments.remove(day);
                                    } else {
                                      _assignments[day] = _shift!;
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? previewColor.withValues(alpha: 0.55)
                                        : _shiftBgColor(existing),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? previewColor
                                          : existing != null
                                              ? (_shiftColors[existing] ??
                                                      _border)
                                                  .withValues(alpha: 0.4)
                                              : AppColors.divider
                                                  .withValues(alpha: 0.5),
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: GoogleFonts.fraunces(
                                        fontSize: 14,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: selected
                                            ? Colors.white
                                            : existing != null
                                                ? _shiftTextColor(existing)
                                                : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                color: _card,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  // 清除按鈕（次要）：刪除所選天的班別
                  Expanded(
                    flex: 3,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(
                          color: _assignments.isEmpty
                              ? _border
                              : AppColors.danger.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _assignments.isEmpty
                          ? null
                          : () {
                              final days = _assignments.keys
                                  .map((d) => DateTime(m.year, m.month, d))
                                  .toList();
                              widget.onClear(days);
                              Navigator.pop(context);
                            },
                      child: Text(
                        _assignments.isEmpty
                            ? '清除'
                            : '清除 ${_assignments.length} 天',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 套用按鈕（主要）
                  Expanded(
                    flex: 5,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _assignments.isEmpty
                          ? null
                          : () {
                              final assignments = <DateTime, String>{};
                              _assignments.forEach((day, shift) {
                                assignments[DateTime(m.year, m.month, day)] =
                                    shift;
                              });
                              widget.onApply(assignments);
                              Navigator.pop(context);
                            },
                      child: Text(
                        _assignments.isEmpty
                            ? '請選日期'
                            : '套用 ${_assignments.length} 天',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qsShiftPill(String v, Color c, Color softBg, String emoji) {
    final active = _shift == v;
    return GestureDetector(
      onTap: () => setState(() => _shift = active ? null : v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? softBg : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? c : _border,
            width: active ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 4),
            Text(
              v,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? c : _text2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qsCustomPill(CustomShift cs) {
    final c = Color(cs.colorValue);
    final active = _shift == cs.name;
    return GestureDetector(
      onTap: () => setState(() => _shift = active ? null : cs.name),
      onLongPress: () => _openShiftDialog(existing: cs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.18) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? c : _border,
            width: active ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              cs.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? c : _text2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qsAddPill() {
    return GestureDetector(
      onTap: () => _openShiftDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: _text2),
            const SizedBox(width: 4),
            Text(
              '新增',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _text2,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
