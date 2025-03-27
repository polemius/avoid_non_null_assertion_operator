import 'package:analyzer/dart/ast/ast.dart';

typedef NullSafetyValidatorFn = bool Function(
    AstNode node, AstNode current, String? variableName);
