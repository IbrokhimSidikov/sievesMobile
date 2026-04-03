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
      'dear': 'Dear',
      'dashboard': 'Dashboard',
      'profileSubtitle': 'Profile information',
      'attendance': 'Attendance',
      'attendanceSubtitle': 'Work hours & tracking',
      'breakOrder': 'Break Order',
      'breakOrderSubtitle': 'Order your meal',
      'breakRecords': 'Break Records',
      'breakRecordsSubtitle': 'Meal history',
      'placeOrder': 'Place Order',
      'history': 'History',
      'historySubtitle': 'Activity log',
      'lWallet': 'L-Calculator',
      'lWalletSubtitle': 'Financial Advicer',
      'comingSoon': 'This feature is coming soon!',
      'learning': 'Learning',
      'learningSubtitle': 'Learning & Development',
      'testHistory': 'Test History',
      'testHistorySubtitle': 'Your test journey',
      'productivityTimer': 'Productivity Timer',
      'productivityTimerSubtitle': 'Track your focus time',
      'checklist': 'Checklist',
      'checklistSubtitle': 'Manage your tasks',
      'faceIdSubtitle': 'Work entry device',
      'calendar': 'Calendar',
      'calendarSubtitle': 'Training schedule',
      //Profile page
      'workHours': 'Work Hours',
      'totalHours': 'Total Hours',
      'dayHours': 'Day Hours',
      'nightHours': 'Night Hours',
      'bonus': 'Bonus',
      'currentBonusAmount': 'Current Bonus Amount',
      'bonusDesc': 'This bonus will be given after 10th of the month',
      'noBonus': 'No bonus available at the moment',
      'prePaid': 'Pre-Paid',
      'transactions': 'Transactions',
      'currentMonthBalance': 'Current Month Balance',
      'prePaidDesc': 'Pre-payment received for current month',
      'vacationDays': 'Vacation Days',
      'earnedLeaveBalance': 'Earned Leave Balance',
      'daysAvailable': 'Days Available',
      'daysUsed': 'Days Used',
      'maxDays': 'Max Days',
      'jobInformation': 'Job Information',
      'branch': 'Branch',
      'department': 'Department',
      'logoutTitle': 'Logout Confirmation',
      'logoutDesc': 'Are you sure you want to logout?',
      'logoutButton': 'Logout',
      'cancelButton': 'Cancel',
      'feedback': 'Feedback',
      'feedbackSubtitle': 'Share your thoughts with us',

      //Attendance page
      'workEntries': 'Work Entries',
      'date': 'Date',
      'checkIn': 'Check-in',
      'checkOut': 'Check-out',
      'status': 'Status',
      'mood': 'Mood',
      'open': 'Open',
      'closed': 'Closed',
      'noEntries': 'No work entries found for this month',
      'noPhotosAvailable': 'No photos available for this entry',

      //Break Records
      'availableBreakBalance': 'Available Balance',
      'amount': 'Amount',
      'details': 'Details',
      'breakRecord': 'Break Record',
      'orderDetails': 'Order Details',
      'total': 'Total',
      'close': 'Close',

      //Notifications
      'notifications': 'Notifications',
      'notificationsSubtitle': 'Stay updated with your latest activity',
      'markAllRead': 'Mark all read',
      'noNotifications': 'No notifications yet',
      'noNotSubTitle': 'You\'re all caught up!',

      //Update required
      'updateRequired': 'Update Required',
      'updateAvailable': 'Update Available',
      'current': 'Current',
      'latest': 'Latest',
      'updateDialog': 'You must update to continue',
      'later': 'Later',
      'updateNow': 'Update Now',

      //Productivity Timer
      'stopwatch': 'Stopwatch',
      'employee': 'Employee',
      'selectEmployee': 'Select employee',
      'noEmployeesAvailable': 'No employees available',
      'loadingEmployees': 'Loading employees...',
      'product': 'Product',
      'selectProduct': 'Select product',
      'note': 'Note',
      'optional': '(Optional)',
      'addNote': 'Add a note or comment...',
      'start': 'Start',
      'pause': 'Pause',
      'resume': 'Resume',
      'stop': 'Stop',
      'reset': 'Reset',
      'submit': 'Submit',
      'submitting': 'Submitting...',
      'running': 'Running',
      'paused': 'Paused',
      'readyToStart': 'Ready to start',
      'tipsTitle': '💡 Tips',
      'tip1': '• Select employee and product before starting',
      'tip2': '• You can pause and resume the timer',
      'tip3': '• Add notes to track your work details',
      'tip4': '• Submit when you\'re done to save the record',
      'validationEmployeeRequired': 'Please select an employee',
      'validationProductRequired': 'Please select a product',
      'errorLoadEmployees': 'Failed to load employees. Please try again.',
      'errorSubmit': 'Failed to submit data. Please try again.',
      'successSubmit': 'Data submitted successfully!',
      'ok': 'OK',
      //face verification
      'faceVerification': 'Face Verification',
      'faceVerificationSubtitle': 'Verify your face',
      'subTitleFaceVerification': 'Review your photo and confirm',
      'subTitle2': 'Position your face in the frame',
      'cameraDialog': 'Initializing camera...',
      'retake': 'Retake',
      'confirmPhoto': 'Confirm',
      'cameraCancelled': 'Camera cancelled. Tap to try again.',
      'moodTitle': 'How are you feeling?',
      'moodSubTitle': 'Select your mood to check in',
      'bad': 'Bad',
      '40': 'Slightly Bad',
      '60': 'Normal',
      '80': 'Good',
      '100': 'Excellent',
      'continue': 'Continue',
      'workEntrySuccess': 'Work Entry Successful!',
      'currentStatus': 'Current Status',
      'time': 'Time',
      'returnHome': 'Return to Home',
      'workEntryFail': 'Face Verification Failed',
      'cancel': 'Cancel',
      'tryAgain': 'Try Again',
      'locationError': 'Location Error',
      'error': 'Error',
      'workEntryDevice': 'Work Entry Device',
      'nextAction': 'Next Action: CHECK OUT',
      'nextAction2': 'Next Action: CHECK IN',
      'analysing!': 'Analyzing...',
      'faceDetected': 'Face Detected',
      'detectionFail': 'Detection Failed',
      'employeeVerified': 'Employee Verified',
      'verifiedAt': 'Verified at',
      'newVerification': 'New Verification',
      'processing': 'Processing...',
      'captureFace': 'Capture Face',
      //checklist
      'mySubmissions': 'My Submissions',
      'submissionsFound': 'submissions found',
      'completed': 'completed',
      'complete': 'Complete',
      'loaderChecklist': 'Loading checklists...',
      'checklistSubmission': 'Submitting checklist...',
      'noChecklists': 'No checklists found',
      'noChecklistBranch': 'There are no checklists for your branch',
      'retry': 'Retry',
      'addNoteOptional': 'Add a note (Optional)',
      'submitChecklist': 'Submit Checklist',
      'submittingChecklist': 'Submitting checklist...',
      'overallProgress': 'Overall Progress',
      //Calendar
      'trainingCalendar': 'Training Calendar',
      'createEvent': 'Create Event',
      'eventName': 'Event Name',
      'eventNameHint': 'Enter event name',
      'eventDate': 'Event Date',
      'selectDate': 'Select date',
      'eventTime': 'Event Time',
      'selectTime': 'Select time',
      'create': 'Create',
      'success': 'Success',
      'eventCreatedSuccess': 'Event created successfully',
      'failedToCreateEvent': 'Failed to create event',
      'authenticationRequired': 'Authentication required',
      'pleaseSelectDateTime': 'Please select date and time',
      'failedToLoadEvents': 'Failed to load training events',
      'errorLoadingEvents': 'Error loading training events',
      'nextDays': 'Next 30 Days',
      'trainingEvent': 'training event',
      'trainingEvents': 'training events',
      'noEventsNext30Days': 'No training events in the next 30 days',
      'unableToLoadVideo': 'Unable to load video',
      //PDF Viewer
      'financialGuide': 'Financial Guide',
      'viewGuide': 'View Guide',
      'page': 'Page',
      'of': 'of',
      'previous': 'Previous',
      'next': 'Next',
      'loadingDocument': 'Loading document...',
      //Employee Productivity
      'employeeProductivity': 'Employee Productivity',
      'employeeProductivitySubtitle': 'Choose your productivity tool',
      'productivityTimerCard': 'Productivity Timer',
      'productivityTimerCardSubtitle':
          'Track your work time and boost efficiency',
      'matrixQualification': 'Matrix Qualification',
      'matrixQualificationSubtitle': 'Assess and improve your skill matrix',
      'qualificationDisplayPage': 'Matrix Qualification',
      'trainingTest': 'HR Training test',
      'hr': 'HR',
      'hrSubtitle': 'Manage employees, training, and qualifications',
      'hrTitle': 'Training & Development',
      'calendarSubtitle1': 'Track upcoming training sessions and schedules',
      'trainingTestSubtitle':
          'Manage HR training exams, schedules, and employee results',
      'trainingCourses': 'Training Courses',
      'availableCourses': 'Available training courses',
      'courseTheme': 'Course Theme',
      'loadingCourses': 'Loading courses...',
      'noCourses': 'No training courses available',
      'errorLoadingCourses': 'Failed to load training courses',
      'coursesFound': 'courses found',
      // Test Session
      'question': 'Question',
      'multipleChoice': 'Multiple Choice',
      'matching': 'Matching',
      'progress': 'Progress',
      'noTestsAvailable': 'No tests available',
      'answerAllQuestions':
          'Please answer all questions before submitting the test.',
      'sessionNotStarted': 'Session not started. Please try again.',
      'failedToSubmitTest': 'Failed to submit test',
      'matchEachItem': 'Match each item with its pair',
      'tapCardToChoose': 'Tap a card to choose the matching answer',
      'tapToSelectMatch': 'Tap to select a match...',
      'chooseAMatch': 'Choose a match',
      'clearMatch': 'Clear',
      'selectCorrectMatch': 'Select the correct match below',
      'used': 'Used',
      'submitTest': 'Submit Test',
      'submittingTest': 'Submitting...',
      // Home Categories
      'catPersonal': 'Personal',
      'catAttendance': 'Attendance',
      'catBreak': 'Break',
      'catFinance': 'Finance',
      'catLearning': 'Learning & HR',
      'catTasks': 'Tasks',
      // Star Rating Hints
      'starRatingTitle': 'Rating Levels',
      'starRatingSubtitle': 'Assessment criteria for each star level',
      'star1Title': 'Star 1 – Learning',
      'star1Desc':
          'Still learning the basics. Needs guidance and supervision to complete tasks.',
      'star2Title': 'Star 2 – Independent',
      'star2Desc':
          'Can work independently. Completes tasks without constant supervision.',
      'star3Title': 'Star 3 – Fast & Quality',
      'star3Desc':
          'Works fast and with high quality. Consistently meets or exceeds standards.',
      'star4Title': 'Star 4 – Can Teach',
      'star4Desc':
          'Can teach others. Shares knowledge and mentors colleagues effectively.',
      'star5Title': 'Star 5 – Can Improve',
      'star5Desc':
          'Can improve processes. Identifies inefficiencies and proposes better solutions.',
      // Test Result Page
      'loadingResults': 'Loading results...',
      'errorLoadingResults': 'Error Loading Results',
      'score': 'Score',
      'congratulations': 'Congratulations!',
      'keepTrying': 'Keep Trying!',
      'youPassedTest': 'You passed the test!',
      'youNeedToPass': 'You need',
      'toPass': 'to pass',
      'totalQuestions': 'Total Questions',
      'correct': 'Correct',
      'wrong': 'Wrong',
      'detailedResults': 'Detailed Results',
      'correctAnswer': 'Correct',
      'backToCourses': 'Back to Courses',

      'skipped': 'Skipped',
      // Leaderboard
      'leaderboard': 'Leaderboard',
      'leaderboardSubtitle': 'Top performers this period',
      'courses': 'Courses',
      'rank': 'Rank',
      'noLeaderboardData': 'No results yet',
      'noLeaderboardDesc': 'Be the first to complete a game test!',
      // Training Game
      'trainingGame': 'Training Games',
      'trainingGameSubtitle': 'Practice your knowledge with game mode',
      'trainingGamePickCourse': 'Select a course to start',
      'trainingGameEmptyDesc': 'No courses are available for game mode yet',
      'startGame': 'Start Game',
      'gameMode': 'Game Mode',
      'sessionTerminated': 'Session Terminated',
      'testComplete': 'Test Complete',
      'summary': 'Summary',
      'review': 'Review',
      'incomplete': 'Incomplete',
      'partial': 'Partial',
      'passed': 'Passed',
      'failed': 'Failed',
      'congratulationsMsg': 'Congratulations!',
      'betterLuckMsg': 'Better luck next time',
      'resultsBasedOnAnswered': 'Results are based on answered questions only',
      'scoredOutOf': 'You scored {correct} out of {total} questions correctly',
      'timeSpent': 'Time Spent',
      'answered': 'Answered',
      'terminated': 'Terminated',
      'backToCourseList': 'Back to Courses',
      'exitSession': 'Exit Session?',
      'exitSessionMsg': 'Leaving will terminate your test session. Your progress will be lost.',
      'exit': 'Exit',
      'submitTestTitle': 'Submit Test?',
      'unansweredMsg': 'You have {count} unanswered question(s). Submit anyway?',
      'failedToLoadQuestions': 'Failed to Load Questions',
      'noQuestionsAvailable': 'No Questions Available',
      'noMcqQuestions': 'This course has no multiple-choice questions yet.',
      'goBack': 'Go Back',
      'submittingEllipsis': 'Submitting…',
      'sessionEndedBg': 'Session ended — you switched to another app.',
      'sessionEndedExit': 'Session ended — you exited the test.',
      'sessionWasTerminated': 'Session was terminated.',
      //feedback page
      'thankYou': 'Thank you',
      'feedbackSubmitted': 'Feedback submitted successfully',
      'done':'Done',
      'submitting': 'Submitting...',
      'submissionError': 'Submission Error',
      'submissionErrorMessage': 'We couldn\'t process your feedback. Please try again later.',
      'tryAgain': 'Try Again',
      'close': 'Close'
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
      'dear': 'Hurmatli',
      'dashboard': 'Bosh Sahifa',
      'profileSubtitle': 'Profil maʼlumotlari',
      'attendance': 'Davomat',
      'attendanceSubtitle': 'Ish soatlari va keldi-ketdi',
      'breakOrder': 'Break Buyurtma',
      'breakOrderSubtitle': 'Ovqat buyurtma qiling',
      'breakRecords': 'Break ma\'lumotlari',
      'breakRecordsSubtitle': 'Break balans va qaydlar',
      'placeOrder': 'Buyurtma berish',
      'history': 'Tarix',
      'historySubtitle': 'Faoliyat jurnali',
      'lWallet': 'L-Hisoblagich',
      'lWalletSubtitle': 'Orzularingizni hotirjam hisoblang',
      'comingSoon': 'Bu funksiya tez orada qoʻshiladi!',
      'learning': 'Test & Imtihon',
      'learningSubtitle': 'O\'rganish va Izlanish',
      'testHistory': 'Test Tarixi',
      'testHistorySubtitle': 'Sizning test sayohatingiz',
      'productivityTimer': 'Tayyorlash sifati',
      'productivityTimerSubtitle': 'Diqqat vaqtini kuzatish',
      'checklist': 'Checklist ro\'yxati',
      'checklistSubtitle': 'Vazifalarni boshqarish',
      'faceIdSubtitle': 'Ishga keldi-ketdi',
      'calendar': 'Kalendar',
      'calendarSubtitle': 'Trening jadvali',
      //Profile page
      'workHours': 'Ish soatlari',
      'totalHours': 'Umumiy soatlar',
      'dayHours': 'Kunduzgi soatlar',
      'nightHours': 'Tungi soatlar',
      'bonus': 'Bonus',
      'currentBonusAmount': 'Joriy bonus miqdori',
      'bonusDesc': 'Bu bonus oyning 10-sanadan keyin beriladi',
      'noBonus': 'Bonus summasi belgilanmagan',
      'prePaid': 'Avans miqdori',
      'transactions': 'Tranzaksiyalar',
      'currentMonthBalance': 'Joriy oy balansi',
      'prePaidDesc': 'Joriy oy uchun olingan avans miqdori',
      'vacationDays': 'Ta’til kunlari',
      'earnedLeaveBalance': 'Yig‘ilgan ta’til balansi',
      'daysAvailable': 'Mavjud kunlar',
      'daysUsed': 'Ishlatilgan kunlar',
      'maxDays': 'Maksimal kunlar',
      'jobInformation': 'Ish ma’lumotlari',
      'branch': 'Filial',
      'department': 'Bo‘lim',
      'logoutTitle': 'Chiqishni tasdiqlash',
      'logoutDesc': 'Haqiqatan ham chiqmoqchimisiz?',
      'logoutButton': 'Chiqish',
      'cancelButton': 'Bekor qilish',
      'feedback': 'Fikr bildirish',
      'feedbackSubtitle': 'Fikr va takliflaringizni yuboring',

      //Attendance
      'workEntries': 'Keldi-Ketdi',
      'date': 'Sana',
      'checkIn': 'Kirish',
      'checkOut': 'Chiqish',
      'status': 'Holat',
      'mood': 'Kayfiyat',
      'open': 'Ochiq',
      'closed': 'Yopiq',
      'noEntries': 'Bu oy uchun ish yozuvlari topilmadi',
      'noPhotosAvailable': 'Bu yozuv uchun rasmlar mavjud emas',

      //Break Records
      'availableBreakBalance': 'Mavjud balans',
      'amount': 'Miqdor',
      'details': 'Tafsilotlar',
      'breakRecord': 'Break qaydlari',
      'orderDetails': 'Buyurtma tafsilotlari',
      'total': 'Jami',
      'close': 'Yopish',

      //Notifications
      'notifications': 'Bildirishnomalar',
      'notificationsSubtitle': 'So‘nggi faoliyatingizdan xabardor bo‘ling',
      'markAllRead': 'O\'qish',
      'noNotifications': 'Hozirgacha bildirishnoma yo‘q',
      'noNotSubTitle': 'Siz hamma narsani ko‘rib chiqdiz!',

      //Update required
      'updateRequired': 'Yangilash talab qilinadi',
      'updateAvailable': 'Yangilash mavjud',
      'current': 'Joriy',
      'latest': 'Eng so‘nggi',
      'updateDialog': 'Davom etish uchun ilovani yangilashingiz kerak',
      'later': 'Keyinroq',
      'updateNow': 'Hozir yangilash',

      //Productivity Timer
      'stopwatch': 'Sekundomer',
      'employee': 'Xodim',
      'selectEmployee': 'Xodimni tanlang',
      'noEmployeesAvailable': 'Xodimlar mavjud emas',
      'loadingEmployees': 'Xodimlar yuklanmoqda...',
      'product': 'Mahsulot',
      'selectProduct': 'Mahsulotni tanlang',
      'note': 'Izoh',
      'optional': '(Ixtiyoriy)',
      'addNote': 'Izoh yoki sharh qo\'shing...',
      'start': 'Boshlash',
      'pause': 'Pauza',
      'resume': 'Davom etish',
      'stop': 'To\'xtatish',
      'reset': 'Qayta',
      'submit': 'Yuborish',
      'submitting': 'Yuborilmoqda...',
      'running': 'Ishlayapti',
      'paused': 'Pauza',
      'readyToStart': 'Boshlashga tayyor',
      'tipsTitle': '💡 Maslahatlar',
      'tip1': '• Boshlashdan oldin xodim va mahsulotni tanlang',
      'tip2': '• Vaqt hisoblagichni to\'xtatib, davom ettirish mumkin',
      'tip3': '• Ish tafsilotlarini kuzatish uchun izoh qo\'shing',
      'tip4': '• Yozuvni saqlash uchun tugagach yuboring',
      'validationEmployeeRequired': 'Iltimos, xodimni tanlang',
      'validationProductRequired': 'Iltimos, mahsulotni tanlang',
      'errorLoadEmployees':
          'Xodimlarni yuklashda xatolik. Qayta urinib ko\'ring.',
      'errorSubmit':
          'Ma\'lumotlarni yuborishda xatolik. Qayta urinib ko\'ring.',
      'successSubmit': 'Qayd etildi!',
      'ok': 'OK',
      //faceVerification
      'faceVerification': 'Face ID',
      'faceVerificationSubtitle': 'Face ID dan o\'ting',
      "subTitleFaceVerification": "Suratingizni tekshiring va tasdiqlang",
      "subTitle2": "Yuzingizni ramka ichiga joylashtiring",
      "cameraDialog": "Kamera ishga tushirilmoqda...",
      "retake": "Qayta olish",
      "confirmPhoto": "Tasdiqlash",
      "cameraCancelled": "Kamera bekor qilindi. Qayta urining",
      "moodTitle": "O‘zingizni qanday his qilyapsiz?",
      "moodSubTitle": "Kayfiyatingizni tanlang",
      "bad": "Qayg\'u",
      "40": "Yomon",
      "60": "Normal",
      "80": "Yaxshi",
      "100": "A’lo",
      "continue": "Davom etish",
      "workEntrySuccess": "Ish boshlandi!",
      "currentStatus": "Joriy holat",
      "time": "Vaqt",
      "returnHome": "Bosh sahifa",
      "workEntryFail": "Yuzni tasdiqlanmadi",
      "cancel": "Bekor qilish",
      "tryAgain": "Qayta urinish",
      "locationError": "Offisda emassiz",
      "error": "Xatolik",
      "workEntryDevice": "Ishga kirish qurilmasi",
      "nextAction": "Keyingi amal: CHIQISH",
      "nextAction2": "Keyingi amal: KIRISH",
      "analysing!": "Tahlil qilinmoqda...",
      "faceDetected": "Yuz aniqlandi",
      "detectionFail": "Aniqlash muvaffaqiyatsiz",
      "employeeVerified": "Xodim tasdiqlandi",
      "verifiedAt": "Tasdiqlangan vaqt",
      "newVerification": "Yangi tasdiqlash",
      "processing": "Qayta ishlanmoqda...",
      "captureFace": "Yuzni suratga olish",
      //checklist
      'mySubmissions': 'Mening cheklistlarim',
      'submissionsFound': 'ta topshiriq topildi',
      'completed': 'bajarilgan',
      'complete': 'Yopilgan',
      'loaderChecklist': 'Cheklistlar yuklanmoqda...',
      'checklistSubmission': 'Yuborilmoqda...',
      'noChecklists': 'Cheklistlar topilmadi',
      'noChecklistBranch': 'Ushbu filial uchun cheklistlar mavjud emas',
      "retry": "Qayta urinish",
      "addNoteOptional": "Izoh qo‘shish (ixtiyoriy)",
      "submitChecklist": "Tekshiruv ro‘yxatini yuborish",
      "submittingChecklist": "Tekshiruv ro‘yxati yuborilmoqda...",
      "overallProgress": "Umumiy jarayon",
      //Calendar
      'trainingCalendar': 'Trening Kalendari',
      'createEvent': 'Tadbir yaratish',
      'eventName': 'Tadbir nomi',
      'eventNameHint': 'Tadbir nomini kiriting',
      'eventDate': 'Tadbir sanasi',
      'selectDate': 'Sanani tanlang',
      'eventTime': 'Tadbir vaqti',
      'selectTime': 'Vaqtni tanlang',
      'create': 'Yaratish',
      'success': 'Muvaffaqiyat',
      'eventCreatedSuccess': 'Tadbir muvaffaqiyatli yaratildi',
      'failedToCreateEvent': 'Tadbir yaratib bo\'lmadi',
      'authenticationRequired': 'Autentifikatsiya talab qilinadi',
      'pleaseSelectDateTime': 'Iltimos, sana va vaqtni tanlang',
      'failedToLoadEvents': 'Trening tadbirlarini yuklab bo\'lmadi',
      'errorLoadingEvents': 'Trening tadbirlarini yuklashda xatolik',
      'nextDays': 'Keyingi 30 kun',
      'trainingEvent': 'ta trening tadbiri',
      'trainingEvents': 'ta trening tadbiri',
      'noEventsNext30Days': 'Keyingi 30 kun ichida trening tadbirlari yo\'q',
      'unableToLoadVideo': 'Videoni yuklab bo\'lmadi',
      //PDF Viewer
      'financialGuide': 'Moliyaviy Qo\'llanma',
      'viewGuide': 'Qo\'llanmani ko\'rish',
      'page': 'Sahifa',
      'of': 'dan',
      'previous': 'Oldingi',
      'next': 'Keyingi',
      'loadingDocument': 'Hujjat yuklanmoqda...',
      //Employee Productivity
      'employeeProductivity': 'Xodim samaradorligi',
      'employeeProductivitySubtitle': 'Samaradorlik vositasini tanlang',
      'productivityTimerCard': 'Tayyorlash sifati',
      'productivityTimerCardSubtitle':
          'Ish vaqtingizni kuzating va samaradorlikni oshiring',
      'matrixQualification': 'Matritsa malakasi',
      'matrixQualificationSubtitle':
          'Ko\'nikma matritsangizni baholang va yaxshilang',
      'qualificationDisplayPage': 'Baholash me\'zoni',
      'trainingTest': 'HR o‘quv testi',
      'hr': 'HR',
      'hrTitle': 'Ta’lim va rivojlanish',
      'hrSubtitle': 'Xodimlar, o‘quv jarayoni va malakalarni boshqarish',
      'calendarSubtitle1':
          'Yaqinlashayotgan o‘quv mashg‘ulotlari va jadvalni kuzatish',
      'trainingTestSubtitle':
          'HR o\'quv imtihonlari, jadvali va xodimlar natijalarini boshqarish',
      'trainingCourses': 'O\'quv kurslari',
      'availableCourses': 'Mavjud o\'quv kurslari',
      'courseTheme': 'Kurs mavzusi',
      'loadingCourses': 'Kurslar yuklanmoqda...',
      'noCourses': 'O\'quv kurslari mavjud emas',
      'errorLoadingCourses': 'Kurslarni yuklashda xatolik',
      'coursesFound': 'ta kurs topildi',
      // Test Session
      'question': 'Savol',
      'multipleChoice': 'Bir javobli',
      'matching': 'Moslashtirish',
      'progress': 'Jarayon',
      'noTestsAvailable': 'Testlar mavjud emas',
      'answerAllQuestions':
          'Testni yuborishdan oldin barcha savollarga javob bering.',
      'sessionNotStarted': 'Sessiya boshlanmadi. Qayta urinib ko\'ring.',
      'failedToSubmitTest': 'Testni yuborishda xatolik',
      'matchEachItem': 'Har bir elementni juftiga moslashtiring',
      'tapCardToChoose': 'Mos javobni tanlash uchun kartani bosing',
      'tapToSelectMatch': 'Moslikni tanlash uchun bosing...',
      'chooseAMatch': 'Moslikni tanlang',
      'clearMatch': 'Tozalash',
      'selectCorrectMatch': 'Quyida to\'g\'ri moslikni tanlang',
      'used': 'Ishlatilgan',
      'submitTest': 'Testni yuborish',
      'submittingTest': 'Yuborilmoqda...',
      // Home Categories
      'catPersonal': 'Shaxsiy',
      'catAttendance': 'Davomat',
      'catBreak': 'Break',
      'catFinance': 'Moliya',
      'catLearning': 'O\'quv & HR',
      'catTasks': 'Vazifalar',
      // Star Rating Hints
      'starRatingTitle': 'Baholash darajalari',
      'starRatingSubtitle': 'Har bir yulduz darajasi uchun baholash mezonlari',
      'star1Title': '1 Yulduz – O\'rganyapti',
      'star1Desc':
          'Hali asoslarni o\'rganmoqda. Vazifalarni bajarish uchun yo\'naltirish va nazorat kerak.',
      'star2Title': '2 Yulduz – Mustaqil ishlay oladi',
      'star2Desc':
          'Mustaqil ishlaya oladi. Doimiy nazoratisiz vazifalarni bajaradi.',
      'star3Title': '3 Yulduz – Tez va sifatli ishlaydi',
      'star3Desc':
          'Tez va yuqori sifatda ishlaydi. Standartlarni muntazam bajaradi yoki oshib ketadi.',
      'star4Title': '4 Yulduz – Boshqalarga o\'rgata oladi',
      'star4Desc':
          'Boshqalarga o\'rgata oladi. Bilimini ulashadi va hamkasblarini samarali nazorat qiladi.',
      'star5Title': 'Yulduz 5 – Yaxshilash',
      'star5Desc':
          'Jarayonlarni yaxshilashi mumkin. Samarasizliklarni aniqlaydi va yaxshiroq yechimlarni taklif qiladi.',
      // Test Result Page
      'loadingResults': 'Natijalar yuklanmoqda...',
      'errorLoadingResults': 'Natijalarni yuklashda xatolik',
      'score': 'Ball',
      'congratulations': 'Tabriklaymiz!',
      'keepTrying': 'Harakat qiling!',
      'youPassedTest': 'Siz testdan o\'tdingiz!',
      'youNeedToPass': 'O\'tish uchun',
      'toPass': 'kerak',
      'totalQuestions': 'Jami savollar',
      'correct': 'To\'g\'ri',
      'wrong': 'Noto\'g\'ri',
      'detailedResults': 'Batafsil natijalar',
      'correctAnswer': 'To\'g\'ri',
      'backToCourses': 'Kurslarga qaytish',

      'skipped': 'O\'tkazib yuborildi',
      // Leaderboard
      'leaderboard': 'Reyting',
      'leaderboardSubtitle': 'Eng yaxshi natijalar',
      'courses': 'Kurslar',
      'rank': 'O\'rin',
      'noLeaderboardData': 'Hali natijalar yo\'q',
      'noLeaderboardDesc': 'O\'yin testini birinchi bo\'lib yakunlang!',
      // Training Game
      'trainingGame': 'Training o\'yinlari',
      'trainingGameSubtitle': 'O\'yin rejimida bilimingizni sinab ko\'ring',
      'trainingGamePickCourse': 'Boshlash uchun kurs tanlang',
      'trainingGameEmptyDesc': 'O\'yin rejimi uchun kurslar mavjud emas',
      'startGame': 'O\'yinni boshlash',
      'gameMode': 'O\'yin rejimi',
      'sessionTerminated': 'Sessiya tugatildi',
      'testComplete': 'Test yakunlandi',
      'summary': 'Xulosa',
      'review': 'Ko\'rib chiqish',
      'incomplete': 'Tugallanmagan',
      'partial': 'Qisman',
      'passed': 'O\'tildi',
      'failed': 'O\'tilmadi',
      'congratulationsMsg': 'Tabriklaymiz!',
      'betterLuckMsg': 'Keyingi safar omad',
      'resultsBasedOnAnswered': 'Natijalar faqat javob berilgan savollarga asoslanadi',
      'scoredOutOf': '{total} ta savoldan {correct} tasiga to\'g\'ri javob berdingiz',
      'timeSpent': 'Sarflangan vaqt',
      'answered': 'Javob berildi',
      'terminated': 'Tugatildi',
      'backToCourseList': 'Kurslarga qaytish',
      'exitSession': 'Chiqasizmi?',
      'exitSessionMsg': 'Chiqish test sessiyasini tugatadi. Jarayoningiz yo\'qoladi.',
      'exit': 'Chiqish',
      'submitTestTitle': 'Testni yuborish?',
      'unansweredMsg': '{count} ta savolga javob berilmadi. Baribir yuborasizmi?',
      'failedToLoadQuestions': 'Savollarni yuklashda xatolik',
      'noQuestionsAvailable': 'Savollar mavjud emas',
      'noMcqQuestions': 'Bu kursda hali ko\'p tanlovli savollar yo\'q.',
      'goBack': 'Orqaga',
      'submittingEllipsis': 'Yuborilmoqda…',
      'sessionEndedBg': 'Sessiya tugadi — boshqa ilovaga o\'tdingiz.',
      'sessionEndedExit': 'Sessiya tugadi — testdan chiqdingiz.',
      'sessionWasTerminated': 'Sessiya tugatildi.',
      //feedback page
      "thankYou": "Rahmat",
      "feedbackSubmitted": "Forma qabul qilindi",
      "done": "Bosh Sahifa",
      "submitting": "Yuborilmoqda...",
      "submissionError": "Xatolik",
      "submissionErrorMessage": "Formani yuborishda xatolik yuz berdi. Iltimos, keyinroq qayta urinib ko'ring.",
      "tryAgain": "Qayta urinish",
      "close": "Yopish"
    },
    'ru': {
      'trainingTest': 'Тестирование',
      'hr': 'HR',
      'hrTitle': 'Обучение и развитие',
      'hrSubtitle': 'Управление сотрудниками, процессом обучения и навыками',
      'calendarSubtitle1': 'Ближайшие учебные занятия и расписание',
      // Test Result Page
      'loadingResults': 'Загрузка результатов...',
      'errorLoadingResults': 'Ошибка загрузки результатов',
      'score': 'Балл',
      'congratulations': 'Поздравляем!',
      'keepTrying': 'Не сдавайтесь!',
      'youPassedTest': 'Вы прошли тест!',
      'youNeedToPass': 'Чтобы пройти',
      'toPass': 'нужно',
      'totalQuestions': 'Всего вопросов',
      'correct': 'Правильно',
      'wrong': 'Неправильно',
      'detailedResults': 'Подробные результаты',
      'correctAnswer': 'Правильный ответ',
      'backToCourses': 'Вернуться к курсам',
      'trainingTestSubtitle': 'Тесты HR, расписание и результаты сотрудников',
      'trainingCourses': 'Курсы обучения',
      'availableCourses': 'Доступные курсы обучения',
      'courseTheme': 'Тема курса',
      'loadingCourses': 'Загрузка курсов...',
      'noCourses': 'Курсы обучения не найдены',
      'errorLoadingCourses': 'Ошибка загрузки курсов',
      'coursesFound': 'курсов найдено',
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
      'dear': 'Уважаемый',
      'dashboard': 'Главная',
      'profileSubtitle': 'Информация профиля',
      'attendance': 'Посещаемость',
      'attendanceSubtitle': 'Рабочие часы и отслеживание',
      'breakOrder': 'Заказ Break',
      'breakOrderSubtitle': 'Закажите еду',
      'breakRecords': 'Записи перерывов',
      'breakRecordsSubtitle': 'История приёмов пищи',
      'placeOrder': 'Оформить заказ',
      'history': 'История',
      'historySubtitle': 'Журнал активности',
      'lWallet': 'L-КОШЕЛЁК',
      'lWalletSubtitle': 'Инвестиции для ваших мечт',
      'comingSoon': 'Эта функция скоро появится!',
      'learning': 'Обучение',
      'learningSubtitle': 'Обучение и Развитие',
      'testHistory': 'История Тестов',
      'testHistorySubtitle': 'Ваш путь тестирования',
      'productivityTimer': 'Таймер продуктивности',
      'productivityTimerSubtitle': 'Отслеживайте время фокуса',
      'checklist': 'Список задач',
      'checklistSubtitle': 'Управляйте задачами',
      'faceIdSubtitle': 'Устройство распознавания',
      'calendar': 'Календарь',
      'calendarSubtitle': 'Расписание тренингов',
      //Profile page
      'workHours': 'Рабочие часы',
      'totalHours': 'Общее количество часов',
      'dayHours': 'Дневные часы',
      'nightHours': 'Ночные часы',
      'bonus': 'Бонус',
      'currentBonusAmount': 'Текущая сумма бонуса',
      'bonusDesc': 'Этот бонус будет начислен после 10-го числа месяца',
      'noBonus': 'Бонусов пока нет',
      'prePaid': 'Аванс',
      'transactions': 'Транзакции',
      'currentMonthBalance': 'Баланс за текущий месяц',
      'prePaidDesc': 'Авансовый платеж за текущий месяц',
      'vacationDays': 'Дни отпуска',
      'earnedLeaveBalance': 'Накопленный отпускной баланс',
      'daysAvailable': 'Доступные дни',
      'daysUsed': 'Исп. дни',
      'maxDays': 'Максимум дней',
      'jobInformation': 'Информация о работе',
      'branch': 'Филиал',
      'department': 'Отдел',
      'logoutTitle': 'Подтверждение выхода',
      'logoutDesc': 'Вы уверены, что хотите выйти?',
      'logoutButton': 'Выйти',
      'cancelButton': 'Отмена',
      'feedback': 'Обратная связь',
      'feedbackSubtitle': 'Поделитесь своими мыслями с нами',

      //Attendance
      'workEntries': 'Рабочие записи',
      'date': 'Дата',
      'checkIn': 'Вход',
      'checkOut': 'Выход',
      'status': 'Статус',
      'mood': 'Настроение',
      'open': 'Открыт',
      'closed': 'Закрыт',
      'noEntries': 'За этот месяц рабочие записи не найдены',
      'noPhotosAvailable': 'Фотографии для этой записи недоступны',

      //Break Records
      'availableBreakBalance': 'Доступный баланс',
      'amount': 'Сумма',
      'details': 'Детали',
      'breakRecord': 'Запись перерыва',
      'orderDetails': 'Детали заказа',
      'total': 'Итого',
      'close': 'Закрыть',

      //Notifications
      'notifications': 'Уведомления',
      'notificationsSubtitle': 'Будьте в курсе последних событий',
      'markAllRead': 'Отметить всё',
      'noNotifications': 'Пока нет уведомлений',
      'noNotSubTitle': 'Вы всё просмотрели!',

      //Update required
      'updateRequired': 'Требуется обновление',
      'updateAvailable': 'Доступно обновление',
      'current': 'Текущая версия',
      'latest': 'Последняя версия',
      'updateDialog': 'Чтобы продолжить, необходимо обновить',
      'later': 'Позже',
      'updateNow': 'Обновить сейчас',

      //Productivity Timer
      'stopwatch': 'Секундомер',
      'employee': 'Сотрудник',
      'selectEmployee': 'Выберите сотрудника',
      'noEmployeesAvailable': 'Сотрудники недоступны',
      'loadingEmployees': 'Загрузка сотрудников...',
      'product': 'Продукт',
      'selectProduct': 'Выберите продукт',
      'note': 'Заметка',
      'optional': '(Необязательно)',
      'addNote': 'Добавьте заметку или комментарий...',
      'start': 'Старт',
      'pause': 'Пауза',
      'resume': 'Продолжить',
      'stop': 'Стоп',
      'reset': 'Сброс',
      'submit': 'Отправить',
      'submitting': 'Отправка...',
      'running': 'Работает',
      'paused': 'Пауза',
      'readyToStart': 'Готов к запуску',
      'tipsTitle': '💡 Советы',
      'tip1': '• Выберите сотрудника и продукт перед началом',
      'tip2': '• Вы можете приостановить и возобновить таймер',
      'tip3': '• Добавляйте заметки для отслеживания деталей',
      'tip4': '• Отправьте данные по завершении работы',
      'validationEmployeeRequired': 'Пожалуйста, выберите сотрудника',
      'validationProductRequired': 'Пожалуйста, выберите продукт',
      'errorLoadEmployees':
          'Не удалось загрузить сотрудников. Попробуйте снова.',
      'errorSubmit': 'Не удалось отправить данные. Попробуйте снова.',
      'successSubmit': 'Успешно отправлено!',
      'ok': 'ОК',
      //faceVerification
      'faceVerification': 'Face ID',
      'faceVerificationSubtitle': 'Face ID dan o\'ting',
      'subTitleFaceVerification': 'Проверьте фото и подтвердите',
      'subTitle2': 'Поместите лицо в рамке',
      'cameraDialog': 'Инициализация камеры...',
      'retake': 'Переснять',
      'confirmPhoto': 'Подтвердить',
      'cameraCancelled': 'Не распознано.  Нажмите, чтобы попробовать снова.',
      'moodTitle': 'Как вы сегодня себя чувствуете?',
      'moodSubTitle': 'Отметьте своё настроение',
      'bad': 'Очень плохое',
      '40': 'Плохое',
      '60': 'Нормальное',
      '80': 'Хорошее',
      '100': 'Отличное',
      'continue': 'Продолжить',
      'workEntrySuccess': 'Отметка успешна!',
      'currentStatus': 'Текущий статус',
      'time': 'Время',
      'returnHome': 'Вернуться на главную',
      'workEntryFail': 'Ошибка проверки лица',
      'cancel': 'Отмена',
      'tryAgain': 'Попробовать снова',
      'locationError': 'Ошибка местоположения',
      'error': 'Ошибка',
      'workEntryDevice': 'Отметка рабочего времени',
      'nextAction': 'Следующая отметка: УХОД',
      'nextAction2': 'Следующая отметка: ПРИХОД',
      'analysing!': 'Анализ...',
      'faceDetected': 'Лицо распознано',
      'detectionFail': 'Сбой при распознавании',
      'employeeVerified': 'Сотрудник подтверждён',
      'verifiedAt': 'Подтверждено в',
      'newVerification': 'Новая проверка',
      'processing': 'Обработка...',
      'captureFace': 'Сделать селфи',
      //checklist
      'mySubmissions': 'Мои задания',
      'submissionsFound': 'заданий найдено',
      'completed': 'выполнено',
      'complete': 'Выполнено',
      'loaderChecklist': 'Загрузка чек-листов...',
      'checklistSubmission': 'Отправка чек-листа...',
      'noChecklists': 'Чек-листы не найдены',
      'noChecklistBranch': 'Для вашего филиала чек-листы отсутствуют',
      "retry": "Повторить",
      "addNoteOptional": "Добавить заметку (необязательно)",
      "submitChecklist": "Отправить чек-лист",
      "submittingChecklist": "Отправка чек-листа...",
      "overallProgress": "Общий прогресс",
      //Calendar
      'trainingCalendar': 'Календарь тренингов',
      'createEvent': 'Создать событие',
      'eventName': 'Название события',
      'eventNameHint': 'Введите название события',
      'eventDate': 'Дата события',
      'selectDate': 'Выберите дату',
      'eventTime': 'Время события',
      'selectTime': 'Выберите время',
      'create': 'Создать',
      'success': 'Успех',
      'eventCreatedSuccess': 'Событие успешно создано',
      'failedToCreateEvent': 'Не удалось создать событие',
      'authenticationRequired': 'Требуется аутентификация',
      'pleaseSelectDateTime': 'Пожалуйста, выберите дату и время',
      'failedToLoadEvents': 'Не удалось загрузить тренинги',
      'errorLoadingEvents': 'Ошибка загрузки тренингов',
      'nextDays': 'Следующие 30 дней',
      'trainingEvent': 'тренинг',
      'trainingEvents': 'тренингов',
      'noEventsNext30Days': 'Нет тренингов в ближайшие 30 дней',
      'unableToLoadVideo': 'Не удалось загрузить видео',
      //PDF Viewer
      'financialGuide': 'Финансовый гид',
      'viewGuide': 'Открыть гид',
      'page': 'Страница',
      'of': 'из',
      'previous': 'Назад',
      'next': 'Вперёд',
      'loadingDocument': 'Загрузка документа...',
      //Employee Productivity
      'employeeProductivity': 'Продуктивность сотрудников',
      'employeeProductivitySubtitle': 'Выберите инструмент продуктивности',
      'productivityTimerCard': 'Таймер продуктивности',
      'productivityTimerCardSubtitle':
          'Отслеживайте рабочее время и повышайте эффективность',
      'matrixQualification': 'Матрица квалификации',
      'matrixQualificationSubtitle': 'Оцените и улучшите свою матрицу навыков',
      'qualificationDisplayPage': 'Матричная квалификация',
      'trainingTest': 'Тест по обучению HR',
      'hr': 'HR',
      'hrTitle': 'Обучение и развитие',
      'hrSubtitle': 'Управление сотрудниками, обучением и квалификациями',
      'calendarSubtitle1':
          'Отслеживание предстоящих обучающих сессий и расписаний',
      'trainingTestSubtitle':
          'Управление HR экзаменами, расписанием и результатами сотрудников',
      'trainingCourses': 'Учебные курсы',
      'availableCourses': 'Доступные учебные курсы',
      'courseTheme': 'Тема курса',
      'loadingCourses': 'Загрузка курсов...',
      'noCourses': 'Нет доступных учебных курсов',
      'errorLoadingCourses': 'Не удалось загрузить курсы',
      'coursesFound': 'курсов найдено',
      // Test Session
      'question': 'Вопрос',
      'multipleChoice': 'Один ответ',
      'matching': 'Сопоставление',
      'progress': 'Прогресс',
      'noTestsAvailable': 'Тесты недоступны',
      'answerAllQuestions':
          'Пожалуйста, ответьте на все вопросы перед отправкой теста.',
      'sessionNotStarted': 'Сессия не начата. Попробуйте снова.',
      'failedToSubmitTest': 'Не удалось отправить тест',
      'matchEachItem': 'Сопоставьте каждый элемент с его парой',
      'tapCardToChoose': 'Нажмите на карточку, чтобы выбрать ответ',
      'tapToSelectMatch': 'Нажмите для выбора...',
      'chooseAMatch': 'Выберите соответствие',
      'clearMatch': 'Очистить',
      'selectCorrectMatch': 'Выберите правильное соответствие ниже',
      'used': 'Использовано',
      'submitTest': 'Отправить тест',
      'submittingTest': 'Отправка...',
      // Home Categories
      'catPersonal': 'Личное',
      'catAttendance': 'Посещаемость',
      'catBreak': 'Перерыв',
      'catFinance': 'Финансы',
      'catLearning': 'Обучение & HR',
      'catTasks': 'Задачи',
      // Star Rating Hints
      'starRatingTitle': 'Уровни оценки',
      'starRatingSubtitle': 'Критерии оценки для каждого уровня звёзд',
      'star1Title': '1 Звезда – Обучается',
      'star1Desc':
          'Ещё изучает основы. Требует руководства и контроля для выполнения задач.',
      'star2Title': '2 Звезды – Работает самостоятельно',
      'star2Desc':
          'Может работать самостоятельно. Выполняет задачи без постоянного контроля.',
      'star3Title': '3 Звезды – Быстро и качественно',
      'star3Desc':
          'Работает быстро и качественно. Стабильно выполняет или превышает стандарты.',
      'star4Title': '4 Звезды – Может обучать других',
      'star4Desc':
          'Может обучать других. Делится знаниями и эффективно наставляет коллег.',
      'star5Title': '5 Звёзд – Может улучшать процессы',
      'star5Desc':
          'Может улучшать процессы. Выявляет неэффективность и предлагает лучшие решения.',

      'skipped': 'Пропущено',
      // Leaderboard
      'leaderboard': 'Рейтинг',
      'leaderboardSubtitle': 'Лучшие результаты',
      'courses': 'Курсы',
      'rank': 'Место',
      'noLeaderboardData': 'Результатов пока нет',
      'noLeaderboardDesc': 'Будьте первым, кто завершит игровой тест!',
      // Training Game
      'trainingGame': 'Тренировочные игры',
      'trainingGameSubtitle': 'Проверьте знания в игровом режиме',
      'trainingGamePickCourse': 'Выберите курс для начала',
      'trainingGameEmptyDesc': 'Курсы для игрового режима пока недоступны',
      'startGame': 'Начать игру',
      'gameMode': 'Игровой режим',
      'sessionTerminated': 'Сессия завершена',
      'testComplete': 'Тест завершён',
      'summary': 'Итоги',
      'review': 'Просмотр',
      'incomplete': 'Не завершено',
      'partial': 'Частично',
      'passed': 'Пройдено',
      'failed': 'Не пройдено',
      'congratulationsMsg': 'Поздравляем!',
      'betterLuckMsg': 'Удачи в следующий раз',
      'resultsBasedOnAnswered': 'Результаты основаны только на отвеченных вопросах',
      'scoredOutOf': 'Вы правильно ответили на {correct} из {total} вопросов',
      'timeSpent': 'Затраченное время',
      'answered': 'Отвечено',
      'terminated': 'Завершена',
      'backToCourseList': 'Вернуться к курсам',
      'exitSession': 'Выйти из сессии?',
      'exitSessionMsg': 'Выход завершит тестовую сессию. Прогресс будет потерян.',
      'exit': 'Выйти',
      'submitTestTitle': 'Отправить тест?',
      'unansweredMsg': 'Вы не ответили на {count} вопрос(ов). Всё равно отправить?',
      'failedToLoadQuestions': 'Не удалось загрузить вопросы',
      'noQuestionsAvailable': 'Вопросы недоступны',
      'noMcqQuestions': 'В этом курсе пока нет вопросов с множественным выбором.',
      'goBack': 'Назад',
      'submittingEllipsis': 'Отправка…',
      'sessionEndedBg': 'Сессия завершена — вы переключились на другое приложение.',
      'sessionEndedExit': 'Сессия завершена — вы вышли из теста.',
      'sessionWasTerminated': 'Сессия была завершена.',
      //feedback form
      "thankYou": "Спасибо",
      "feedbackSubmitted": "Отзыв успешно отправлен",
      "done": "Готово",
      "submitting": "Отправка...",
      "submissionError": "Ошибка отправки",
      "submissionErrorMessage": "Не удалось обработать ваш отзыв. Пожалуйста, попробуйте позже.",
      "tryAgain": "Попробовать снова",
      "close": "Закрыть"
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
  String get breakOrder => translate('breakOrder');
  String get breakOrderSubtitle => translate('breakOrderSubtitle');
  String get breakRecords => translate('breakRecords');
  String get breakRecordsSubtitle => translate('breakRecordsSubtitle');
  String get placeOrder => translate('placeOrder');
  String get history => translate('history');
  String get historySubtitle => translate('historySubtitle');
  String get lWallet => translate('lWallet');
  String get lWalletSubtitle => translate('lWalletSubtitle');
  String get comingSoon => translate('comingSoon');
  String get learning => translate('learning');
  String get learningSubtitle => translate('learningSubtitle');
  String get testHistory => translate('testHistory');
  String get testHistorySubtitle => translate('testHistorySubtitle');
  String get productivityTimer => translate('productivityTimer');
  String get productivityTimerSubtitle =>
      translate('productivityTimerSubtitle');
  String get checklist => translate('checklist');
  String get checklistSubtitle => translate('checklistSubtitle');
  String get faceIdSubtitle => translate('faceIdSubtitle');
  String get calendar => translate('calendar');
  String get calendarSubtitle => translate('calendarSubtitle');

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
  String get feedback => translate('feedback');
  String get feedbackSubtitle => translate('feedbackSubtitle');
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
  String get noPhotosAvailable => translate('noPhotosAvailable');

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

  //Productivity Timer
  String get stopwatch => translate('stopwatch');
  String get employee => translate('employee');
  String get selectEmployee => translate('selectEmployee');
  String get noEmployeesAvailable => translate('noEmployeesAvailable');
  String get loadingEmployees => translate('loadingEmployees');
  String get product => translate('product');
  String get selectProduct => translate('selectProduct');
  String get note => translate('note');
  String get optional => translate('optional');
  String get addNote => translate('addNote');
  String get start => translate('start');
  String get pause => translate('pause');
  String get resume => translate('resume');
  String get stop => translate('stop');
  String get reset => translate('reset');
  String get submit => translate('submit');
  String get submitting => translate('submitting');
  String get running => translate('running');
  String get paused => translate('paused');
  String get readyToStart => translate('readyToStart');
  String get tipsTitle => translate('tipsTitle');
  String get tip1 => translate('tip1');
  String get tip2 => translate('tip2');
  String get tip3 => translate('tip3');
  String get tip4 => translate('tip4');
  String get validationEmployeeRequired =>
      translate('validationEmployeeRequired');
  String get validationProductRequired =>
      translate('validationProductRequired');
  String get errorLoadEmployees => translate('errorLoadEmployees');
  String get errorSubmit => translate('errorSubmit');
  String get successSubmit => translate('successSubmit');
  String get ok => translate('ok');
  //faceVerification
  String get faceVerification => translate('faceVerification');
  String get faceVerificationSubtitle => translate('faceVerificationSubtitle');
  String get subTitleFaceVerification => translate('subTitleFaceVerification');
  String get subTitle2 => translate('subTitle2');
  String get cameraDialog => translate('cameraDialog');
  String get retake => translate('retake');
  String get confirmPhoto => translate('confirmPhoto');
  String get cameraCancelled => translate('cameraCancelled');
  String get moodTitle => translate('moodTitle');
  String get moodSubTitle => translate('moodSubTitle');
  String get bad => translate('bad');
  String get mood40 => translate('40');
  String get mood60 => translate('60');
  String get mood80 => translate('80');
  String get mood100 => translate('100');
  String get continueText => translate('continue');
  String get workEntrySuccess => translate('workEntrySuccess');
  String get currentStatus => translate('currentStatus');
  String get time => translate('time');
  String get returnHome => translate('returnHome');
  String get workEntryFail => translate('workEntryFail');
  String get cancel => translate('cancel');
  String get tryAgain => translate('tryAgain');
  String get locationError => translate('locationError');
  String get error => translate('error');
  String get workEntryDevice => translate('workEntryDevice');
  String get nextAction => translate('nextAction');
  String get nextAction2 => translate('nextAction2');
  String get analysing => translate('analysing!');
  String get faceDetected => translate('faceDetected');
  String get detectionFail => translate('detectionFail');
  String get employeeVerified => translate('employeeVerified');
  String get verifiedAt => translate('verifiedAt');
  String get newVerification => translate('newVerification');
  String get processing => translate('processing');
  String get captureFace => translate('captureFace');
  //checklist
  String get mySubmissions => translate('mySubmissions');
  String get submissionsFound => translate('submissionsFound');
  String get completed => translate('completed');
  String get complete => translate('complete');
  String get loaderChecklist => translate('loaderChecklist');
  String get checklistSubmission => translate('checklistSubmission');
  String get noChecklists => translate('noChecklists');
  String get noChecklistBranch => translate('noChecklistBranch');
  String get retry => translate('retry');
  String get addNoteOptional => translate('addNoteOptional');
  String get submitChecklist => translate('submitChecklist');
  String get submittingChecklist => translate('submittingChecklist');
  String get overallProgress => translate('overallProgress');
  //Employee Productivity
  String get employeeProductivity => translate('employeeProductivity');
  String get employeeProductivitySubtitle =>
      translate('employeeProductivitySubtitle');
  String get productivityTimerCard => translate('productivityTimerCard');
  String get productivityTimerCardSubtitle =>
      translate('productivityTimerCardSubtitle');
  String get matrixQualification => translate('matrixQualification');
  String get matrixQualificationSubtitle =>
      translate('matrixQualificationSubtitle');
  String get qualificationDisplayPage => translate('qualificationDisplayPage');
  String get trainingTest => translate('trainingTest');
  String get hr => translate('hr');
  String get hrTitle => translate('hrTitle');
  String get hrSubtitle => translate('hrSubtitle');
  String get calendarSubtitle1 => translate('calendarSubtitle1');
  String get trainingTestSubtitle => translate('trainingTestSubtitle');
  String get trainingCourses => translate('trainingCourses');
  String get availableCourses => translate('availableCourses');
  String get courseTheme => translate('courseTheme');
  String get loadingCourses => translate('loadingCourses');
  String get noCourses => translate('noCourses');
  String get errorLoadingCourses => translate('errorLoadingCourses');
  String get coursesFound => translate('coursesFound');
  // Test Session
  String get question => translate('question');
  String get multipleChoice => translate('multipleChoice');
  String get matching => translate('matching');
  String get progress => translate('progress');
  String get noTestsAvailable => translate('noTestsAvailable');
  String get answerAllQuestions => translate('answerAllQuestions');
  String get sessionNotStarted => translate('sessionNotStarted');
  String get failedToSubmitTest => translate('failedToSubmitTest');
  String get matchEachItem => translate('matchEachItem');
  String get tapCardToChoose => translate('tapCardToChoose');
  String get tapToSelectMatch => translate('tapToSelectMatch');
  String get chooseAMatch => translate('chooseAMatch');
  String get clearMatch => translate('clearMatch');
  String get selectCorrectMatch => translate('selectCorrectMatch');
  String get used => translate('used');
  String get submitTest => translate('submitTest');
  String get submittingTest => translate('submittingTest');
  String get previous => translate('previous');
  String get next => translate('next');
  // Home Categories
  String get catPersonal => translate('catPersonal');
  String get catAttendance => translate('catAttendance');
  String get catBreak => translate('catBreak');
  String get catFinance => translate('catFinance');
  String get catLearning => translate('catLearning');
  String get catTasks => translate('catTasks');
  // Star Rating Hints
  String get starRatingTitle => translate('starRatingTitle');
  String get starRatingSubtitle => translate('starRatingSubtitle');
  String get star1Title => translate('star1Title');
  String get star1Desc => translate('star1Desc');
  String get star2Title => translate('star2Title');
  String get star2Desc => translate('star2Desc');
  String get star3Title => translate('star3Title');
  String get star3Desc => translate('star3Desc');
  String get star4Title => translate('star4Title');
  String get star4Desc => translate('star4Desc');
  String get star5Title => translate('star5Title');
  String get star5Desc => translate('star5Desc');
  // Test Result Page
  String get loadingResults => translate('loadingResults');
  String get errorLoadingResults => translate('errorLoadingResults');
  String get score => translate('score');
  String get congratulations => translate('congratulations');
  String get keepTrying => translate('keepTrying');
  String get youPassedTest => translate('youPassedTest');
  String get youNeedToPass => translate('youNeedToPass');
  String get toPass => translate('toPass');
  String get totalQuestions => translate('totalQuestions');
  String get correct => translate('correct');
  String get wrong => translate('wrong');
  String get detailedResults => translate('detailedResults');
  String get correctAnswer => translate('correctAnswer');
  String get backToCourses => translate('backToCourses');
  String get thankYou => translate('thankYou');
  String get feedbackSubmitted => translate('feedbackSubmitted');
  String get done => translate('done');
  String get submissionError => translate('submissionError');
  String get submissionErrorMessage => translate('submissionErrorMessage');
  String get skipped => translate('skipped');
  // Training Game
  String get trainingGame => translate('trainingGame');
  String get trainingGameSubtitle => translate('trainingGameSubtitle');
  String get trainingGamePickCourse => translate('trainingGamePickCourse');
  String get trainingGameEmptyDesc => translate('trainingGameEmptyDesc');
  String get startGame => translate('startGame');
  String get gameMode => translate('gameMode');
  String get sessionTerminated => translate('sessionTerminated');
  String get testComplete => translate('testComplete');
  String get summary => translate('summary');
  String get review => translate('review');
  String get incomplete => translate('incomplete');
  String get partial => translate('partial');
  String get passed => translate('passed');
  String get failed => translate('failed');
  String get congratulationsMsg => translate('congratulationsMsg');
  String get betterLuckMsg => translate('betterLuckMsg');
  String get resultsBasedOnAnswered => translate('resultsBasedOnAnswered');
  String get timeSpent => translate('timeSpent');
  String get answered => translate('answered');
  String get terminated => translate('terminated');
  String get backToCourseList => translate('backToCourseList');
  String get exitSession => translate('exitSession');
  String get exitSessionMsg => translate('exitSessionMsg');
  String get exit => translate('exit');
  String get submitTestTitle => translate('submitTestTitle');
  String get failedToLoadQuestions => translate('failedToLoadQuestions');
  String get noQuestionsAvailable => translate('noQuestionsAvailable');
  String get noMcqQuestions => translate('noMcqQuestions');
  String get goBack => translate('goBack');
  String get submittingEllipsis => translate('submittingEllipsis');
  String get sessionEndedBg => translate('sessionEndedBg');
  String get sessionEndedExit => translate('sessionEndedExit');
  String get sessionWasTerminated => translate('sessionWasTerminated');
  String unansweredMsg(int count) =>
      translate('unansweredMsg').replaceAll('{count}', '$count');
  String scoredOutOf(int correct, int total) => translate('scoredOutOf')
      .replaceAll('{correct}', '$correct')
      .replaceAll('{total}', '$total');

  // Leaderboard
  String get leaderboard => translate('leaderboard');
  String get leaderboardSubtitle => translate('leaderboardSubtitle');
  String get courses => translate('courses');
  String get rank => translate('rank');
  String get noLeaderboardData => translate('noLeaderboardData');
  String get noLeaderboardDesc => translate('noLeaderboardDesc');
}
