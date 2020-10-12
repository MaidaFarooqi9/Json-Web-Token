import 'dart:convert' show json, base64, ascii;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwttokenmcommerce/woocommerce_customer.dart';
import 'func.dart';
class Signup extends StatefulWidget {
  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
 WooCommerce wc=new WooCommerce(baseUrl: 'http://10.0.0.210:8080/WebsiteWordpressChecking/wordpress-5.2.2/wordpress', consumerKey: 'ck_46bee59719510f0af6b327cae5d9450c3d9a8431', consumerSecret: 'cs_d03fb7dd03e3611800e4f5ba20ae5e7a8ce42da6');
 Future<int> attemptSignUp(String email,String username, String password) async {
   SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
   var res = await http.post(
     'http://10.0.0.210:8080/WebsiteWordpressChecking/wordpress-5.2.2/wordpress/customers?consumer_key=ck_46bee59719510f0af6b327cae5d9450c3d9a8431&consumer_secret=cs_d03fb7dd03e3611800e4f5ba20ae5e7a8ce42da6',
     body: json.encode({
       'email': email,
       'username': username,
       'password': password,
     }),
     headers: {"Content-Type": "application/json"},
   );
   print(res.body);
   print(res.statusCode);
   var jsondata = null;
   if (res.statusCode == 200) {
     jsondata = json.decode(res.body);
     sharedPreferences.setString("token", jsondata['token']);
   } else {
     print(jsondata);
     print(res.statusCode);
     print(res.body);
     return res.statusCode;
   }
 }

 @override
  Widget build(BuildContext context) {
    TextEditingController tce = TextEditingController();
    TextEditingController tcp = TextEditingController();
    TextEditingController tcu = TextEditingController();
    TextEditingController tcf = TextEditingController();
    TextEditingController tcl = TextEditingController();

    return Scaffold(
       appBar: AppBar(title:Text('Signup'),backgroundColor: Colors.brown,),
        body: Container(
          decoration: BoxDecoration(
              image:DecorationImage(image:NetworkImage('https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcTex2dfkMpTVMiT63QIQVCV_RoVsMelyBGnUg&usqp=CAU'),fit:BoxFit.fill)
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[

                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: tce,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.yellow.shade50,
                          hintText: 'email',
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(250.0)),)
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: tcp,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.yellow.shade50,
                          hintText: 'password',
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(250.0)),)
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: tcu,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.yellow.shade50,
                          hintText: 'username',
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(250.0)),)
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: tcf,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.yellow.shade50,
                          hintText: 'First name',
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(250.0)),)
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: tcl,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.yellow.shade50,
                          hintText: 'Last name',
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(250.0)),)
                      ),
                    ),
                  ),


                  RaisedButton(child:Text('Create My Account'),color:Colors.green.shade500,onPressed: ()async{
                    WooCustomer user = WooCustomer(username: tcu.text, password: tcp.text,email: tce.text,firstName: tcf.text,lastName:tcl.text);//id and datetime will be generated automatically
                     await wc.createCustomer(user);

                  },)
                ],
              ),
            ),
          ),
        ),


    );
  }
}


