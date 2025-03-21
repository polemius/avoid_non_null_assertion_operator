class A {
  String? nullable;
}

void main() {
  String? nullable = "test";
  String nonNullable = nullable!; // Should trigger the lint

  A a = A();
  String nonNullable2 = a.nullable!; // Should trigger the lint
}
