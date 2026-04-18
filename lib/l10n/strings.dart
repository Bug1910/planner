import '../utils/locale_notifier.dart';

class S {
  static String get _l => localeNotifier.value;

  static String t(String key) =>
      _map[_l]?[key] ?? _map['zh']![key] ?? key;

  static String shift(String key) => _shifts[_l]?[key] ?? key;

  static List<String> get weekdayHeaders => _wdHeaders[_l]!;

  static String weekdayName(int w) => _wdNames[_l]![w];

  static String dateHeader(int month, int day) {
    if (_l == 'en') return '${_months[month - 1]} $day';
    return '$month月$day日';
  }

  static String monthYear(int year, int month) {
    if (_l == 'en') return '${_months[month - 1]} $year';
    return '$year年 $month月';
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  static const _shifts = {
    'zh': {'早班': '早班', '晚班': '晚班', '休假': '休假'},
    'en': {'早班': 'Morning', '晚班': 'Evening', '休假': 'Day Off'},
    'ja': {'早班': '早番', '晚班': '遅番', '休假': '休み'},
  };

  static const _wdHeaders = {
    'zh': ['日', '一', '二', '三', '四', '五', '六'],
    'en': ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'],
    'ja': ['日', '月', '火', '水', '木', '金', '土'],
  };

  static const _wdNames = {
    'zh': ['', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'],
    'en': ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    'ja': ['', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'],
  };

  static const _map = {
    'zh': {
      'nav_home': '首頁', 'nav_schedule': '班表', 'nav_salary': '薪資',
      'monthly_overview': '本月概況', 'monthly_expense': '本月花費',
      'work_days': '上班天數', 'days_unit': '天',
      'finance_analysis': '收支分析', 'set_budget': '設定預算',
      'donut_chart': '圓餅圖', 'line_chart': '曲線圖',
      'spent': '已花費', 'remaining_budget': '剩餘預算',
      'monthly_budget': '月預算', 'remaining': '剩餘', 'expense': '花費',
      'not_set': '未設定', 'set_monthly_budget': '設定月預算',
      'cancel': '取消', 'confirm': '確認', 'save': '儲存',
      'shift': '班別', 'work_time': '上班時間', 'today_expense': '今日花費',
      'work_time_hint': '例：09:00 – 18:00', 'budget_hint': '例：20000',
      'salary_mgmt': '薪資管理', 'income_tracking': '收入追蹤・確認入帳',
      'treasury': '剩餘價值', 'confirmed': '已入帳', 'pending': '待入帳',
      'monthly_pay': '月薪', 'daily_pay': '日薪',
      'confirm_payment': '確認入帳', 'expected': '預計', 'actual': '實領',
      'expected_amount': '預計金額', 'actual_amount': '實際入帳金額',
      'pay_date': '入帳日期', 'select_date': '選擇日期',
      'job_name': '工作名稱', 'date_or_desc': '日期或說明',
      'job_name_hint': '例：蝦皮兼職', 'date_hint': '例：4/17',
      'no_records': '尚無記錄', 'tap_to_add': '點擊下方 + 新增',
      'add_record': '新增', 'diff_from': '與預計差',
      'settings': '設定', 'language': '語言',
      'lang_zh': '繁體中文', 'lang_en': 'English', 'lang_ja': '日本語',
      'day_label': '日',
    },
    'en': {
      'nav_home': 'Home', 'nav_schedule': 'Schedule', 'nav_salary': 'Salary',
      'monthly_overview': 'Monthly Overview', 'monthly_expense': 'Monthly Expense',
      'work_days': 'Work Days', 'days_unit': 'd',
      'finance_analysis': 'Finance', 'set_budget': 'Set Budget',
      'donut_chart': 'Donut', 'line_chart': 'Line',
      'spent': 'Spent', 'remaining_budget': 'Remaining',
      'monthly_budget': 'Budget', 'remaining': 'Left', 'expense': 'Spent',
      'not_set': 'Not set', 'set_monthly_budget': 'Set Monthly Budget',
      'cancel': 'Cancel', 'confirm': 'Confirm', 'save': 'Save',
      'shift': 'Shift', 'work_time': 'Work Hours', 'today_expense': "Today's Exp.",
      'work_time_hint': 'e.g. 09:00 – 18:00', 'budget_hint': 'e.g. 20000',
      'salary_mgmt': 'Salary', 'income_tracking': 'Track & Confirm Income',
      'treasury': 'Surplus', 'confirmed': 'Received', 'pending': 'Pending',
      'monthly_pay': 'Monthly', 'daily_pay': 'Daily',
      'confirm_payment': 'Confirm', 'expected': 'Expected', 'actual': 'Actual',
      'expected_amount': 'Expected Amount', 'actual_amount': 'Actual Amount',
      'pay_date': 'Pay Date', 'select_date': 'Select Date',
      'job_name': 'Job Name', 'date_or_desc': 'Date or Note',
      'job_name_hint': 'e.g. Part-time', 'date_hint': 'e.g. 4/17',
      'no_records': 'No records yet', 'tap_to_add': 'Tap + below to add',
      'add_record': 'Add', 'diff_from': 'Diff',
      'settings': 'Settings', 'language': 'Language',
      'lang_zh': '繁體中文', 'lang_en': 'English', 'lang_ja': '日本語',
      'day_label': '',
    },
    'ja': {
      'nav_home': 'ホーム', 'nav_schedule': '勤務表', 'nav_salary': '給与',
      'monthly_overview': '今月の概要', 'monthly_expense': '今月の支出',
      'work_days': '出勤日数', 'days_unit': '日',
      'finance_analysis': '収支分析', 'set_budget': '予算設定',
      'donut_chart': '円グラフ', 'line_chart': '折れ線',
      'spent': '支出', 'remaining_budget': '残り予算',
      'monthly_budget': '月予算', 'remaining': '残り', 'expense': '支出',
      'not_set': '未設定', 'set_monthly_budget': '月次予算設定',
      'cancel': 'キャンセル', 'confirm': '確認', 'save': '保存',
      'shift': 'シフト', 'work_time': '勤務時間', 'today_expense': '今日の支出',
      'work_time_hint': '例：09:00 – 18:00', 'budget_hint': '例：20000',
      'salary_mgmt': '給与管理', 'income_tracking': '収入追跡・確認',
      'treasury': '剰余価値', 'confirmed': '入金済', 'pending': '入金待ち',
      'monthly_pay': '月給', 'daily_pay': '日給',
      'confirm_payment': '入金確認', 'expected': '予定', 'actual': '実際',
      'expected_amount': '予定金額', 'actual_amount': '実際入金額',
      'pay_date': '入金日', 'select_date': '日付選択',
      'job_name': '仕事名', 'date_or_desc': '日付またはメモ',
      'job_name_hint': '例：アルバイト', 'date_hint': '例：4/17',
      'no_records': '記録なし', 'tap_to_add': '下の + をタップ',
      'add_record': '追加', 'diff_from': '予定との差',
      'settings': '設定', 'language': '言語',
      'lang_zh': '繁體中文', 'lang_en': 'English', 'lang_ja': '日本語',
      'day_label': '日',
    },
  };
}
