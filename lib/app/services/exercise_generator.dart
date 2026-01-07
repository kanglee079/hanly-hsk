import 'dart:math';
import '../data/models/vocab_model.dart';
import '../data/models/exercise_model.dart';

/// Service to generate exercises from vocabulary
class ExerciseGenerator {
  final Random _random = Random();
  
  /// Generate exercises for a list of vocab based on session config
  /// 
  /// [preserveOrder] - if true, keeps vocab AND exercise order consistent
  ///                   (for learnNew mode: structured pipeline per word)
  List<Exercise> generateExercises({
    required List<VocabModel> vocabs,
    required SessionConfig config,
    List<VocabModel>? allVocabs, // For distractors
    bool preserveOrder = false, // Structured learning (no shuffle)
  }) {
    final exercises = <Exercise>[];
    final distractorPool = allVocabs ?? vocabs;
    
    for (final vocab in vocabs) {
      // For preserveOrder (learnNew): keep exercise types in defined order
      // For other modes: shuffle exercise types for variety
      final types = preserveOrder 
          ? config.exerciseTypes 
          : (List<ExerciseType>.from(config.exerciseTypes)..shuffle(_random));
      
      // Generate up to exercisesPerVocab exercises
      for (int i = 0; i < config.exercisesPerVocab && i < types.length; i++) {
        final exercise = _generateExercise(
          vocab: vocab,
          type: types[i],
          distractors: distractorPool.where((v) => v.id != vocab.id).toList(),
          config: config,
        );
        if (exercise != null) {
          exercises.add(exercise);
        }
      }
    }
    
    // Only shuffle entire list if NOT preserving order
    if (!preserveOrder) {
      exercises.shuffle(_random);
    }
    
    return exercises;
  }
  
  /// Generate a single exercise
  Exercise? _generateExercise({
    required VocabModel vocab,
    required ExerciseType type,
    required List<VocabModel> distractors,
    required SessionConfig config,
  }) {
    switch (type) {
      case ExerciseType.hanziToMeaning:
        return _generateHanziToMeaning(vocab, distractors);
      case ExerciseType.meaningToHanzi:
        return _generateMeaningToHanzi(vocab, distractors);
      case ExerciseType.audioToHanzi:
        return _generateAudioToHanzi(vocab, distractors);
      case ExerciseType.audioToMeaning:
        return _generateAudioToMeaning(vocab, distractors);
      case ExerciseType.hanziToPinyin:
        return _generateHanziToPinyin(vocab, distractors);
      case ExerciseType.fillBlank:
        return _generateFillBlank(vocab, distractors);
      case ExerciseType.matchingPairs:
        // Matching needs multiple vocabs
        return null;
      case ExerciseType.sentenceOrder:
        return _generateSentenceOrder(vocab);
      case ExerciseType.strokeWriting:
      case ExerciseType.speakWord:
        return _generateSpeakWord(vocab);
    }
  }
  
  /// Hanzi → Meaning (Show 你好, choose "Xin chào")
  Exercise _generateHanziToMeaning(VocabModel vocab, List<VocabModel> distractors) {
    final options = _generateMCQOptions(
      correct: vocab.meaningViCapitalized,
      distractors: distractors.map((v) => v.meaningViCapitalized).toList(),
      count: 4,
      isChinese: false, // Options are Vietnamese meanings
    );
    
    return Exercise(
      id: 'h2m_${vocab.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: ExerciseType.hanziToMeaning,
      vocabId: vocab.id,
      questionHanzi: vocab.hanzi,
      questionPinyin: vocab.pinyin,
      questionAudioUrl: vocab.audioUrl,
      questionSlowAudioUrl: vocab.audioSlowUrl,
      options: options.shuffled,
      correctIndex: options.correctIndex,
      xpReward: 10,
    );
  }
  
