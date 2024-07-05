import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crimebott/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // List<Post> _userPosts = [];

  String _selectedField = 'Email';
  final List<String> _fields = [
    'Username',
    'Email',
    'Password',
    'Mobile Number'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // _loadUserPosts();
  }

  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _usernameController.text = userData['username'] ?? '';
        _emailController.text = user.email ?? '';
        _mobileNumberController.text = userData['mobileNumber'] ?? '';
      });
    }
  }

  // void _loadUserPosts() async {
  //   User? user = _auth.currentUser;
  //   if (user != null) {
  //     QuerySnapshot<Map<String, dynamic>> _userPostsSnapshot =
  //         await FirebaseFirestore.instance
  //             .collection('posts')
  //             .where('userId', isEqualTo: user.uid)
  //             .get();

  //     // Convert each document snapshot into a Post object
  //     List<Post> posts = _userPostsSnapshot.docs
  //         .map((doc) => Post.fromJson(doc.data()))
  //         .toList();
  //     // Update the _userPosts list
  //     setState(() {
  //       _userPosts = posts;
  //     });
  //   }
  // }

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xffc2bfbf),
      appBar: AppBar(
        title: Text(
          'Profile Page',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red, // Set the font weight to bold
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image:
                AssetImage('assets/road.jpg'), // Replace with your image path
            fit: BoxFit.cover, // Adjust the fit as needed
          ),
        ),
        child: Center(
          // Center widget added here
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Widgets inside the Column
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          'Hi, ${user?.displayName ?? _usernameController.text}!',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.location_pin,
                        color: Colors.black,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: Colors.blueGrey,
                        width: 1.5,
                      ),
                      color: Colors.grey[400],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.grey[400],
                      ),
                      child: DropdownButton<String>(
                        value: _selectedField,
                        items: _fields.map((field) {
                          return DropdownMenuItem<String>(
                            value: field,
                            child: Center(
                              child: Text(
                                field,
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedField = value!;
                          });
                        },
                        underline: Container(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    controller: _getControllerForSelectedField(),
                    decoration: InputDecoration(
                      labelText: _selectedField,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.blueGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      fillColor: Colors.grey[400],
                      filled: true,
                    ),
                  ),

                  SizedBox(height: 220.0),
                  ElevatedButton(
                    onPressed: () {
                      _updateProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 146, 39, 31),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      'Update $_selectedField',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 4.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      signOut(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 146, 39, 31),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      'Log Out',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextEditingController _getControllerForSelectedField() {
    switch (_selectedField) {
      case 'Username':
        return _usernameController;
      case 'Email':
        return _emailController;
      case 'Password':
        return _passwordController;
      default:
        return TextEditingController();
    }
  }

  Future<void> _updateProfile() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        String? password = await _showPasswordPrompt();

        if (password != null) {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
          await user.reauthenticateWithCredential(credential);

          if (_selectedField == 'Password') {
            if (_passwordController.text.isNotEmpty) {
              await user.updatePassword(_passwordController.text);
            } else {
              throw Exception(
                  "New password is required for updating the password");
            }
          } else if (_selectedField == 'Email') {
            if (_emailController.text.isNotEmpty) {
              await user.updateEmail(_emailController.text);
            } else {
              throw Exception("New email is required for updating the email");
            }
          }

          FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'username': _usernameController.text,
            'email': _emailController.text,
            'password': _passwordController.text,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
            ),
          );
        }
      }
    } catch (error) {
      print('Error updating profile: $error');
      String errorMessage = 'Error updating profile. Please try again.';
      if (error is FirebaseAuthException) {
        errorMessage = error.message ?? errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }

  Future<String?> _showPasswordPrompt() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String password = '';

        return AlertDialog(
          title: const Text('Enter your current password'),
          content: TextField(
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Password',
            ),
            onChanged: (value) {
              password = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(password);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}