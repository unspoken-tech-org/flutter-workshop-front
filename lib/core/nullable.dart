class Nullable<T> {
  final T? value;

  Nullable({this.value});

  factory Nullable.of(T? value) {
    return Nullable(value: value);
  }

  factory Nullable.empty() {
    return Nullable(value: null);
  }

  bool get isNull => value == null;
  bool get isNotNull => value != null;
}
