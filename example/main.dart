class A {
  String? nullable;
  int? counter;

  String getFieldSafeWithBang() {
    if (nullable != null) {
      return nullable!; // Allowed: Null check before using !
    }
    return "";
  }

  String getFieldUnsafe() {
    return nullable!; // Flagged: No null check before using !
  }
}

class B {
  String? field;
}

class C {
  B? b;
}

class D {
  String? name;
  D() {
    print(name!); // Flagged: No check in constructor
  }
  D.withCheck() {
    if (name != null) {
      print(name!); // Allowed: Check in constructor
    }
  }
}

class E {
  F? testF;
  E(this.testF);
}

class F {
  G testG;
  H? testH;
  F(this.testG, [this.testH]);
}

class H {
  F? testF;
  H(this.testF);
}

enum G { g_a, g_b, g_c }

F _createTaskAction(E task, int serviceUserId) {
  return F(G.g_c);
}

// --- Test Functions ---

void test1() {
  String? text;
  print(text!); // Flagged: No null check
}

void test2() {
  String? text;
  if (text != null) {
    print("Not null");
  }
  print(text!); // Flagged: Null check in different scope
}

void test3(String? outer, String? inner) {
  if (outer != null) {
    if (inner != null) {
      print(outer!); // Allowed: Outer is checked
      print(inner!); // Allowed: Inner is checked
    }
    print(outer!); // Allowed: Outer is checked
    print(inner!); // Flagged: Inner check in nested scope
  }
}

void test4(B b) {
  print(b.field!); // Flagged: No null check
  if (b.field != null) {
    print(b.field!); // Allowed: Checked
  }
}

void test5(C c) {
  print(c.b!.field!); // Flagged: Neither c.b nor field is checked
  if (c.b != null) {
    print(c.b!.field!); // Flagged: c.b is checked, but field isn’t
  }
  if (c.b != null && c.b!.field != null) {
    print(c.b!.field!); // Allowed: Both are checked
  }
}

void test6() {
  String? value;
  if (value != null && true) {
    print(value!); // Allowed: Value is checked
  }
  if (value == null || false) {
    print(value!); // Flagged: No guarantee value isn’t null
  }
}

void test7() {
  String? item;
  while (item != null) {
    print(item!); // Allowed: Checked in loop condition
  }
  print(item!); // Flagged: No check outside loop
}

String? getString() => null;

void test8() {
  print(getString()!); // Flagged: No null check on return value
  var result = getString();
  if (result != null) {
    print(result!); // Allowed: Checked
  }
}

void test9() {
  String? x;
  String y;
  if (x != null) {
    y = x!; // Allowed: Checked
  }
  y = x!; // Flagged: No check
}

void test10() {
  String? a;
  String? b;
  print((a! + b!)); // Flagged: Neither a nor b is checked
  if (a != null && b != null) {
    print((a! + b!)); // Allowed: Both checked
  }
}

void test12() {
  String? data;
  if (data != null) {
    print(data!); // Allowed: Checked
  } else {
    print(data!); // Flagged: Data is null in else
  }
}

void test13() {
  final Map<String, int> data = {};
  if (data.containsKey('test')) {
    var t = data['test'];
    print(t!); // Allowed: Map key check
  }
}

void test14() {
  String? value;
  var result =
      true ? value! : "default"; // Flagged: No check in conditional expression
  print(result);
}

void test15() {
  String? value;
  if (value != null) {
    var result = true
        ? value!
        : "default"; // Allowed: Check before conditional expression
    print(result);
  }
}

void test16() {
  String? value;
  var result = (value != null)
      ? value!
      : "default"; // Allowed: Check in conditional expression
  print(result);
}

void test17() {
  String? value;
  var result = (value != null)
      ? "default"
      : value!; // Flagged: No check in conditional expression
  print(result);
}

void test18() {
  String? value;
  String? other;
  var result = (value != null)
      ? value!
      : (other != null)
          ? other!
          : "default"; // Allowed: Both checked in nested conditional expression
  print(result);
}

