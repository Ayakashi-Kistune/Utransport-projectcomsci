import 'package:cloud_firestore/cloud_firestore.dart';

class newUser{
  static late String? uid;
  static late String location;
  static final firestore = FirebaseFirestore.instance;
  static late String? _name;
  static late int? _token;
  static late String nickname;

  static void user(String? name, int token, String? uid){
    newUser._name = name;
    newUser._token = token;
    newUser.nickname = name!;
    newUser.uid = uid;
  }

  static Map<String, dynamic> uploadFirestore(){
    return{
      if (_name != null)   "Name"  : _name,
      if (_token != null)  "Token" : _token,
      if (nickname != null) "Nickname" : _name,
      if (uid != null ) "UID" : uid,
    };
  }

  static int? get balance => _token;
  static String? get getname => _name;
  static String? get getnickname => nickname;

  static void insertStore() async{
    final user = await firestore.collection("users").doc(newUser.getname);
    user.get().then((value) => {
      if (value.exists) {
        print("account exist"),
      }else{
        print("creating account"),
        user.set(uploadFirestore())
      }
    });
  }



}