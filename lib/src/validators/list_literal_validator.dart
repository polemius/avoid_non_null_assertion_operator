import 'package:analyzer/dart/ast/ast.dart';
import '../utils/ast_utils.dart';
import '../utils/condition_checker.dart';

bool validateListLiteral(AstNode node, AstNode current, String? variableName) {
  if (current is! ListLiteral || variableName == null) return false;

  final elements = current.elements;
  for (final element in elements) {
    if (element is IfElement) {
      final condition = AstUtils.unwrapParentheses(element.expression);
      if (AstUtils.isDescendant(node, element) &&
          ConditionChecker.isNullSafeCondition(condition, variableName)) {
        return true;
      }
    }
  }

  return false;
}
