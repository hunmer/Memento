class Subtask {
  final String id;
  String title;
  bool isCompleted;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'],
        title: json['title'],
        isCompleted: json['isCompleted'],
      );
}