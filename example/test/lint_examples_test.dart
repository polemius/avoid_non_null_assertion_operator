import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('Custom lint flags match the number of "flagged"/"Flagged" comments',
      () async {
    final process = await Process.run(
      'dart',
      ['run', 'custom_lint'],
      workingDirectory: Directory.current.path,
    );

    final output = process.stdout.toString();
    final errorOutput = process.stderr.toString();

    print('Lint output: $output');
    if (errorOutput.isNotEmpty) print('Lint errors: $errorOutput');

    // Read the source file
    final sourceFile = File('./main.dart');
    final sourceLines = sourceFile.readAsLinesSync();

    final flaggedCount = sourceLines
        .map((line) => RegExp(r'(flagged|Flagged)').allMatches(line).length)
        .reduce((a, b) => a + b);

    final lintLines = output
        .split('\n')
        .where((line) => line.contains('avoid_non_null_assertion_operator'))
        .toList();

    for (final lint in lintLines) {
      final lineNumberStr = lint.split(':')[1];
      final lineNumber = int.parse(lineNumberStr);
      final sourceLine = sourceLines[lineNumber - 1];

      final hasFlagged = sourceLine.contains(RegExp(r'(flagged|Flagged)'));
      expect(
        hasFlagged,
        isTrue,
        reason: 'Line $lineNumber: "$sourceLine"\n'
            'Error: $lint\n'
            'Expected "flagged" or "Flagged" in comment, but it was missing.',
      );
    }

    expect(
      lintLines.length,
      equals(flaggedCount),
      reason:
          'Expected $flaggedCount lint errors (matching "flagged"/"Flagged" count), '
          'but found ${lintLines.length}.',
    );

    expect(
      lintLines.isNotEmpty,
      isTrue,
      reason: 'No lint errors were found; check the lint rule or source file.',
    );
  });
}