void test19() {
  final Map<String, int> data = {};
  var result =
      data.containsKey('key1') ? data['key1']! : 0; // Allowed: Map key check
  var result2 = data.containsKey('key1')
      ? data['key2']! // Flagged: No check for 'key2'
      : 0;
  print(result);
}

String? test20(D testD) {
  if (testD.name == null) {
    return null;
  }

  return testD.name!; // Allowed: Check before return
}

void test21() {
  String? n = 'hello';
  final items = [
    'start',
    if (n != null) n!, // Allowed: Check in list literal
    if (n != null && n.isNotEmpty) n!, // Allowed: Check in list literal
    'end',
  ];
  print(items);
}

String? test22(D testD) {
  if (testD.name == null) {
    throw Error();
  }

  return testD.name!; // Allowed: Check before throw
}

String? test23(D testD) {
  if (testD.name == null) {
    return null;
  } else {
    return testD.name!; // Allowed: Check in else block
  }
}

void test24(List<String> elements) {
  Map<String, List<int>> grouped = {};
  for (var e in elements) {
    if (grouped.containsKey(e)) {
      grouped[e]!.add(1); // Allowed: Map key check in loop
    }
  }
}

void test25() {
  String? value;
  var result =
      (value == null) ? "" : value!; // Allowed: Check in conditional expression
  print(result);
}

void test26() {
  List<int>? l = null;

  if (l == null || l!.isEmpty) {
    // Allowed: Check in conditional expression
    print(l);
  }
}

void test27() {
  final List<A> testA = [];

  testA.map((e) =>
      e.counter != null &&
      e.counter! >= 0 &&
      e.counter! <= 10); // Allowed: Multiple checks
}

// TODO
// void test28(String? bar) {
//   if (bar == null) return;
//   print(bar!); // Allowed: Check before return
// }

// void test29(String? bar) {
//   if (identical(bar, null)) return;
//   print(bar!); // Allowed: Identical check
// }

// void test30(String? bar) {
//   if (bar is! String) return;
//   print(bar!); // Allowed: Type check
// }

// void test31(String? bar) {
//   if (bar?.isNotEmpty == true) {
//     print(bar!); // Allowed: Null-aware operator check
//   }
// }

// void testFunction(E task, dynamic event) {
//   F testFLocal = _createTaskAction(task, event.serviceUserId);

//   if (task.testF?.testH?.testF != null &&
//       (task.testF!.testG == G.g_a || task.testF!.testG == G.g_b)) {
//     final localTestTestF = task.testF!;
//     final testFHF = localTestTestF.testH!.testF!; // Allowed: Multiple checks
//   }
// }

void test32() {
  String? value;
  if (value == null) {
    return;
  }
  print(value!); // Allowed: Check before return
}

void test33() {
  String? value;
  if (value != null) {
    print(value!); // Allowed
  } else if (value == null) {
    return;
  }
  print(value!); // Flagged: value is null
}

void test34() {
  String? value;
  if (value == null) {
    print(value!); // Flagged: value is null
  }
}

void test35() {
  String? value;
  if (value != null) {
    print(value!); // Allowed
  }
  if (value == null) {
    return;
  }
  print(value!); // Allowed
}

void test36() {
  String? value;
  if (value == null) {
    return;
  }
  if (value != null) {
    print(value!); // Allowed
  }
}

void test37() {
  String? value;
  if (value != null) {
    print(value!); // Allowed
  }
  if (value != null) {
    print(value!); // Allowed
  }
}

void test38() {
  String? value;
  if (value == null) {
    return;
  }
  if (value == null) {
    return;
  }
  print(value!); // Allowed
}

void test39() {
  String? value;
  if (value != null) {
    print(value!); // Allowed
  } else if (value == null) {
    print(value!); // Flagged: value is null
  }
  print(value!); // Flagged: value is null
}

void main() {
  final A testA = A();

  print(testA.nullable!); // Flagged: No check

  if (testA.nullable != null) {
    print(testA.nullable!); // Allowed: Checked
  }
}
