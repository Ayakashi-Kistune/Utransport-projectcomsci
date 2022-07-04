import 'dart:developer';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:utransport/Firestore/newUser.dart';

class adminpage extends StatefulWidget {
  const adminpage({Key? key}) : super(key: key);
  static bool nocheckcam = true;
  static bool nobalance = false;
  @override
  State<adminpage> createState() => _adminpageState();
}

class _adminpageState extends State<adminpage> {
  int loadvalue = 0;
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
    setState((){adminpage.nocheckcam = false;});
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
            setState((){curindex = index;});
            changepage(index);
          },
          items: const [
            BottomNavigationBarItem(
                label: 'Reload',
                icon: Icon(Icons.qr_code)
            ),
            BottomNavigationBarItem(
                label: 'QR Deduction',
                icon: Icon(Icons.person))
          ],
        ),

        body: PageView(

          onPageChanged: changepage,
          physics: NeverScrollableScrollPhysics(),
          controller: pageController,
          children: [
            QRscan(),
            PersonalQr()
          ],
        )
    );
  }

  Widget PersonalQr(){
    String value ="Deduct-${newUser.location}";
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
                    Container(
                      child: Row(
                        children: [
                          IconButton(onPressed: (){
                            setState((){
                              loadvalue--;
                            });
                          }, icon: Icon(Icons.remove)),
                          Text('${loadvalue}'),
                          IconButton(onPressed: (){
                            setState((){
                              loadvalue++;
                            });
                          }, icon: Icon(Icons.add)),
                        ],
                      ),

                    )

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
          if(adminpage.nocheckcam){
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
      if(adminpage.nobalance){
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
        balanceReload(scanData.code.toString(), loadvalue);
      }
    });
  }

  void balanceReload(String code,int incrementLoad){
    if(code.contains("Reload")){
      firestore
          .collection('Transaction-Reload')
          .doc()
          .set(transaction(result!.code.toString()));
      firestore
          .collection('users')
          .doc(code.substring(code.indexOf('-')+1))
          .update({'Token': FieldValue.increment(incrementLoad)});
    }
  }

  Map<String,dynamic> transaction(String code){
    return{
      "Function"  : code.substring(0, code.indexOf('-')),
      "Name"      : code.substring(code.indexOf('-')+1),
      "Location"  : newUser.location,
      "Time"      : Timestamp.now()
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

