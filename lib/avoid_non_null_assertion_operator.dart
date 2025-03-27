import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

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
      if (node.operator.type != TokenType.BANG) {
        return;
      }
      final operand = node.operand;
      String? variableName = _getVariableName(operand);

      if (variableName == null) {
        if (operand is IndexExpression) {
          if (_isIndexExpressionGuarded(node, operand)) {
            return;
          }
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
      if (current is IfStatement) {
        final condition = current.expression;
        if (_isNodeInStatement(node, current.thenStatement) &&
            _checkMapContainsKeyGuardForIndex(
                condition, operand.target!, operand.index)) {
          return true;
        }
      }
      current = current.parent;
    }
    return false;
  }

  bool _checkMapContainsKeyGuardForIndex(
      AstNode condition, Expression target, Expression index) {
    if (condition is MethodInvocation) {
      final methodName = condition.methodName.name;
      final targetCondition = condition.target;
      final argumentList = condition.argumentList.arguments;

      if (methodName == 'containsKey' &&
          argumentList.length == 1 &&
          targetCondition != null &&
          _areNodesEqual(target, targetCondition) &&
          _areNodesEqual(index, argumentList.first)) {
        return true;
      }
    }
    return false;
  }

  String? _getVariableName(Expression operand) {
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

  bool _isGuardedByNullCheck(AstNode node, String variableName) {
    AstNode? current = node;

    while (current != null) {
      if (current is ListLiteral) {
        final elements = current.elements;
        for (int i = 0; i < elements.length; i++) {
          final element = elements[i];
          if (element is IfElement) {
            final condition = _unwrapParentheses(element.expression);
            if (_isDescendant(node, element) &&
                _checkCondition(condition, variableName)) {
              return true;
            }
          }
        }
      } else if (current is Block) {
        final statements = current.statements;
        Statement? containingStatement;
        int nodeIndex = -1;

        for (int i = 0; i < statements.length; i++) {
          if (_isDescendant(node, statements[i])) {
            containingStatement = statements[i];
            nodeIndex = i;
            break;
          }
        }

        if (nodeIndex > 0 && containingStatement != null) {
          for (int i = 0; i < nodeIndex; i++) {
            final stmt = statements[i];
            if (stmt is IfStatement) {
              final condition = _unwrapParentheses(stmt.expression);
              if (condition is BinaryExpression &&
                  condition.operator.type == TokenType.EQ_EQ &&
                  condition.rightOperand is NullLiteral) {
                final left = condition.leftOperand;
                String? checkedName = _getVariableName(left);
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
      } else if (current is ConditionalExpression) {
        final condition = _unwrapParentheses(current.condition);
        if (condition is BinaryExpression &&
            condition.rightOperand is NullLiteral &&
            _getVariableName(condition.leftOperand) == variableName) {
          final isNotNullCheck = condition.operator.type == TokenType.BANG_EQ;
          final isNullCheck = condition.operator.type == TokenType.EQ_EQ;

          if (_isNodeInExpression(node, current.thenExpression)) {
            if (isNotNullCheck) {
              return true;
            }
          } else if (_isNodeInExpression(node, current.elseExpression)) {
            if (isNullCheck) {
              return true;
            }
          }
        }
      } else if (current is IfStatement) {
        final condition = current.expression;
        if (current.elseStatement != null &&
            _isNodeInStatement(node, current.elseStatement!)) {
          final unwrappedCondition = _unwrapParentheses(condition);
          if (unwrappedCondition is BinaryExpression &&
              unwrappedCondition.operator.type == TokenType.EQ_EQ &&
              unwrappedCondition.rightOperand is NullLiteral) {
            final left = unwrappedCondition.leftOperand;
            String? checkedName = _getVariableName(left);
            if (checkedName == variableName) {
              return true;
            }
          }
          if (_checkCondition(condition, variableName, isInBlock: true)) {
            return false;
          }
        } else if (_isNodeInStatement(node, current.thenStatement)) {
          if (_checkCondition(condition, variableName, isInBlock: true) ||
              _checkMapContainsKeyGuard(
                  node, variableName, condition, current.thenStatement)) {
            return true;
          }
        } else {
          if (_checkCondition(condition, variableName, isInBlock: false)) {
            return true;
          }
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

    return false;
  }

  bool _checkCondition(AstNode condition, String variableName,
      {bool isInBlock = true}) {
    final unwrappedCondition = _unwrapParentheses(condition);

    if (unwrappedCondition is BinaryExpression) {
      final left = unwrappedCondition.leftOperand;
      final right = unwrappedCondition.rightOperand;
      final operator = unwrappedCondition.operator.type;

      if (operator == TokenType.BANG_EQ && right is NullLiteral) {
        if (left is SimpleIdentifier && left.name == variableName) {
          return true;
        } else if (left is PrefixedIdentifier &&
            left.identifier.name == variableName) {
          return true;
        } else if (left is PropertyAccess &&
            '${(left.target as SimpleIdentifier).name}.${left.propertyName.name}' ==
                variableName) {
          return true;
        }
      }

      if (operator == TokenType.EQ_EQ && right is NullLiteral) {
        if (left is SimpleIdentifier && left.name == variableName) {
          return true;
        } else if (left is PrefixedIdentifier &&
            left.identifier.name == variableName) {
          return true;
        } else if (left is PropertyAccess &&
            '${(left.target as SimpleIdentifier).name}.${left.propertyName.name}' ==
                variableName) {
          return true;
        }
      }

      if (operator == TokenType.AMPERSAND_AMPERSAND) {
        final leftCondition = _unwrapParentheses(left);
        if (leftCondition is BinaryExpression &&
            leftCondition.operator.type == TokenType.BANG_EQ &&
            leftCondition.rightOperand is NullLiteral) {
          final leftLeft = leftCondition.leftOperand;
          String? checkedName = _getVariableName(leftLeft);
          if (checkedName == variableName) {
            return true;
          }
        }

        return _checkCondition(left, variableName) ||
            _checkCondition(right, variableName);
      }

      if (operator == TokenType.BAR_BAR) {
        final leftSafe =
            _checkCondition(left, variableName, isInBlock: isInBlock);
        final rightSafe =
            _checkCondition(right, variableName, isInBlock: isInBlock);
        if (isInBlock) {
          // If ! is in the block, all conditions must ensure non-nullity
          return leftSafe && rightSafe;
        } else {
          // If ! is in the condition (e.g., l!.isEmpty), check if guarded
          return leftSafe || rightSafe;
        }
      }
    }
    return false;
  }

  AstNode _unwrapParentheses(AstNode node) {
    if (node is ParenthesizedExpression) {
      return _unwrapParentheses(node.expression);
    }
    return node;
  }

  bool _checkMapContainsKeyGuard(AstNode node, String variableName,
      AstNode condition, Statement thenStatement) {
    VariableDeclaration? declaration =
        _findVariableDeclarationInStatement(thenStatement, variableName);
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
              _areNodesEqual(target, targetCondition) &&
              _areNodesEqual(index, argumentList.first)) {
            return true;
          }
        }
      }
    }

    if (node is PostfixExpression && node.operator.type == TokenType.BANG) {
      final operand = node.operand;
      if (operand is IndexExpression) {
        final target = operand.target;
        final index = operand.index;

        if (condition is MethodInvocation) {
          final methodName = condition.methodName.name;
          final targetCondition = condition.target;
          final argumentList = condition.argumentList.arguments;

          if (methodName == 'containsKey' &&
              argumentList.length == 1 &&
              targetCondition != null &&
              _areNodesEqual(target, targetCondition) &&
              _areNodesEqual(index, argumentList.first)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _checkMapContainsKeyForExpression(
      AstNode condition, Expression thenExpression) {
    if (thenExpression is PostfixExpression &&
        thenExpression.operator.type == TokenType.BANG) {
      final operand = thenExpression.operand;
      if (operand is IndexExpression) {
        final target = operand.target;
        final index = operand.index;

        if (condition is MethodInvocation) {
          final methodName = condition.methodName.name;
          final targetCondition = condition.target;
          final argumentList = condition.argumentList.arguments;

          if (methodName == 'containsKey' &&
              argumentList.length == 1 &&
              targetCondition != null &&
              _areNodesEqual(target, targetCondition) &&
              _areNodesEqual(index, argumentList.first)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  VariableDeclaration? _findVariableDeclarationInStatement(
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

  bool _areNodesEqual(AstNode? node1, AstNode? node2) {
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

  bool _isNodeInStatement(AstNode node, Statement statement) {
    if (statement is Block) {
      for (var stmt in statement.statements) {
        if (stmt == node || _isNodeInStatement(node, stmt)) {
          return true;
        }
      }
    } else {
      return _isDescendant(node, statement);
    }
    return false;
  }

  bool _isNodeInExpression(AstNode node, Expression expression) {
    if (node == expression) {
      return true;
    }
    for (var child in expression.childEntities) {
      if (child is AstNode && _isDescendant(node, child)) {
        return true;
      }
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
        final condition = current.expression;
        if (_conditionContainsExpression(condition, node.operand) &&
            _checkExpressionCondition(condition)) {
          return true;
        }
      } else if (current is BinaryExpression &&
          current.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        if (_checkExpressionCondition(current)) {
          return true;
        }
      } else if (current is ConditionalExpression) {
        final condition = current.condition;
        if (_isNodeInExpression(node, current.thenExpression) &&
            (_checkExpressionCondition(condition) ||
                _checkMapContainsKeyForExpression(condition, node))) {
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
