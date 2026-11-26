import 'package:flutter_workshop_front/core/format/br_format.dart';
import 'package:flutter_workshop_front/core/validators/cpf_validator.dart';

class FilterUtils {
  final String _rawTerm;
  final String _digitsOnly;

  FilterUtils(String term)
    : _rawTerm = term.trim().replaceAll(RegExp(r'\s+'), ' '),
      _digitsOnly = BrFormat.digitsOnly(term);

  String get text => _rawTerm;

  String get digits => _digitsOnly;

  bool get isCpf {
    if (!RegExp(r'^[\d.\-\s]+$').hasMatch(_rawTerm)) {
      return false;
    }

    if (_digitsOnly.length != 11) {
      return false;
    }

    return CpfValidator.isValid(_digitsOnly);
  }

  bool get isName {
    if (_rawTerm.isEmpty || isEmail) {
      return false;
    }

    return RegExp(r'\p{L}', unicode: true).hasMatch(_rawTerm);
  }

  bool get isEmail {
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(_rawTerm);
  }

  bool get isId {
    return RegExp(r'^\d{1,7}$').hasMatch(_rawTerm);
  }

  bool get isPhoneOrCellPhone {
    if (!RegExp(r'^[\d\s()\-+]+$').hasMatch(_rawTerm)) {
      return false;
    }

    final isLength = _digitsOnly.length >= 8 && _digitsOnly.length <= 11;
    return isLength && !isCpf;
  }
}
