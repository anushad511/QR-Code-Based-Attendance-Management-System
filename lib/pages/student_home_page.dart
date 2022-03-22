import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:encrypt/encrypt.dart' as ency;


import 'package:miniproject/services/authentication.dart';

import 'package:qrscan/qrscan.dart' as scanner;

class StudentHomePage extends StatefulWidget {
  StudentHomePage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  //final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String barcode = "";
  String status = "";

  //final _textEditingController = TextEditingController();

  //bool _isEmailVerified = false;
  




  @override
  void initState() {
    super.initState();
    

    //_checkEmailVerification();
  }
  


  signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }



  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async => false,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('Smart Attendance'),
          backgroundColor: Colors.deepOrange,
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 20.0, color: Colors.white)),
                onPressed: signOut)
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(2, 2, 2, 2),
                    width: 400,
                    height: 60,
                    alignment: Alignment(100, 20),
                    decoration: BoxDecoration(
                      color: Colors.deepOrangeAccent,
                      shape: BoxShape.rectangle,
                      //borderRadius: BorderRadius.circular(15),
                      borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(25),
                          topLeft: Radius.circular(25)),
                    ),
                    child: const Center(
                     child: Text(
                        'Hello Student' ,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
            

              
              Container(
                  margin: new EdgeInsets.only(top: 40, bottom: 40),
                  width: 320.0,
                  height: 380.0,
                  //alignment: Alignment(100, 20),
                  decoration: BoxDecoration(
                    //color: Colors.lightBlue[50],
                    shape: BoxShape.rectangle,
                    //borderRadius: BorderRadius.circular(25),
                    borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(35),
                        topLeft: Radius.circular(35)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            qrCodeScan();
                          },
                          child: Container(
                            // margin: new  EdgeInsets.only(left: 10,right:10,top:10,bottom:30),
                            padding: EdgeInsets.fromLTRB(2, 2, 2, 2),
                            width: 200,
                            margin: new EdgeInsets.only(top: 60, bottom: 10),
                            height: 80,
                            alignment: Alignment(50, 50),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              shape: BoxShape.rectangle,
                              borderRadius:
                                  BorderRadius.all(Radius.elliptical(20, 30)),
                              //borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Center(
                              child: Text(
                                '  Scan QR \n     Code',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 200),
                        new Text(status),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
    
  }

  Future qrCodeScan() async {
    String barcode = await scanner.scan();
    final key = ency.Key.fromUtf8('JingalalahuhuJingalalahuhuJingal');
    final iv = ency.IV.fromLength(16);
    final encrypter = ency.Encrypter(ency.AES(key));
    final decryptedQR =
        encrypter.decrypt(ency.Encrypted.from64(barcode), iv: iv);
    print('BARCODE' + decryptedQR);
    setState(() => this.barcode = decryptedQR);
    var a = updateDatabase();
  }

  Future<void> updateDatabase() async {
    final firestoreInstance = Firestore.instance;
    var docs = Firestore.instance.document('Users/$this.userId');
    var qrDetails = barcode.split('/');
    var classname = qrDetails[0];
    var dates = qrDetails[1].split('.');
    var day = dates[0];
    var date = dates[1] + '.' + dates[2];
    var check = qrDetails[2];
    var secretCode = qrDetails[3];
    var updatedCount = 0;
    var updatedCodes = [];
    var codeExists = 0;
    var teacherCodeExists = 0;
    var exists = 0;
    //print(docs);
    var teacherUID = qrDetails[4];
    var firebaseUser = await FirebaseAuth.instance.currentUser();
    final CollectionReference monthsRef = Firestore.instance
        .collection('users')
        .document(firebaseUser.uid)
        .collection(classname);
    var monthsDocs = await Firestore.instance
        .collection("users")
        .document(firebaseUser.uid)
        .collection(classname)
        .getDocuments();

    var months = monthsDocs.documents;

    for (int i = 0; i < months.length; i++)
      if (date == months[i].documentID) {
        exists = 1;
        break;
      }

    if (exists == 0) await monthsRef.document(date).setData({});

    var data = await Firestore.instance
        .collection("users")
        .document(firebaseUser.uid)
        .collection(classname)
        .document(date)
        .get();

    print('TEACHER UID :' + teacherUID);

    var teacherData = await Firestore.instance
        .collection("users")
        .document(teacherUID)
        .collection(classname)
        .document(date)
        .get();

    try {
      for (int i = 0; i < teacherData[day]['codes'].length; i++) {
        print(teacherData[day]['codes'][i]);
        if (teacherData[day]['codes'][i] == secretCode) {
          teacherCodeExists = 1;
          break;
        }
      }
    } catch (e) {
      print('Teacher Code exists caught');
    }

    try {
      updatedCount = data[day]['count'] + 1;
    } catch (e) {
      updatedCount = 1;
      
    }

    try {
      for (int i = 0; i < data[day]['codes'].length; i++) {
        print(data[day]['codes'][i]);
        if (data[day]['codes'][i] == secretCode) {
          codeExists = 1;
          break;
        }
      }
    } catch (e) {
      print('Code exists caught');
    }
    print('CODE EXISTS' + codeExists.toString());
    if (int.parse(check) < updatedCount) {
      setState(() {
        this.status = 'Attendance limit exeeded';
      });
    } else if (codeExists == 1) {
      setState(() {
        this.status = 'Reuse of code detected';
      });
    } else if (teacherCodeExists == 0) {
      setState(() {
        this.status = 'Invalid Code,not in database';
      });
    } else {
      try {
        updatedCodes = data[day]['codes'] + [secretCode];
      } catch (e) {
        updatedCodes = [secretCode];
      }

      try {
        firestoreInstance
            .collection("users")
            .document(firebaseUser.uid)
            .collection(classname)
            .document(date)
            .updateData({
          "$day.check": int.parse(check),
          "$day.count": updatedCount,
          "$day.codes": updatedCodes
        }).then((_) {
          setState(() {
            this.status = 'Update Successful';
          });
        });
      } catch (e) {
        setState(() {
          this.status = this.status + 'Update Fail';
        });
        print(e.toString());
      }
    }
  }
}
