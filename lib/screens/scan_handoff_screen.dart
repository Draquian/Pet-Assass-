import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/game_state.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';

/// S'obre quan el jugador prem "He eliminat al meu objectiu". Espera
/// a escanear el QR que la víctima generarà en el seu propi mòbil al
/// confirmar "m'han eliminat". Aquest QR conté el següent objectiu,
/// que passa a ser el nostre.
///
/// En mode multidispositiu, el 'killer' és sempre el jugador actual
/// (widget.state.myName): no cal enviar-lo en el QR perquè el cazador
/// ja sap qui és.
class ScanHandoffScreen extends StatefulWidget {
  final GameState state;

  const ScanHandoffScreen({super.key, required this.state});

  @override
  State<ScanHandoffScreen> createState() => _ScanHandoffScreenState();
}

class _ScanHandoffScreenState extends State<ScanHandoffScreen> {
  bool _handled = false;
  String? _error;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null) return;

    final data = CryptoService.decryptJson(raw);
    if (data == null || data['type'] != 'handoff') {
      setState(() => _error = 'Aquest codi no és un traspàs d\'objectiu vàlid.');
      return;
    }
    if (data['gameId'] != widget.state.gameId) {
      setState(() => _error = 'Aquest codi pertany a una altra partida.');
      return;
    }
    final eliminated = data['eliminated'] as String;
    if (eliminated != widget.state.currentTarget) {
      setState(() => _error = 'Aquest codi no correspon a l\'objectiu actual.');
      return;
    }

    _handled = true;
    final nextTarget = data['nextTarget'] as String;
    final isWinner = nextTarget == widget.state.myName;
    final nextItem = (data['nextItem'] as String?) ?? widget.state.assignedItem;

    // lastWords del QR (pot ser null si la víctima no n'ha escrit)
    // Es podria guardar localment per a una pantalla de resum futura.
    // Per ara, es llegeix però no es persisteix (multi-device no té historial centralitzat).
    // final lastWords = data['lastWords'] as String?;

    final newState = GameState(
      gameId: widget.state.gameId,
      myName: widget.state.myName,
      myPin: widget.state.myPin,
      status: isWinner ? PlayerStatus.winner : PlayerStatus.alive,
      currentTarget: isWinner ? null : nextTarget,
      gameMode: widget.state.gameMode,
      assignedItem: isWinner ? null : nextItem,
      myHunter: widget.state.myHunter,
    );
    await StorageService.saveState(newState);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escaneja el codi del teu objectiu')),
      body: Column(
        children: [
          Expanded(child: MobileScanner(onDetect: _onDetect)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Demana al teu objectiu que confirmi la seva eliminació al seu mòbil '
              'i et mostri el codi que li apareixerà.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
