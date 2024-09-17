import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:exif/exif.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'stitched_image_page.dart';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  final String loggedInUser;
  const HomePage({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _classroomNumberController = TextEditingController();
  List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();
  final List<String> _courseCodes = ['C1', 'C2', 'C3', 'C4', 'C5'];
  String? _selectedCourseCode;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName');
    });
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedImages = await _picker.pickMultiImage(
      imageQuality: 80,
    );

    if (pickedImages.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(pickedImages);
      });
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  Future<void> _captureImage() async {
    // Request camera permission
    var status = await Permission.camera.request();
    if (status.isGranted) {
      // Select an image from the camera
      final pickedImage = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          _pickedImages.add(pickedImage);
        });
      }
    } else {
      // Handle case where permission is denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission denied')),
      );
    }
  }

  Future<String> _getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    } else {
      return 'Unknown Device';
    }
  }

  Future<void> _stitchImages() async {
    // 1. Validate inputs (course code, classroom number, images)
    if (_formKey.currentState!.validate() && _pickedImages.isNotEmpty) {
      final courseCode = _selectedCourseCode!;
      final classroomNumber = _classroomNumberController.text;

      // 2. Convert images to base64
      final imageBase64List =
          await Future.wait(_pickedImages.map((image) async {
        final bytes = await image.readAsBytes();
        return base64Encode(bytes);
      }).toList());

      // 3. Get Device Information
      String? deviceIP = await NetworkInfo().getWifiIP();
      String deviceName = await _getDeviceName();

      // 4. API Call for stitching
      final response = await http.post(
        Uri.parse('http://192.168.50.52:5000/stitch'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'course_code': courseCode,
          'classroom_number': classroomNumber,
          'images': imageBase64List,
          'device_ip': deviceIP,
          'device_name': deviceName,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final stitchedImageBase64 = responseData['stitched_image'];
        final faceCount = responseData['face_count'];
        final serverImagePath = responseData['image_path'];

        // 6. Get EXIF data from the first image
        final exifData = await _readExifData(_pickedImages.first);

        // 7. Navigate to StitchedImagePage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StitchedImagePage(
              stitchedImage: stitchedImageBase64,
              faceCount: faceCount,
              courseCode: courseCode,
              classroomNumber: classroomNumber,
              exifData: exifData,
              userName: widget.loggedInUser,
              serverImagePath: serverImagePath,
            ),
          ),
        );
      } else {
        // Handle errors
        print('Error during stitching: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stitching images')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _readExifData(XFile image) async {
    final bytes = await image.readAsBytes();
    final exif = await readExifFromBytes(bytes);
    return exif;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('St🪡mage'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButton<String>(
                value: _selectedCourseCode,
                hint: Text('Select Course'),
                items: _courseCodes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCourseCode = newValue;
                  });
                },
              ),
              TextFormField(
                controller: _classroomNumberController,
                decoration: const InputDecoration(
                  labelText: 'Classroom Number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the classroom number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _captureImage,
                    child: const Text('Capture Image'),
                  ),
                  ElevatedButton(
                    onPressed: () => _getImage(ImageSource.gallery),
                    child: const Text('Choose Image'),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _pickedImages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Image.file(
                        File(_pickedImages[index].path),
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text('Image ${index + 1}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeImage(index),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _stitchImages,
                child: const Text('Stitch Images'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
