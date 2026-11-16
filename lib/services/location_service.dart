import 'package:geolocator/geolocator.dart';

/// Camada de serviço que isola as validações de segurança do GPS
/// (serviço ligado e permissões) e a busca de coordenadas.
class LocationService {
  /// Coordenadas aproximadas da Fatec Matão "Luiz Marchesan"
  /// (Av. Habib Gabriel, 1360 – Residencial Olivio Benassi, Matão-SP).
  static const double fatecLatitude = -21.6207;
  static const double fatecLongitude = -48.3604;

  static const LocationSettings _configuracao = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  /// Verifica serviço e permissões antes de capturar a posição atual.
  Future<Position> obterPosicaoAtual() async {
    final servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) {
      throw Exception('O serviço de GPS está desativado no dispositivo.');
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        throw Exception('Permissão de localização negada pelo usuário.');
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception('Permissões negadas permanentemente. Altere nas configurações.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Fluxo contínuo de posições (atualiza a cada 10 metros percorridos).
  Stream<Position> monitorarPosicao() {
    return Geolocator.getPositionStream(locationSettings: _configuracao);
  }

  /// Desafio Intermediário: distância em metros até a Fatec Matão.
  double distanciaAteFatec(double latitude, double longitude) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      fatecLatitude,
      fatecLongitude,
    );
  }
}
