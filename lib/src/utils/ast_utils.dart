import 'package:analyzer/dart/ast/ast.dart';

class AstUtils {
  static String? getVariableName(Expression operand) {
    if (operand is SimpleIdentifier) {
      return operand.name;
    }
    if (operand is PrefixedIdentifier) {
      return operand.identifier.name;
    }
    if (operand is PropertyAccess && operand.target is SimpleIdentifier) {
      return '${(operand.target as SimpleIdentifier).name}.${operand.propertyName.name}';
    }
    return null;
  }

  static AstNode unwrapParentheses(AstNode node) {
    if (node is ParenthesizedExpression) {
      return unwrapParentheses(node.expression);
    }
    return node;
  }

  static bool areNodesEqual(AstNode? node1, AstNode? node2) {
    if (node1 == null || node2 == null) return node1 == node2;
    if (node1.runtimeType != node2.runtimeType) return false;

    if (node1 is SimpleIdentifier && node2 is SimpleIdentifier) {
      return node1.name == node2.name;
    }
    if (node1 is StringLiteral && node2 is StringLiteral) {
      return node1.stringValue == node2.stringValue;
    }
    return node1.toString() == node2.toString();
  }

  static bool isDescendant(AstNode node, AstNode parent) {
    if (node == parent) return true;
    return parent.childEntities
        .whereType<AstNode>()
        .any((child) => isDescendant(node, child));
  }

  static bool isInStatement(AstNode node, Statement statement) {
    if (statement is Block) {
      return statement.statements
          .any((stmt) => stmt == node || isInStatement(node, stmt));
    }
    return isDescendant(node, statement);
  }

  static bool isInExpression(AstNode node, Expression expression) {
    if (node == expression) return true;
    return expression.childEntities
        .whereType<AstNode>()
        .any((child) => isDescendant(node, child));
  }

  static VariableDeclaration? findVariableDeclarationInStatement(
      Statement statement, String variableName) {
    if (statement is Block) {
      for (var stmt in statement.statements) {
        if (stmt is VariableDeclarationStatement) {
          for (var decl in stmt.variables.variables) {
            if (decl.name.toString() == variableName) {
              return decl;
            }
          }
        }
      }
    } else if (statement is VariableDeclarationStatement) {
      for (var decl in statement.variables.variables) {
        if (decl.name.toString() == variableName) {
          return decl;
        }
      }
    }
    return null;
  }

  static bool conditionContainsExpression(
      AstNode condition, Expression operand) {
    if (condition.toString().contains(operand.toString())) {
      return true;
    }
    if (condition is BinaryExpression) {
      return conditionContainsExpression(condition.leftOperand, operand) ||
          conditionContainsExpression(condition.rightOperand, operand);
    }
    return false;
  }
}
