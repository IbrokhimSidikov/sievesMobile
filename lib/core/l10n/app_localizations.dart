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
      'comingSoon':'Bu funksiya tez orada qoʻshiladi!'

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
      'comingSoon':'Эта функция скоро появится!'

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
}