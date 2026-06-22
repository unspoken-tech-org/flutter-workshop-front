import 'package:flutter_workshop_front/utils/filter_utils.dart';

class Ordenation {
  final String orderByField;
  final String orderByDirection;

  Ordenation({
    this.orderByField = 'name',
    this.orderByDirection = 'ASC',
  });

  Map<String, dynamic> toJson() {
    return {
      'orderByField': orderByField,
      'orderByDirection': orderByDirection,
    };
  }
}

class CustomerSearchFilter {
  final int? id;
  final String? searchName;
  final String? cpf;
  final String? searchEmail;
  final String? phone;
  final int? page;
  final int? size;
  final Ordenation? ordenation;

  CustomerSearchFilter({
    this.id,
    this.searchName,
    this.cpf,
    this.searchEmail,
    this.phone,
    this.page,
    this.size,
    this.ordenation,
  });

  CustomerSearchFilter copyWith({
    int? id,
    String? searchName,
    String? cpf,
    String? searchEmail,
    String? phone,
    int? page,
    int? size,
    Ordenation? ordenation,
  }) {
    return CustomerSearchFilter(
      id: id ?? this.id,
      searchName: searchName ?? this.searchName,
      cpf: cpf ?? this.cpf,
      searchEmail: searchEmail ?? this.searchEmail,
      phone: phone ?? this.phone,
      page: page ?? this.page,
      size: size ?? this.size,
      ordenation: ordenation ?? this.ordenation,
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
    } else if (filterUtils.isCpf) {
      return CustomerSearchFilter(
        cpf: searchTerm,
        page: page,
        size: size,
      );
    } else if (filterUtils.isEmail) {
      return CustomerSearchFilter(
        searchEmail: searchTerm,
        page: page,
        size: size,
      );
    } else if (filterUtils.isPhoneOrCellPhone) {
      return CustomerSearchFilter(
        phone: searchTerm,
        page: page,
        size: size,
      );
    } else if (filterUtils.isName) {
      return CustomerSearchFilter(
        searchName: searchTerm,
        page: page,
        size: size,
      );
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'searchName': searchName,
      'cpf': cpf,
      'searchEmail': searchEmail,
      'phone': phone,
      'page': page,
      'size': size,
      'ordenation': ordenation?.toJson(),
    };
  }
}
