import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';
import '../widgets/precisao_chip.dart';

class GeolocalizacaoScreen extends StatefulWidget {
  /// O serviço pode ser injetado (útil nos testes de widget).
  final LocationService? locationService;

  const GeolocalizacaoScreen({super.key, this.locationService});

  @override
  State<GeolocalizacaoScreen> createState() => _GeolocalizacaoScreenState();
}

class _GeolocalizacaoScreenState extends State<GeolocalizacaoScreen> {
  late final LocationService _locationService = widget.locationService ?? LocationService();

  Position? _posicaoAtual;
  bool _carregando = false;
  String? _mensagemErro;
  StreamSubscription<Position>? _positionStreamSub;
  bool _rastreando = false;

  String _limparErro(Object erro) => erro.toString().replaceAll('Exception: ', '');

  /// Captura única da posição atual.
  Future<void> _buscarLocalizacao() async {
    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });
    try {
      final posicao = await _locationService.obterPosicaoAtual();
      if (mounted) setState(() => _posicaoAtual = posicao);
    } catch (e) {
      if (mounted) setState(() => _mensagemErro = _limparErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// Liga/desliga o rastreamento contínuo via Stream.
  Future<void> _alternarRastreamento() async {
    if (_rastreando) {
      _positionStreamSub?.cancel();
      _positionStreamSub = null;
      setState(() => _rastreando = false);
      return;
    }

    // Garante serviço ligado e permissão concedida antes de abrir o Stream.
    await _buscarLocalizacao();
    if (!mounted || _mensagemErro != null) return;

    setState(() => _rastreando = true);
    _positionStreamSub = _locationService.monitorarPosicao().listen(
      (pos) => setState(() {
        _posicaoAtual = pos;
        _mensagemErro = null;
      }),
      onError: (Object err) => setState(() {
        _mensagemErro = _limparErro(err);
        _rastreando = false;
      }),
    );
  }

  /// Desafio Avançado: abre a posição atual no Google Maps.
  Future<void> _abrirNoMapa() async {
    final pos = _posicaoAtual;
    if (pos == null) return;
    final url = Uri.parse('https://maps.google.com/?q=${pos.latitude},${pos.longitude}');
    final abriu = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o mapa.')),
      );
    }
  }

  String _formatarDistancia(double metros) => metros >= 1000
      ? '${(metros / 1000).toStringAsFixed(2)} km'
      : '${metros.toStringAsFixed(0)} m';

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = _posicaoAtual;

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in & GPS'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    if (_carregando)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_mensagemErro != null)
                      Card(
                        color: Colors.red.shade100,
                        child: ListTile(
                          leading: const Icon(Icons.error_outline, color: Colors.red),
                          title: Text(_mensagemErro!, style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                    if (pos == null && !_carregando && _mensagemErro == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(Icons.location_searching, size: 72, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Toque em "Capturar Localização Atual" para fazer o check-in.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    if (pos != null) ...[
                      if (_rastreando)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
                              SizedBox(width: 6),
                              Text('Rastreamento em tempo real ativo'),
                            ],
                          ),
                        ),
                      Card(
                        elevation: 3,
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.my_location, color: Colors.blue),
                              title: const Text('Latitude'),
                              subtitle: Text('${pos.latitude}'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.location_on, color: Colors.green),
                              title: const Text('Longitude'),
                              subtitle: Text('${pos.longitude}'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.speed, color: Colors.orange),
                              title: const Text('Precisão / Altitude'),
                              subtitle: Text(
                                'Precisão: ${pos.accuracy.toStringAsFixed(1)}m | '
                                'Alt: ${pos.altitude.toStringAsFixed(1)}m',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PrecisaoChip(precisao: pos.accuracy),
                            ),
                          ],
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.school, color: Colors.indigo),
                          title: const Text('Distância até a Fatec Matão'),
                          subtitle: Text(
                            _formatarDistancia(
                              _locationService.distanciaAteFatec(pos.latitude, pos.longitude),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: _abrirNoMapa,
                        icon: const Icon(Icons.map),
                        label: const Text('Abrir no Mapa'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _carregando ? null : _buscarLocalizacao,
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Capturar Localização Atual'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _carregando ? null : _alternarRastreamento,
                icon: Icon(_rastreando ? Icons.stop : Icons.play_arrow),
                label: Text(_rastreando ? 'Parar Rastreamento' : 'Iniciar Rastreamento Contínuo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
