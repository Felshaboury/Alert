import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Provide the correct Firebase configuration for your platform (iOS/Android).
    return const FirebaseOptions(
        apiKey: 'AIzaSyD2UCNNrZFifhIx9KW2qdiJ20yoHrSziTE',
        appId: 'com.example.crimebott',
        messagingSenderId: '1:122962147922:android:cb8566391c1d065502bd8b',
        projectId: 'alert-395b8',
        storageBucket: 'alert-395b8.appspot.com',
        databaseURL: 'https://alert-395b8-default-rtdb.firebaseio.com/');
  }
}
