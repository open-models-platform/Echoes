class BookmarkModel {
  String key;
  String echooId;
  String createdAt;
  BookmarkModel({
    required this.key,
    required this.echooId,
    required this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<dynamic, dynamic> json) => BookmarkModel(
        key: json["echooId"],
        echooId: json["echooId"],
        createdAt: json["created_at"],
      );

  Map<String, dynamic> toJson() => {
        "key": key,
        "echooId": echooId,
        "created_at": createdAt,
      };
}
