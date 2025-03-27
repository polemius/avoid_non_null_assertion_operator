class A {
  String? nullable;

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
  var result = data.containsKey('key') ? data['key']! : 0; // allowed
  print(result);
}

void main() {
  final A testA = A();

  print(testA.nullable!); // Should be flagged

  if (testA.nullable != null) {
    print(testA.nullable!); // Allowed
  }
}
