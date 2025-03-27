import 'package:analyzer/dart/ast/ast.dart';
import '../utils/condition_checker.dart';

bool validateWhileStatement(
    AstNode node, AstNode current, String? variableName) {
  if (current is! WhileStatement || variableName == null) return false;

  return ConditionChecker.isNullSafeCondition(
    current.condition,
    variableName,
  );
}
