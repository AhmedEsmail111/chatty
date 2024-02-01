import 'dart:io';

import 'package:chatty/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

// a global var for initializing a firebase auth object
final _kFirebaseAuth = FirebaseAuth.instance;
// a global var for initializing a firebase storage object
final _kFirebaseStorage = FirebaseStorage.instance;

// a global var for initializing a firebase fireStore database object
final _kFirebaseFireStore = FirebaseFirestore.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<StatefulWidget> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  // a form key to get hold of the state of the form
  final _formKey = GlobalKey<FormState>();
  // a bool to control which mode we are in sign up or sign in
  var _isLogin = true;
  // var to control whether we should show a loading spinner or not
  var _isAuthenticating = false;
  // four vars to store the users's data
  var _enteredEmail = '';
  var _enteredPassword = '';
  File? _selectedImage;
  var _enteredUserName = '';
  // aethod to validate that the password ust have at least Minimum 1 Upper case,1 lowercase,
  //1 Numeric Number,1 Special Character,Common Allow Character ( ! @ # $ & * ~ )
  bool validateStructure(String value) {
    String pattern =
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(value);
  }

  //  a method to trigger the validation and saving the user inputs
  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    if (!_isLogin && _selectedImage == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
          'Please choose an Image first.',
          textAlign: TextAlign.center,
        )),
      );
      return;
    }
    _formKey.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        final userCredentials = await _kFirebaseAuth.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        final userCredentials =
            await _kFirebaseAuth.createUserWithEmailAndPassword(
                email: _enteredEmail, password: _enteredPassword);
        // upload the image to firebase and then get the URL of that Image
        final storageRef = _kFirebaseStorage
            .ref()
            .child('users_image')
            .child('${userCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);

        final imageUrl = await storageRef.getDownloadURL();
        // after awaiting to get the image url we'll upload the user's data to fireStore now
        _kFirebaseFireStore
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set(
          {
            'userName': _enteredUserName,
            'email': _enteredEmail,
            'userImage': imageUrl,
          },
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        _isAuthenticating = false;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        error.message ?? 'Operation failed!',
        textAlign: TextAlign.center,
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isLogin)
                          UserImagePicker(
                            setImage: (image) {
                              _selectedImage = image;
                            },
                          ),
                        if (!_isLogin)
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'UserName'),
                            enableSuggestions: false,
                            autocorrect: false,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.trim().length < 5) {
                                return 'Please enter at least 5 characters';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredUserName = value!;
                            },
                          ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                !value.contains('@')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredEmail = value!;
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null ||
                                value.trim().length < 6 ||
                                !validateStructure(value)) {
                              return 'Please enter a more secure password ';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredPassword = value!;
                          },
                        ),
                        const SizedBox(height: 15),
                        !_isAuthenticating
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer),
                                onPressed: _submit,
                                child: Text(_isLogin ? 'Log in' : 'Sign up'),
                              )
                            : const CircularProgressIndicator(),
                        if (!_isAuthenticating)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(_isLogin
                                ? 'Create an Account'
                                : 'I already have an Account'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