  /// Meaning → Hanzi (Show "Xin chào", choose 你好)
  Exercise _generateMeaningToHanzi(VocabModel vocab, List<VocabModel> distractors) {
    final options = _generateMCQOptions(
      correct: vocab.hanzi,
      distractors: distractors.map((v) => v.hanzi).toList(),
      count: 4,
      isChinese: true, // Options are Chinese Hanzi
    );
    
    return Exercise(
      id: 'm2h_${vocab.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: ExerciseType.meaningToHanzi,
      vocabId: vocab.id,
      questionMeaning: vocab.meaningVi,
      questionAudioUrl: vocab.audioUrl,
      questionSlowAudioUrl: vocab.audioSlowUrl,
      options: options.shuffled,
      correctIndex: options.correctIndex,
      xpReward: 15, // Harder recall
    );
  }
  
  /// Audio → Hanzi (Play audio, choose correct Hanzi)
  Exercise _generateAudioToHanzi(VocabModel vocab, List<VocabModel> distractors) {
    if (vocab.audioUrl == null || vocab.audioUrl!.isEmpty) {
      // Fallback to hanzi to meaning
      return _generateHanziToMeaning(vocab, distractors);
    }
    
    final options = _generateMCQOptions(
      correct: vocab.hanzi,
      distractors: distractors.map((v) => v.hanzi).toList(),
      count: 4,
      isChinese: true, // Options are Chinese Hanzi
    );
    
    return Exercise(
      id: 'a2h_${vocab.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: ExerciseType.audioToHanzi,
      vocabId: vocab.id,
      questionHanzi: vocab.hanzi, // For reference
      questionPinyin: vocab.pinyin,
      questionMeaning: vocab.meaningVi,
      questionAudioUrl: vocab.audioUrl,
      questionSlowAudioUrl: vocab.audioSlowUrl,
      options: options.shuffled,
      correctIndex: options.correctIndex,
      xpReward: 15,
    );
  }
  
  /// Audio → Meaning (Play audio, choose correct meaning)
  Exercise _generateAudioToMeaning(VocabModel vocab, List<VocabModel> distractors) {
    if (vocab.audioUrl == null || vocab.audioUrl!.isEmpty) {
      return _generateHanziToMeaning(vocab, distractors);
    }
    
    final options = _generateMCQOptions(
      correct: vocab.meaningViCapitalized,
      distractors: distractors.map((v) => v.meaningViCapitalized).toList(),
      count: 4,
      isChinese: false, // Options are Vietnamese meanings
    );
    
    return Exercise(
      id: 'a2m_${vocab.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: ExerciseType.audioToMeaning,
      vocabId: vocab.id,
      questionHanzi: vocab.hanzi,
      questionPinyin: vocab.pinyin,
      questionMeaning: vocab.meaningVi,
      questionAudioUrl: vocab.audioUrl,
      questionSlowAudioUrl: vocab.audioSlowUrl,
      options: options.shuffled,
      correctIndex: options.correctIndex,
      xpReward: 10,
    );
  }
  
  /// Hanzi → Pinyin (Show 你好, choose nǐ hǎo)
  Exercise _generateHanziToPinyin(VocabModel vocab, List<VocabModel> distractors) {
    final options = _generateMCQOptions(
      correct: vocab.pinyin,
      distractors: distractors.map((v) => v.pinyin).toList(),
      count: 4,
      isPinyin: true, // Options are Pinyin
    );
    
    return Exercise(
      id: 'h2p_${vocab.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: ExerciseType.hanziToPinyin,
      vocabId: vocab.id,
      questionHanzi: vocab.hanzi,
      questionMeaning: vocab.meaningVi,
      questionAudioUrl: vocab.audioUrl,
      questionSlowAudioUrl: vocab.audioSlowUrl,
      options: options.shuffled,
      correctIndex: options.correctIndex,
      xpReward: 10,
    );
  }
  
