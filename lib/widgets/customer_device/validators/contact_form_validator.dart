import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';

enum ContactField {
  contactType,
  phoneNumber,
  contactStatus,
  technician,
  deviceStatus,
  message,
}

mixin ContactFormValidator {
  final Map<ContactField, bool> _validationState = {
    ContactField.contactType: false,
    ContactField.phoneNumber: false,
    ContactField.contactStatus: false,
    ContactField.technician: false,
    ContactField.deviceStatus: false,
    ContactField.message: false,
  };

  bool isFieldInvalid(ContactField field) => _validationState[field] ?? false;

  void validateField(ContactField field, InputCustomerContact input) {
    switch (field) {
      case ContactField.contactType:
        _validationState[field] = input.contactType == null;
        break;
      case ContactField.phoneNumber:
        _validationState[field] =
            input.contactType != 'Pessoalmente' && input.phoneNumberId == null;
        break;
      case ContactField.contactStatus:
        _validationState[field] = input.contactStatus == null;
        break;
      case ContactField.technician:
        _validationState[field] = input.technicianId == null;
        break;
      case ContactField.deviceStatus:
        _validationState[field] = input.deviceStatus == null;
        break;
      case ContactField.message:
        _validationState[field] = (input.message?.trim().isEmpty ?? true);
        break;
    }
  }

  void clearFieldValidation(ContactField field) {
    _validationState[field] = false;
  }

  bool validateAll(InputCustomerContact input) {
    for (var field in ContactField.values) {
      validateField(field, input);
    }
    return !_validationState.values.any((isInvalid) => isInvalid);
  }

  void clearAllValidations() {
    _validationState.updateAll((_, __) => false);
  }
}
