import 'dart:async';
import 'package:flutter/material.dart';
import 'package:novus/widgets/HeaderWidget.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  String chosenUsername;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formkey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context, title: 'Create Account', enableBackButton: true),
      body: Center(
        child: Column(
          children: [
            Text(
              "Enter a username",
              style: TextStyle(fontSize: 16.0, color: Colors.white),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Form(
                key: _formkey,
                child: TextFormField(
                  style: TextStyle(color: Colors.white),
                  onSaved: (newValue) => chosenUsername = newValue,
                  decoration: InputDecoration(
                    hintText: 'e.g. Novus123',
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                    disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value.trim().length < 4 || value.isEmpty)
                      return "username is too short";
                    else if (value.trim().length > 13)
                      return "username is too long";
                    else
                      return null;
                  },
                ),
              ),
            ),
            Container(
              width: 85,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextButton(
                onPressed: submitUsername,
                child: Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  submitUsername() {
    final form = _formkey.currentState;
    if (form.validate()) {
      form.save();
      SnackBar snackBar = SnackBar(content: Text('Welcome ' + chosenUsername + ' to Novus'));
      
      _scaffoldKey.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 4), () => Navigator.pop(context, chosenUsername));
    }
  }
}
