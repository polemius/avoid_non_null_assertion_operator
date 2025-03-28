class A {
  String? nullable;
  int? counter;

  String getFieldSafeWithBang() {
    if (nullable != null) {
      return nullable!; // Allowed
    }
    return "";
  }

  String getFieldUnsafe() {
    return nullable!; // Should be flagged
  }
}

void test1() {
  String? text;
  print(text!); // Should be flagged (no null check)
}

void test2() {
  String? text;
  if (text != null) {
    print("Not null");
  }
  print(text!); // Should be flagged (null check is in a different scope)
}

void test3(String? outer, String? inner) {
  if (outer != null) {
    if (inner != null) {
      print(outer!); // Allowed (outer is checked)
      print(inner!); // Allowed (inner is checked)
    }
    print(outer!); // Allowed (outer is checked)
    print(inner!); // Should be flagged (inner check is in a nested scope)
  }
}

class B {
  String? field;
}

void test4(B b) {
  print(b.field!); // Should be flagged (no null check)
  if (b.field != null) {
    print(b.field!); // Allowed (checked)
  }
}

class C {
  B? b;
}

void test5(C c) {
  print(c.b!.field!); // Should be flagged (neither c.b nor field is checked)
  if (c.b != null) {
    print(c.b!.field!); // Should be flagged (c.b is checked, but field isn’t)
  }
  if (c.b != null && c.b!.field != null) {
    print(c.b!.field!); // Allowed (both are checked)
  }
}

void test6() {
  String? value;
  if (value != null && true) {
    print(value!); // Allowed (value is checked)
  }
  if (value == null || false) {
    print(value!); // Should be flagged (no guarantee value isn’t null)
  }
}

void test7() {
  String? item;
  while (item != null) {
    print(item!); // Allowed (checked in loop condition)
  }
  print(item!); // Should be flagged (no check outside loop)
}

String? getString() => null;

void test8() {
  print(getString()!); // Should be flagged (no null check on return value)
  var result = getString();
  if (result != null) {
    print(result!); // Allowed (checked)
  }
}

void test9() {
  String? x;
  String y;
  if (x != null) {
    y = x!; // Allowed (checked)
  }
  y = x!; // Should be flagged (no check)
}

void test10() {
  String? a;
  String? b;
  print((a! + b!)); // Should be flagged (neither a nor b is checked)
  if (a != null && b != null) {
    print((a! + b!)); // Allowed (both checked)
  }
}

class D {
  String? name;
  D() {
    print(name!); // Should be flagged (no check)
  }
  D.withCheck() {
    if (name != null) {
      print(name!); // Allowed (checked)
    }
  }
}

void test12() {
  String? data;
  if (data != null) {
    print(data!); // Allowed
  } else {
    print(data!); // Should be flagged (data is null in else)
  }
}

void test13() {
  final Map<String, int> data = {};
  if (data.containsKey('test')) {
    var t = data['test'];
    print(t!); // Allowed
  }
}

void test14() {
  String? value;
  var result = true ? value! : "default"; // should be flagged
  print(result);
}

void test15() {
  String? value;
  if (value != null) {
    var result = true ? value! : "default"; // allowed
    print(result);
  }
}

void test16() {
  String? value;
  var result = (value != null) ? value! : "default"; // allowed
  print(result);
}

void test17() {
  String? value;
  var result = (value != null) ? "default" : value!; // should be flagged
  print(result);
}

void test18() {
  String? value;
  String? other;
  var result = (value != null)
      ? value!
      : (other != null)
          ? other!
          : "default"; // allowed both
  print(result);
}

void test19() {
  final Map<String, int> data = {};
  var result = data.containsKey('key1') ? data['key1']! : 0; // allowed
  var result2 =
      data.containsKey('key1') ? data['key2']! : 0; // should be flagged
  print(result);
}

String? test20(D testD) {
  if (testD.name == null) {
    return null;
  }

  return testD.name!; // allowed
}

void test21() {
  String? n = 'hello';
  final items = [
    'start',
    if (n != null) n!, // allowed
    if (n != null && n.isNotEmpty) n!, // allowed
    'end',
  ];
  print(items);
}

String? test22(D testD) {
  if (testD.name == null) {
    throw Error();
  }

  return testD.name!; // allowed
}

String? test23(D testD) {
  if (testD.name == null) {
    return null;
  } else {
    return testD.name!; // allowed
  }
}

// todo
void test24(List<String> elements) {
  Map<String, List<int>> grouped = {};
  for (var e in elements) {
    if (grouped.containsKey(e)) {
      grouped[e]!.add(1); // allowed
    }
  }
}

void test25() {
  String? value;
  var result = (value == null) ? "" : value!; // allowed
  print(result);
}

void test26() {
  List<int>? l = null;

  if (l == null || l!.isEmpty) {
    // allowed
    print(l);
  }
}

void main() {
  final A testA = A();

  print(testA.nullable!); // Should be flagged

  if (testA.nullable != null) {
    print(testA.nullable!); // Allowed
  }
}

void test27() {
  final List<A> testA = [];

  testA.map((e) =>
      e.counter != null && e.counter! >= 0 && e.counter! <= 10); // allowed
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

void testFunction(E task, dynamic event) {
  F testFLocal = _createTaskAction(task, event.serviceUserId);

  if (task.testF?.testH?.testF != null &&
      (task.testF!.testG == G.g_a || task.testF!.testG == G.g_b)) {
    final localTestTestF = task.testF!;
    final testFHF = localTestTestF.testH!.testF!;
  }
}
