import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebasee/screens/email_auth/login_screen.dart';
import 'package:flutter_firebasee/screens/email_auth/signup_screen.dart';
import 'package:flutter_firebasee/screens/home_screen.dart';
import 'package:flutter_firebasee/screens/phone_auth/sign_in_with_phone.dart';
import 'package:flutter_firebasee/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.initialize();

//  FIRESTORE OPERATIONS :-
  // FirebaseFirestore _firestore = FirebaseFirestore.instance;

// DocumentSnapshot snapshot = await _firestore.collection("users").doc(
// "29FyT0NrWx45R4AztChG").get();
//   log(snapshot.data().toString());

  // Map<String, dynamic> newUserData = {
  //   "name": "SlantCode",
  //   "email": "slantcode@gmail.com"
  // };

  // await _firestore
  //     .collection("users")
  //     .add(newUserData);
  // log("User Added!");
  // await _firestore
  //     .collection("users")
  //     .doc("your-id-here")
  //     .update({"email": "beast@gmail.com"});
  // log("User Updated!");
//  await _firestore.collection("users").doc("o0IEC8tqkgHpRt7yJhYN").delete();
//    log("User deleted!");
  
  

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: (FirebaseAuth.instance.currentUser != null)
          ? HomeScreen()
          : LoginScreen(), // if you've saved your login info before in mobile(locally) i.e currentUser!=NULL then directly go to HomeScreen() or else go to LoginScreen() to log in
    );
  }
}
