import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive.dart';
import '../utils/app_state.dart';
import '../theme/app_colors.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focus = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    AppState.dayData.addListener(_rebuild);
  }

  @override
  void dispose() {
    AppState.dayData.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  List<String> _shiftsFor(DateTime d) {
    final data = AppState.dayData.value[_key(d)];
    if (data == null) return const [];
    final list = data['shifts'];
    if (list is List) return list.whereType<String>().toList();
    final single = data['shift'];
    return single is String && single.isNotEmpty ? [single] : const [];
  }

  int _expenseFor(DateTime d) =>
      (AppState.dayData.value[_key(d)]?['expense'] as int?) ?? 0;

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final daysInMonth = DateTime(_focus.year, _focus.month + 1, 0).day;
    final days = List.generate(
        daysInMonth, (i) => DateTime(_focus.year, _focus.month, i + 1));

    // 統計本月
    int morning = 0, evening = 0, off = 0, expense = 0;
    final scheduled = <DateTime>[];
    for (final d in days) {
      final shifts = _shiftsFor(d);
      if (shifts.isEmpty && _expenseFor(d) == 0) continue;
      scheduled.add(d);
      for (final s in shifts) {
        if (s == '早班') morning++;
        else if (s == '晚班') evening++;
        else if (s == '休假') off++;
      }
      expense += _expenseFor(d);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStats(morning, evening, off, expense, morning + evening),
            Expanded(
              child: scheduled.isEmpty
                  ? _buildEmpty()
                  : _buildTimeline(scheduled),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(R.sp(24), R.sp(20), R.sp(24), R.sp(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '班表',
                style: TextStyle(
                  fontSize: R.fs(22),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: R.sp(2)),
              Text(
                '${_focus.year} 年 ${_focus.month} 月',
                style: TextStyle(
                  fontSize: R.fs(13),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          _arrow(Icons.chevron_left_rounded, () {
            setState(() => _focus = DateTime(_focus.year, _focus.month - 1));
          }),
          SizedBox(width: R.sp(6)),
          _arrow(Icons.chevron_right_rounded, () {
            setState(() => _focus = DateTime(_focus.year, _focus.month + 1));
          }),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: R.sp(34),
        height: R.sp(34),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon,
            size: R.fs(20), color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildStats(int m, int e, int o, int exp, int workDays) {
    return Padding(
      padding: EdgeInsets.fromLTRB(R.sp(20), R.sp(8), R.sp(20), R.sp(12)),
      child: Container(
        padding: EdgeInsets.all(R.sp(18)),
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
        child: Column(
          children: [
            Row(
              children: [
                _statCell('上班天數', '$workDays', AppColors.primary),
                _statCell('本月花費', 'NT\$$exp', AppColors.danger),
              ],
            ),
            SizedBox(height: R.sp(14)),
            const Divider(height: 1, color: AppColors.divider),
            SizedBox(height: R.sp(14)),
            Row(
              children: [
                _miniCell(AppColors.shiftMorningDot, '早班', m),
                _miniCell(AppColors.shiftEveningDot, '晚班', e),
                _miniCell(AppColors.shiftOffDot, '休假', o),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: R.fs(11),
                color: AppColors.textSecondary,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              )),
          SizedBox(height: R.sp(6)),
          Text(value,
              style: GoogleFonts.fraunces(
                fontSize: R.fs(26),
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: -0.5,
              )),
        ],
      ),
    );
  }

  Widget _miniCell(Color dot, String label, int count) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          SizedBox(width: R.sp(6)),
          Text(label,
              style: TextStyle(
                fontSize: R.fs(12),
                color: AppColors.textSecondary,
              )),
          SizedBox(width: R.sp(6)),
          Text('$count',
              style: GoogleFonts.fraunces(
                fontSize: R.fs(16),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          Text(' 天',
              style: TextStyle(
                fontSize: R.fs(11),
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined,
              size: R.fs(56), color: AppColors.textMuted),
          SizedBox(height: R.sp(12)),
          Text('本月還沒排班',
              style: TextStyle(
                fontSize: R.fs(15),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              )),
          SizedBox(height: R.sp(4)),
          Text('回首頁點日期即可排班',
              style: TextStyle(
                fontSize: R.fs(12),
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<DateTime> scheduled) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(R.sp(20), 0, R.sp(20), R.sp(24)),
      itemCount: scheduled.length,
      separatorBuilder: (_, __) => SizedBox(height: R.sp(8)),
      itemBuilder: (_, i) {
        final d = scheduled[i];
        final shifts = _shiftsFor(d);
        final exp = _expenseFor(d);
        return Container(
          padding: EdgeInsets.symmetric(
              horizontal: R.sp(14), vertical: R.sp(12)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              // 日期
              SizedBox(
                width: R.sp(42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.day}',
                      style: GoogleFonts.fraunces(
                        fontSize: R.fs(22),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: R.sp(2)),
                    Text(
                      weekdays[(d.weekday - 1) % 7],
                      style: TextStyle(
                        fontSize: R.fs(10),
                        color: AppColors.textMuted,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: R.sp(12)),
              Container(width: 1, height: R.sp(32), color: AppColors.divider),
              SizedBox(width: R.sp(12)),
              // 班別 chips
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final s in shifts)
                      _shiftChip(s),
                    if (shifts.isEmpty)
                      Text('—',
                          style: TextStyle(
                            fontSize: R.fs(13),
                            color: AppColors.textMuted,
                          )),
                  ],
                ),
              ),
              // 花費
              if (exp > 0)
                Text(
                  'NT\$$exp',
                  style: GoogleFonts.fraunces(
                    fontSize: R.fs(14),
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _shiftChip(String s) {
    Color bg, text, dot;
    switch (s) {
      case '早班':
        bg = AppColors.shiftMorningBg;
        text = AppColors.shiftMorningText;
        dot = AppColors.shiftMorningDot;
        break;
      case '晚班':
        bg = AppColors.shiftEveningBg;
        text = AppColors.shiftEveningText;
        dot = AppColors.shiftEveningDot;
        break;
      case '休假':
        bg = AppColors.shiftOffBg;
        text = AppColors.shiftOffText;
        dot = AppColors.shiftOffDot;
        break;
      default:
        bg = AppColors.backgroundAlt;
        text = AppColors.textSecondary;
        dot = AppColors.textMuted;
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: R.sp(10), vertical: R.sp(5)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          SizedBox(width: R.sp(5)),
          Text(
            s,
            style: TextStyle(
              fontSize: R.fs(12),
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
