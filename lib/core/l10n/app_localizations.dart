import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Sieves',
      'welcome': 'Welcome',
      'login': 'Login',
      'logout': 'Logout',
      'profile': 'Profile',
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      // Home Page
      'dear':'Dear',
      'dashboard':'Dashboard',
      'profileSubtitle':'Profile information',
      'attendance':'Attendance',
      'attendanceSubtitle':'Work hours & tracking',
      'breakRecords':'Break Records',
      'breakRecordsSubtitle':'Meal history',
      'history':'History',
      'historySubtitle':'Activity log',
      'lWallet':'L-WALLET',
      'lWalletSubtitle':'Investment for your dreams',
      'comingSoon':'This feature is coming soon!',

      //Profile page
      'workHours':'Work Hours',
      'totalHours':'Total Hours',
      'dayHours':'Day Hours',
      'nightHours':'Night Hours',
      'bonus':'Bonus',
      'currentBonusAmount':'Current Bonus Amount',
      'bonusDesc':'This bonus will be given after 10th of the month',
      'noBonus':'No bonus available at the moment',
      'prePaid':'Pre-Paid',
      'transactions':'Transactions',
      'currentMonthBalance':'Current Month Balance',
      'prePaidDesc':'Pre-payment received for current month',
      'vacationDays':'Vacation Days',
      'earnedLeaveBalance':'Earned Leave Balance',
      'daysAvailable':'Days Available',
      'daysUsed':'Days Used',
      'maxDays':'Max Days',
      'jobInformation':'Job Information',
      'branch':'Branch',
      'department':'Department',
      'logoutTitle':'Logout Confirmation',
      'logoutDesc':'Are you sure you want to logout?',
      'logoutButton':'Logout',
      'cancelButton':'Cancel'
    },
    'uz': {
      'title': 'Sieves',
      'welcome': 'Xush kelibsiz',
      'login': 'Kirish',
      'logout': 'Chiqish',
      'profile': 'Profil',
      'settings': 'Sozlamalar',
      'language': 'Til',
      'theme': 'Mavzu',
      'dark_mode': 'Qorong\'i rejim',
      'light_mode': 'Yorug\' rejim',
      // Home Page
      'dear':'Hurmatli',
      'dashboard':'Bosh Sahifa',
      'profileSubtitle':'Profil maʼlumotlari',
      'attendance':'Davomat',
      'attendanceSubtitle':'Ish soatlari va keldi-ketdi',
      'breakRecords':'Break ma\'lumotlari',
      'breakRecordsSubtitle':'Break balans va qaydlar',
      'history':'Tarix',
      'historySubtitle':'Faoliyat jurnali',
      'lWallet':'L-HAMYON',
      'lWalletSubtitle':'Orzularingiz uchun investitsiya',
      'comingSoon':'Bu funksiya tez orada qoʻshiladi!',

      //Profile page
      'workHours':'Ish soatlari',
      'totalHours':'Umumiy soatlar',
      'dayHours':'Kunduzgi soatlar',
      'nightHours':'Tungi soatlar',
      'bonus':'Bonus',
      'currentBonusAmount':'Joriy bonus miqdori',
      'bonusDesc':'Bu bonus oyning 10-sanadan keyin beriladi',
      'noBonus':'Bonus summasi belgilanmagan',
      'prePaid':'Avans miqdori',
      'transactions':'Tranzaksiyalar',
      'currentMonthBalance':'Joriy oy balansi',
      'prePaidDesc':'Joriy oy uchun olingan avans miqdori',
      'vacationDays':'Ta’til kunlari',
      'earnedLeaveBalance':'Yig‘ilgan ta’til balansi',
      'daysAvailable':'Mavjud kunlar',
      'daysUsed':'Ishlatilgan kunlar',
      'maxDays':'Maksimal kunlar',
      'jobInformation':'Ish ma’lumotlari',
      'branch':'Filial',
      'department':'Bo‘lim',
      'logoutTitle':'Chiqishni tasdiqlash',
      'logoutDesc':'Haqiqatan ham chiqmoqchimisiz?',
      'logoutButton':'Chiqish',
      'cancelButton':'Bekor qilish'


},
    'ru': {
      'title': 'Sieves',
      'welcome': 'Добро пожаловать',
      'login': 'Войти',
      'logout': 'Выйти',
      'profile': 'Профиль',
      'settings': 'Настройки',
      'language': 'Язык',
      'theme': 'Тема',
      'dark_mode': 'Темный режим',
      'light_mode': 'Светлый режим',
      // Home page
      'dear':'Уважаемый',
      'dashboard':'Главная',
      'profileSubtitle':'Информация профиля',
      'attendance':'Посещаемость',
      'attendanceSubtitle':'Рабочие часы и отслеживание',
      'breakRecords':'Записи перерывов',
      'breakRecordsSubtitle':'История приёмов пищи',
      'history':'История',
      'historySubtitle':'Журнал активности',
      'lWallet':'L-КОШЕЛЁК',
      'lWalletSubtitle':'Инвестиции для ваших мечт',
      'comingSoon':'Эта функция скоро появится!',

      //Profile page
      'workHours':'Рабочие часы',
      'totalHours':'Общее количество часов',
      'dayHours':'Дневные часы',
      'nightHours':'Ночные часы',
      'bonus':'Бонус',
      'currentBonusAmount':'Текущая сумма бонуса',
      'bonusDesc':'Этот бонус будет начислен после 10-го числа месяца',
      'noBonus':'Бонусов пока нет',
      'prePaid':'Аванс',
      'transactions':'Транзакции',
      'currentMonthBalance':'Баланс за текущий месяц',
      'prePaidDesc':'Авансовый платеж за текущий месяц',
      'vacationDays':'Дни отпуска',
      'earnedLeaveBalance':'Накопленный отпускной баланс',
      'daysAvailable':'Доступные дни',
      'daysUsed':'Исп. дни',
      'maxDays':'Максимум дней',
      'jobInformation':'Информация о работе',
      'branch':'Филиал',
      'department':'Отдел',
      'logoutTitle':'Подтверждение выхода',
      'logoutDesc':'Вы уверены, что хотите выйти?',
      'logoutButton':'Выйти',
      'cancelButton':'Отмена',


    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters
  String get title => translate('title');
  String get welcome => translate('welcome');
  String get login => translate('login');
  String get logout => translate('logout');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get language => translate('language');
  String get theme => translate('theme');
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');
  String get dear => translate('dear');
  String get dashboard => translate('dashboard');
  String get profileSubtitle => translate('profileSubtitle');
  String get attendance => translate('attendance');
  String get attendanceSubtitle => translate('attendanceSubtitle');
  String get breakRecords => translate('breakRecords');
  String get breakRecordsSubtitle => translate('breakRecordsSubtitle');
  String get history => translate('history');
  String get historySubtitle => translate('historySubtitle');
  String get lWallet => translate('lWallet');
  String get lWalletSubtitle => translate('lWalletSubtitle');
  String get comingSoon => translate('comingSoon');
  //Profile page
  String get workHours => translate('workHours');
  String get totalHours => translate('totalHours');
  String get dayHours => translate('dayHours');
  String get nightHours => translate('nightHours');
  String get bonus => translate('bonus');
  String get currentBonusAmount => translate('currentBonusAmount');
  String get bonusDesc => translate('bonusDesc');
  String get noBonus => translate('noBonus');
  String get prePaid => translate('prePaid');
  String get transactions => translate('transactions');
  String get currentMonthBalance => translate('currentMonthBalance');
  String get prePaidDesc => translate('prePaidDesc');
  String get vacationDays => translate('vacationDays');
  String get earnedLeaveBalance => translate('earnedLeaveBalance');
  String get daysAvailable => translate('daysAvailable');
  String get daysUsed => translate('daysUsed');
  String get maxDays => translate('maxDays');
  String get jobInformation => translate('jobInformation');
  String get branch => translate('branch');
  String get department => translate('department');
  String get logoutTitle => translate('logoutTitle');
  String get logoutDesc => translate('logoutDesc');
  String get logoutButton => translate('logoutButton');
  String get cancelButton => translate('cancelButton');

}