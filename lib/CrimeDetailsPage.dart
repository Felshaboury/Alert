import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'WeaponDetectionPage.dart';

class CrimeDetailsPage extends StatefulWidget {
  final LatLng position;

  CrimeDetailsPage(this.position);

  @override
  _CrimeDetailsPageState createState() => _CrimeDetailsPageState();
}

class _CrimeDetailsPageState extends State<CrimeDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  Uint8List? _imageBytes;
  String _reporterName = '';
  bool _isAnonymous = false;
  String _crimeType = '';
  double _reliability = 0.0;
  DateTime _reportTime = DateTime.now();

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = imageBytes;
        });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _imageBytes != null) {
      _formKey.currentState!.save();
      final crimeDetails = {
        'description': _description,
        'imageBytes': _imageBytes,
        'reporterName': _reporterName,
        'isAnonymous': _isAnonymous,
        'crimeType': _crimeType,
        'reportTime': _reportTime,
        'reliability': _reliability,
      };
      Navigator.pop(context, crimeDetails);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crime Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onSaved: (value) {
                  _description = value!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Reporter Name'),
                onSaved: (value) {
                  _reporterName = value!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Report Anonymously'),
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value;
                  });
                },
              ),
              SizedBox(height: 16),
              Text('Crime Type'),
              RadioListTile(
                title: Text('Car Accident'),
                value: 'CarAccident',
                groupValue: _crimeType,
                onChanged: (value) {
                  setState(() {
                    _crimeType = value.toString();
                  });
                },
              ),
              RadioListTile(
                title: Text('Fire Accident'),
                value: 'FireAccident',
                groupValue: _crimeType,
                onChanged: (value) {
                  setState(() {
                    _crimeType = value.toString();
                  });
                },
              ),
              RadioListTile(
                title: Text('Robbery/Assault'),
                value: 'RobberyAssault',
                groupValue: _crimeType,
                onChanged: (value) {
                  setState(() {
                    _crimeType = value.toString();
                  });
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Select Image'),
              ),
              if (_imageBytes != null)
                Column(
                  children: [
                    SizedBox(height: 16),
                    Image.memory(_imageBytes!),
                  ],
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
