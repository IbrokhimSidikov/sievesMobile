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
      'learning':'Learning',
      'learningSubtitle':'Learning & Development',

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
      'cancelButton':'Cancel',

      //Attendance page
      'workEntries':'Work Entries',
      'date':'Date',
      'checkIn':'Check-in',
      'checkOut':'Check-out',
      'status':'Status',
      'mood':'Mood',
      'open':'Open',
      'closed':'Closed',
      'noEntries':'No work entries found for this month',

      //Break Records
      'availableBreakBalance':'Available Balance',
      'amount':'Amount',
      'details':'Details',
      'breakRecord':'Break Record',
      'orderDetails':'Order Details',
      'total':'Total',
      'close':'Close',

      //Notifications
      'notifications':'Notifications',
      'notificationsSubtitle':'Stay updated with your latest activity',
      'markAllRead':'Mark all read',
      'noNotifications':'No notifications yet',
      'noNotSubTitle':'You\'re all caught up!',

      //Update required
      'updateRequired':'Update Required',
      'updateAvailable':'Update Available',
      'current':'Current',
      'latest':'Latest',
      'updateDialog':'You must update to continue',
      'later':'Later',
      'updateNow':'Update Now'

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
      'learning':'Test & Imtihon',
      'learningSubtitle':'O\'rganish va Izlanish',
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
      'cancelButton':'Bekor qilish',

      //Attendance
      'workEntries':'Keldi-Ketdi',
      'date':'Sana',
      'checkIn':'Kirish',
      'checkOut':'Chiqish',
      'status':'Holat',
      'mood':'Kayfiyat',
      'open':'Ochiq',
      'closed':'Yopiq',
      'noEntries':'Bu oy uchun ish yozuvlari topilmadi',

      //Break Records
      'availableBreakBalance':'Mavjud balans',
      'amount':'Miqdor',
      'details':'Tafsilotlar',
      'breakRecord':'Break qaydlari',
      'orderDetails':'Buyurtma tafsilotlari',
      'total':'Jami',
      'close':'Yopish',

      //Notifications
      'notifications':'Bildirishnomalar',
      'notificationsSubtitle':'So‘nggi faoliyatingizdan xabardor bo‘ling',
      'markAllRead':'O\'qish',
      'noNotifications':'Hozirgacha bildirishnoma yo‘q',
      'noNotSubTitle':'Siz hamma narsani ko‘rib chiqdiz!',

      //Update required
      'updateRequired': 'Yangilash talab qilinadi',
      'updateAvailable': 'Yangilash mavjud',
      'current': 'Joriy',
      'latest': 'Eng so‘nggi',
      'updateDialog': 'Davom etish uchun ilovani yangilashingiz kerak',
      'later': 'Keyinroq',
      'updateNow': 'Hozir yangilash'

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
      'learning': 'Обучение',
      'learningSubtitle': 'Обучение и Развитие',

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

      //Attendance
      'workEntries':'Рабочие записи',
      'date':'Дата',
      'checkIn':'Вход',
      'checkOut':'Выход',
      'status':'Статус',
      'mood':'Настроение',
      'open':'Открыт',
      'closed':'Закрыт',
      'noEntries':'За этот месяц рабочие записи не найдены',

      //Break Records
      'availableBreakBalance':'Доступный баланс',
      'amount':'Сумма',
      'details':'Детали',
      'breakRecord':'Запись перерыва',
      'orderDetails':'Детали заказа',
      'total':'Итого',
      'close':'Закрыть',

      //Notifications
      'notifications':'Уведомления',
      'notificationsSubtitle':'Будьте в курсе последних событий',
      'markAllRead':'Отметить всё',
      'noNotifications':'Пока нет уведомлений',
      'noNotSubTitle':'Вы всё просмотрели!',

      //Update required
      'updateRequired': 'Требуется обновление',
      'updateAvailable': 'Доступно обновление',
      'current': 'Текущая версия',
      'latest': 'Последняя версия',
      'updateDialog': 'Чтобы продолжить, необходимо обновить',
      'later': 'Позже',
      'updateNow': 'Обновить сейчас'


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
  String get learning => translate('learning');
  String get learningSubtitle => translate('learningSubtitle');

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
  //Attendance
  String get workEntries => translate('workEntries');
  String get date => translate('date');
  String get checkIn => translate('checkIn');
  String get checkOut => translate('checkOut');
  String get status => translate('status');
  String get mood => translate('mood');
  String get open => translate('open');
  String get closed => translate('closed');
  String get noEntries => translate('noEntries');

  //Break Records
  String get availableBreakBalance => translate('availableBreakBalance');
  String get amount => translate('amount');
  String get details => translate('details');
  String get breakRecord => translate('breakRecord');
  String get orderDetails => translate('orderDetails');
  String get total => translate('total');
  String get close => translate('close');

  //Notifications page
  String get notifications => translate('notifications');
  String get notificationsSubtitle => translate('notificationsSubtitle');
  String get markAllRead => translate('markAllRead');
  String get noNotifications => translate('noNotifications');
  String get noNotSubTitle => translate('noNotSubTitle');

  //Update required
  String get updateRequired => translate('updateRequired');
  String get updateAvailable => translate('updateAvailable');
  String get current => translate('current');
  String get latest => translate('latest');
  String get updateDialog => translate('updateDialog');
  String get later => translate('later');
  String get updateNow => translate('updateNow');

}