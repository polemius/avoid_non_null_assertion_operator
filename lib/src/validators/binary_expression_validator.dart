import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import '../utils/condition_checker.dart';

bool validateBinaryExpression(
    AstNode node, AstNode current, String? variableName) {
  if (node is! BinaryExpression || variableName == null) return false;

  if (node.operator.type != TokenType.AMPERSAND_AMPERSAND) return false;

  return ConditionChecker.isNullSafeCondition(
    node,
    variableName,
  );
}
