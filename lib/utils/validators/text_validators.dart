/// Field-level checks shared by the forms.
class TextValidators {
  TextValidators._();

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Whether [value] has at least one non-whitespace character.
  static bool hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  /// Whether [value] looks like `local@domain.tld`, with no spaces.
  static bool isEmail(String value) => _email.hasMatch(value.trim());
}
