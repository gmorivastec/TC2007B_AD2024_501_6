// 1st - go to firebase and click on add app on general description of your project
// 2nd - install firebase cli - https://firebase.google.com/docs/cli?hl=es&authuser=1&_gl=1*n7ki9u*_ga*OTQ0Njk3MTUwLjE3MjQyNDY0OTI.*_ga_CW55HF8NVT*MTczMDgxMzIxOS40Ni4xLjE3MzA4MTMyODYuNjAuMC4w#windows-npm
//  macos + linux - curl -sL https://firebase.tools | bash
//  windows - download binary + double click or npm install -g firebase-tools
// 3rd - install flutterfire - dart pub global activate flutterfire_cli
// 4th - add your dart pub-cache/bin folder to your path
// 5th - flutterfire configure --project=your_projects_name
// 6th - flutter pub add firebase_core
// 7th - flutter pub add firebase_auth
// 8th - flutter pub add cloud_firestore
// 9th - update minSdk to 23 on your build.gradle

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {

  // since it's async now we need to ensure native bindings are up
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: RealTimeWidget(),
        ),
      ),
    );
  }
}

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {

  // we are going to add a couple of controllers 
  // controllers are objects that keep track of input widgets
  TextEditingController login = TextEditingController();
  TextEditingController password = TextEditingController();

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    login.text = "";
    password.text = "";
  }

  @override
  Widget build(BuildContext context) {

    FirebaseAuth.instance.authStateChanges().listen((User? user) {

      if(user != null){
        print("*** USER IS VALID ${user.uid}");
      } else {
        print("*** SIGNED OUT");
      }
    });


    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Login'
            ),
            controller: login,
          )
        ),
        Container(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password'
            ),
            controller: password,
            obscureText: true,
          )
        ),
        TextButton(
          onPressed: () async {

            // try keyword - mechanism used in several languages
            // to enclose risky code (code that we know might throw an exception)

            // a mechanism used to try to fail gracefully
            try {
              // this code is using a singleton 
              // https://en.wikipedia.org/wiki/Singleton_pattern
              final user = 
              await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: login.text, 
                password: password.text
              );
              print("USER CREATED: ${user.user?.uid}");

            } on FirebaseException catch(e){
              if(e.code == 'weak-password') {
                print("YOUR PASSWORD IS WEAK");
              } else if (e.code == 'email-already-in-use') {
                print("ACCOUNT EXISTS");
              }
            } catch(e) {
              print(e);
            } finally {
              // this code will always run
              // normally used to do clean up
            }
          }, 
          child: const Text("Sign up")
        ),
        TextButton(
          onPressed: () async {

            try {
              final user = await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: login.text, 
                password: password.text
              );
              print("USER LOGGED IN: ${user.user?.uid}");
            } catch(e) {
              print(e);
            }
          }, 
          child: const Text("Log in")
        ),
        TextButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            print("SIGNED OUT!");
          }, 
          child: const Text("Log out")
        ),
        TextButton(
          onPressed: () {
            
            final puppy = <String, dynamic> {
              "name" : "Chucho",
              "breed" : "Pomeranian",
              "age" : 10
            };

            FirebaseFirestore.instance
            .collection("perritos")
            .add(puppy)
            .then((DocumentReference document) {
              print("new document created: ${document.id}");
            });
          }, 
          child: const Text("Add record")
        ),
        TextButton(
          onPressed: () {

            FirebaseFirestore.instance
            .collection("perritos")
            .get()
            .then((QuerySnapshot perritos) {
              for(var currentDoc in perritos.docs){
                print("DOCUMENT: ${currentDoc.data()}");
              }
            });
          }, 
          child: const Text("Query")
        ),
      ],
    );
  }
}

class RealTimeWidget extends StatefulWidget {
  const RealTimeWidget({super.key});

  @override
  State<RealTimeWidget> createState() => _RealTimeWidgetState();
}

class _RealTimeWidgetState extends State<RealTimeWidget> {

  final Stream<QuerySnapshot> puppiesStream = 
    FirebaseFirestore.instance.collection("perritos").snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: puppiesStream, 
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {

        if(snapshot.hasError) {
          return const Text("ERROR ON QUERY, PLEASE VERIFY");
        }

        if(snapshot.connectionState == ConnectionState.waiting){
          return const CircularProgressIndicator();
        }

        return ListView(
          children: snapshot.data!.docs
          .map((DocumentSnapshot doc) {
            // iterate through docs nd build  widget for ech one

            // step 1 
            // get data for current doc 
            Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

            // with data now availabe step 2 - build a widget
            return ListTile(
              title: Text(data['name']),
              subtitle: Text(data['breed']),
            );
          }).toList().cast(),
        );
      }
    );
  }
}