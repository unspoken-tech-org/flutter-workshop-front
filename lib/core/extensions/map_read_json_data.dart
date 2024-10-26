extension ReadJsonData on Map<String, dynamic> {
  T? to<T>(String s, fnc) {
    var value = this[s];
    if (value == null) return null;

    if (value is T) {
      return value;
    } else if (value is String) {
      return fnc(value);
    }

    return null;
  }

  double? toDouble(String s, {double? defaultValue}) {
    var value = this[s];
    if (value == null) return defaultValue;
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      try {
        return double.parse(
          value,
        );
      } catch (e) {
        return defaultValue;
      }
    }
    return null;
  }

  String? toStr(String s, {String? defaultValue}) {
    var value = this[s];
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
    var value = this[s];
    if (value == null) return defaultValue;
    if (value is bool) {
      return value;
    } else if (value is String) {
      return bool.parse(value);
    }
    return null;
  }

  List<int>? toListInt(String s) {
    var value = this[s];
    return value == null ? List<int>.empty() : value.cast<int>();
  }

  List<int?>? toListIntDouble(String s) {
    var value = this[s];
    return value == null ? List<double>.empty() : value.cast<double>();
  }

  int? toInt(String s, {int? defaultValue}) {
    var value = this[s];
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
  T? toModel<T>(String key, T Function(Map<String, dynamic>) fromJson,
      {T? defaultValue}) {
    if (this[key] == null) return defaultValue;
    return fromJson(this[key]);
  }
}
