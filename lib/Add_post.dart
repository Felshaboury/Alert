import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'post.dart';

class AddPostPage extends StatefulWidget {
  final String username;

  const AddPostPage({Key? key, required this.username}) : super(key: key);
  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDataFuture;
  late PostType _selectedType = PostType.robberyAssault;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUsername();
    _userId = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 27, 27),
      appBar: AppBar(
        title: const Text('Add Post'),
        backgroundColor: const Color.fromARGB(255, 146, 39, 31),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _userDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // Loading indicator
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  String username = snapshot.data?['username'] ?? '';
                  return Text(
                    "Post as: $username",
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                filled: true,
                fillColor: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                filled: true,
                fillColor: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var type in PostType.values)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                        });
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: getColorForType(type),
                            child: Icon(
                              getIconForType(type),
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getCrimeType(type).toString(),
                            style: TextStyle(
                              color: _selectedType == type
                                  ? Colors.blue
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isNotEmpty &&
                    _contentController.text.isNotEmpty) {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Create the Post object with the updated fields
                    Post newPost = Post(
                      _userId, // Use the current user's UID
                      _titleController.text,
                      _contentController.text,
                      getCrimeType(_selectedType).toString().split('.').last,
                      getIconForType(_selectedType).codePoint.toString(),
                      username: user.uid, // Set username to user's uid
                      timestamp: DateTime.now(), // Use current timestamp
                      id: '', imageURL: '', // Add the ID parameter
                    );
                    Navigator.pop(context, newPost);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color.fromARGB(255, 146, 39, 31),
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
              child: const Text('Add Post'),
            ),
          ],
        ),
      ),
    );
  }
}   