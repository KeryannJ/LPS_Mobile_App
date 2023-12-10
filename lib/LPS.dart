import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'DashedRectangle.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'AuthBio.dart';
import 'package:flutter/services.dart';

void main() => runApp(LPS());

class LPS extends StatelessWidget {
  LPS({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return MaterialApp(
        title: "Login Par Smartphone",
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 4, 48, 99),
              brightness: Brightness.light),
          textTheme: TextTheme(
            displayLarge: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const AuthBio());
  }
}

// classe du lecteur de QRCode
class QRCodeScanner extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRCodeScannerState();
}

class _QRCodeScannerState extends State<QRCodeScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // extrait le nom de domaine au lieu d'afficher toute l'url un peu mieux
  // pour l'utilisateur
  String extractDomain(String? url) {
    RegExp domainRegex = RegExp(r'(?<=://)([^/]+)');
    Match? match = domainRegex.firstMatch(url!);
    return match?.group(0) ?? '';
  }

  // variable conteant le résultat de la lecture du code barre
  Barcode? result;
  // sert à vider le buffer
  QRViewController? controller;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Scanner QR Code',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 4, 48, 99),
      ),
      // corps de la page ( appareil photo )
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
                Positioned(
                  child: CustomPaint(
                    size: Size(250, 250),
                    painter: DashedRectPainter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // lance une web view au sein d'une alertbox afin d'afficher la page de connexion
  // keycloak ce qui beaucoup plus agréable qu'un simple urlLauncher
  void _launchURLInWebView(Uri url, QRViewController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.fromLTRB(10, 100, 10, 20),
          backgroundColor: Colors.grey[850],
          content: Container(
            height: double.infinity,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
            child: WebViewWidget(
              controller: WebViewController()..loadRequest(url),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Fermer', style: TextStyle(color: Colors.white)),
              onPressed: () {
                controller.resumeCamera(); // redémarre la caméra
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera(); // Pause la caméra
      setState(() {
        result = scanData;
      });

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Connexion"),
            content: Text(
                "Voulez-vous vous connecter à ${extractDomain(result?.code)}"),
            actions: <Widget>[
              TextButton(
                child: Text("Non"),
                onPressed: () {
                  Navigator.of(context).pop(); // Ferme la boîte de dialogue
                },
              ),
              TextButton(
                child: Text("Oui"),
                onPressed: () async {
                  Navigator.of(context).pop(); // Ferme la boîte de dialogue
                  if (result?.code != null) {
                    final Uri? uri = Uri.tryParse(result!.code!);
                    if (uri != null) {
                      _launchURLInWebView(uri, controller);
                    }
                  } else {
                    print('Impossible de lancer l\'URL ${result!.code}');
                  }
                },
              )
            ],
          );
        },
      );
    });
  }

  // désallocation de la mémoire du buffer de lecture du QRCOde
  @override
  void dispose() {
    controller?.dispose;
    super.dispose();
  }
}
