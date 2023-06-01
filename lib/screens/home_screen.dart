import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebasee/screens/email_auth/login_screen.dart';
import 'package:flutter_firebasee/screens/phone_auth/sign_in_with_phone.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'email_auth/signup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  File? profilepic;

  void logOut() async {
    await FirebaseAuth.instance
        .signOut(); // locally your user info will be erased
    Navigator.popUntil(context, (route) => route.isFirst); // go to 1st page
    Navigator.pushReplacement(
        context, CupertinoPageRoute(builder: (context) => LoginScreen()));
  }

  void saveUser() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String ageString = ageController.text.trim();

    int age = int.parse(ageString);

    nameController.clear();
    emailController.clear();
    ageController.clear();

    if (name != "" && email != "" && profilepic != null) {
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child("profilepictures")
          .child(Uuid().v1())
          .putFile(
              profilepic!); //in Firebase Storage ref is root "folder", inside ref is it's child "folder" (here named as "profilepictures"), inside that is unique id "folder"(having unique name for every file) , inside it profilepic "file" is put.

      StreamSubscription taskSubscription =
          uploadTask.snapshotEvents.listen((snapshot) {
        double percentage =
            snapshot.bytesTransferred / snapshot.totalBytes * 100;
        log(percentage
            .toString()); // to check how much data of image is transferred in percentage
      });

      TaskSnapshot taskSnapshot =
          await uploadTask; // uploadTask is uploaded in storage
      String downloadUrl = await taskSnapshot.ref
          .getDownloadURL(); // get url of image from taskSnapshot

      taskSubscription.cancel();

      Map<String, dynamic> userData = {
        "name": name,
        "email": email,
        "age": age,
        "profilepic": downloadUrl,
        "samplearray": [name, email, age]
      };
      FirebaseFirestore.instance.collection("users").add(userData);
      log("User created!");
    } else {
      log("Please fill all the fields!");
    }

    setState(() {
      profilepic = null; // to clear profile picture for next user
    });
  }

  void deleted(id) async {
    await FirebaseFirestore.instance.collection("users").doc(id).delete();
    log("user deleted");
  }

  void getInitialMessage() async {
    RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();

    if (message != null) {
      if (message.data["page"] == "email") {
        Navigator.push(
            context, CupertinoPageRoute(builder: (context) => SignUpScreen()));
      } else if (message.data["page"] == "phone") {
        Navigator.push(context,
            CupertinoPageRoute(builder: (context) => SignInWithPhone()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Invalid Page!"),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  void initState() {
    super.initState();

    getInitialMessage();

    FirebaseMessaging.onMessage.listen((message) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message.data["myname"].toString()),
        duration: Duration(seconds: 10),
        backgroundColor: Colors.green,
      ));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("App was opened by a notification"),
        duration: Duration(seconds: 10),
        backgroundColor: Colors.green,
      ));
    });
  }

  CollectionReference ref = FirebaseFirestore.instance.collection('users');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Firebase App"),
        actions: [
          IconButton(
            onPressed: () {
              logOut();
            },
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              CupertinoButton(
                onPressed: () async {
                  XFile? selectedImage = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);

                  if (selectedImage != null) {
                    File convertedFile =
                        File(selectedImage.path); //converting xfile to file
                    setState(() {
                      profilepic = convertedFile;
                    });
                    log("Image selected!");
                  } else {
                    log("No image selected!");
                  }
                },
                padding: EdgeInsets.zero,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: (profilepic != null)
                      ? FileImage(profilepic!)
                      : null, // if profilepic !=null FileImage is given profilepic file and that FileImage is given to background image, else if profilepic  =null background image =null
                  backgroundColor: Colors.grey,
                ),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: "Name"),
              ),
              SizedBox(
                height: 10,
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(hintText: "Email Address"),
              ),
              SizedBox(
                height: 10,
              ),
              TextField(
                controller: ageController,
                decoration: InputDecoration(hintText: "Age"),
              ),
              SizedBox(
                height: 10,
              ),
              CupertinoButton(
                onPressed: () {
                  saveUser();
                },
                child: Text("Save"),
              ),
              SizedBox(
                height: 20,
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .where("age", isGreaterThanOrEqualTo: 19)
                    .orderBy("age",
                        descending:
                            true) // additional functionalitites to sort the users
                    .snapshots(), // snapshot tells current state
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    // if successfully connected to data
                    if (snapshot.hasData && snapshot.data != null) {
                      // if firestore have some data
                      return Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> userMap =
                                snapshot.data!.docs[index].data() as Map<String,
                                    dynamic>; // converted to map so that need not to write "snapshot.data!.docs[index]" again and again

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(userMap["profilepic"]),
                              ),
                              title: Text(
                                  userMap["name"] + " (${userMap["age"]})"),
                              subtitle: Text(userMap["email"]),
                              trailing: IconButton(
                                onPressed: () {
                                  deleted(snapshot.data!.docs[index].id);
                                  setState(() {});
                                },
                                icon: Icon(Icons.delete),
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      return Text("No data!");
                    }
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