  /// Fill in the blank
  Exercise? _generateFillBlank(VocabModel vocab, List<VocabModel> distractors) {
    // Use examples from vocab
    final examples = vocab.examples;
    if (examples.isEmpty) {
      // Fallback to hanzi to meaning
      return _generateHanziToMeaning(vocab, distractors);
    }
    
    // Find an example that contains the hanzi
    for (final example in examples) {
      final sentence = example.hanzi;
      if (sentence.contains(vocab.hanzi)) {
        final blankSentence = sentence.replaceFirst(vocab.hanzi, '____');
        
        final options = _generateMCQOptions(
          correct: vocab.hanzi,
          distractors: distractors.map((v) => v.hanzi).toList(),
          count: 4,
          isChinese: true, // Options are Chinese Hanzi
        );
        
        return Exercise(
          id: 'fb_${vocab.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: ExerciseType.fillBlank,
          vocabId: vocab.id,
          questionSentence: blankSentence,
          questionMeaning: example.meaningVi,
          questionHanzi: vocab.hanzi,
          options: options.shuffled,
          correctIndex: options.correctIndex,
          xpReward: 15,
        );
      }
    }
    
    return _generateHanziToMeaning(vocab, distractors);
  }
  
  /// Sentence ordering
  /// Generate sentence ordering exercise
  /// Words are sent in CORRECT order - widget handles shuffling
  Exercise? _generateSentenceOrder(VocabModel vocab) {
    final examples = vocab.examples;
    if (examples.isEmpty) {
      return null;
    }
    
    final example = examples.first;
    final sentence = example.hanzi;
    
    // Try to split by common Chinese word boundaries
    // If sentence has spaces, use them; otherwise split by characters
    List<String> words;
    if (sentence.contains(' ')) {
      // Sentence already has word boundaries
      words = sentence.split(' ').where((w) => w.trim().isNotEmpty).toList();
    } else {
      // Split into 2-3 character groups for more natural words
      // This is a heuristic - ideally we'd have pre-tokenized data
      words = _splitIntoChineseWords(sentence);
    }
    
    if (words.length < 3) return null;
    
    return Exercise(
      id: 'so_${vocab.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: ExerciseType.sentenceOrder,
      vocabId: vocab.id,
      questionMeaning: example.meaningViCapitalized,
      sentenceWords: words, // Correct order - widget will shuffle
      correctSentence: words.join(''), // For verification
      xpReward: 20,
    );
  }
  
  /// Split Chinese sentence into word-like segments
  /// This is a simple heuristic - ideally use tokenized data
  List<String> _splitIntoChineseWords(String sentence) {
    // Remove punctuation for cleaner tokens
    final cleaned = sentence.replaceAll(RegExp(r'[。，！？、；：""''（）【】]'), '');
    
    // Simple heuristic: try to split into 2-character groups (most Chinese words are 2 chars)
    // But preserve single chars at the end
    final chars = cleaned.split('').where((c) => c.trim().isNotEmpty).toList();
    final words = <String>[];
    
    int i = 0;
    while (i < chars.length) {
      // If we have at least 2 chars left, make a 2-char word
      if (i + 1 < chars.length) {
        // Randomly decide between 1-char and 2-char words for variety
        if (_random.nextBool() && chars.length > 4) {
          words.add(chars[i]);
          i += 1;
        } else {
          words.add(chars[i] + chars[i + 1]);
          i += 2;
        }
      } else {
        words.add(chars[i]);
        i += 1;
      }
    }
    
    return words;
  }
  
  /// Speak word exercise
  Exercise _generateSpeakWord(VocabModel vocab) {
    return Exercise(
      id: 'sw_${vocab.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: ExerciseType.speakWord,
      vocabId: vocab.id,
      questionHanzi: vocab.hanzi,
      questionPinyin: vocab.pinyin,
      questionMeaning: vocab.meaningVi,
      questionAudioUrl: vocab.audioUrl,
      questionSlowAudioUrl: vocab.audioSlowUrl,
      options: [],
      correctIndex: 0,
      xpReward: 15,
    );
  }
  
