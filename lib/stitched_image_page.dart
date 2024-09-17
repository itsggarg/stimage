import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class StitchedImagePage extends StatefulWidget {
  final String stitchedImage;
  final int faceCount;
  final String courseCode;
  final String classroomNumber;
  final String userName;
  final Map<String, dynamic> exifData;
  final String serverImagePath;

  const StitchedImagePage({
    Key? key,
    required this.stitchedImage,
    required this.faceCount,
    required this.courseCode,
    required this.classroomNumber,
    required this.userName,
    required this.exifData,
    required this.serverImagePath,
  }) : super(key: key);

  @override
  _StitchedImagePageState createState() => _StitchedImagePageState();
}

class _StitchedImagePageState extends State<StitchedImagePage> {
  bool _savingData = false;

  Future<void> _saveImageAndData() async {
    setState(() {
      _savingData = true;
    });

    // Image path
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/stitched_image.jpg';

    // 3. Save the image to local storage
    final file =
        await File(filePath).writeAsBytes(base64Decode(widget.stitchedImage));

    final info = NetworkInfo();
    final deviceInfoPlugin = DeviceInfoPlugin();

    Future<Map<String, String?>> getNetworkDetails() async {
      // Get the IP and MAC addresses
      var wifiIP = await info.getWifiIP(); // IP address when connected to Wi-Fi
      var wifiBSSID =
          await info.getWifiBSSID(); // MAC address of the Wi-Fi network

      return {
        'wifiIP': wifiIP,
        'wifiBSSID': wifiBSSID,
      };
    }

    Future<Map<String, String?>> getDeviceDetails() async {
      var deviceData = <String, String?>{};

      // Check platform and retrieve respective device information
      if (Theme.of(context).platform == TargetPlatform.android) {
        var androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData = {
          'device_name': androidInfo.model,
          'device_manufacturer': androidInfo.manufacturer,
          'os_version': 'Android ${androidInfo.version.release}',
        };
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        var iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData = {
          'device_name': iosInfo.name,
          'device_model': iosInfo.model,
          'os_version': 'iOS ${iosInfo.systemVersion}',
        };
      }

      return deviceData;
    }

    // Get the network details (IP and MAC)

    // Get the device details (name, manufacturer, OS version)
    var deviceDetails = await getDeviceDetails();

    // Get the IP address
    var networkDetails = await getNetworkDetails();
    // Now create the data map with the IP address
    final data = {
      'course_code': widget.courseCode,
      'classroom_number': widget.classroomNumber,
      'face_count': widget.faceCount,
      'image_path': widget.serverImagePath,
      'stitched_image': widget.stitchedImage,
      'user_name': widget.userName,
      'device_ip': networkDetails['wifiIP'], // IP address
      'device_mac': networkDetails['wifiBSSID'], // MAC address
      'device_name': deviceDetails['device_name'], // Device name
    };

    // 5. API Call to save data
    final response = await http.post(
      Uri.parse('http://192.168.50.52:5003/save_data'),
      headers: {'Content-type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      // 6. Handle success (e.g., show a message)
      print('Data saved successfully!');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Data saved successfully!')));
    } else {
      // 7. Handle errors
      print('Error saving data: ${response.statusCode}');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving data!')));
    }

    setState(() {
      _savingData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('St🪡mage'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Stitched Image
              InteractiveViewer(
                boundaryMargin: EdgeInsets.all(10),
                child: Image.memory(
                  base64Decode(widget.stitchedImage),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Error Loading Image');
                  },
                ),
              ),
              const SizedBox(height: 16.0),

              // Display Data
              Text('Course Code: ${widget.courseCode}'),
              Text('Classroom Number: ${widget.classroomNumber}'),
              Text('Number of Faces Detected: ${widget.faceCount}'),
              Text('User Name: ${widget.userName}'),

              // Save Button
              ElevatedButton(
                onPressed: _saveImageAndData,
                child: _savingData
                    ? CircularProgressIndicator()
                    : Text('Save Image and Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
