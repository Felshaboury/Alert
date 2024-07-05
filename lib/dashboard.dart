import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crimebott/crimemarkers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'Add_post.dart';
import 'constants.dart';
import 'post.dart';
import 'crime.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late PostType _selectedCrimeType = PostType.accident;
  late User currentUser;
  CollectionReference get postRef => _firestore.collection('posts');
  CollectionReference get userRef => _firestore.collection('users');

  List<Post> posts = [];

  PostType getCrimeTypeFromString(String value) {
    switch (value) {
      case 'CarAccident':
        return PostType.accident;
      case 'robberyAssault':
        return PostType.robberyAssault;
      case 'fireAccident':
        return PostType.fireAccident;
      default:
        return PostType.accident; // Default value if not found
    }
  }

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    _loadUsername(currentUser.uid); // Pass currentUser.uid
    _fetchPosts();
  }

  Future<void> _deletePost(Post post) async {
    try {
      QuerySnapshot<Object?> postSnapshot =
          await postRef.where('content', isEqualTo: post.content).get();
//await confirmation dialog func
      if (postSnapshot.docs.isNotEmpty) {
        bool confirmDelete =
            await _showConfirmationDialog(); // Show confirmation dialog

        if (confirmDelete) {
          await postRef.doc(postSnapshot.docs.first.id).delete();
          await _fetchPosts(); // Refresh posts after deletion
        }
      }
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  //if you want to confirm deleting post else do not change
  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text('Are you sure you want to delete this post?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Return false (cancel)
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(true); // Return true (continue with deletion)
                  },
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false; // If user dismisses the dialog, consider it as canceling the deletion
  }

  Future<void> _fetchPosts() async {
    try {
      QuerySnapshot<Map<String, dynamic>> postSnapshot =
          await postRef.get() as QuerySnapshot<Map<String, dynamic>>;
      ;
      setState(() {
        posts = postSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          // Default username to 'Anonymous'
          String username = 'Anonymous';

          // Retrieve the username if userId is available
          if (data.containsKey('userId')) {
            String userId = data['userId'];
            _loadUsername(userId).then((value) {
              setState(() {
                username = value ?? username;
              });
            });
          }

          return Post(
            data['userId'] ?? '',
            data['title'] ?? '',
            data['content'] ?? '',
            data['PostType'].toString() ?? '',
            data['iconData'] ?? '',
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            id: doc.id,
            username: username,
            upvotes: data['upvotes'] ?? 0,
            downvotes: data['downvotes'] ?? 0, imageURL: '',
          );
        }).toList();
        posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    } catch (e) {
      print('Error fetching posts: $e');
    }
  }

  Future<String?> _loadUsername(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userData = await userRef
          .doc(userId)
          .get() as DocumentSnapshot<Map<String, dynamic>>;
      if (userData.exists) {
        return userData.data()?['username'] ?? '';
      } else {
        return 'Anonymous'; // Return default if user data not found
      }
    } catch (e) {
      print('Error loading username: $e');
      return 'Anonymous'; // Return default on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.red)),
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: 150, // Adjust the width as needed
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: DropdownButton<PostType>(
                value: _selectedCrimeType,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCrimeType = newValue!;
                  });
                },
                underline: SizedBox(), // Remove the underline
                icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                style: TextStyle(color: Colors.white),
                dropdownColor:
                    Colors.black, // Set the dropdown background color
                items: PostType.values.map((crimeType) {
                  return DropdownMenuItem<PostType>(
                    value: crimeType,
                    child: Text(
                      getCrimeType(crimeType),
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Color.fromARGB(255, 45, 44, 44), // Set the background color here
        // decoration: const BoxDecoration(
        //   image: DecorationImage(
        //     image: AssetImage('assets/background_img.jpg'),
        //     fit: BoxFit.cover,
        //   ),
        // ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            CrimeMarkersPage(posts: posts)), // Pass posts to the CrimeMarkersPage
                  );
                },
                icon: Icon(Icons.location_on,
                    color: Colors.red), // Red location pin icon
                label: Text('Go to Crime Markers Page'),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Colors.black), // Button background color
                  foregroundColor: MaterialStateProperty.all(
                      Colors.white), // Button text color
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  PostType currentType = posts[index].crimeType;
                  IconData icon = getIconForType(currentType);
                  Color color = getColorForType(currentType);
                  String crimeType = getCrimeType(currentType);
                  String userId = posts[index].username; // Access userId

                  if (currentType == _selectedCrimeType) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Opacity(
                        opacity: 0.8,
                        child: Transform.translate(
                          offset: Offset(0, -5),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 234, 219, 202),
                              border: Border.all(
                                color: const Color(0xffd76961),
                                width: 3.2,
                              ),
                              borderRadius: BorderRadius.circular(9.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Row(
                                    children: [
                                      Icon(
                                        getIconForType(posts[index].crimeType),
                                        color: getColorForType(
                                            posts[index].crimeType),
                                        size: 35,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ), // Add space between icon and text
                                      Text(
                                        userId, // Display userId here, // Display username here
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff9f2e26),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ListTile(
                                  title: Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Text(
                                      posts[index].title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          posts[index].content,
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          crimeType,
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                                255, 27, 114, 185),
                                          ),
                                        ),
                                        Text(
                                          posts[index].formattedTimestamp,
                                          style: const TextStyle(
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Ink(
                                          decoration: const ShapeDecoration(
                                            color: Colors.black,
                                            shape: CircleBorder(),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.thumb_up,
                                                color: Colors.black, size: 15),
                                            onPressed: () {
                                              setState(() {
                                                posts[index].incrementUpvotes();
                                              });
                                            },
                                          ),
                                        ),
                                        Text('${posts[index].upvotes}'),
                                        SizedBox(width: 2),
                                        Ink(
                                          decoration: const ShapeDecoration(
                                            color: Colors.black,
                                            shape: CircleBorder(),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.thumb_down,
                                                color: Colors.black, size: 15),
                                            onPressed: () {
                                              setState(() {
                                                posts[index]
                                                    .incrementDownvotes();
                                              });
                                            },
                                          ),
                                        ),
                                        Text('${posts[index].downvotes}'),
                                        SizedBox(width: 2),
                                        Ink(
                                          decoration: const ShapeDecoration(
                                            color: Colors.black,
                                            shape: CircleBorder(),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.black, size: 15),
                                            onPressed: () {
                                              _deletePost(posts[index]);
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Ink(
                                          decoration: const ShapeDecoration(
                                            color: Colors.black,
                                            shape: CircleBorder(),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.info,
                                                color: Colors.black, size: 15),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => CrimePage(post: posts[index], posts: [],),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return SizedBox(); // Return an empty SizedBox if post doesn't match selected crime type
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final User? user = _auth.currentUser;
          if (user != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPostPage(
                    username: user.uid), // Pass userId instead of displayName
              ),
            );
            if (result != null && result is Post) {
              result.username = user.displayName ?? 'Anonymous';
              await _addPost(result);
              await _fetchPosts();
            }
          }
        },
        backgroundColor: Color.fromARGB(255, 146, 39, 31),
        child: const Icon(
          Icons.post_add,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _addPost(Post post) async {
    try {
      User? user = _auth.currentUser;
      post.username = user?.displayName ?? 'Anonymous';
      if (user != null) {
        Map<String, dynamic> postData = {
          'title': post.title,
          'content': post.content,
          'PostType': getCrimeType(post.crimeType),
          'iconData': post.iconData,
          'username': post.userId, // Set username to user's uid
          'timestamp': FieldValue.serverTimestamp(),
          'upvotes': post.upvotes,
          'downvotes': post.downvotes,
          'userId': user.uid, // Add user ID to post data
        };

        await postRef.add(postData);
      }
    } catch (e) {
      print('Error adding post: $e');
    }
  }
}
