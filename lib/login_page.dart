// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'home_page.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _showSignup = false; 
//   String? _loggedInUser;

//   @override
//   void initState() {
//     super.initState();
//     _checkLoginStatus();
//   }

//   Future<void> _checkLoginStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     _loggedInUser = prefs.getString('loggedInUser');
//     if (_loggedInUser != null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//             builder: (context) => HomePage(loggedInUser: _loggedInUser!)),
//       );
//     }
//   }

//   Future<void> _signIn() async {
//     if (_formKey.currentState!.validate()) {
//       // API Call to your backend for authentication
//       final response = await http.post(
//         Uri.parse('http://192.168.50.52:5001/login'), // Replace with your backend URL
//         body: {
//           'email': _emailController.text,
//           'password': _passwordController.text,
//         },
//       );

//       if (response.statusCode == 200) {
//         // Successful login, save user data (e.g., token)
//         final data = jsonDecode(response.body);
//         if (data['success']) {
//           final prefs = await SharedPreferences.getInstance();
//           prefs.setString('loggedInUser', _emailController.text);

//           // Navigate to HomePage
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (context) =>
//                     HomePage(loggedInUser: _emailController.text)),
//           );
//         } else {
//           // Handle login error
//           print('Login failed: ${data['message']}');
//           // Display an error message to the user
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(data['message'])),
//           );
//         }
//       } else {
//         // Handle login error
//         print('Login failed: ${response.statusCode}');
//         // Display an error message to the user
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Login Failed')),
//         );
//       }
//     }
//   }

//   Future<void> _navigateToSignup() async {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => SignupPage()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('St🪡mage'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               if (!_showSignup) ...[
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: const InputDecoration(
//                     labelText: 'Email',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your email';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16.0),
//                 TextFormField(
//                   controller: _passwordController,
//                   obscureText: true,
//                   decoration: const InputDecoration(
//                     labelText: 'Password',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your password';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 32.0),
//                 ElevatedButton(
//                   onPressed: _signIn,
//                   child: const Text('Sign In'),
//                 ),
//                 TextButton(
//                   onPressed: _navigateToSignup,
//                   child: const Text('New User? Sign Up'),
//                 ),
//               ] else ...[
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: const InputDecoration(
//                     labelText: 'Email',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your email';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16.0),
//                 TextFormField(
//                   controller: _passwordController,
//                   obscureText: true,
//                   decoration: const InputDecoration(
//                     labelText: 'Password',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your password';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 32.0),
//                 ElevatedButton(
//                   onPressed: _signIn,
//                   child: const Text('Sign Up'),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     setState(() {
//                       _showSignup = false; 
//                     });
//                   },
//                   child: const Text('Already have an account? Sign In'),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }