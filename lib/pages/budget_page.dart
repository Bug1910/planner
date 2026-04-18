import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/responsive.dart';
import '../utils/locale_notifier.dart';
import '../utils/app_state.dart';
import '../l10n/strings.dart';
import '../theme/app_colors.dart';

const _purple = AppColors.primary;
const _blue = AppColors.primaryDark;
const _green = AppColors.accent;
const _orange = AppColors.warning;
const _surface = AppColors.surface;
const _bg = AppColors.background;

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    localeNotifier.addListener(_rebuild);
    AppState.entries.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    AppState.entries.removeListener(_rebuild);
    _tabController.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _openAddSheet(WorkType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddIncomeSheet(
        type: type,
        onSave: AppState.addEntry,
      ),
    );
  }

  void _confirmEntry(IncomeEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        entry: entry,
        onConfirm: (actual) => AppState.confirmEntry(entry, actual),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSummaryRow(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(R.sp(20), R.sp(20), R.sp(20), R.sp(8)),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.t('salary_mgmt'),
                  style: TextStyle(
                    fontSize: R.fs(24),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  )),
              Text(S.t('income_tracking'),
                  style: TextStyle(
                    fontSize: R.fs(13),
                    color: AppColors.textMuted,
                  )),
            ],
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: R.sp(12), vertical: R.sp(6)),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(R.sp(20)),
              border: Border.all(color: _purple.withValues(alpha: 0.3)),
            ),
            child: Text(
              S.t('treasury'),
              style: TextStyle(
                fontSize: R.fs(12),
                color: _purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: R.sp(20), vertical: R.sp(8)),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: S.t('confirmed'),
              amount: AppState.totalConfirmedIncome,
              color: _green,
              icon: Icons.check_circle_outline,
            ),
          ),
          SizedBox(width: R.sp(10)),
          Expanded(
            child: _SummaryCard(
              label: S.t('pending'),
              amount: AppState.totalPendingIncome,
              color: _orange,
              icon: Icons.hourglass_empty,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: R.sp(20), vertical: R.sp(4)),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(R.sp(12)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _purple.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(R.sp(10)),
          border: Border.all(color: _purple.withValues(alpha: 0.5)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: TextStyle(
            fontSize: R.fs(13), fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: R.fs(13), fontWeight: FontWeight.w400),
        tabs: [
          Tab(text: S.t('monthly_pay')),
          Tab(text: S.t('daily_pay')),
          const Tab(text: 'PT'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildList(WorkType.monthly),
        _buildList(WorkType.daily),
        _buildList(WorkType.pt),
      ],
    );
  }

  Widget _buildList(WorkType type) {
    final filtered =
        AppState.entries.value.where((e) => e.type == type).toList();
    if (filtered.isEmpty) {
      return _EmptyState(type: type, onAdd: () => _openAddSheet(type));
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(
          horizontal: R.sp(20), vertical: R.sp(8)),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _IncomeCard(
        entry: filtered[i],
        onConfirm: () => _confirmEntry(filtered[i]),
        onDelete: () => AppState.removeEntry(filtered[i]),
      ),
    );
  }

  Widget _buildFAB() {
    final types = [WorkType.monthly, WorkType.daily, WorkType.pt];
    return FloatingActionButton(
      backgroundColor: _purple,
      onPressed: () => _openAddSheet(types[_tabController.index]),
      child: const Icon(Icons.add, color: AppColors.textPrimary),
    );
  }
}

String _typeLabel(WorkType t) {
  switch (t) {
    case WorkType.monthly:
      return S.t('monthly_pay');
    case WorkType.daily:
      return S.t('daily_pay');
    case WorkType.pt:
      return 'PT';
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(R.sp(14)),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(R.sp(14)),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(R.sp(8)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(R.sp(8)),
            ),
            child: Icon(icon, color: color, size: R.icon(18)),
          ),
          SizedBox(width: R.sp(10)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: R.fs(11),
                      color: AppColors.textMuted)),
              Text(
                '\$${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: R.fs(18),
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeCard extends StatelessWidget {
  final IncomeEntry entry;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;

  const _IncomeCard({
    required this.entry,
    required this.onConfirm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = entry.confirmed;
    final statusColor = isConfirmed ? _green : _orange;
    final typeColor = entry.type == WorkType.monthly
        ? _purple
        : entry.type == WorkType.daily
            ? _blue
            : _orange;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: R.sp(20)),
        margin: EdgeInsets.only(bottom: R.sp(10)),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(R.sp(14)),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: EdgeInsets.only(bottom: R.sp(10)),
        padding: EdgeInsets.all(R.sp(14)),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(R.sp(14)),
          border: Border.all(
              color: isConfirmed
                  ? _green.withValues(alpha: 0.2)
                  : const Color(0xFF2A2A3E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: R.sp(8), vertical: R.sp(3)),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(R.sp(6)),
                  ),
                  child: Text(
                    _typeLabel(entry.type),
                    style: TextStyle(
                        fontSize: R.fs(11),
                        color: typeColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: R.sp(8)),
                Expanded(
                  child: Text(entry.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: R.fs(15),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: R.sp(8), vertical: R.sp(3)),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(R.sp(6)),
                  ),
                  child: Text(
                    isConfirmed ? S.t('confirmed') : S.t('pending'),
                    style: TextStyle(
                        fontSize: R.fs(11),
                        color: statusColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            SizedBox(height: R.sp(10)),
            Row(
              children: [
                _AmountRow(
                    label: S.t('expected'),
                    amount: entry.expected,
                    color: const Color(0xFF8A88A8)),
                if (isConfirmed && entry.actual != null) ...[
                  SizedBox(width: R.sp(16)),
                  _AmountRow(
                      label: S.t('actual'),
                      amount: entry.actual!,
                      color: _green),
                ],
                if (entry.payDate != null) ...[
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.event_outlined,
                          size: R.icon(13),
                          color: AppColors.textMuted),
                      SizedBox(width: R.sp(3)),
                      Text(
                        '${entry.payDate!.month}/${entry.payDate!.day}',
                        style: TextStyle(
                            fontSize: R.fs(12),
                            color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (!isConfirmed) ...[
              SizedBox(height: R.sp(10)),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onConfirm,
                  style: TextButton.styleFrom(
                    backgroundColor: _purple.withValues(alpha: 0.15),
                    foregroundColor: _purple,
                    padding:
                        EdgeInsets.symmetric(vertical: R.sp(8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(R.sp(8)),
                      side: BorderSide(
                          color: _purple.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Text(S.t('confirm_payment'),
                      style: TextStyle(
                          fontSize: R.fs(13),
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountRow(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label：',
            style: TextStyle(
                fontSize: R.fs(12),
                color: AppColors.textMuted)),
        Text('\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: R.fs(15),
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final WorkType type;
  final VoidCallback onAdd;

  const _EmptyState({required this.type, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final label = _typeLabel(type);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined,
              size: R.icon(56), color: const Color(0xFF2A2A3E)),
          SizedBox(height: R.sp(14)),
          Text('${S.t('no_records')} · $label',
              style: TextStyle(
                  fontSize: R.fs(16),
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: R.sp(6)),
          Text(S.t('tap_to_add'),
              style: TextStyle(
                  fontSize: R.fs(13),
                  color: const Color(0xFF3A3858))),
          SizedBox(height: R.sp(24)),
          TextButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add_circle_outline,
                size: R.icon(18), color: _purple),
            label: Text('${S.t('add_record')} $label',
                style: TextStyle(
                    fontSize: R.fs(14),
                    color: _purple,
                    fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              backgroundColor: _purple.withValues(alpha: 0.1),
              padding: EdgeInsets.symmetric(
                  horizontal: R.sp(20), vertical: R.sp(10)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(R.sp(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddIncomeSheet extends StatefulWidget {
  final WorkType type;
  final void Function(IncomeEntry) onSave;

  const _AddIncomeSheet({required this.type, required this.onSave});

  @override
  State<_AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<_AddIncomeSheet> {
  final _labelCtrl = TextEditingController();
  final _expectedCtrl = TextEditingController();
  DateTime? _payDate;

  bool get _showPayDate =>
      widget.type == WorkType.monthly || widget.type == WorkType.pt;

  @override
  void initState() {
    super.initState();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    _labelCtrl.dispose();
    _expectedCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _save() {
    final label = _labelCtrl.text.trim();
    final expected = double.tryParse(_expectedCtrl.text) ?? 0;
    if (label.isEmpty || expected <= 0) return;

    widget.onSave(IncomeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: widget.type,
      label: label,
      expected: expected,
      payDate: _payDate,
      createdAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _purple,
            surface: _surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _payDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final typeLabel = _typeLabel(widget.type);
    return Container(
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(R.sp(24))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            R.sp(24), R.sp(20), R.sp(24), R.sp(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: R.sp(36),
                height: R.sp(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3858),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: R.sp(16)),
            Text('${S.t('add_record')} $typeLabel',
                style: TextStyle(
                    fontSize: R.fs(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            SizedBox(height: R.sp(20)),
            _InputField(
              controller: _labelCtrl,
              label: widget.type == WorkType.daily
                  ? S.t('date_or_desc')
                  : S.t('job_name'),
              hint: widget.type == WorkType.daily
                  ? S.t('date_hint')
                  : S.t('job_name_hint'),
            ),
            SizedBox(height: R.sp(12)),
            _InputField(
              controller: _expectedCtrl,
              label: S.t('expected_amount'),
              hint: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefix: '\$',
            ),
            if (_showPayDate) ...[
              SizedBox(height: R.sp(12)),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: R.sp(14), vertical: R.sp(14)),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(R.sp(12)),
                    border: Border.all(color: const Color(0xFF2A2A3E)),
                  ),
                  child: Row(
                    children: [
                      Text(S.t('pay_date'),
                          style: TextStyle(
                              fontSize: R.fs(13),
                              color: AppColors.textMuted)),
                      const Spacer(),
                      Text(
                        _payDate == null
                            ? S.t('select_date')
                            : '${_payDate!.year}/${_payDate!.month}/${_payDate!.day}',
                        style: TextStyle(
                          fontSize: R.fs(14),
                          color: _payDate == null
                              ? const Color(0xFF3A3858)
                              : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: R.sp(6)),
                      Icon(Icons.chevron_right,
                          size: R.icon(18),
                          color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: R.sp(24)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: R.sp(14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(R.sp(12)),
                  ),
                ),
                child: Text(S.t('save'),
                    style: TextStyle(
                        fontSize: R.fs(15),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatefulWidget {
  final IncomeEntry entry;
  final void Function(double actual) onConfirm;

  const _ConfirmSheet({required this.entry, required this.onConfirm});

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  late TextEditingController _actualCtrl;

  @override
  void initState() {
    super.initState();
    _actualCtrl = TextEditingController(
        text: widget.entry.expected.toStringAsFixed(0));
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    _actualCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _confirm() {
    final actual = double.tryParse(_actualCtrl.text) ?? widget.entry.expected;
    widget.onConfirm(actual);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final diff = (double.tryParse(_actualCtrl.text) ?? widget.entry.expected) -
        widget.entry.expected;

    return StatefulBuilder(
      builder: (ctx, setModalState) => Container(
        margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(R.sp(24))),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              R.sp(24), R.sp(20), R.sp(24), R.sp(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: R.sp(36),
                  height: R.sp(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3858),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: R.sp(16)),
              Text(S.t('confirm_payment'),
                  style: TextStyle(
                      fontSize: R.fs(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              SizedBox(height: R.sp(6)),
              Text(widget.entry.label,
                  style: TextStyle(
                      fontSize: R.fs(14),
                      color: AppColors.textMuted)),
              SizedBox(height: R.sp(20)),
              Container(
                padding: EdgeInsets.all(R.sp(14)),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(R.sp(12)),
                  border: Border.all(color: const Color(0xFF2A2A3E)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(S.t('expected_amount'),
                        style: TextStyle(
                            fontSize: R.fs(13),
                            color: AppColors.textMuted)),
                    Text('\$${widget.entry.expected.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: R.fs(15),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
              SizedBox(height: R.sp(12)),
              _InputField(
                controller: _actualCtrl,
                label: S.t('actual_amount'),
                hint: '0',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefix: '\$',
                onChanged: (_) => setModalState(() {}),
              ),
              if (diff != 0) ...[
                SizedBox(height: R.sp(8)),
                Row(
                  children: [
                    Icon(
                      diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: R.icon(13),
                      color: diff > 0 ? _green : Colors.red,
                    ),
                    SizedBox(width: R.sp(4)),
                    Text(
                      '${S.t('diff_from')} \$${diff.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: R.fs(12),
                        color: diff > 0 ? _green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: R.sp(24)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: R.sp(14)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(R.sp(12)),
                    ),
                  ),
                  child: Text(S.t('confirm_payment'),
                      style: TextStyle(
                          fontSize: R.fs(15),
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefix;
  final void Function(String)? onChanged;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.prefix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: R.fs(13),
                color: AppColors.textMuted)),
        SizedBox(height: R.sp(6)),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: TextStyle(
              fontSize: R.fs(15),
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: const Color(0xFF3A3858),
                fontSize: R.fs(15)),
            prefixText: prefix,
            prefixStyle: TextStyle(
                color: const Color(0xFF8A88A8),
                fontSize: R.fs(15)),
            filled: true,
            fillColor: _bg,
            contentPadding: EdgeInsets.symmetric(
                horizontal: R.sp(14), vertical: R.sp(14)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.sp(12)),
              borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.sp(12)),
              borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.sp(12)),
              borderSide: const BorderSide(color: _purple),
            ),
          ),
        ),
      ],
    );
  }
}
