import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoc_tieng_trung_hsk_hanly/app/services/realtime/realtime_resource.dart';

void main() {
  group('RealtimeResource', () {
    test('syncNow updates data once when fingerprint unchanged', () async {
      int fetchCalls = 0;

      final resource = RealtimeResource<Map<String, dynamic>>(
        key: 'unit',
        interval: const Duration(seconds: 999),
        fetcher: () async {
          fetchCalls++;
          return {'v': 1};
        },
        fingerprinter: (v) => v.toString(),
      );

      int updates = 0;
      final sub = resource.data.listen((_) => updates++);

      await resource.syncNow();
      await resource.syncNow();

      expect(fetchCalls, 2); // still fetches, but should not emit identical payload
      expect(resource.data.value, {'v': 1});
      expect(updates, 1);

      await sub.cancel();
    });

    test('syncNow prevents overlapping fetches', () async {
      int fetchCalls = 0;
      final completer = Completer<void>();

      final resource = RealtimeResource<int>(
        key: 'unit',
        interval: const Duration(seconds: 999),
        fetcher: () async {
          fetchCalls++;
          await completer.future;
          return 1;
        },
        fingerprinter: (v) => '$v',
      );

      final f1 = resource.syncNow();
      final f2 = resource.syncNow(); // should no-op

      expect(fetchCalls, 1);

      completer.complete();
      await Future.wait([f1, f2]);

      expect(resource.data.value, 1);
      expect(resource.isBootstrapping.value, false);
    });
  });
}


