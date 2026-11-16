import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:pdm_aula14_geolocalizacao/screens/geolocalizacao_screen.dart';
import 'package:pdm_aula14_geolocalizacao/services/location_service.dart';
import 'package:pdm_aula14_geolocalizacao/widgets/precisao_chip.dart';

Position _posicao({double lat = -21.6207, double lng = -48.3604, double precisao = 8}) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026),
      accuracy: precisao,
      altitude: 580,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 0,
    );

class _ServicoFake extends LocationService {
  final Position? posicao;
  final Object? erro;

  _ServicoFake({this.posicao, this.erro});

  @override
  Future<Position> obterPosicaoAtual() async {
    if (erro != null) throw erro!;
    return posicao!;
  }

  @override
  Stream<Position> monitorarPosicao() => Stream.value(posicao!);

  @override
  double distanciaAteFatec(double latitude, double longitude) => 1500;
}

Widget _app(LocationService servico) =>
    MaterialApp(home: GeolocalizacaoScreen(locationService: servico));

void main() {
  testWidgets('exibe coordenadas, precisão e distância após a captura', (tester) async {
    await tester.pumpWidget(_app(_ServicoFake(posicao: _posicao())));
    await tester.tap(find.text('Capturar Localização Atual'));
    await tester.pumpAndSettle();

    expect(find.text('-21.6207'), findsOneWidget);
    expect(find.text('-48.3604'), findsOneWidget);
    expect(find.text('Precisão Alta (8.0 m)'), findsOneWidget);
    expect(find.text('1.50 km'), findsOneWidget);
    expect(find.text('Abrir no Mapa'), findsOneWidget);
  });

  testWidgets('exibe mensagem amigável quando a permissão é negada', (tester) async {
    await tester.pumpWidget(_app(
      _ServicoFake(erro: Exception('Permissão de localização negada pelo usuário.')),
    ));
    await tester.tap(find.text('Capturar Localização Atual'));
    await tester.pumpAndSettle();

    expect(find.text('Permissão de localização negada pelo usuário.'), findsOneWidget);
  });

  testWidgets('alterna o rastreamento contínuo', (tester) async {
    await tester.pumpWidget(_app(_ServicoFake(posicao: _posicao())));
    await tester.tap(find.text('Iniciar Rastreamento Contínuo'));
    await tester.pumpAndSettle();
    expect(find.text('Parar Rastreamento'), findsOneWidget);
    expect(find.text('Rastreamento em tempo real ativo'), findsOneWidget);

    await tester.tap(find.text('Parar Rastreamento'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar Rastreamento Contínuo'), findsOneWidget);
  });

  testWidgets('chip de precisão muda conforme a faixa', (tester) async {
    for (final (valor, rotulo) in [(10.0, 'Alta'), (30.0, 'Média'), (80.0, 'Baixa')]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PrecisaoChip(precisao: valor))));
      expect(find.textContaining('Precisão $rotulo'), findsOneWidget);
    }
  });

  test('distância real até a Fatec usa Geolocator.distanceBetween', () {
    final metros = LocationService().distanciaAteFatec(-21.6036, -48.3658);
    expect(metros, greaterThan(1000));
    expect(metros, lessThan(3000));
  });
}
