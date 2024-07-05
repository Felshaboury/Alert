import 'package:crimebott/constants.dart';
import 'package:flutter/material.dart';
import 'post.dart';

class CrimePage extends StatelessWidget {
  final Post post;

  CrimePage({required this.post, required List<Post> posts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crime Details', style: TextStyle(color: Colors.red)),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Posted by ${post.username}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              post.content,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Type: ${getCrimeType(post.crimeType)}',
              style: TextStyle(color: Colors.blue),
            ),
            SizedBox(height: 8),
            Text(
              'Posted on: ${post.formattedTimestamp}',
              style: TextStyle(color: Colors.blueGrey),
            ),
            SizedBox(height: 16),
            if (post.imageURL != null && post.imageURL.isNotEmpty)
              Image.network(post.imageURL),
          ],
        ),
      ),
    );
  }
}
