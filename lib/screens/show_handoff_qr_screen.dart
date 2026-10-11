import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/game_state.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';

/// Se obre quan el jugador prem "M'han eliminat". Tras confirmar
/// (acció irreversible), demana les últimes paraules opcionals i
/// genera un QR de traspàs perquè el seu killer l'escaneji.
///
/// Payload resultant inclou:
/// - type: 'handoff'
/// - gameId, eliminated, nextTarget, nextItem  (com abans)
/// - lastWords: text opcional de l'eliminat (si n'ha escrit)
///
/// Nota: el camp 'killer' NO s'inclou aquí perquè és l'escàner (cazador)
/// qui coneix la seva pròpia identitat; no cal enviar-la en el QR.
class ShowHandoffQrScreen extends StatefulWidget {
  final GameState state;

  const ShowHandoffQrScreen({super.key, required this.state});

  @override
  State<ShowHandoffQrScreen> createState() => _ShowHandoffQrScreenState();
}

class _ShowHandoffQrScreenState extends State<ShowHandoffQrScreen> {
  bool _confirmed = false;
  String? _lastWords;

  final _lastWordsController = TextEditingController();

  @override
  void dispose() {
    _lastWordsController.dispose();
    super.dispose();
  }

  Future<void> _markEliminated() async {
    final newState = GameState(
      gameId: widget.state.gameId,
      myName: widget.state.myName,
      myPin: widget.state.myPin,
      status: PlayerStatus.eliminated,
      currentTarget: null,
      gameMode: widget.state.gameMode,
    );
    await StorageService.saveState(newState);
    setState(() {
      _lastWords = _lastWordsController.text.trim().isEmpty
          ? null
          : _lastWordsController.text.trim();
      _confirmed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_confirmed) {
      return Scaffold(
        appBar: AppBar(title: const Text('M\'han eliminat')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirma nomes quan algú t\'hagi eliminat.\n'
                'Al confirmar, es generarà un codi que ha '
                'd\'escanear qui t\'ha eliminat.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Últimes paraules opcional
              const Text(
                'Últimes paraules (opcional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lastWordsController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Escriu alguna cosa abans de ser eliminat...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _markEliminated,
                child: const Text('M\'han eliminat'),
              ),
            ],
          ),
        ),
      );
    }

    // widget.state.currentTarget és l'objectiu que tenia ABANS de ser
    // eliminat: és just el que ha d'heretar qui acaba de caçar-lo.
    final payload = <String, dynamic>{
      'type': 'handoff',
      'gameId': widget.state.gameId,
      'eliminated': widget.state.myName,
      'nextTarget': widget.state.currentTarget,
      'nextItem': widget.state.assignedItem,
      // 'killer' NO s'inclou: el cazador ja sap que és ell.
      if (_lastWords != null) 'lastWords': _lastWords,
    };
    final encrypted = CryptoService.encryptJson(payload);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ensenya aquest codi'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Que qui t\'ha eliminat escaneji aquest codi amb el seu mòbil.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: encrypted,
                  version: QrVersions.auto,
                  size: 260,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ja l\'han escanejat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