  /// Generate matching pairs exercise
  Exercise generateMatchingExercise(List<VocabModel> vocabs) {
    // Take 6 vocabs for matching
    final selected = vocabs.take(6).toList();
    
    final items = <MatchingItem>[];
    for (int i = 0; i < selected.length; i++) {
      items.add(MatchingItem(
        leftIndex: i,
        rightIndex: i,
        leftText: selected[i].hanzi,
        rightText: selected[i].meaningVi,
      ));
    }
    
    return Exercise(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      type: ExerciseType.matchingPairs,
      vocabId: selected.first.id,
      matchingItems: items,
      options: [],
      correctIndex: 0,
      xpReward: 30,
    );
  }
  
  /// Helper to generate MCQ options
  /// [optionType] determines which generic distractors to use if needed
  _MCQOptions _generateMCQOptions({
    required String correct,
    required List<String> distractors,
    int count = 4,
    bool isChinese = false,
    bool isPinyin = false,
  }) {
    final options = <String>[correct];
    
    // Filter out duplicates and empty
    final filtered = distractors
        .where((d) => d.isNotEmpty && d != correct && !options.contains(d))
        .toList()
      ..shuffle(_random);
    
    // Add distractors
    for (final d in filtered) {
      if (options.length >= count) break;
      options.add(d);
    }
    
    // Add generic distractors if needed - USE CORRECT LANGUAGE
    List<String> genericDistractors;
    if (isChinese) {
      genericDistractors = _getChineseGenericDistractors();
    } else if (isPinyin) {
      genericDistractors = _getPinyinGenericDistractors();
    } else {
      genericDistractors = _getVietnameseGenericDistractors();
    }
    
    while (options.length < count && genericDistractors.isNotEmpty) {
      final d = genericDistractors.removeAt(0);
      if (!options.contains(d)) {
        options.add(d);
      }
    }
    
    // Shuffle and find correct index
    final shuffled = List<String>.from(options)..shuffle(_random);
    final correctIndex = shuffled.indexOf(correct);
    
    return _MCQOptions(shuffled: shuffled, correctIndex: correctIndex);
  }
  
  /// Chinese generic distractors for Hanzi options
  List<String> _getChineseGenericDistractors() {
    return [
      '谢谢', '你好', '再见', '对不起', '没关系',
      '好', '是', '不', '很', '也',
      '我', '你', '他', '她', '们',
      '什么', '这个', '那个', '一个', '两个',
      '可以', '不行', '知道', '看见', '听说',
    ]..shuffle(_random);
  }
  
  /// Vietnamese generic distractors for meaning options
  List<String> _getVietnameseGenericDistractors() {
    return [
      'Xin chào', 'Tạm biệt', 'Cảm ơn', 'Xin lỗi', 'Không sao',
      'Tốt', 'Là', 'Không', 'Rất', 'Cũng',
      'Tôi', 'Bạn', 'Anh ấy', 'Cô ấy', 'Họ',
      'Cái này', 'Cái kia', 'Một cái', 'Hai cái', 'Được',
      'Không được', 'Biết', 'Nhìn thấy', 'Nghe nói', 'Muốn',
    ]..shuffle(_random);
  }
  
  /// Pinyin generic distractors
  List<String> _getPinyinGenericDistractors() {
    return [
      'nǐ hǎo', 'zài jiàn', 'xiè xie', 'duì bu qǐ', 'méi guān xi',
      'hǎo', 'shì', 'bù', 'hěn', 'yě',
      'wǒ', 'nǐ', 'tā', 'men', 'de',
      'zhè ge', 'nà ge', 'yī ge', 'liǎng ge', 'kě yǐ',
    ]..shuffle(_random);
  }
}

class _MCQOptions {
  final List<String> shuffled;
  final int correctIndex;
  
  _MCQOptions({required this.shuffled, required this.correctIndex});
}

