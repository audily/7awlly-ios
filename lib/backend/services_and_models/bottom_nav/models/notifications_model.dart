// To parse this JSON data, do
//
//     final notificationModel = notificationModelFromJson(jsonString);

import 'dart:convert';

NotificationModel notificationModelFromJson(String str) =>
    NotificationModel.fromJson(json.decode(str));

String notificationModelToJson(NotificationModel data) =>
    json.encode(data.toJson());

class NotificationModel {
  final Message message;

  final String type;
  final int status;

  NotificationModel({
    required this.message,
    required this.type,
    required this.status,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        message: Message.fromJson(json["message"]),
        type: json["type"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "message": message.toJson(),
        "type": type,
        "status": status,
      };
}

class Message {
  final Success success;

  Message({
    required this.success,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        success: Success.fromJson(json["success"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success.toJson(),
      };
}

class Success {
  final List<NotificationItem> notifications;
  final bool isRead;

  Success({
    required this.notifications,
    required this.isRead,
  });

  factory Success.fromJson(Map<String, dynamic> json) => Success(
        notifications: List<NotificationItem>.from(
            json["notifications"].map((x) => NotificationItem.fromJson(x))),
        isRead: json["is_read"],
      );

  Map<String, dynamic> toJson() => {
        "notifications":
            List<dynamic>.from(notifications.map((x) => x.toJson())),
        "is_read": isRead,
      };
}

class NotificationItem {
  final int id;
  final String title;
  final String message;

  final DateTime createdAt;
  final DateTime updatedAt;
  final int isToAll;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    required this.isToAll,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json["id"],
        title: json["title"],
        message: json["message"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        isToAll: json["is_to_all"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "message": message,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "is_to_all": isToAll,
      };
}

enum Data { NULL, PAGE_CURRENCY_12, PAGE_CURRENCY_2, PAGE_CURRENCY_4 }

final dataValues = EnumValues({
  "null": Data.NULL,
  "{\"page\":\"currency::12\"}": Data.PAGE_CURRENCY_12,
  "{\"page\":\"currency::2\"}": Data.PAGE_CURRENCY_2,
  "{\"page\":\"currency::4\"}": Data.PAGE_CURRENCY_4
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
