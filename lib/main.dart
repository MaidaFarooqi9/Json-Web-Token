import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwttokenmcommerce/signup.dart';
import 'func.dart';
import 'package:jwttokenmcommerce/local_db.dart';

void main() => runApp(
      MaterialApp(
          //home:MyApp()
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => MyApp(),
            '/signup': (context) => Signup(),
          }),
    );

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  WooCommerce wc = new WooCommerce(
      baseUrl:
          'http://10.0.0.210:8080/WebsiteWordpressChecking/wordpress-5.2.2/wordpress', //use your own website url,and LAN connection
      consumerKey: 'ck_46bee59719510f0af6b327cae5d9450c3d9a8431', //use your own consumer key and consumer secret key
      consumerSecret: 'cs_d03fb7dd03e3611800e4f5ba20ae5e7a8ce42da6');

  @override
  Widget build(BuildContext context) {
    TextEditingController usernamecontroller = TextEditingController();
    TextEditingController passwordcontroller = TextEditingController();
    return Scaffold(
      appBar:
          AppBar(title: Text('JWT Auth Token'), backgroundColor: Colors.brown),
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: NetworkImage(
    'https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcTex2dfkMpTVMiT63QIQVCV_RoVsMelyBGnUg&usqp=CAU'),
                fit: BoxFit.fill)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(32.0, 32.0, 32.0, 12.0),
              child: TextField(
                controller: usernamecontroller,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.yellow.shade50,
                    hintText: 'username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(250.0)),
                    )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32.0, 26.0, 32.0, 12.0),
              child: TextField(
                controller: passwordcontroller,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.yellow.shade50,
                    hintText: 'password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(250.0)),
                    )),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                      child: Text('login'),
                      color: Colors.green.shade500,
                      onPressed: () async {
                        await wc.loginCustomer(
                            username: usernamecontroller.text,
                            password: passwordcontroller.text);
                        print(WooCommerce.valid);
                        setState(() {
                          if (WooCommerce.valid == true) {
                            print('successful');
                          } else {
                            print('Un successful');
                          }
                        });
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                    child: Text('sign up'),
                    color: Colors.green.shade500,
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
