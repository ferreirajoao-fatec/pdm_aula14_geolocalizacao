# Aula 14 — Geolocalização e GPS

Programação para Dispositivos Móveis I — Prof. Diego Menegassi (2026/2)

App Flutter de **check-in** que usa o sensor de GPS com o pacote [`geolocator`](https://pub.dev/packages/geolocator): verifica se o serviço de localização está ligado, solicita permissão, captura latitude/longitude/precisão/altitude e acompanha o deslocamento em tempo real com um `Stream`.

## Estrutura

| Arquivo | Responsabilidade |
|---|---|
| `lib/services/location_service.dart` | `LocationService`: checagem do serviço, permissões (`denied` / `deniedForever`), `getCurrentPosition`, `getPositionStream` (filtro de 10 m) e distância até a Fatec |
| `lib/screens/geolocalizacao_screen.dart` | `GeolocalizacaoScreen`: estados de carregamento e erro, cartão de coordenadas, rastreamento contínuo e botão do mapa |
| `lib/widgets/precisao_chip.dart` | Chip colorido de precisão |
| `lib/main.dart` | `MaterialApp` com Material 3 |
| `android/app/src/main/AndroidManifest.xml` | `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` e `<queries>` para abrir links https |
| `ios/Runner/Info.plist` | `NSLocationWhenInUseUsageDescription` |

## Desafios implementados (os três níveis)

- **Básico — Medidor de Precisão:** `Chip` verde (< 15 m), amarelo (15–50 m) ou vermelho (> 50 m).
- **Intermediário — Cálculo de Distância:** distância até a Fatec Matão com `Geolocator.distanceBetween` (exibida em m ou km).
- **Avançado — Abrir no Google Maps:** botão **Abrir no Mapa** que usa `url_launcher` para abrir `https://maps.google.com/?q=lat,lng`.

> Coordenadas da Fatec Matão usadas no cálculo (aproximadas, Av. Habib Gabriel – Residencial Olivio Benassi): `-21.6207, -48.3604`.

## Adaptações em relação ao roteiro

- `Colors.sky` não existe no Flutter; o tema usa `Colors.lightBlue`.
- O parâmetro `desiredAccuracy` está descontinuado no `geolocator` atual; foi substituído por `locationSettings: LocationSettings(accuracy: LocationAccuracy.high)`.
- Antes de iniciar o rastreamento contínuo, o app valida serviço e permissão, e os erros do `Stream` aparecem no cartão vermelho.

## Como executar

```bash
flutter pub get
flutter analyze
flutter test
flutter run   # em um dispositivo/emulador Android com localização ativada
```

No emulador Android, defina uma localização em **Extended controls → Location** para simular o GPS.
