class Page<T> {
  final List<T> content;
  final bool last;
  final int totalPages;
  final int totalElements;
  final int size;
  final int number;
  final int numberOfElements;
  final bool first;
  final bool empty;

  Page({
    required this.content,
    required this.last,
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.number,
    required this.numberOfElements,
    required this.first,
    required this.empty,
  });

  factory Page.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    final content = (json['content'] as List).map(fromJson).toList();
    final number = json['number'] as int;
    return Page<T>(
      content: content,
      last: json['last'] as bool,
      totalPages: json['totalPages'] as int,
      totalElements: json['totalElements'] as int,
      size: json['size'] as int,
      number: number,
      numberOfElements: json['numberOfElements'] as int? ?? content.length,
      first: json['first'] as bool? ?? number == 0,
      empty: json['empty'] as bool? ?? content.isEmpty,
    );
  }
}
