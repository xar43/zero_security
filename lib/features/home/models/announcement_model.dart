class AnnouncementModel {
  final String id;
  final String description;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "description": description,
    "createdAt": createdAt.toIso8601String(),
  };

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json["id"],
      description: json["description"],
      createdAt: DateTime.parse(json["createdAt"]),
    );
  }
}
