import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

import 'secrets.dart';



class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // final LatLng _initialPosition = const LatLng(30.0285952, 31.5523072);
  LatLng? _initialPosition;
  LatLng? _startLocation;
  LatLng? _destinationLocation;
  Set<Polyline> _polylines = {};
  Set<LatLng> _avoidCoordinates = {LatLng(30.027439045271805, 31.528331641070277)}; // Set to store avoid coordinates
  late GoogleMapController mapController;
  Set<Marker> crimeMarkers = {};
  String _routeDistance = '';
  String _routeDuration = '';
  bool placingPin = false;
  bool _isRouteGenerated = false;

  late Future<BitmapDescriptor> _startMarkerIcon;
  late Future<BitmapDescriptor> _destinationMarkerIcon;
  final Map<String, String> crimeTypeToIcon = {
    'Car Accident': 'accident.png',
    'Fire': 'fire.png',
    'Robbery/Assault': 'robbery.png',
  };
  Future<void> _showPlacePinDialog(LatLng position) async {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CrimeDetailsPage(position),
    ),
  ).then((crimeDetails) {
    if (crimeDetails != null) {
      _addCrimeMarker(
        position,
        crimeDetails['description'],
        crimeDetails['imageBytes'],
        crimeDetails['reporterName'],
        crimeDetails['isAnonymous'],
        crimeDetails['crimeType'],
        crimeDetails['reportTime'],
        crimeDetails['weaponDetected'],
      );
    }
  });
}

  @override
  void initState() {
    super.initState();
    _startMarkerIcon = _loadMarkerIcon('assets/first.png'); 
    _destinationMarkerIcon = _loadMarkerIcon('assets/finish.png');
    loadMarkersFromFirestore();   
    _getUserLocation();
  }
    Future<BitmapDescriptor> _loadMarkerIcon(String assetName) async {
    final ByteData byteData = await rootBundle.load(assetName);
    final Uint8List imageData = byteData.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(imageData);

  }
  Future<BitmapDescriptor> _loadTMarkerIcon(String crimeType) async {
    final String? iconName = crimeTypeToIcon[crimeType];
    if (iconName != null) {
      final ByteData byteData = await rootBundle.load('assets/$iconName');
      final Uint8List imageData = byteData.buffer.asUint8List();
      return BitmapDescriptor.fromBytes(imageData);
    } else {
      return BitmapDescriptor.defaultMarker;
    }
  }


  Future<void> _getUserLocation() async {
    Location location = new Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();

    setState(() {
      _initialPosition = LatLng(_locationData.latitude!, _locationData.longitude!);
    });
  }
    void _updateDistanceAndTime(String distance, String time) {
    setState(() {
      _routeDistance = distance;
      _routeDuration = time;
      _isRouteGenerated = true;
    });
  }


