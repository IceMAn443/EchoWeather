
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/air_quality_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/forecast_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/meteo_current_weather_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/neshan_city_entity.dart';

import '../../data/models/weather_news_model.dart';

abstract class WeatherRepository{

  Future<DataState<MeteoCurrentWeatherEntity>> fetchCurrentWeatherData(String cityName);

  Future<DataState<ForecastEntity>> fetchForecast(ForecastParams params);

  Future<List<NeshanCityItem>> fetchSuggestData(String cityName);

  Future<DataState<AirQualityEntity>> getAirQuality(ForecastParams params);

  Future<DataState<List<WeatherNews>>> fetchWeatherNews(String cityName);

  Future<DataState<MeteoCurrentWeatherEntity>> getCurrentWeatherByCoordinates(double lat, double lon);



}