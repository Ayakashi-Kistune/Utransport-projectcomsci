import 'package:flutter/material.dart';
import 'package:utransport/Authentication/loginprocess.dart';
import '../Homepage/Homepage.dart';
import 'UsernamePass.dart';

class Loginpage extends StatefulWidget {
  Loginpage({Key? key}) : super(key: key);

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {

  void waitlogin(){
    loginwithgoogle.glogin();
    Future.delayed(Duration(seconds: 5),() {
      if(loginwithgoogle.currentUser != null) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (builder) => Homepage()));
      }
    },);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(flex: 10,),
            Buttonlogin("Login with Google account",Icons.mail, waitlogin),
            Buttonlogin("Login with Username and Password", Icons.person_add, ()=> Navigator.push(context, MaterialPageRoute(builder: (builder) => Loginusernamepass() ))),
            Spacer(flex: 1,)
          ],
        ),
      );
  }
}

class Buttonlogin extends StatelessWidget {
  Buttonlogin(this._title, this._icon, this._funct, {Key? key}) : super(key: key);

  final void Function() _funct;
  final String? _title;
  final IconData? _icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18,vertical: 10),
      child: ElevatedButton(
          onPressed: _funct,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(5,10,20,10),
                child: Icon(_icon, size: 25,),
              ),
              Text(_title!,
                style: const TextStyle(
                  fontSize: 15
                ),
              ),
            ],
          )
      ),
    );
  }


}
