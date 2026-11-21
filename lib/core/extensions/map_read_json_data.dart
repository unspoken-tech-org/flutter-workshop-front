extension ReadJsonData on Map<String, dynamic> {
  T? to<T>(String s, T Function(String) fnc) {
    final value = this[s];
    if (value == null) return null;

    if (value is T) {
      return value;
    } else if (value is String) {
      return fnc(value);
    }

    return null;
  }

  double? toDouble(String s, {double? defaultValue}) {
    final value = this[s];
    if (value == null) return defaultValue;
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    return null;
  }

  String? toStr(String s, {String? defaultValue}) {
    final value = this[s];
    if (value == null) return defaultValue;
    if (value is String) {
      return value;
    } else if (value is Object) {
      return value.toString();
    } else if (value is num) {
      return value.toString();
    }
    return null;
  }

  bool? toBool(String s, {bool? defaultValue}) {
    final value = this[s];
    if (value == null) return defaultValue;
    if (value is bool) {
      return value;
    } else if (value is String) {
      return bool.parse(value);
    }
    return null;
  }

  List<int>? toListInt(String s) {
    final value = this[s];
    return value == null
        ? List<int>.empty()
        : (value as List<dynamic>).cast<int>();
  }

  List<int?>? toListIntDouble(String s) {
    final value = this[s];
    return value == null
        ? List<int?>.empty()
        : (value as List<dynamic>).cast<int?>();
  }

  int? toInt(String s, {int? defaultValue}) {
    final value = this[s];
    if (value == null) return defaultValue;
    if (value is int) {
      return value;
    } else if (value is double) {
      return value.toInt();
    } else if (value is String) {
      return int.parse(value);
    }
    return null;
  }
}

extension ReadJsonObject on Map<String, dynamic> {
  T? toModel<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    T? defaultValue,
  }) {
    final value = this[key];
    if (value == null) return defaultValue;
    return fromJson(value as Map<String, dynamic>);
  }
}
