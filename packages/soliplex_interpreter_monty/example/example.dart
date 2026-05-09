/// Runs a trivial Python expression through `MontyExecutionService` and
/// prints the result.
///
/// Loads the real Monty platform via `dart_monty`'s default factory, so it
/// requires the FFI native binding (or WASM on the web). Pure Dart only —
/// no `dart:io` so this example also runs on the web.
library;

import 'package:soliplex_interpreter_monty/soliplex_interpreter_monty.dart';

Future<void> main() async {
  final service = MontyExecutionService(limits: MontyLimitsDefaults.tool);

  try {
    final events =
        await service.execute('print("Hello from Monty!")\n2 + 40').toList();

    for (final event in events) {
      switch (event) {
        case ConsoleOutput(:final text):
          print('print: ${text.trimRight()}');
        case ConsoleComplete(:final result):
          print(
            'return value: ${result.value} '
            '(usage: ${result.usage.timeElapsedMs}ms)',
          );
        case ConsoleError(:final error):
          print('error: ${error.message}');
      }
    }
  } finally {
    service.dispose();
  }
}
