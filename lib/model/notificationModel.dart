import 'dart:convert';

import 'package:Echoes/model/user.dart';

class NotificationModel {
  String? id;
  String? echooKey;
  String? updatedAt;
  String? createdAt;
  late String? type;
  Map<String, dynamic>? data;

  NotificationModel({
    this.id,
    this.echooKey,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    required this.data,
  });

  NotificationModel.fromJson(String echooId, Map<dynamic, dynamic> map) {
    id = echooId;
    Map<String, dynamic> data = {};
    if (map.containsKey('data')) {
      data = json.decode(json.encode(map["data"])) as Map<String, dynamic>;
    }
    echooKey = echooId;
    updatedAt = map["updatedAt"];
    type = map["type"];
    createdAt = map["createdAt"];
    this.data = data;
  }
}

extension NotificationModelHelper on NotificationModel {
  UserModel get user => UserModel.fromJson(data);

  DateTime? get timeStamp => updatedAt != null || createdAt != null
      ? DateTime.tryParse(updatedAt ?? createdAt!)
      : null;
}
