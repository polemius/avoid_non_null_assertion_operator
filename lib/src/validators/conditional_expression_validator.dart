import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import '../utils/ast_utils.dart';

bool validateConditionalExpression(
    AstNode node, AstNode current, String? variableName) {
  if (current is! ConditionalExpression || variableName == null) return false;

  final condition = AstUtils.unwrapParentheses(current.condition);
  if (condition is BinaryExpression &&
      condition.rightOperand is NullLiteral &&
      AstUtils.getVariableName(condition.leftOperand) == variableName) {
    final isNotNullCheck = condition.operator.type == TokenType.BANG_EQ;
    final isNullCheck = condition.operator.type == TokenType.EQ_EQ;

    if (AstUtils.isInExpression(node, current.thenExpression)) {
      if (isNotNullCheck) {
        return true;
      }
    } else if (AstUtils.isInExpression(node, current.elseExpression)) {
      if (isNullCheck) {
        return true;
      }
    }
  }
  return false;
}
