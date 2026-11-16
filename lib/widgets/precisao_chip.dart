import 'package:flutter/material.dart';

/// Desafio Básico: indicador visual da precisão do GPS.
/// Verde (< 15 m), amarelo (15–50 m) e vermelho (> 50 m).
class PrecisaoChip extends StatelessWidget {
  final double precisao;

  const PrecisaoChip({super.key, required this.precisao});

  @override
  Widget build(BuildContext context) {
    final (cor, rotulo, icone) = switch (precisao) {
      < 15 => (Colors.green, 'Alta', Icons.gps_fixed),
      <= 50 => (Colors.amber, 'Média', Icons.gps_not_fixed),
      _ => (Colors.red, 'Baixa', Icons.gps_off),
    };

    return Chip(
      avatar: Icon(icone, color: Colors.white, size: 18),
      label: Text(
        'Precisão $rotulo (${precisao.toStringAsFixed(1)} m)',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: cor.shade700,
      side: BorderSide.none,
    );
  }
}
