class PhoneUtils {
  static String formatPhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    } else {
      return input; // fallback sem formatação
    }
  }
}
