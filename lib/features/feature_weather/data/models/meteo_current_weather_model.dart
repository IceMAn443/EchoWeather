

import 'package:echo_weather/features/feature_weather/domain/entities/meteo_current_weather_entity.dart';

class MeteoCurrentWeatherModel extends MeteoCurrentWeatherEntity {
  MeteoCurrentWeatherModel({
    String? name,
    Coord? coord,
    Sys? sys,
    int? timezone,
    double? temperature,
    int? humidity,
    double? pressure,
    double? windSpeed,
    int? windDirection,
    int? weatherCode,
    String? description,
    String? sunrise,
    String? sunset,
  }) : super(
    name: name,
    coord: coord,
    sys: sys ?? Sys(sunrise: sunrise, sunset: sunset),
    timezone: timezone,
    main: Main(
      temp: temperature,
      humidity: humidity,
      pressure: pressure?.toInt(),
    ),
    wind: Wind(
      speed: windSpeed,
      deg: windDirection,
    ),
    weather: weatherCode != null && description != null
        ? [Weather(id: weatherCode, description: description)]
        : [],
  );

  factory MeteoCurrentWeatherModel.fromJson(Map<String, dynamic> json, {String? name, Coord? coord}) {
    print('JSON دریافتی: $json');
    final current = json['current'] ?? {};
    final daily = json['daily'] ?? {};
    final weatherCode = current['weathercode'] as int?;

    final timezoneStr = json['timezone'] as String? ?? 'UTC';
    final timezoneOffset = _getTimezoneOffset(timezoneStr);

    return MeteoCurrentWeatherModel(
      name: name ?? json['city_name'] as String?,
      coord: coord ?? Coord(
        lat: json['latitude'] is num ? json['latitude'].toDouble() : null,
        lon: json['longitude'] is num ? json['longitude'].toDouble() : null,
      ),
      temperature: current['temperature_2m'] as double?,
      humidity: current['relativehumidity_2m'] as int?,
      pressure: current['pressure_msl'] as double?,
      windSpeed: current['windspeed_10m'] as double?,
      windDirection: current['winddirection_10m'] as int?,
      weatherCode: weatherCode,
      description: weatherCode != null ? _mapWeatherCodeToDescription(weatherCode, 'fa') : 'نامشخص',
      timezone: timezoneOffset,
      sunrise: daily['sunrise'] is List && daily['sunrise'].isNotEmpty ? daily['sunrise'][0] as String? : null,
      sunset: daily['sunset'] is List && daily['sunset'].isNotEmpty ? daily['sunset'][0] as String? : null,
    );
  }

  // متد استاتیک برای تبدیل weatherCode به توضیحات
  static String _mapWeatherCodeToDescription(int code, String lang) {
    Map<int, String> weatherDescriptions = {
      0: 'آفتابی',
      1: 'کمی ابری',
      2: 'ابری',
      3: 'ابری کامل',
      45: 'مه',
      48: 'مه شدید',
      51: 'باران ریز سبک',
      53: 'باران ریز',
      55: 'باران ریز شدید',
      56: 'باران ریز یخ‌زده',
      57: 'باران ریز یخ‌زده شدید',
      61: 'باران سبک',
      63: 'باران',
      65: 'باران شدید',
      66: 'باران یخ‌زده سبک',
      67: 'باران یخ‌زده شدید',
      71: 'برف سبک',
      73: 'برف',
      75: 'برف شدید',
      77: 'دانه برف',
      80: 'رگبار سبک',
      81: 'رگبار',
      82: 'رگبار شدید',
      85: 'برف سبک',
      86: 'برف شدید',
      95: 'رعد و برق',
      96: 'رعد و برق با تگرگ سبک',
      99: 'رعد و برق با تگرگ شدید',
    };

    return weatherDescriptions[code] ?? 'ناشناخته';
  }

  // متد برای تبدیل timezone به offset ثانیه‌ای
  static int _getTimezoneOffset(String timezone) {
    const timezoneOffsets = {
      'UTC': 0,
      'Asia/Tehran': 12600, // +03:30 (3 ساعت و 30 دقیقه = 12600 ثانیه)
    };
    return timezoneOffsets[timezone] ?? 0;
  }
}