import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'ast_utils.dart';

class ConditionChecker {
  static bool isNullSafeCondition(
    AstNode condition,
    String variableName, {
    bool isInBlock = true,
  }) {
    final unwrappedCondition = AstUtils.unwrapParentheses(condition);

    if (unwrappedCondition is! BinaryExpression) return false;

    final left = unwrappedCondition.leftOperand;
    final right = unwrappedCondition.rightOperand;
    final operator = unwrappedCondition.operator.type;

    if (right is NullLiteral) {
      if (operator == TokenType.BANG_EQ || operator == TokenType.EQ_EQ) {
        return _checkVariableMatch(left, variableName);
      }
    }

    if (operator == TokenType.AMPERSAND_AMPERSAND) {
      final leftCondition = AstUtils.unwrapParentheses(left);
      if (_isNotNullCheck(leftCondition, variableName)) {
        return true;
      }

      return isNullSafeCondition(left, variableName) ||
          isNullSafeCondition(right, variableName);
    }

    if (operator == TokenType.BAR_BAR) {
      final leftSafe =
          isNullSafeCondition(left, variableName, isInBlock: isInBlock);
      final rightSafe =
          isNullSafeCondition(right, variableName, isInBlock: isInBlock);

      return isInBlock ? leftSafe && rightSafe : leftSafe || rightSafe;
    }

    return false;
  }

  static bool _isNotNullCheck(AstNode node, String variableName) {
    if (node is! BinaryExpression) return false;

    return node.operator.type == TokenType.BANG_EQ &&
        node.rightOperand is NullLiteral &&
        _checkVariableMatch(node.leftOperand, variableName);
  }

  static bool _checkVariableMatch(Expression expression, String variableName) {
    if (expression is SimpleIdentifier) {
      return expression.name == variableName;
    }
    if (expression is PrefixedIdentifier) {
      return expression.identifier.name == variableName;
    }
    if (expression is PropertyAccess) {
      String leftName = '';
      if (expression.target is SimpleIdentifier) {
        leftName = (expression.target as SimpleIdentifier).name;
      } else {
        leftName = expression.target?.toString() ?? '';
      }
      return '$leftName.${expression.propertyName.name}' == variableName;
    }
    return false;
  }

  static bool checkMapContainsKeyGuard(AstNode node, String variableName,
      AstNode condition, Statement thenStatement) {
    VariableDeclaration? declaration =
        AstUtils.findVariableDeclarationInStatement(
            thenStatement, variableName);
    if (declaration != null && declaration.initializer != null) {
      if (declaration.initializer is IndexExpression) {
        final indexExpr = declaration.initializer as IndexExpression;
        final target = indexExpr.target;
        final index = indexExpr.index;

        if (condition is MethodInvocation) {
          final methodName = condition.methodName.name;
          final targetCondition = condition.target;
          final argumentList = condition.argumentList.arguments;

          if (methodName == 'containsKey' &&
              argumentList.length == 1 &&
              targetCondition != null &&
              AstUtils.areNodesEqual(target, targetCondition) &&
              AstUtils.areNodesEqual(index, argumentList.first)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static bool isMapKeyGuard(
    AstNode condition,
    Expression target,
    Expression index,
  ) {
    if (condition is! MethodInvocation) return false;

    final args = condition.argumentList.arguments;
    final methodTarget = condition.target;

    if (args.isEmpty || methodTarget == null) return false;

    return condition.methodName.name == 'containsKey' &&
        args.length == 1 &&
        AstUtils.areNodesEqual(target, methodTarget) &&
        AstUtils.areNodesEqual(index, args[0]);
  }

  static bool isGuardedMapAccess(
    Expression expression,
    AstNode condition,
  ) {
    if (expression is! IndexExpression) return false;

    final target = expression.target;
    if (target == null) return false;

    return isMapKeyGuard(condition, target, expression.index);
  }

  static bool isGuardedMapAccessInThen(
    AstNode node,
    String variableName,
    AstNode condition,
    Statement thenStatement,
  ) {
    final declaration = AstUtils.findVariableDeclarationInStatement(
      thenStatement,
      variableName,
    );

    if (declaration?.initializer == null) return false;

    return isGuardedMapAccess(declaration!.initializer!, condition);
  }
}
