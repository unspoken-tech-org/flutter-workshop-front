import 'package:flutter_workshop_front/utils/filter_utils.dart';

class CustomerSearchFilter {
  final int? id;
  final String? name;
  final String? cpf;
  final String? email;
  final String? phone;
  final int? page;
  final int? size;

  CustomerSearchFilter({
    this.id,
    this.name,
    this.cpf,
    this.email,
    this.phone,
    this.page,
    this.size,
  });

  CustomerSearchFilter copyWith({
    int? id,
    String? name,
    String? cpf,
    String? email,
    String? phone,
    int? page,
    int? size,
  }) {
    return CustomerSearchFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      cpf: cpf ?? this.cpf,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  static CustomerSearchFilter? getCustomerSearchFilter(String? searchTerm,
      {int? page, int? size}) {
    FilterUtils filterUtils = FilterUtils(searchTerm ?? '');

    if (filterUtils.isId) {
      return CustomerSearchFilter(
        id: int.parse(searchTerm ?? ''),
        page: page,
        size: size,
      );
    } else if (filterUtils.isName) {
      return CustomerSearchFilter(
        name: searchTerm,
        page: page,
        size: size,
      );
    } else if (filterUtils.isCpf) {
      return CustomerSearchFilter(
        cpf: searchTerm,
        page: page,
        size: size,
      );
    } else if (filterUtils.isPhoneOrCellPhone) {
      return CustomerSearchFilter(
        phone: searchTerm,
        page: page,
        size: size,
      );
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cpf': cpf,
      'email': email,
      'phone': phone,
      'page': page,
      'size': size,
    };
  }
}