Future<void> _addCrimeMarker(
  LatLng position,
  String description,
  Uint8List imageBytes,
  String reporterName,
  bool isAnonymous,
  String crimeType,
  DateTime reportTime,
  bool weaponDetected,  // Add this parameter

) async {
  final markerId = MarkerId('${position.latitude}-${position.longitude}');
  BitmapDescriptor markerIcon = await _loadTMarkerIcon(crimeType);


  final marker = Marker(
    markerId: markerId,
    position: position,
    icon: markerIcon,
    onTap: (){
      Navigator.push(context, 
        MaterialPageRoute(
          builder: (context) => CrimeInfo(position: position),
        ),
      );
    },
  );

  setState(() {
    crimeMarkers.add(marker);
  });

  DocumentReference<Map<String, dynamic>> docRef =
      await FirebaseFirestore.instance.collection('crimeMarkers').add({
    'latitude': position.latitude,
    'longitude': position.longitude,
    'description': description,
    'imageUrl': base64Encode(imageBytes),
    'reporterName': reporterName,
    'isAnonymous': isAnonymous,
    'reportTime': Timestamp.fromDate(reportTime),
    'crimeType': crimeType,
    'weaponDetected': weaponDetected,  

  });

  String imageUrl = await _uploadImageToFirestore(imageBytes, docRef.id);

  await docRef.update({'imageUrl': imageUrl});
}
  Future<String> _uploadImageToFirestore(
      Uint8List imageBytes, String documentId) async {
    String imageName = DateTime.now().toIso8601String();

    Reference ref =
        FirebaseStorage.instance.ref().child('crime_images/$imageName.jpg');
    UploadTask uploadTask = ref.putData(imageBytes);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

    String imageUrl = await taskSnapshot.ref.getDownloadURL();

    return imageUrl;
  }

  Future<void> loadMarkersFromFirestore() async {
    final markers =
        await FirebaseFirestore.instance.collection('crimeMarkers').get();

    for (var doc in markers.docs) {
      final latitude = doc['latitude'] as double;
      final longitude = doc['longitude'] as double;
      final description = doc['description'] as String;
      final imageUrl = doc['imageUrl'] as String;
      final reporterName = doc['reporterName'] as String;
      final isAnonymous = doc['isAnonymous'] as bool;
      final reportTime = (doc['reportTime'] as Timestamp).toDate();
      final weaponDetected = doc['weaponDetected'] as bool;
      final crimeType = doc['crimeType'] as String;

      final markerId = MarkerId('$latitude-$longitude');
      BitmapDescriptor markerIcon = await _loadTMarkerIcon(crimeType);

      final marker = Marker(
        markerId: markerId,
        position: LatLng(latitude, longitude),
        icon: markerIcon,
        onTap: () {
        // Open a new page when the marker is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CrimeInfo(position:LatLng(latitude, longitude)),
          ),      
          );
        },
      );
      setState(() {
        crimeMarkers.add(marker);
      });
    }
  }

  void _onMapTap(LatLng tappedPoint) async {
    setState(() {
      if (_startLocation == null) {
        _startLocation = tappedPoint;
        _addMarker(tappedPoint, 'start', _startMarkerIcon);
      } else if (_destinationLocation == null) {
        _destinationLocation = tappedPoint;
        _addMarker(tappedPoint, 'destination', _destinationMarkerIcon);
        _drawRoute();
      } else {
        _startLocation = tappedPoint;
        _destinationLocation = null;
        _polylines.clear();
        _clearMarkers();
      }
    });
  }

  void _addMarker(LatLng position, String markerId, Future<BitmapDescriptor> icon) async {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: await icon,
    );

    setState(() {
      crimeMarkers.add(marker);
    });
  }

  void _clearMarkers() {
    setState(() {
      crimeMarkers.clear();
    });
  }

  Future<void> _drawRoute() async {
    if (_startLocation == null || _destinationLocation == null) return;

    // Fetch crime markers from Firestore
    final QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection('crimeMarkers').get();

    // Convert crime markers to a Set of LatLng
    final avoidCoordinates = querySnapshot.docs.map((doc) {
      final latitude = doc['latitude'] as double;
      final longitude = doc['longitude'] as double;
      return LatLng(latitude, longitude);
    }).toSet();

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_startLocation!.latitude},${_startLocation!.longitude}&destination=${_destinationLocation!.latitude},${_destinationLocation!.longitude}&key=${Secrets.API_KEY}&alternatives=true');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      Map data = jsonDecode(response.body);
      List routes = data['routes'];
      _polylines.clear();
      bool anyRouteAdded = false;
      List<LatLng>? fallbackRoute = null;

      for (var i = 0; i < routes.length; i++) {
        List<LatLng> polylineCoordinates = _decodePoly(routes[i]['overview_polyline']['points']);
        bool containsAvoidCoordinate = polylineCoordinates.any((point) => _isNearAvoid(point, avoidCoordinates));

        if (!containsAvoidCoordinate) {
          _polylines.add(_createPolyline(i, polylineCoordinates));
          anyRouteAdded = true;
          final routeDistance = routes[i]['legs'][0]['distance']['value'] / 1000; // in kilometers
          final routeDuration = routes[i]['legs'][0]['duration']['value'] / 60; // in minutes
          setState(() {
            _routeDistance = 'Route Distance: ${routeDistance.toStringAsFixed(2)} km';
            _routeDuration = 'Estimated Time: ${routeDuration.toStringAsFixed(0)} minutes';
            _isRouteGenerated = true;
          });
        } else  { 
          if(fallbackRoute == null)
          fallbackRoute = polylineCoordinates;
          final routeDistance = routes[i]['legs'][0]['distance']['value'] / 1000; // in kilometers
          final routeDuration = routes[i]['legs'][0]['duration']['value'] / 60; // in minutes
          setState(() {
            _routeDistance = 'Route Distance: ${routeDistance.toStringAsFixed(2)} km';
            _routeDuration = 'Estimated Time: ${routeDuration.toStringAsFixed(0)} minutes';
            _isRouteGenerated = true;
          });
        }
      }

      if (!anyRouteAdded && fallbackRoute != null) {
        _askUserForFallback(fallbackRoute);
        loadMarkersFromFirestore(); 
      } else {
        _addMarker(_startLocation!, 'start', _startMarkerIcon);
        loadMarkersFromFirestore();
        setState(() {});  
      }
    } else {
      throw Exception('Failed to load directions');
    }
  }

  void _askUserForFallback(List<LatLng> fallbackRoute) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Routing Issue'),
          content: const Text('All possible routes pass through dangerous areas. Display the best availableroute?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _polylines.add(_createPolyline(0, fallbackRoute)); // Add fallback route
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Polyline _createPolyline(int index, List<LatLng> coordinates) {
    return Polyline(
      polylineId: PolylineId('route$index'),
      color: _getRouteColor(index),
      points: coordinates,
      width: 5,
    );
  }

  Color _getRouteColor(int routeIndex) {
    switch (routeIndex % 3) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.black;
      default:
        return Colors.blue;
    }
  }

  bool _isNearAvoid(LatLng point, Set<LatLng> avoidCoordinates) {
    return avoidCoordinates.any((avoid) => _calculateDistance(point, avoid) < 250);
  }

  List<LatLng> _decodePoly(String poly) {
    List<int> list = poly.codeUnits;
    List<double> latLngList = [];
    int index = 0;
    int current = 0;
    int bit = 0;
    int result = 0;
    int shift;

    while (index < poly.length) {
      current = list[index] - 63;
      result |= (current & 0x1f) << (5 * bit);
      if (current < 0x20) {
        shift = ((result & 1) == 1 ? ~(result >> 1) : (result >> 1));
        latLngList.add(shift.toDouble());
        index++;
        bit = 0;
        result = 0;
        continue;
      }
      index++;
      bit++;
    }

    List<LatLng> polylineCoordinates = [];
    double lat = 0;
    double lng = 0;

    for (int i = 0; i < latLngList.length; i += 2) {
      lat += latLngList[i] / 100000.0;
      lng += latLngList[i + 1] / 100000.0;
      polylineCoordinates.add(LatLng(lat, lng));
    }

    return polylineCoordinates;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // harvesine formula
    final lat1 = point1.latitude;
    final lon1 = point1.longitude;
    final lat2 = point2.latitude;
    final lon2 = point2.longitude;
    const R = 6371000.0; // Earth radius in meters
    final phi1 = lat1 * (pi / 180);
    final phi2= lat2 * (pi / 180);
    final deltaPhi = (lat2 - lat1) * (pi / 180);
    final deltaLambda = (lon2 - lon1) * (pi / 180);

    final a = (sin(deltaPhi / 2) * sin(deltaPhi / 2)) +
              (cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Distance in meters
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        if (_initialPosition!= null)
          GoogleMap(
            onMapCreated: (controller) {
              setState(() {
                mapController = controller;
              });
            },
            initialCameraPosition: CameraPosition(
              target: _initialPosition!,
              zoom: 15.0,
            ),
            myLocationEnabled: true,
            markers: crimeMarkers,
            onTap: placingPin? _showPlacePinDialog : _onMapTap,
            polylines: _polylines,
          ),
              if (_isRouteGenerated)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Distance: $_routeDistance',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Time: $_routeDuration',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            child: Column(
              children: [
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      placingPin = !placingPin;
                    });
                  },
                  child: Text(placingPin ? 'Cancel Placing Pin' : 'Report Crime'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CrimeDetailsPage extends StatefulWidget {
  final LatLng position;

  const CrimeDetailsPage(this.position, {super.key});

  @override
  _CrimeDetailsPageState createState() => _CrimeDetailsPageState();
}

class _CrimeDetailsPageState extends State<CrimeDetailsPage> {
  String description = '';
  Uint8List imageBytes = Uint8List(0);
  String reporterName = '';
  bool isAnonymous = false;
  String crimeType = 'Car Accident';
  DateTime reportTime = DateTime.now();
  bool weaponDetected = false;

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        imageBytes = bytes;
      });

      final detectionResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YoloImage(imageBytes: imageBytes),
        ),
      );

      setState(() {
        weaponDetected = detectionResult['weaponDetected'];
      });
    }
  }

  Future<void> _confirmAndSubmit() async {
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Image'),
          content: imageBytes.isNotEmpty
              ? Image.memory(imageBytes)
              : const Text('No image selected.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (shouldSubmit ?? false) {
      Navigator.pop(
        context,
        {
          'description': description,
          'imageBytes': imageBytes,
          'reporterName': reporterName,
          'isAnonymous': isAnonymous,
          'crimeType': crimeType,
          'reportTime': reportTime,
          'weaponDetected': weaponDetected,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Report Crime',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red, // Set the font weight to bold
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: crimeType,
              onChanged: (value) {
                setState(() {
                  crimeType = value!;
                });
              },
              items: <String>[
                'Car Accident',
                'Fire',
                'Robbery/Assault',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            TextField(
              onChanged: (value) => description = value,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              onChanged: (value) => reporterName = value,
              decoration: const InputDecoration(labelText: 'Reporter Name'),
            ),
            Row(
              children: [
                Checkbox(
                  value: isAnonymous,
                  onChanged: (value) {
                    setState(() {
                      isAnonymous = value!;
                    });
                  },
                ),
                const Text('Anonymous'),
              ],
            ),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.redAccent, padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _confirmAndSubmit,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.redAccent, padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class YoloImage extends StatefulWidget {
  final Uint8List imageBytes;

  const YoloImage({required this.imageBytes, Key? key}) : super(key: key);

  @override
  State<YoloImage> createState() => _YoloImageState();
}

class _YoloImageState extends State<YoloImage> {
  late FlutterVision vision;
  List<Map<String, dynamic>> yoloResults = [];
  bool isLoaded = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  int? imageWidth;
  int? imageHeight;

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
    loadYoloModel();
    loadImage(widget.imageBytes);
  }

  @override
  void dispose() {
    vision.closeYoloModel();
    super.dispose();
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
      labels: 'assets/labels.txt',
      modelPath: 'assets/best-fp16.tflite',
      modelVersion: "yolov5",
      numThreads: 8,
      useGpu: false,
    );
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> loadImage(Uint8List imageBytes) async {
    try {
      final pickedFile = await _picker.getImage(source: ImageSource.gallery);
      final image = File(pickedFile!.path);
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage != null) {
        setState(() {
          _image = image;
          imageWidth = decodedImage.width;
          imageHeight = decodedImage.height;
        });
        yoloOnImage(image, imageWidth!, imageHeight!);
      } else {
        throw Exception("Decoded image is null");
      }
    } catch (e) {
      print("Error decoding or saving image: $e");
    }
  }

  Future<void> yoloOnImage(File image, int width, int height) async {
    try {
      if (!await image.exists()) {
        throw Exception("Image file does not exist");
      }
      final bytes = await image.readAsBytes();
      final result = await vision.yoloOnImage(
        bytesList: bytes,
        imageHeight: height,
        imageWidth: width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5,
      );
      setState(() {
        yoloResults = result;
      });

      final weaponDetected = yoloResults.any((result) => result['tag'] == 'knife');
      Navigator.pop(context, {'weaponDetected': weaponDetected});
    } catch (e) {
      print("Error during YOLO detection: $e");
      Navigator.pop(context, {'weaponDetected': false});
    }
  }
  void _confirmImage() {
    final weaponDetected = yoloResults.any((result) => result['tag'] == 'knife');
    Navigator.pop(context, {'weaponDetected': weaponDetected});
  }
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Analysis"),
      ),
      body: Column(
        children: [
          if (_image != null)
            Stack(
              children: [
                Image.file(_image!, fit: BoxFit.contain),
                ...displayBoxesAroundRecognizedObjects(size),
              ],
            ),
          if (_image == null)
            Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            if (_image != null)
            ElevatedButton(
              onPressed: _confirmImage,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
),
              ),
              child: const Text('Confirm Image'),
            ),
        ],
      ),
    );
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty || _image == null) return [];
double factorX = screen.width / (imageWidth ?? 1);
double factorY = screen.height / (imageHeight ?? 1);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: colorPick,
              width: 3,
            ),
          ),
          child: Text(
            "${result['tag']} ${(result['confidence'])}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.black,
              fontSize: 15,
            ),
          ),
        ),
      );
    }).toList();
  }
}


