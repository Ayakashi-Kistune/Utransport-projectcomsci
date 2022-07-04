import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:utransport/Authentication/loginprocess.dart';
import 'package:utransport/Firestore/newUser.dart';
import 'package:utransport/qr%20management/qrscreen.dart';

class Homepage extends StatefulWidget {
  Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final fire = FirebaseFirestore.instance;
  late var docs;
  String nickname = "";

  @override
  void initState() {
    if(newUser.getname != null) setdata();
    fire.collection("users").doc(newUser.getnickname).get().then((value) => newUser.nickname = value.data()!['Nickname']);
    super.initState();
  }
  void setdata(){
    setState((){
      docs = fire.collection("users").doc(newUser.getname).get();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: FutureBuilder(
          future: fire.collection('users').doc(newUser.getname).get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if(snapshot.hasData){
              Map<String, dynamic> data = snapshot.data!.data() as Map<String,dynamic>;
              return Text("Hello ${data['Nickname']}",
                  style: const TextStyle(
                      color: Colors.black
                  ),
              );
            }


          return const Text("Hello User");
        },),
        actions: [
          IconButton(onPressed: (){
            loginwithgoogle.glogout();
            newUser.user("", 0, '');
            Navigator.pop(context);
          }, icon: const Icon(Icons.logout,color: Colors.black,))
        ],
        backgroundColor: Colors.white,
      ),

      body: RefreshIndicator(
        onRefresh: (){
          return Future.delayed(const Duration(seconds: 1), (){
            setdata();
          });
        },
        child: FutureBuilder(
          future: docs,
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){

            if (snapshot.hasError) {
              return const Text("Something went wrong",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 50,
                  )
              );
            }

            if (snapshot.hasData && !snapshot.data!.exists) {
              return const Text("Document does not exist",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 50,
                )
              );
            }

            if (snapshot.connectionState == ConnectionState.done) {
              Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(

                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 50),
                        child: Text("Your available Token",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 50,
                            )
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Material(
                          color: data['Token'] >= 4 ? Colors.greenAccent : data['Token'] <= 2 ? Colors.redAccent : Colors.amberAccent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            splashColor: Colors.white70,
                            borderRadius: BorderRadius.circular(175),
                            onTap: (){
                              setdata();
                              setState((){qrscreen.nocheckcam = true;});
                              CircularProgressIndicator(value: 10,);
                              Future.delayed(Duration(seconds: 2),() {
                                if(data['Token'] == 0){
                                  qrscreen.nobalance =true;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("not enough Token"),duration: Duration(seconds: 2),));
                                }else{
                                  qrscreen.nobalance = false;
                                }
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const qrscreen()));
                              },);
                            },
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              radius: 180,
                              child: Text('${data["Token"]}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 60
                                )),
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 70),
                        child: IconButton(
                            icon: const Icon(Icons.draw),
                            onPressed: (){
                              print(newUser.getnickname);
                              final textControl = TextEditingController();
                              showDialog(context: context, builder: (builder) {
                                return AlertDialog(
                                  title: const Text("Change your Nickname"),
                                  content: TextField(
                                    controller: textControl,
                                    showCursor: true,
                                  ),
                                  actions: [
                                    TextButton(onPressed: (){
                                      String name = textControl.text[0].toUpperCase() + textControl.text.substring(1);
                                      fire.collection("users").doc(data['Name']).update({"Nickname": name});
                                      setdata();
                                      Navigator.pop(context);
                                    }, child: const Text("Confirm")),
                                    TextButton(onPressed: (){
                                      Navigator.pop(context);
                                    }, child: const Text("Cancel")),
                                  ],
                                );
                              });
                            }),
                      ),
                    ],
                  ),

              );

            }

            return const Align(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}
