import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';
import 'potty_predictor.dart';
import 'seasonal.dart';

/// Avviso caldo legato all'orario della prossima uscita (06 aggiunta 20).
/// Facoltativo: usa Open-Meteo (gratuito, senza account). Viene inviata
/// solo la città (o le coordinate), nessun altro dato.
class Weather {
  static final _cache = <String, (DateTime, Map<DateTime, (double, double)>)>{};

  static Future<({double lat, double lon, String name})?> geocode(
    String city,
  ) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': city,
      'count': '1',
      'language': 'it',
    });
    final r = await http.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) return null;
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final res = (j['results'] as List?)?.cast<Map<String, dynamic>>();
    if (res == null || res.isEmpty) return null;
    return (
      lat: (res.first['latitude'] as num).toDouble(),
      lon: (res.first['longitude'] as num).toDouble(),
      name: res.first['name'] as String,
    );
  }

  /// Temperatura percepita e umidità per ora (ora locale).
  static Future<Map<DateTime, (double, double)>> hourly(
    double lat,
    double lon,
  ) async {
    final key = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    final c = _cache[key];
    if (c != null && DateTime.now().difference(c.$1).inMinutes < 60) {
      return c.$2;
    }
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lon',
      'hourly': 'apparent_temperature,relative_humidity_2m',
      'forecast_days': '2',
      'timezone': 'auto',
    });
    final r = await http.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) return const {};
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final h = j['hourly'] as Map<String, dynamic>;
    final times = (h['time'] as List).cast<String>();
    final temp = (h['apparent_temperature'] as List).cast<num?>();
    final hum = (h['relative_humidity_2m'] as List).cast<num?>();
    final out = <DateTime, (double, double)>{};
    for (var i = 0; i < times.length; i++) {
      if (temp[i] == null || hum[i] == null) continue;
      out[DateTime.parse(times[i])] = (temp[i]!.toDouble(), hum[i]!.toDouble());
    }
    _cache[key] = (DateTime.now(), out);
    return out;
  }

  /// Cani più a rischio di colpo di calore.
  static bool atRisk(Dog d, DateTime now) =>
      Breeds.isBrachy(d.breed) ||
      lifeStageOf(d, now) == LifeStage.anziano ||
      d.bodyCondition >= 7 ||
      d.weightKg >= 50 ||
      RegExp('cardi|laring|trache|respir|bronc')
          .hasMatch(d.conditions.toLowerCase());

  /// Messaggio se all'ora [at] fa troppo caldo per un'uscita, altrimenti null.
  static Future<String?> heatWarning(Dog d, DateTime at) async {
    if (!d.heatAlertsOn || d.lat == null || d.lon == null) return null;
    try {
      final data = await hourly(d.lat!, d.lon!);
      final hour = DateTime(at.year, at.month, at.day, at.hour);
      final v = data[hour];
      if (v == null) return null;
      final (t, rh) = v;
      if (t < 0) {
        return 'Alle ${hour.hour}:00 sono previsti ${t.round()} °C percepiti: '
            'uscita breve${d.weightKg < 10 ? ', cappottino' : ''}, asciugalo '
            'al rientro e sciacqua i polpastrelli dal sale antighiaccio.';
      }
      final risk = atRisk(d, at);
      final limit = risk ? 24.0 : 27.0;
      if (t < limit && !(t >= limit - 2 && rh >= 70)) return null;
      return 'Alle ${hour.hour}:00 sono previsti ${t.round()} °C percepiti'
          '${rh >= 70 ? ' con umidità alta' : ''}. '
          '${risk ? '${d.name} è più a rischio di colpo di calore. ' : ''}'
          'Fai un\'uscita breve all\'ombra, porta acqua, evita asfalto e sforzi; '
          'la passeggiata lunga nelle ore fresche. Asfalto: se non riesci a '
          'tenerci il dorso della mano per 7 secondi è troppo caldo per le zampe.';
    } catch (_) {
      return null;
    }
  }
}
