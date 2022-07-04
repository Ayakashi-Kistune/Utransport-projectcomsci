import 'dart:developer';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:utransport/Firestore/newUser.dart';

class qrscreen extends StatefulWidget {
  const qrscreen({Key? key}) : super(key: key);
  static bool nocheckcam = true;
  static bool nobalance = false;
  @override
  State<qrscreen> createState() => _qrscreenState();
}

class _qrscreenState extends State<qrscreen> {

  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  int curindex = 0;
  IconData flash = Icons.flash_off;
  bool camstatus = true;
  PageController pageController = PageController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  PageController checkview = PageController();

  void checkshow(index){
    checkview.jumpToPage(index);
    setState((){qrscreen.nocheckcam = false;});
  }

  void changepage(index){
    pageController.animateToPage(curindex, duration: Duration(milliseconds: 600), curve: Curves.linearToEaseOut);
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: curindex,
        onTap: (index){
          print(index);
          setState((){curindex = index;});
          changepage(index);
        },
        items: [
          BottomNavigationBarItem(
              label: 'Scan',
              icon: Icon(Icons.qr_code)
          ),
          BottomNavigationBarItem(
              label: 'Transaction',
              icon: Icon(Icons.list_alt_rounded)
          ),
          BottomNavigationBarItem(
              label: 'My QR',
              icon: Icon(Icons.person))
        ],
      ),

      body: PageView(

        onPageChanged: changepage,
        physics: NeverScrollableScrollPhysics(),
        controller: pageController,
        children: [
          QRscan(),
          Transactionlist(),
          PersonalQr()
        ],
      )
    );
  }
  Widget Transactionlist(){
    var snap = firestore.collection("Transaction-Deduction").get();
    return RefreshIndicator(
      onRefresh: (){
        return Future.delayed(Duration(seconds: 1),() {
          setState(()=> snap = firestore.collection("Transaction-Deduction").get());
        },);
      },
      child: FutureBuilder<QuerySnapshot>(
          future: snap,
          builder: (context,AsyncSnapshot<QuerySnapshot> snapshot){
            var time = Timestamp.now();
            time.nanoseconds;
            if(snapshot.hasData){
              return ListView.builder(
                  itemCount: snapshot.data?.size,
                  itemBuilder: (BuildContext,index){
                     if(snapshot.data?.docs[index]['User'] == newUser.getname){
                       Timestamp time = snapshot.data?.docs[index]['Time'];
                       int leadnum = index+1;
                       return ListTile(
                         title: Text("${snapshot.data?.docs[index]['Function']} Load ${snapshot.data?.docs[index]['Location']}\n" + time.toDate().toString()),
                         leading: Text(leadnum.toString(),textAlign: TextAlign.center,style: TextStyle(fontSize: 20),),
                       );//how to convert timestamp dem

                     }
                     return Container();
                  });
            }
            return CircularProgressIndicator();

          }),
    );
  }

  Widget PersonalQr(){
    String value ="Reload-${newUser.getname}";
    return Column(
      children: [
        Container(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 100),
            child: QrImage(
                size: 400,
                data: value),
          ),
        ),
        Container(
          child: Column(
            children: [
              Text(textAlign: TextAlign.center,value)
            ],
          ),
        )

      ],
    );
  }

  Widget QRscan(){
      return Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text(
                        '${result!.code}')
                  else
                    const Text('Scan a code'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: IconButton(
                          icon: Icon(flash),
                          onPressed: () async {
                            if(camstatus){
                              await controller?.toggleFlash();
                              setState(() {flash == Icons.flash_off ? flash = Icons.flash_on : flash = Icons.flash_off;});
                            }
                          },
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      );

  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller

    return GestureDetector(
      onTap: (){
        if(qrscreen.nocheckcam){
            if (camstatus) {
              controller?.stopCamera();
              camstatus = !camstatus;
            } else {
              controller?.resumeCamera();
              camstatus = !camstatus;
            }
          }
        },
      child: PageView(
        controller: checkview,
        onPageChanged: checkshow,
        physics: NeverScrollableScrollPhysics(),
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
                borderColor: Colors.cyanAccent,
                borderRadius: 20,
                borderLength: 30,
                borderWidth: 20,
                cutOutSize: scanArea),
            onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
          ),
          Container(
            color: Colors.greenAccent,
            child: Icon(Icons.check_circle_outline_rounded,size: 100,),
          ),
          Container(
            color: Colors.redAccent,
            child: Icon(Icons.close_rounded,size: 100,),
          )
        ],
      )
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if(qrscreen.nobalance){
        camstatus = false;
        checkshow(2);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("not enough Token"),duration: Duration(seconds: 2),));
      }else{
        camstatus = false;
        checkshow(1);
        controller.stopCamera();
        setState(() {
          // result.code is link, need to figure out how to make a transaction history format with time and info did from admin after scan code
          result = scanData;
        });
        balanceDeduct(scanData.code.toString());
      }
    });
  }

  void balanceDeduct(String code){
    if(code.contains("Deduct")) {
      firestore
          .collection('Transaction-Deduction')
          .doc()
          .set(transaction(result!.code.toString()));
      firestore
          .collection('users')
          .doc(newUser.getname)
          .update({'Token': FieldValue.increment(-1)});
    }else{
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("u tried to scan others yeah"),duration: Duration(seconds: 2),));
    }
  }

  Map<String,dynamic> transaction(String code){
    return{
      "Function" : code.substring(0, code.indexOf('-')),
      "Location" : code.substring(code.indexOf('-')+1),
      "User"     : newUser.getname,
      "Time"     : Timestamp.now()
    };
  }
  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

