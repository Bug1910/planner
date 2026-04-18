# MyPlanner · 個人行事曆 + 記帳 App

## 專案概述
Flutter 跨平台 App，結合排班日曆 + 薪資追蹤。使用者為電商營運專員，用來管理自己的工作班表與收入。

## 核心功能
1. **首頁（HomePage）**：月曆（可排班）+ 底部「剩餘價值」大數字 + 快速排班按鈕
2. **班表（SchedulePage）**：詳細班表檢視
3. **薪資（BudgetPage）**：已入帳 / 待入帳卡片、月薪 / 日薪 / PT 三種類別

## 設計系統（日系 muji 和紙風）

### 配色（`lib/theme/app_colors.dart`）
- 背景：`#F5EFE6` 和紙米白
- 表面：`#FAF6EE` surface / `#F0EAE0` surfaceAlt
- 主色（墨藍）：`#2C3E5C` primary
- 次色（抹茶）：`#7B8F6B` accent
- 文字：`#2B2724` textPrimary / `#8A8178` textSecondary / `#B5AC9E` textMuted
- 班別色：早班棕 `#C88B52` / 晚班墨藍 `#2C3E5C` / 休假抹茶 `#7B8F6B`

### 字體
- Body：`GoogleFonts.notoSerifJpTextTheme` (Noto Serif JP)
- 數字：`GoogleFonts.fraunces` (Fraunces 襯線體)

## 重要設計決策（不要改動除非使用者要求）

### 「剩餘價值」= 首頁主 KPI
- 原本叫「總金庫」，使用者改名為「剩餘價值」
- 翻譯：zh=剩餘價值 / en=Surplus / ja=剰余価値
- 首頁**只顯示這一個數字**（不放已入帳/待入帳/花費/上班天數，那些在薪資分頁）

### 日曆設計
- 填滿螢幕剩餘高度（`LayoutBuilder` 動態計算 aspectRatio）
- 每格用 `Stack + Positioned` 絕對定位，確保數字對齊（有無班別標籤都同位置）
- 數字字級 18pt Fraunces，班別標籤 10pt
- 支援**一天兩個班**（不同工作），資料結構 `shifts: List<String>`（向後相容舊 `shift: String`）

### 班別顏色必須統一
- 首頁日曆格 + 快速排班 sheet + 詳細日期 sheet 三處顏色必須一致
- 都透過 `_shiftBgColor()` / `_shiftTextColor()` 工具函式取色，不要直接用 hex

### 不要做的事
- 不要放多色漸層、loud purple gradient
- 不要做「花費圖表」（donut/line chart）在首頁，使用者要極簡
- 不要加預算條、月概況卡片之類堆疊資訊

## 關鍵檔案
- `lib/main.dart` — 3-tab NavigationBar
- `lib/pages/home_page.dart` — 首頁（日曆 + 剩餘價值），~2100 行
- `lib/pages/schedule_page.dart` — 班表分頁
- `lib/pages/budget_page.dart` — 薪資分頁
- `lib/theme/app_colors.dart` — 配色常數
- `lib/theme/app_theme.dart` — Material theme 組裝
- `lib/l10n/strings.dart` — 繁中 / EN / 日 三語
- `lib/utils/app_state.dart` — 全域狀態 (dayData, entries)
- `lib/utils/responsive.dart` — `R.sp()` / `R.fs()` 尺寸工具

## 開發環境
- Flutter：`C:\flutter\bin\flutter.bat`
- 模擬器：Android AVD `Pixel_8`
- adb：`C:\Users\lolcp\AppData\Local\Android\Sdk\platform-tools\adb.exe`
- 一鍵啟動：`C:\Users\lolcp\Desktop\開啟排班APP.bat`

## 常用指令
```bash
# 啟動（emulator 開好後）
C:\flutter\bin\flutter.bat run

# 截圖到 Screenshots 資料夾
adb exec-out screencap -p > C:\Users\lolcp\Pictures\Screenshots\shot.png

# 熱鍵（flutter run 執行時）
r  = 熱重載
R  = 熱重啟
q  = 退出
```

## 使用者偏好
- 電商營運專員、設計非工程背景 → 說明要口語、不假設懂程式術語
- 會截圖給我看，截圖放在 `C:\Users\lolcp\Pictures\Screenshots\`
- 設計決策偏好：極簡 > 堆疊資訊、日系和紙感、襯線字體、墨藍強調
- 改版節奏：常常看截圖後「我覺得這樣更醜」要整個 revert，要學會判斷什麼是定稿什麼是實驗
