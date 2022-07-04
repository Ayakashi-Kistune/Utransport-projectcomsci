import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:utransport/Firestore/newUser.dart';

class loginwithgoogle{
  static final firebaseauth = FirebaseAuth.instance;
  static final firestore = FirebaseFirestore.instance;
  static GoogleSignInAccount? currentUser;
  static final googleSignIn = GoogleSignIn(
      scopes: <String>[
        'https://www.googleapis.com/auth/userinfo.email',
        'https://www.googleapis.com/auth/userinfo.profile'
      ]
  );

  static Future<void> glogin() async {
    currentUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? authentication = await currentUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: authentication?.accessToken,
      idToken: authentication?.idToken,
    );
    var useracc = await firebaseauth.signInWithCredential(credential);
    newUser.user(currentUser!.displayName, 0, useracc.user?.uid);
    newUser.insertStore();
  }

  static void glogout() async {
    await googleSignIn.signOut();
  }

  static void fireAccountremove() async {
    await firebaseauth.currentUser?.delete();
  }


}
