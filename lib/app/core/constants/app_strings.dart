import 'package:get/get.dart';
import '../../services/l10n_service.dart';
import 'strings_vi.dart';
import 'strings_en.dart';

/// Dynamic string getter that returns the correct locale string
/// Usage: AppStrings.ok (instead of S.ok)
class AppStrings {
  AppStrings._();

  static L10nService? _l10n;

  static L10nService get _service {
    _l10n ??= Get.find<L10nService>();
    return _l10n!;
  }

  static bool get _isEn => _service.isEnglish;

  // App
  static String get appName => _isEn ? S_EN.appName : S.appName;

  // Common
  static String get ok => _isEn ? S_EN.ok : S.ok;
  static String get cancel => _isEn ? S_EN.cancel : S.cancel;
  static String get save => _isEn ? S_EN.save : S.save;
  static String get delete => _isEn ? S_EN.delete : S.delete;
  static String get edit => _isEn ? S_EN.edit : S.edit;
  static String get done => _isEn ? S_EN.done : S.done;
  static String get next => _isEn ? S_EN.next : S.next;
  static String get back => _isEn ? S_EN.back : S.back;
  static String get close => _isEn ? S_EN.close : S.close;
  static String get search => _isEn ? S_EN.search : S.search;
  static String get loading => _isEn ? S_EN.loading : S.loading;
  static String get error => _isEn ? S_EN.error : S.error;
  static String get retry => _isEn ? S_EN.retry : S.retry;
  static String get comingSoon => _isEn ? S_EN.comingSoon : S.comingSoon;

  // Auth
  static String get enterEmail => _isEn ? S_EN.enterEmail : S.enterEmail;
  static String get emailHint => _isEn ? S_EN.emailHint : S.emailHint;
  static String get password => _isEn ? S_EN.password : S.password;
  static String get confirmPassword =>
      _isEn ? S_EN.confirmPassword : S.confirmPassword;
  static String get login => _isEn ? S_EN.login : S.login;
  static String get register => _isEn ? S_EN.register : S.register;
  static String get createAccount =>
      _isEn ? S_EN.createAccount : S.createAccount;
  static String get alreadyHaveAccount =>
      _isEn ? S_EN.alreadyHaveAccount : S.alreadyHaveAccount;
  static String get dontHaveAccount =>
      _isEn ? S_EN.dontHaveAccount : S.dontHaveAccount;
  static String get forgotPassword =>
      _isEn ? S_EN.forgotPassword : S.forgotPassword;
  static String get signIn => _isEn ? S_EN.signIn : S.signIn;
  static String get signOut => _isEn ? S_EN.signOut : S.signOut;
  static String get signOutConfirm =>
      _isEn ? S_EN.signOutConfirm : S.signOutConfirm;

  // Navigation tabs
  static String get tabToday => _isEn ? S_EN.tabToday : S.tabToday;
  static String get tabLearn => _isEn ? S_EN.tabLearn : S.tabLearn;
  static String get tabExam => _isEn ? S_EN.tabExam : S.tabExam;
  static String get tabExplore => _isEn ? S_EN.tabExplore : S.tabExplore;
  static String get tabMe => _isEn ? S_EN.tabMe : S.tabMe;

  // Today
  static String get today => _isEn ? S_EN.today : S.today;
  static String get goodMorning => _isEn ? S_EN.goodMorning : S.goodMorning;
  static String get goodAfternoon =>
      _isEn ? S_EN.goodAfternoon : S.goodAfternoon;
  static String get goodEvening => _isEn ? S_EN.goodEvening : S.goodEvening;
  static String get streak => _isEn ? S_EN.streak : S.streak;
  static String get streakDays => _isEn ? S_EN.streakDays : S.streakDays;
  static String get dailyProgress =>
      _isEn ? S_EN.dailyProgress : S.dailyProgress;
  static String get learnNewWords =>
      _isEn ? S_EN.learnNewWords : S.learnNewWords;
  static String get review => _isEn ? S_EN.review : S.review;
  static String get dueToday => _isEn ? S_EN.dueToday : S.dueToday;
  static String get noWordsDue => _isEn ? S_EN.noWordsDue : S.noWordsDue;
  static String get wordsToReview =>
      _isEn ? S_EN.wordsToReview : S.wordsToReview;
  static String get newWords => _isEn ? S_EN.newWords : S.newWords;
  static String get completed => _isEn ? S_EN.completed : S.completed;

  // Learn
  static String get learn => _isEn ? S_EN.learn : S.learn;
  static String get modeMixed => _isEn ? S_EN.modeMixed : S.modeMixed;
  static String get modeFlashcards =>
      _isEn ? S_EN.modeFlashcards : S.modeFlashcards;
  static String get modeListening =>
      _isEn ? S_EN.modeListening : S.modeListening;
  static String get modeHanziBuilder =>
      _isEn ? S_EN.modeHanziBuilder : S.modeHanziBuilder;
  static String get modeCollocations =>
      _isEn ? S_EN.modeCollocations : S.modeCollocations;
  static String get modeReview => _isEn ? S_EN.modeReview : S.modeReview;
  static String get modeGame30s => _isEn ? S_EN.modeGame30s : S.modeGame30s;

