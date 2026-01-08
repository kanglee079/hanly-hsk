/// Exercise types for the learning system
enum ExerciseType {
  // Multiple Choice
  hanziToMeaning, // Show Hanzi → Choose correct meaning
  meaningToHanzi, // Show Meaning → Choose correct Hanzi
  audioToHanzi, // Play audio → Choose correct Hanzi
  audioToMeaning, // Play audio → Choose correct meaning
  hanziToPinyin, // Show Hanzi → Choose correct pinyin
  fillBlank, // Fill in the blank in sentence
  // Interactive
  matchingPairs, // Match Hanzi with meanings
  sentenceOrder, // Arrange words to form sentence
  strokeWriting, // Draw character strokes
  // Pronunciation
  speakWord, // Speak the word shown
}

/// Exercise difficulty
enum ExerciseDifficulty { easy, medium, hard }

/// A single exercise/question
class Exercise {
  final String id;
  final ExerciseType type;
  final ExerciseDifficulty difficulty;
  final String vocabId;

  // Question data
  final String? questionHanzi;
  final String? questionPinyin;
  final String? questionMeaning;
  final String? questionAudioUrl;
  final String? questionSlowAudioUrl; // Slow audio variant
  final String? questionSentence; // For fill blank
  final int? blankPosition; // Position of blank in sentence

  // Options (for MCQ)
  final List<String> options;
  final int correctIndex;

  // For matching game
  final List<MatchingItem>? matchingItems;

  // For sentence ordering
  final List<String>? sentenceWords;
  final String? correctSentence;

  // Metadata
  final int xpReward;
  final int timeLimit; // seconds, 0 = no limit

  Exercise({
    required this.id,
    required this.type,
    this.difficulty = ExerciseDifficulty.medium,
    required this.vocabId,
    this.questionHanzi,
    this.questionPinyin,
    this.questionMeaning,
    this.questionAudioUrl,
    this.questionSlowAudioUrl,
    this.questionSentence,
    this.blankPosition,
    this.options = const [],
    this.correctIndex = 0,
    this.matchingItems,
    this.sentenceWords,
    this.correctSentence,
    this.xpReward = 10,
    this.timeLimit = 0,
  });

  /// Get appropriate audio URL based on speed mode
  String? getAudioUrl({bool slow = false}) {
    if (slow) {
      // Prefer slow URL, fallback to normal
      return questionSlowAudioUrl ?? questionAudioUrl;
    }
    return questionAudioUrl;
  }

  /// Check if slow audio is available (native slow, not fallback)
  bool get hasNativeSlowAudio =>
      questionSlowAudioUrl != null && questionSlowAudioUrl!.isNotEmpty;

  /// Check if answer is correct
  bool checkAnswer(dynamic answer) {
    switch (type) {
      case ExerciseType.hanziToMeaning:
      case ExerciseType.meaningToHanzi:
      case ExerciseType.audioToHanzi:
      case ExerciseType.audioToMeaning:
      case ExerciseType.hanziToPinyin:
      case ExerciseType.fillBlank:
        return answer == correctIndex;

      case ExerciseType.matchingPairs:
        // Answer should be a map of matched pairs
        if (answer is! Map<int, int>) return false;
        final matched = answer;
        if (matchingItems == null) return false;
        for (final item in matchingItems!) {
          if (matched[item.leftIndex] != item.rightIndex) return false;
        }
        return true;

      case ExerciseType.sentenceOrder:
        if (answer is! List<String>) return false;
        final answerList = answer;
        return answerList.join('') == correctSentence?.replaceAll(' ', '');

      case ExerciseType.strokeWriting:
      case ExerciseType.speakWord:
        // These are evaluated separately
        return true;
    }
  }

  /// Get correct answer for display
  String get correctAnswerDisplay {
    switch (type) {
      case ExerciseType.hanziToMeaning:
      case ExerciseType.audioToMeaning:
        return questionMeaning ?? options[correctIndex];
      case ExerciseType.meaningToHanzi:
      case ExerciseType.audioToHanzi:
        return questionHanzi ?? options[correctIndex];
      case ExerciseType.hanziToPinyin:
        return questionPinyin ?? options[correctIndex];
      case ExerciseType.fillBlank:
        return options[correctIndex];
      case ExerciseType.sentenceOrder:
        return correctSentence ?? '';
      default:
        return options.isNotEmpty ? options[correctIndex] : '';
    }
  }
}

/// Item for matching game
class MatchingItem {
  final int leftIndex; // Index in left column
  final int rightIndex; // Index in right column
  final String leftText;
  final String rightText;

  MatchingItem({
    required this.leftIndex,
    required this.rightIndex,
    required this.leftText,
    required this.rightText,
  });
}

