import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'constants.dart';

class Post {
  late String id;
  late String userId;
  late String title;
  late String content;
  late PostType crimeType;
  late String iconData;
  late DateTime timestamp;
  late String username; // Add username attribute
  late int upvotes;
  late int downvotes;
  late String imageURL; // Add imageURL attribute

  Post(
    this.userId,
    this.title,
    this.content,
    String crimeTypeString,
    this.iconData, {
    required this.timestamp,
    this.upvotes = 0,
    this.downvotes = 0,
    required String id,
    required this.username,
    required this.imageURL, // Initialize imageURL in constructor
  }) : crimeType = _convertStringToPostType(crimeTypeString);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'crimeType': crimeType.toString().split('.').last,
      'iconData': iconData,
      'timestamp': timestamp,
      'username': username,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'imageURL': imageURL, // Include imageURL in JSON serialization
    };
  }

  set setUsername(String name) {
    username = name;
  }

  String get formattedTimestamp {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
  }

  // Methods to increment/decrement upvotes and downvotes
  void incrementUpvotes() {
    upvotes++;
  }

  void decrementUpvotes() {
    if (upvotes > 0) {
      upvotes--;
    }
  }

  void incrementDownvotes() {
    downvotes++;
  }

  void decrementDownvotes() {
    if (downvotes > 0) {
      downvotes--;
    }
  }

  static PostType _convertStringToPostType(String value) {
    return PostType.values.firstWhere(
      (type) => type.toString() == 'PostType.$value',
      orElse: () => PostType.accident,
    );
  }

  Post.fromJson(Map<dynamic, dynamic> json)
      : id = json['id'],
        userId = json['userId'],
        title = json['title'],
        content = json['content'],
        iconData = json['iconData'],
        timestamp = (json['timestamp'] as Timestamp).toDate(),
        crimeType = _convertStringToPostType(json['crimeType']),
        username = json['username'],
        upvotes = json['upvotes'] ?? 0,
        downvotes = json['downvotes'] ?? 0,
        imageURL = json['imageURL'] ?? ''; // Initialize imageURL from JSON
}
