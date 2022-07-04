import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utransport/Firestore/newUser.dart';
import 'package:utransport/Homepage/Adminpage.dart';
import 'package:utransport/Homepage/Homepage.dart';

class Loginusernamepass extends StatefulWidget {
  const Loginusernamepass({Key? key}) : super(key: key);

  @override
  State<Loginusernamepass> createState() => _LoginusernamepassState();
}

class _LoginusernamepassState extends State<Loginusernamepass> {
  final passwordField = TextEditingController();
  final usernameField = TextEditingController();
  String buttonlog = "Sign up";
  String textbtn = 'already signed up? login here';
  bool issignup = true;
  late UserCredential credential;
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      resizeToAvoidBottomInset: false,
      body: usernamelogin(),
    );
  }

  Widget usernamelogin(){
    return Card(
      color: Colors.tealAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
      margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height/3.5,horizontal: MediaQuery.of(context).size.width/10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(flex: 3,child: Container()),
          Container(
            child: Text(buttonlog,
              style: TextStyle(
                  fontSize: 30
              ),),
          ),
          cardTextField('username', usernameField),
          cardTextField("Password", passwordField),
          Expanded(flex: 1,child: Container()),
          ElevatedButton(onPressed: (){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('please wait...'),duration: Duration(seconds: 2),));
            if(issignup) {
              signup();
            }else{
              signin();
            }
          }, child: Text(buttonlog)),
          TextButton(onPressed: changestate, child: Text(textbtn))
        ],
      ),
    );
  }
  
  Widget cardTextField(String title, TextEditingController controller, ){
    return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(const Radius.circular(5))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(" ${title}", textAlign: TextAlign.left),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                  label: Text(" ${title}"),
                  border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent)
                  )
              ),
            ),
          ],
        )
    );
  }
  void changestate(){
      setState(() {
        buttonlog == "Sign up" ? buttonlog = "Login" : buttonlog = "Sign up";
        textbtn ==  "already signed up? login here"? textbtn = "not yet signed in? sign up here" : textbtn = "already signed up? login here";
        issignup = !issignup;
      });
      print(issignup);

  }

  Future<void> signup() async {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
        var data = await snapshot.docs;
        String name;
        bool noduplicate = true;
        for(int i = 0; i < data.length;i++){
          name = data[i]['Name'];
          if(name == "Admin"){
            newUser.location = data[i]['Location'];
            Future.delayed(Duration(seconds: 2),() {
              Navigator.push(context, MaterialPageRoute(builder: (context) => adminpage()));
            },);
            setState((){
              noduplicate = false;

            });
            break;
          }
          if(name.toLowerCase() ==  usernameField.text){
            noduplicate = false;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username Exist"),duration: Duration(seconds: 2),));
          }

        }
        if(noduplicate){
          newUser.user(usernameField.text, 0, passwordField.text);
          newUser.insertStore();
          print("signed up");
          Future.delayed(Duration(seconds: 2),() {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Homepage()));
          },);

        }
  }

  Future<void> signin() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    var data = await snapshot.docs;
    String name,pass,loc;
    for(int i = 0; i < data.length;i++){
      name = data[i]['Name'];
      pass = data[i]['UID'];
      if(name ==  usernameField.text){
        if(pass == passwordField.text){
          if(name == "Admin"){
            newUser.location = data[i]['Location'];
            Future.delayed(Duration(seconds: 2),() {
              Navigator.push(context, MaterialPageRoute(builder: (context) => adminpage()));
            },);
            break;
          }
          newUser.user(usernameField.text, 0, passwordField.text);
          print("signed in");
          Future.delayed(Duration(seconds: 2),() {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Homepage()));
          },);
          break;
        }else{
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wrong password or username"),duration: Duration(seconds: 2),));
        }
      }
      if(i == data.length-1) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account not exist"),duration: Duration(seconds: 2),));

    }


  }
}