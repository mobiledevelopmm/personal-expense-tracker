class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
