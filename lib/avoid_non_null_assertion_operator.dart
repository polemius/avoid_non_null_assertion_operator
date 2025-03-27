import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'src/utils/ast_utils.dart';
import 'src/utils/condition_checker.dart';
import 'src/validators/index.dart';

class AvoidNonNullAssertionOperator extends DartLintRule {
  AvoidNonNullAssertionOperator() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_non_null_assertion_operator',
    problemMessage:
        'Avoid using "!" unless you\'ve checked the variable isn\'t null first.',
    errorSeverity: analyzer.ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPostfixExpression((node) {
      if (node.operator.type != TokenType.BANG) return;

      final operand = node.operand;
      final variableName = AstUtils.getVariableName(operand);

      if (variableName == null) {
        if (operand is IndexExpression) {
          if (_isIndexExpressionGuarded(node, operand)) return;
        }
        if (!_isExpressionGuarded(node)) {
          reporter.atNode(node, code);
        }
        return;
      }

      if (!_isGuardedByNullCheck(node, variableName)) {
        reporter.atNode(node, code);
      }
    });
  }

  bool _isIndexExpressionGuarded(
      PostfixExpression node, IndexExpression operand) {
    AstNode? current = node;
    while (current != null) {
      if (current is IfStatement &&
          AstUtils.isInStatement(node, current.thenStatement)) {
        if (ConditionChecker.isGuardedMapAccess(operand, current.expression)) {
          return true;
        }
      }
      current = current.parent;
    }
    return false;
  }

  bool _isGuardedByNullCheck(AstNode node, String variableName) {
    AstNode? current = node;

    List<NullSafetyValidatorFn> validators = [
      validateListLiteral,
      validateBlock,
      validateConditionalExpression,
      validateIfStatement,
      validateWhileStatement,
      validateBinaryExpression
    ];

    while (current != null) {
      if (validators
          .any((validator) => validator(node, current!, variableName))) {
        return true;
      }
      current = current.parent;
    }

    return false;
  }

  bool _isExpressionGuarded(PostfixExpression node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is IfStatement) {
        final condition = current.expression;
        if (AstUtils.isInStatement(node, current.thenStatement) &&
            (AstUtils.conditionContainsExpression(condition, node.operand) &&
                _checkExpressionCondition(condition))) {
          return true;
        }
      } else if (current is BinaryExpression &&
          current.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        if (_checkExpressionCondition(current)) {
          return true;
        }
      } else if (current is ConditionalExpression) {
        final condition = current.condition;
        if (AstUtils.isInExpression(node, current.thenExpression) &&
            (_checkExpressionCondition(condition) ||
                (node.operand is IndexExpression &&
                    ConditionChecker.isGuardedMapAccess(
                        node.operand as IndexExpression, condition)))) {
          return true;
        }
      }
      current = current.parent;
    }
    return false;
  }

  bool _checkExpressionCondition(AstNode condition) {
    if (condition is BinaryExpression) {
      final right = condition.rightOperand;
      final operator = condition.operator.type;
      if (right is NullLiteral && operator == TokenType.BANG_EQ) {
        return true;
      }
      if (condition.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        return _checkExpressionCondition(condition.leftOperand) ||
            _checkExpressionCondition(condition.rightOperand);
      }
    }
    return false;
  }
}

PluginBase createPlugin() => _AvoidNonNullAssertionLint();

class _AvoidNonNullAssertionLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [AvoidNonNullAssertionOperator()];
  }
}
