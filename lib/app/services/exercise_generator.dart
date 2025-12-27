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
      correct: vocab.meaningVi,
      distractors: distractors.map((v) => v.meaningVi).toList(),
      count: 4,
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
      correct: vocab.meaningVi,
      distractors: distractors.map((v) => v.meaningVi).toList(),
      count: 4,
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
  Exercise? _generateSentenceOrder(VocabModel vocab) {
    final examples = vocab.examples;
    if (examples.isEmpty) {
      return null;
    }
    
    final example = examples.first;
    final sentence = example.hanzi;
    
    // Split sentence into characters/words (basic split)
    final words = sentence.split('').where((c) => c.trim().isNotEmpty).toList();
    if (words.length < 3) return null;
    
    final shuffled = List<String>.from(words)..shuffle(_random);
    
    return Exercise(
      id: 'so_${vocab.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: ExerciseType.sentenceOrder,
      vocabId: vocab.id,
      questionMeaning: example.meaningVi,
      sentenceWords: shuffled,
      correctSentence: sentence,
      xpReward: 20,
    );
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
  _MCQOptions _generateMCQOptions({
    required String correct,
    required List<String> distractors,
    int count = 4,
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
    
    // Add generic distractors if needed
    final genericDistractors = _getGenericDistractors();
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
  
  List<String> _getGenericDistractors() {
    return [
      '谢谢', '你好', '再见', '对不起', '没关系',
      '好', '是', '不', '很', '也',
      '我', '你', '他', '她', '们',
      'xin chào', 'tạm biệt', 'cảm ơn', 'xin lỗi', 'không sao',
      'tốt', 'là', 'không', 'rất', 'cũng',
      'tôi', 'bạn', 'anh ấy', 'cô ấy', 'họ',
    ]..shuffle(_random);
  }
}

class _MCQOptions {
  final List<String> shuffled;
  final int correctIndex;
  
  _MCQOptions({required this.shuffled, required this.correctIndex});
}