/// Result of an exercise attempt
class ExerciseResult {
  final String exerciseId;
  final ExerciseType type;
  final bool isCorrect;
  final int timeSpent; // milliseconds
  final int xpEarned;
  final dynamic userAnswer;
  final String? feedback;

  ExerciseResult({
    required this.exerciseId,
    required this.type,
    required this.isCorrect,
    required this.timeSpent,
    this.xpEarned = 0,
    this.userAnswer,
    this.feedback,
  });
}

/// Session configuration for different modes
class SessionConfig {
  final String id;
  final String name;
  final String description;
  final List<ExerciseType> exerciseTypes;
  final int vocabCount;
  final int exercisesPerVocab;
  final bool showLearningContent; // Show Hanzi DNA, context before quiz
  final bool showPronunciation;
  final bool useSRSRating; // Show again/hard/good/easy buttons
  final int timeLimit; // 0 = no limit
  final int xpMultiplier;

  const SessionConfig({
    required this.id,
    required this.name,
    required this.description,
    this.exerciseTypes = const [ExerciseType.hanziToMeaning],
    this.vocabCount = 10,
    this.exercisesPerVocab = 1,
    this.showLearningContent = false,
    this.showPronunciation = false,
    this.useSRSRating = false,
    this.timeLimit = 0,
    this.xpMultiplier = 1,
  });

  /// Predefined session configs
  /// Learn New: Structured pipeline per word
  /// Flow: Learning Content → Hanzi→Meaning → Meaning→Hanzi → Audio→Hanzi
  static const learnNew = SessionConfig(
    id: 'learn_new',
    name: 'Học từ mới',
    description: 'Học từ vựng mới với đầy đủ nội dung',
    exerciseTypes: [
      ExerciseType.hanziToMeaning, // Quiz 1: Xem từ → Chọn nghĩa
      ExerciseType.audioToHanzi, // Quiz 2: Nghe → Chọn từ (nếu có audio)
      ExerciseType.fillBlank, // Quiz 3: Điền vào chỗ trống
    ],
    vocabCount: 5,
    exercisesPerVocab: 3, // All 3 exercise types per vocab
    showLearningContent: true,
    showPronunciation: false, // Pronunciation is optional for now
    useSRSRating: false,
    xpMultiplier: 2,
  );

  static const reviewSRS = SessionConfig(
    id: 'review_srs',
    name: 'Ôn tập SRS',
    description: 'Ôn tập nhanh với Spaced Repetition',
    exerciseTypes: [ExerciseType.hanziToMeaning, ExerciseType.meaningToHanzi],
    vocabCount: 10,
    exercisesPerVocab: 1,
    showLearningContent: false,
    showPronunciation: false,
    useSRSRating: true,
    xpMultiplier: 1,
  );

  static const listeningPractice = SessionConfig(
    id: 'listening',
    name: 'Luyện nghe',
    description: 'Nghe và chọn đáp án đúng',
    exerciseTypes: [ExerciseType.audioToHanzi, ExerciseType.audioToMeaning],
    vocabCount: 15,
    exercisesPerVocab: 1,
    showLearningContent: false,
    showPronunciation: false,
    useSRSRating: false,
    xpMultiplier: 1,
  );

  static const matchingGame = SessionConfig(
    id: 'matching',
    name: 'Ghép từ',
    description: 'Ghép Hanzi với nghĩa',
    exerciseTypes: [ExerciseType.matchingPairs],
    vocabCount: 6, // 6 pairs per round
    exercisesPerVocab: 1,
    showLearningContent: false,
    showPronunciation: false,
    useSRSRating: false,
    xpMultiplier: 1,
  );

  static const game30s = SessionConfig(
    id: 'game30s',
    name: 'Game 30s',
    description: 'Trả lời nhanh trong 30 giây',
    exerciseTypes: [ExerciseType.hanziToMeaning, ExerciseType.meaningToHanzi],
    vocabCount: 20,
    exercisesPerVocab: 1,
    showLearningContent: false,
    showPronunciation: false,
    useSRSRating: false,
    timeLimit: 30,
    xpMultiplier: 2,
  );

  /// Sentence Formation: Đặt câu - Sắp xếp từ tạo câu đúng
  /// Flow: Show Vietnamese meaning → Arrange Chinese words → Check → Next
  static const sentenceFormation = SessionConfig(
    id: 'sentence_formation',
    name: 'Đặt câu',
    description: 'Sắp xếp từ tạo câu đúng',
    exerciseTypes: [ExerciseType.sentenceOrder],
    vocabCount: 10,
    exercisesPerVocab: 1,
    showLearningContent: false,
    showPronunciation: false,
    useSRSRating: false,
    xpMultiplier: 2,
  );
}
