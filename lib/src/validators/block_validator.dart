import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import '../utils/ast_utils.dart';

bool validateBlock(AstNode node, AstNode current, String? variableName) {
  if (current is! Block || variableName == null) return false;

  final statements = current.statements;
  Statement? containingStatement;
  int nodeIndex = -1;

  for (int i = 0; i < statements.length; i++) {
    if (AstUtils.isDescendant(node, statements[i])) {
      containingStatement = statements[i];
      nodeIndex = i;
      break;
    }
  }

  if (nodeIndex > 0 && containingStatement != null) {
    for (int i = 0; i < nodeIndex; i++) {
      final stmt = statements[i];
      if (stmt is IfStatement) {
        final condition = AstUtils.unwrapParentheses(stmt.expression);
        if (condition is BinaryExpression &&
            condition.operator.type == TokenType.EQ_EQ &&
            condition.rightOperand is NullLiteral) {
          final left = condition.leftOperand;
          String? checkedName = AstUtils.getVariableName(left);
          if (checkedName == variableName &&
              stmt.thenStatement is Block &&
              (stmt.thenStatement as Block).statements.any((s) =>
                  s is ReturnStatement ||
                  (s is ExpressionStatement &&
                      s.expression is ThrowExpression)) &&
              stmt.elseStatement == null) {
            return true;
          }
        }
      }
    }
  }
  return false;
}
