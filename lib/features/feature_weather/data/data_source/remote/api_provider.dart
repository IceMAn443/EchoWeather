
import 'package:dio/dio.dart';
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/utils/constants.dart';
import 'package:echo_weather/features/feature_weather/data/models/air_quality_model.dart';
import 'package:echo_weather/features/feature_weather/data/models/meteo_current_weather_model.dart';
import 'package:echo_weather/features/feature_weather/data/models/neshan__city_model.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/meteo_murrent_weather_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/neshan_city_entity.dart';
import 'package:intl/intl.dart';

class ApiProvider {
  final Dio _dio =Dio();

  final String apiKeys = Constants.apiKey;

  Future<NeshanCityEntity> sendRequestCitySuggestion(String prefix) async {
    try {
      var response = await _dio.get(
        "https://api.neshan.org/v1/search",
        queryParameters: {
          'term': prefix,
          'lat': 35.6892,
          'lng': 51.3890,
        },
        options: Options(
          headers: {
            'Api-Key': apiKeys,
          },
        ),
      );

      if (response.statusCode == 200) {
        final model = NeshanCityModel.fromJson(response.data);
        return NeshanCityEntity(
          count: model.count,
          items: model.items?.map((item) => NeshanCityItem(
            title: item.title,
            address: item.address,
            location: item.location != null
                ? Location(x: item.location!.x, y: item.location!.y)
                : null,
          )).toList(),
        );
      }
      throw Exception('خطا در دریافت داده‌های شهر: وضعیت ${response.statusCode}');
    } catch (e) {
      throw Exception('خطا در جستجوی شهر: $e');
    }
  }

  Future<NeshanCityItem?> getCityByCoordinates(double lat, double lon) async {
    try {
      var response = await _dio.get(
        "https://api.neshan.org/v2/reverse",
        queryParameters: {
          'lat': lat,
          'lng': lon,
        },
        options: Options(
          headers: {
            'Api-Key': apiKeys,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return NeshanCityItem(
          title: data['city'] ?? data['formatted_address']?.split(',')?.first ?? 'Unknown City',
          address: data['formatted_address'],
          location: Location(x: lon, y: lat),
        );
      }
      return null;
    } catch (e) {
      print('Error in getCityByCoordinates: $e');
      return null;
    }
  }

  Future<MeteoCurrentWeatherEntity> callCurrentWeather(String cityName) async {
    try {
      final cityData = await sendRequestCitySuggestion(cityName);
      final city = cityData.items?.first;
      if (city == null || city.location == null) {
        throw Exception('شهر پیدا نشد یا مختصات نامعتبر است');
      }

      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);

      var response = await _dio.get(
        "https://api.open-meteo.com/v1/forecast",
        queryParameters: {
          'latitude': city.location!.y,
          'longitude': city.location!.x,
          'current_weather': true,
          'daily': 'sunrise,sunset',
          'start_date': today,
          'end_date': today,
          'timezone': 'Asia/Tehran',
        },
      );

      if (response.statusCode == 200) {
        final model = MeteoCurrentWeatherModel.fromJson(
          response.data,
          name: city.title,
          coord: Coord(lat: city.location!.y, lon: city.location!.x),
        );

        return MeteoCurrentWeatherEntity(
          name: model.name,
          coord: model.coord,
          sys: model.sys,
          timezone: model.timezone,
          main: model.main,
          wind: model.wind,
          weather: model.weather,
        );
      }
      throw Exception('خطا در دریافت داده‌های آب‌وهوای کنونی: وضعیت ${response.statusCode}');
    } catch (e) {
      throw Exception('خطا در دریافت آب‌وهوای کنونی: $e');
    }
  }

  /// 7 days weather api call
  Future<Map<String, dynamic>> getForecastWeather(ForecastParams params) async {
    final now = DateTime.now();
    final df = DateFormat('yyyy-MM-dd');
    final startDate = df.format(now);                   // امروز
    final endDate = df.format(now.add(const Duration(days: 14))); // هفت روز بعد

    final response = await _dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': params.lat,
        'longitude': params.lon,
        'daily': 'weathercode,temperature_2m_max',
        'hourly': 'temperature_2m,weathercode',
        'start_date': startDate,   // ← باید همین باشه
        'end_date': endDate,       // ← هفت روز جلوتر
        'timezone': 'auto',
      },
    );
    return response.data as Map<String, dynamic>;
  }


  Future<AirQualityModel> getAirQuality(ForecastParams params) async {
    try {
      final response = await _dio.get(
        'https://air-quality-api.open-meteo.com/v1/air-quality',
        queryParameters: {
          'latitude': params.lat,
          'longitude': params.lon,
          'current': 'pm10,pm2_5,ozone,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide',
          'timezone': 'Asia/Tehran',
        },
      );
      print('پاسخ خام API برای مختصات (${params.lat}, ${params.lon}): ${response.data}');
      return AirQualityModel.fromJson(response.data);
    } catch (e) {
      print('خطا در دریافت داده‌های کیفیت هوا: $e');
      throw Exception('خطا در دریافت داده‌های کیفیت هوا: $e');
    }
  }


}
