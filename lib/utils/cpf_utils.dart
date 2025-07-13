class CpfUtils {
  static String formatCpf(String? input) {
    if (input == null) {
      return '';
    }
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
    } else {
      return input;
    }
  }
}
