import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:LPS/LPS.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthBio extends StatefulWidget {
  const AuthBio({Key? key}) : super(key: key);

  @override
  _AuthBioState createState() => _AuthBioState();
}

class _AuthBioState extends State<AuthBio> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    authenticateUser();
  }

  Future<void> authenticateUser() async {
    final prefs = await SharedPreferences.getInstance();
    // récupère l'état d'activation de l'authentification biométrique
    bool isAuthBioActivated = prefs.getBool('isAuthBioActivated') ?? false;
    // si elle n'est pas active alors on skip à la page principale
    if (!isAuthBioActivated) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => QRCodeScanner()));
    } else {
      bool authenticated = false;
      while (!authenticated) {
        final isAvailable = await auth.canCheckBiometrics;
        if (!isAvailable) {
          break;
        } else {
          try {
            authenticated = await auth.authenticate(
              // Texte s'affichant dans la boite de dialogue de scan d'empreinte
              // bizarrement celle-ci laisse du texte en anglais :/
              localizedReason:
                  'Scannez votre empreinte digitale pour vous authentifier',
            );
          } catch (e) {
            break;
          }
        }
      }
      // en cas d'authentification réussi on redirige vers la page de scan
      if (authenticated) {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => QRCodeScanner()));
      }
    }
  }
  // remplissage du fond

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 60,
            child: Container(
              color: Color.fromARGB(255, 255, 255, 255),
              child: Center(
                child: Image.asset('assets/keycloak_logo.png'),
              ),
            ),
          ),
          Expanded(
            flex: 40,
            child: Container(
              color: const Color.fromARGB(255, 4, 48, 99),
            ),
          ),
        ],
      ),
    );
  }
}
