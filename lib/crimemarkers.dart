import 'dart:math';

import 'package:flutter/material.dart';
import 'post.dart';

// Mock data source
class MockCrimeMarker {
  final double latitude;
  final double longitude;
  final String reporterName;
  final String description;
  final String crimeType;
  final int upvotes;
  final int downvotes;
  final String imageURL; // Added imageURL attribute

  MockCrimeMarker({
    required this.latitude,
    required this.longitude,
    required this.reporterName,
    required this.description,
    required this.crimeType,
    required this.upvotes,
    required this.downvotes,
    required this.imageURL, // Initialize imageURL in constructor
  });
}

class CrimeMarkersPage extends StatefulWidget {
  final List<Post> posts; // Define the posts parameter
  const CrimeMarkersPage({Key? key, required this.posts}) : super(key: key);

  @override
  _CrimeMarkersPageState createState() => _CrimeMarkersPageState();
}

class _CrimeMarkersPageState extends State<CrimeMarkersPage> {
  late final List<MockCrimeMarker> mockCrimeMarkers;

  @override
  void initState() {
    super.initState();
    // Initialize mock crime markers
    mockCrimeMarkers = List.generate(
      10,
      (index) => MockCrimeMarker(
        latitude: _generateRandomDouble(30, 40),
        longitude: _generateRandomDouble(-120, -70),
        reporterName: 'User ${index + 1}',
        description: 'Description for crime marker ${index + 1}',
        crimeType: _generateRandomCrimeType(),
        upvotes: _generateRandomInt(0, 100),
        downvotes: _generateRandomInt(0, 100),
        imageURL: 'https://via.placeholder.com/150', // Example image URL
      ),
    );
  }

  // Method to generate random latitude and longitude
  double _generateRandomDouble(double min, double max) {
    var rng = new Random();
    return min + rng.nextDouble() * (max - min);
  }

  // Method to generate random crime type
  String _generateRandomCrimeType() {
    var rng = new Random();
    List<String> crimeTypes = ['Assault', 'Robbery', 'Car Accident', 'Fire'];
    return crimeTypes[rng.nextInt(crimeTypes.length)];
  }

  // Method to generate random integer
  int _generateRandomInt(int min, int max) {
    var rng = new Random();
    return min + rng.nextInt(max - min);
  }

  // Method to get color for crime type
  Color _getColorForCrimeType(String crimeType) {
    switch (crimeType) {
      case 'Assault':
      case 'Robbery':
        return Colors.purple;
      case 'Car Accident':
        return Colors.blue;
      case 'Fire':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  // Method to get icon for crime type
  IconData _getIconForCrimeType(String crimeType) {
    switch (crimeType) {
      case 'Assault':
      case 'Robbery':
        return Icons.emoji_people;
      case 'Car Accident':
        return Icons.car_rental;
      case 'Fire':
        return Icons.fireplace;
      default:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crime Markers',
          style: TextStyle(color: Colors.red),
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Color.fromARGB(255, 45, 44, 44),
        child: ListView.builder(
          itemCount: mockCrimeMarkers.length,
          itemBuilder: (context, index) {
            final crimeMarker = mockCrimeMarkers[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Opacity(
                opacity: 0.8,
                child: Transform.translate(
                  offset: Offset(0, -5),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CrimeDetailsPage(
                            crimeMarker: crimeMarker,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 234, 219, 202),
                        border: Border.all(
                          color: Color(0xffd76961),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(9.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Row(
                              children: [
                                Icon(
                                  _getIconForCrimeType(crimeMarker.crimeType),
                                  color:
                                      _getColorForCrimeType(crimeMarker.crimeType),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Crime Type: ${crimeMarker.crimeType}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reporter: ${crimeMarker.reporterName}',
                                  style: TextStyle(color: Colors.black),
                                ),
                                Text(
                                  'Description: ${crimeMarker.description}',
                                  style: TextStyle(color: Colors.black),
                                ),
                                Text(
                                  'Latitude: ${crimeMarker.latitude}',
                                  style: TextStyle(color: Colors.black),
                                ),
                                Text(
                                  'Longitude: ${crimeMarker.longitude}',
                                  style: TextStyle(color: Colors.black),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.thumb_up, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('${crimeMarker.upvotes}',
                                        style: TextStyle(color: Colors.black)),
                                    SizedBox(width: 16),
                                    Icon(Icons.thumb_down, color: Colors.red),
                                    SizedBox(width: 4),
                                    Text('${crimeMarker.downvotes}',
                                        style: TextStyle(color: Colors.black)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CrimeDetailsPage extends StatelessWidget {
  final MockCrimeMarker crimeMarker;

  const CrimeDetailsPage({Key? key, required this.crimeMarker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crime Details'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Color.fromARGB(255, 45, 44, 44),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crime Type: ${crimeMarker.crimeType}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Reporter: ${crimeMarker.reporterName}',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Description: ${crimeMarker.description}',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Latitude: ${crimeMarker.latitude}',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Longitude: ${crimeMarker.longitude}',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Image.network(
              crimeMarker.imageURL, // Display image from URL
              height: 200,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.thumb_up, color: Colors.green),
                SizedBox(width: 4),
                Text('${crimeMarker.upvotes}',
                    style: TextStyle(color: Colors.white)),
                SizedBox(width: 16),
                Icon(Icons.thumb_down, color: Colors.red),
                SizedBox(width: 4),
                Text('${crimeMarker.downvotes}',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
