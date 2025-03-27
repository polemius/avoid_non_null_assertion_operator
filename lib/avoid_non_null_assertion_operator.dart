import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AvoidNonNullAssertionOperator extends DartLintRule {
  AvoidNonNullAssertionOperator() : super(code: _code);

  // Define the lint rule details
  static const _code = LintCode(
    name: 'avoid_non_null_assertion_operator',
    problemMessage:
        'Avoid using "!" unless you’ve checked the variable isn’t null first.',
    errorSeverity: analyzer.ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPostfixExpression((node) {
      if (node.operator.type == TokenType.BANG) {
        final operand = node.operand;
        String? variableName;

        if (operand is SimpleIdentifier) {
          variableName = operand.name;
        } else if (operand is PrefixedIdentifier) {
          variableName = operand.identifier.name;
        } else if (operand is PropertyAccess) {
          variableName = operand.propertyName.name;
        }

        if (variableName != null) {
          if (!_isGuardedByNullCheck(node, variableName)) {
            reporter.reportErrorForNode(code, node);
          }
        } else {
          if (!_isExpressionGuarded(node)) {
            reporter.reportErrorForNode(code, node);
          }
        }
      }
    });
  }

  bool _isGuardedByNullCheck(AstNode node, String variableName) {
    AstNode? current = node;

    while (current != null) {
      if (current is IfStatement) {
        final condition = current.condition;
        if (current.elseStatement != null &&
            _isNodeInStatement(node, current.elseStatement!)) {
          if (_checkCondition(condition, variableName)) {
            return false; // In else branch where null check failed
          }
        } else if (_checkCondition(condition, variableName)) {
          return true; // In then branch or outside else, null check succeeded
        }
      } else if (current is WhileStatement) {
        final condition = current.condition;
        if (_checkCondition(condition, variableName)) {
          return true;
        }
      } else if (current is BinaryExpression &&
          current.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        if (_checkCondition(current, variableName)) {
          return true;
        }
      }

      current = current.parent;
    }

    return false; // No guarding null check found
  }

  bool _checkCondition(AstNode condition, String variableName) {
    if (condition is BinaryExpression) {
      final left = condition.leftOperand;
      final right = condition.rightOperand;
      final operator = condition.operator.type;

      if (left is SimpleIdentifier &&
          left.name == variableName &&
          right is NullLiteral &&
          operator == TokenType.BANG_EQ) {
        return true;
      } else if (left is PrefixedIdentifier &&
          left.identifier.name == variableName &&
          right is NullLiteral &&
          operator == TokenType.BANG_EQ) {
        return true;
      } else if (left is PropertyAccess &&
          left.propertyName.name == variableName &&
          right is NullLiteral &&
          operator == TokenType.BANG_EQ) {
        return true;
      }

      if (condition.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        return _checkCondition(condition.leftOperand, variableName) ||
            _checkCondition(condition.rightOperand, variableName);
      }
    }
    return false;
  }

  bool _isNodeInStatement(AstNode node, Statement statement) {
    if (statement is Block) {
      for (var stmt in statement.statements) {
        if (stmt == node || _isNodeInStatement(node, stmt)) {
          return true;
        }
      }
    } else {
      // Recursively check if node is a descendant of the statement
      return _isDescendant(node, statement);
    }
    return false;
  }

  bool _isDescendant(AstNode node, AstNode parent) {
    if (node == parent) {
      return true;
    }
    for (var child in parent.childEntities) {
      if (child is AstNode && _isDescendant(node, child)) {
        return true;
      }
    }
    return false;
  }

  bool _isExpressionGuarded(PostfixExpression node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is IfStatement) {
        final condition = current.condition;
        if (_conditionContainsExpression(condition, node.operand) &&
            _checkExpressionCondition(condition)) {
          return true;
        }
      } else if (current is BinaryExpression &&
          current.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        if (_checkExpressionCondition(current)) {
          return true;
        }
      }
      current = current.parent;
    }
    return false;
  }

  bool _conditionContainsExpression(AstNode condition, Expression operand) {
    if (condition.toString().contains(operand.toString())) {
      return true;
    }
    if (condition is BinaryExpression) {
      return _conditionContainsExpression(condition.leftOperand, operand) ||
          _conditionContainsExpression(condition.rightOperand, operand);
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
