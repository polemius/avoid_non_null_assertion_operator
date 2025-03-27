import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import '../utils/ast_utils.dart';
import '../utils/condition_checker.dart';

bool validateIfStatement(AstNode node, AstNode current, String? variableName) {
  if (current is! IfStatement || variableName == null) return false;

  final condition = current.expression;
  if (current.elseStatement != null &&
      AstUtils.isInStatement(node, current.elseStatement!)) {
    final unwrappedCondition = AstUtils.unwrapParentheses(condition);
    if (unwrappedCondition is BinaryExpression &&
        unwrappedCondition.operator.type == TokenType.EQ_EQ &&
        unwrappedCondition.rightOperand is NullLiteral) {
      final left = unwrappedCondition.leftOperand;
      String? checkedName = AstUtils.getVariableName(left);
      if (checkedName == variableName) {
        return true;
      }
    }
    if (ConditionChecker.isNullSafeCondition(condition, variableName,
        isInBlock: true)) {
      return false;
    }
  } else if (AstUtils.isInStatement(node, current.thenStatement)) {
    if (ConditionChecker.isNullSafeCondition(condition, variableName,
            isInBlock: true) ||
        ConditionChecker.checkMapContainsKeyGuard(
            node, variableName, condition, current.thenStatement)) {
      return true;
    }
  } else {
    if (ConditionChecker.isNullSafeCondition(condition, variableName,
        isInBlock: false)) {
      return true;
    }
  }

  return false;
}
