import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AvoidNonNullAssertionOperator extends DartLintRule {
  AvoidNonNullAssertionOperator() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_non_null_assertion_operator',
    problemMessage:
        'Avoid using the non-null assertion operator (!). Use alternative null handling.',
    errorSeverity: analyzer.ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPostfixExpression((node) {
      if (node.operator.toString() == '!') {
        reporter.atNode(node, _code);
      }
    });
  }
}

PluginBase createPlugin() => _AvoidNonNullAssertionLint();

class _AvoidNonNullAssertionLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [AvoidNonNullAssertionOperator()];
  }
}
