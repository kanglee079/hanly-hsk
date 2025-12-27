import 'package:flutter_test/flutter_test.dart';
import 'package:hoc_tieng_trung_hsk_hanly/app/data/models/vocab_model.dart';
import 'package:hoc_tieng_trung_hsk_hanly/app/data/models/exercise_model.dart';
import 'package:hoc_tieng_trung_hsk_hanly/app/services/exercise_generator.dart';

void main() {
  group('Exercise Audio Tests', () {
    late ExerciseGenerator generator;
    late List<VocabModel> testVocabs;

    setUp(() {
      generator = ExerciseGenerator();
      
      // Create test vocabs with distinct audio URLs
      testVocabs = [
        VocabModel(
          id: 'vocab_1',
          hanzi: '你好',
          pinyin: 'nǐ hǎo',
          meaningVi: 'Xin chào',
          level: 'HSK1',
          audioUrl: 'https://audio.test/nihao.mp3',
          audioSlowUrl: 'https://audio.test/nihao_slow.mp3',
        ),
        VocabModel(
          id: 'vocab_2',
          hanzi: '谢谢',
          pinyin: 'xiè xiè',
          meaningVi: 'Cảm ơn',
          level: 'HSK1',
          audioUrl: 'https://audio.test/xiexie.mp3',
          audioSlowUrl: 'https://audio.test/xiexie_slow.mp3',
        ),
        VocabModel(
          id: 'vocab_3',
          hanzi: '再见',
          pinyin: 'zài jiàn',
          meaningVi: 'Tạm biệt',
          level: 'HSK1',
          audioUrl: 'https://audio.test/zaijian.mp3',
          audioSlowUrl: null, // No slow audio available
        ),
      ];
    });

    test('Exercise should contain normal audio URL from vocab', () {
      final exercises = generator.generateExercises(
        vocabs: testVocabs,
        config: SessionConfig.learnNew,
      );
      
      expect(exercises.isNotEmpty, true);
      
      for (final exercise in exercises) {
        // Find the vocab for this exercise
        final vocab = testVocabs.firstWhere((v) => v.id == exercise.vocabId);
        
        // Normal audio URL should match vocab's audioUrl
        expect(
          exercise.questionAudioUrl, 
          vocab.audioUrl,
          reason: 'Exercise audio URL should match vocab audioUrl for vocabId=${exercise.vocabId}',
        );
      }
    });

    test('Exercise should contain slow audio URL from vocab', () {
      final exercises = generator.generateExercises(
        vocabs: testVocabs,
        config: SessionConfig.learnNew,
      );
      
      for (final exercise in exercises) {
        final vocab = testVocabs.firstWhere((v) => v.id == exercise.vocabId);
        
        // Slow audio URL should match vocab's audioSlowUrl
        expect(
          exercise.questionSlowAudioUrl, 
          vocab.audioSlowUrl,
          reason: 'Exercise slow audio URL should match vocab audioSlowUrl for vocabId=${exercise.vocabId}',
        );
      }
    });

    test('Exercise.getAudioUrl() returns correct URL based on slow flag', () {
      final exercise = Exercise(
        id: 'test_1',
        type: ExerciseType.hanziToMeaning,
        vocabId: 'vocab_1',
        questionHanzi: '你好',
        questionAudioUrl: 'https://audio.test/normal.mp3',
        questionSlowAudioUrl: 'https://audio.test/slow.mp3',
        options: ['A', 'B', 'C', 'D'],
        correctIndex: 0,
      );
      
      // Normal speed should return normal URL
      expect(exercise.getAudioUrl(slow: false), 'https://audio.test/normal.mp3');
      
      // Slow speed should return slow URL
      expect(exercise.getAudioUrl(slow: true), 'https://audio.test/slow.mp3');
    });

    test('Exercise.getAudioUrl() falls back to normal URL when slow is null', () {
      final exercise = Exercise(
        id: 'test_2',
        type: ExerciseType.hanziToMeaning,
        vocabId: 'vocab_3',
        questionHanzi: '再见',
        questionAudioUrl: 'https://audio.test/normal.mp3',
        questionSlowAudioUrl: null, // No slow audio
        options: ['A', 'B', 'C', 'D'],
        correctIndex: 0,
      );
      
      // Slow speed should fall back to normal URL
      expect(exercise.getAudioUrl(slow: true), 'https://audio.test/normal.mp3');
    });

    test('Exercise.hasNativeSlowAudio correctly identifies slow audio availability', () {
      final withSlowAudio = Exercise(
        id: 'test_3',
        type: ExerciseType.hanziToMeaning,
        vocabId: 'vocab_1',
        questionSlowAudioUrl: 'https://audio.test/slow.mp3',
        options: [],
        correctIndex: 0,
      );
      
      final withoutSlowAudio = Exercise(
        id: 'test_4',
        type: ExerciseType.hanziToMeaning,
        vocabId: 'vocab_3',
        questionSlowAudioUrl: null,
        options: [],
        correctIndex: 0,
      );
      
      expect(withSlowAudio.hasNativeSlowAudio, true);
      expect(withoutSlowAudio.hasNativeSlowAudio, false);
    });

    test('Exercises for different vocabs have different audio URLs', () {
      final exercises = generator.generateExercises(
        vocabs: testVocabs,
        config: SessionConfig.learnNew,
      );
      
      // Group exercises by vocabId
      final exercisesByVocab = <String, List<Exercise>>{};
      for (final ex in exercises) {
        exercisesByVocab.putIfAbsent(ex.vocabId, () => []).add(ex);
      }
      
      // Verify each vocab group has consistent audio URLs
      for (final entry in exercisesByVocab.entries) {
        final vocabId = entry.key;
        final vocabExercises = entry.value;
        final expectedVocab = testVocabs.firstWhere((v) => v.id == vocabId);
        
        for (final ex in vocabExercises) {
          expect(
            ex.questionAudioUrl, 
            expectedVocab.audioUrl,
            reason: 'All exercises for vocabId=$vocabId should have same audio URL',
          );
        }
      }
    });

    test('Audio exercises require audio URL', () {
      final vocabWithAudio = VocabModel(
        id: 'with_audio',
        hanzi: '是',
        pinyin: 'shì',
        meaningVi: 'Là',
        level: 'HSK1',
        audioUrl: 'https://audio.test/shi.mp3',
      );
      
      final vocabWithoutAudio = VocabModel(
        id: 'without_audio',
        hanzi: '不',
        pinyin: 'bù',
        meaningVi: 'Không',
        level: 'HSK1',
        audioUrl: null, // No audio
      );
      
      final exercises = generator.generateExercises(
        vocabs: [vocabWithAudio, vocabWithoutAudio],
        config: SessionConfig.listeningPractice, // Audio-based exercises
      );
      
      // Exercises should have valid audio URLs or be fallback types
      for (final ex in exercises) {
        if (ex.type == ExerciseType.audioToHanzi || 
            ex.type == ExerciseType.audioToMeaning) {
          expect(
            ex.questionAudioUrl?.isNotEmpty ?? false, 
            true,
            reason: 'Audio exercises must have audio URL',
          );
        }
      }
    });

    test('LearnNew preserveOrder keeps vocab order and step order', () {
      final exercises = generator.generateExercises(
        vocabs: testVocabs,
        config: SessionConfig.learnNew,
        preserveOrder: true,
      );

      final perVocab = SessionConfig.learnNew.exercisesPerVocab;
      expect(exercises.length, testVocabs.length * perVocab);

      for (int vocabIndex = 0; vocabIndex < testVocabs.length; vocabIndex++) {
        final base = vocabIndex * perVocab;
        final vocab = testVocabs[vocabIndex];

        // Vocab order preserved
        expect(exercises[base].vocabId, vocab.id);

        // Step order preserved (matches SessionConfig.learnNew.exerciseTypes)
        for (int step = 0; step < perVocab; step++) {
          expect(
            exercises[base + step].vocabId,
            vocab.id,
            reason: 'Exercises must be grouped per vocab when preserveOrder=true',
          );
          expect(
            exercises[base + step].type,
            SessionConfig.learnNew.exerciseTypes[step],
            reason: 'Step order must match config.exerciseTypes when preserveOrder=true',
          );
        }
      }
    });
  });
}