  // Session
  static String get step => _isEn ? S_EN.step : S.step;
  static String get correct => _isEn ? S_EN.correct : S.correct;
  static String get incorrect => _isEn ? S_EN.incorrect : S.incorrect;
  static String get sessionComplete =>
      _isEn ? S_EN.sessionComplete : S.sessionComplete;
  static String get accuracy => _isEn ? S_EN.accuracy : S.accuracy;

  // Rating
  static String get rateAgain => _isEn ? S_EN.rateAgain : S.rateAgain;
  static String get rateHard => _isEn ? S_EN.rateHard : S.rateHard;
  static String get rateGood => _isEn ? S_EN.rateGood : S.rateGood;
  static String get rateEasy => _isEn ? S_EN.rateEasy : S.rateEasy;

  // Explore
  static String get explore => _isEn ? S_EN.explore : S.explore;
  static String get searchVocab => _isEn ? S_EN.searchVocab : S.searchVocab;
  static String get all => _isEn ? S_EN.all : S.all;
  static String get filter => _isEn ? S_EN.filter : S.filter;
  static String get noResults => _isEn ? S_EN.noResults : S.noResults;

  // Word Detail
  static String get meanings => _isEn ? S_EN.meanings : S.meanings;
  static String get examples => _isEn ? S_EN.examples : S.examples;
  static String get addToFavorites =>
      _isEn ? S_EN.addToFavorites : S.addToFavorites;
  static String get removeFromFavorites =>
      _isEn ? S_EN.removeFromFavorites : S.removeFromFavorites;

  // Favorites
  static String get favorites => _isEn ? S_EN.favorites : S.favorites;
  static String get noFavorites => _isEn ? S_EN.noFavorites : S.noFavorites;
  static String get noFavoritesDesc =>
      _isEn ? S_EN.noFavoritesDesc : S.noFavoritesDesc;

  // Decks
  static String get decks => _isEn ? S_EN.decks : S.decks;
  static String get createDeck => _isEn ? S_EN.createDeck : S.createDeck;
  static String get noDecks => _isEn ? S_EN.noDecks : S.noDecks;
  static String get noDecksDesc => _isEn ? S_EN.noDecksDesc : S.noDecksDesc;
  static String get wordCount => _isEn ? S_EN.wordCount : S.wordCount;

  // Me / Account
  static String get account => _isEn ? S_EN.account : S.account;
  static String get profile => _isEn ? S_EN.profile : S.profile;
  static String get editProfile => _isEn ? S_EN.editProfile : S.editProfile;
  static String get settings => _isEn ? S_EN.settings : S.settings;
  static String get privacyPolicy =>
      _isEn ? S_EN.privacyPolicy : S.privacyPolicy;
  static String get termsOfService =>
      _isEn ? S_EN.termsOfService : S.termsOfService;
  static String get deleteAccount =>
      _isEn ? S_EN.deleteAccount : S.deleteAccount;

  // Me screen specific
  static String get me => _isEn ? S_EN.me : S.me;
  static String get dailyGoal => _isEn ? S_EN.dailyGoal : S.dailyGoal;
  static String get words => _isEn ? S_EN.words : S.words;
  static String get dayStreak => _isEn ? S_EN.dayStreak : S.dayStreak;
  static String get mastered => _isEn ? S_EN.mastered : S.mastered;
  static String get quickActions => _isEn ? S_EN.quickActions : S.quickActions;
  static String get adjustGoal => _isEn ? S_EN.adjustGoal : S.adjustGoal;
  static String get preferences => _isEn ? S_EN.preferences : S.preferences;
  static String get notifications =>
      _isEn ? S_EN.notifications : S.notifications;
  static String get soundHaptics => _isEn ? S_EN.soundHaptics : S.soundHaptics;
  static String get vietnameseSupport =>
      _isEn ? S_EN.vietnameseSupport : S.vietnameseSupport;
  static String get appVersion => _isEn ? S_EN.appVersion : S.appVersion;
  static String get proMember => _isEn ? S_EN.proMember : S.proMember;

  // Premium
  static String get premiumTitle => _isEn ? S_EN.premiumTitle : S.premiumTitle;
  static String get premiumSubtitle =>
      _isEn ? S_EN.premiumSubtitle : S.premiumSubtitle;
  static String get premiumCta => _isEn ? S_EN.premiumCta : S.premiumCta;
  static String get restorePurchase =>
      _isEn ? S_EN.restorePurchase : S.restorePurchase;

  // Errors
  static String get errorNetwork => _isEn ? S_EN.errorNetwork : S.errorNetwork;
  static String get errorServer => _isEn ? S_EN.errorServer : S.errorServer;
  static String get errorUnknown => _isEn ? S_EN.errorUnknown : S.errorUnknown;
  static String get errorSessionExpired =>
      _isEn ? S_EN.errorSessionExpired : S.errorSessionExpired;

  // Empty states
  static String get emptyVocabs => _isEn ? S_EN.emptyVocabs : S.emptyVocabs;
  static String get emptyDecks => _isEn ? S_EN.emptyDecks : S.emptyDecks;

  // Settings (new)
  static String get language => _isEn ? S_EN.language : 'Ngôn ngữ';
  static String get selectLanguage =>
      _isEn ? S_EN.selectLanguage : 'Chọn ngôn ngữ';
}