class CrimeInfo extends StatefulWidget {
  final LatLng position;

  CrimeInfo({required this.position});

  @override
  _CrimeInfoState createState() => _CrimeInfoState();
}

class _CrimeInfoState extends State<CrimeInfo> {
  double reliabilityScore = 20.0;
  bool hasVoted = false;
  String? crimeId;

  @override
  void initState() {
    super.initState();
    _loadCrimeData();
  }

  Future<void> _loadCrimeData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('crimeMarkers')
        .where('latitude', isEqualTo: widget.position.latitude)
        .where('longitude', isEqualTo: widget.position.longitude)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final crimeData = snapshot.docs[0].data();
      setState(() {
        crimeId = snapshot.docs[0].id;
        bool weaponDetected = crimeData['weaponDetected'] ?? false;
        reliabilityScore = crimeData['reliabilityScore']?.toDouble() ?? (weaponDetected ? 60.0 : 20.0);
      });
      _checkUserVote();
    }
  }

  Future<void> _checkUserVote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && crimeId != null) {
      final voteSnapshot = await FirebaseFirestore.instance
          .collection('votes')
          .where('userId', isEqualTo: user.uid)
          .where('crimeId', isEqualTo: crimeId)
          .get();

      if (voteSnapshot.docs.isNotEmpty) {
        setState(() {
          hasVoted = true;
        });
      }
    }
  }

  void _updateReliabilityScoreInFirestore(double newScore) async {
    if (crimeId != null) {
      await FirebaseFirestore.instance
          .collection('crimeMarkers')
          .doc(crimeId)
          .update({'reliabilityScore': newScore});

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('votes').add({
          'userId': user.uid,
          'crimeId': crimeId,
        });
        setState(() {
          hasVoted = true;
        });
      }
    }
  }

  void _increaseScore() {
    if (hasVoted) {
      _showAlreadyVotedWarning();
    } else {
      setState(() {
        reliabilityScore = (reliabilityScore + 5).clamp(0.0, 100.0);
        _updateReliabilityScoreInFirestore(reliabilityScore);
      });
    }
  }

  void _decreaseScore() {
    if (hasVoted) {
      _showAlreadyVotedWarning();
    } else {
      setState(() {
        reliabilityScore = (reliabilityScore - 5).clamp(0.0, 100.0);
        _updateReliabilityScoreInFirestore(reliabilityScore);
      });
    }
  }

  void _showAlreadyVotedWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Warning'),
        content: Text('You have already voted on this crime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crime Info',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red, // Set the font weight to bold
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('crimeMarkers')
            .where('latitude', isEqualTo: widget.position.latitude)
            .where('longitude', isEqualTo: widget.position.longitude)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            QuerySnapshot<Map<String, dynamic>> data =
                snapshot.data as QuerySnapshot<Map<String, dynamic>>;
            Map<String, dynamic> crimeData = data.docs[0].data();

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 198, 123, 248), Color.fromARGB(255, 127, 0, 254)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reliability Score: ${reliabilityScore.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Crime Type: ${crimeData['crimeType']}',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    Text(
                      'Description: ${crimeData['description']}',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    Text(
                      'Reporter: ${crimeData['reporterName']}',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    Text(
                      'Time: ${crimeData['reportTime'].toDate().toString()}',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    Image.network(crimeData['imageUrl']),
                    SizedBox(height: 16),
                    Text(
                      'Weapon detected: ${crimeData['weaponDetected']}',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    Spacer(),
                    if (!hasVoted) Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: Icon(Icons.thumb_up, color: Colors.green, size: 40),
                          onPressed: _increaseScore,
                        ),
                        IconButton(
                          icon: Icon(Icons.thumb_down, color: Colors.red, size: 40),
                          onPressed: _decreaseScore,
                        ),
                      ],
                    ),
                    if (hasVoted) Center(
                      child: Text(
                        'You have already voted.',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
