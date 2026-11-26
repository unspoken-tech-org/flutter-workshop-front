import 'package:flutter_workshop_front/models/pageable/page_model.dart';

Page<T> makePage<T>(
  List<T> content, {
  int number = 0,
  int size = 15,
  int? totalElements,
  int? totalPages,
  bool? last,
  bool? first,
}) {
  final effectiveTotal = totalElements ?? content.length;
  final effectiveLast = last ?? true;
  final effectivePages =
      totalPages ?? (effectiveLast ? number + 1 : number + 2);
  return Page<T>(
    content: content,
    totalPages: effectivePages,
    totalElements: effectiveTotal,
    last: effectiveLast,
    size: size,
    number: number,
    first: first ?? (number == 0),
    numberOfElements: content.length,
    empty: content.isEmpty,
  );
}
