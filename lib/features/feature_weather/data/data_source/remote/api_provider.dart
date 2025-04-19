
import 'package:dio/dio.dart';
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/utils/constants.dart';
import 'package:intl/intl.dart';

class ApiProvider {
  final Dio _dio =Dio();

  var apiKey = Constants.apiKeys1;

  /// current weather api call
  Future<dynamic> callCurrentWeather(cityName) async {
   var response = await _dio.get(
       '${Constants.baseUrl}/data/2.5/weather',
       queryParameters: {
        'q' : cityName,
        'appid' : apiKey,
        'units' : 'metric'
       }
   );
   return response;
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


  /// city name suggest api
  Future<dynamic> sendRequestCitySuggestion(String prefix) async {
    var response = await _dio.get(
        "http://geodb-free-service.wirefreethought.com/v1/geo/cities",
        queryParameters: {'limit': 7, 'offset': 0, 'namePrefix': prefix});

    return response;
  }


}
