
import 'package:dio/dio.dart';
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/features/feature_weather/data/data_source/remote/api_provider.dart';
import 'package:echo_weather/features/feature_weather/data/models/forecast_model.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/air_quality_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/forecast_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/meteo_murrent_weather_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/neshan_city_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/repository/weather_repository.dart';

import '../models/forecast_model.dart';


class WeatherRepositoryImpl extends WeatherRepository{
  ApiProvider _apiProvider;

  WeatherRepositoryImpl(this._apiProvider);

  @override
    Future<DataState<MeteoCurrentWeatherEntity>> fetchCurrentWeatherData(String cityName) async {
      try {
        MeteoCurrentWeatherEntity currentWeatherEntity = await _apiProvider.callCurrentWeather(cityName);
        return DataSuccess(currentWeatherEntity);
      } catch (e) {
        print(e.toString());
        return DataFailed("please check your connection...");
      }
    }


  @override
  Future<DataState<ForecastEntity>> fetchForecast(ForecastParams params) async {
    try {
      final json = await _apiProvider.getForecastWeather(params);
      final forecast = ForecastModel.fromJson(json);
      return DataSuccess(forecast);
    } catch (e) {
      return DataFailed("خطا در دریافت پیش‌بینی: ${e.toString()}");
    }
  }

  @override
    Future<List<NeshanCityItem>> fetchSuggestData(String cityName) async {
      try {
        NeshanCityEntity suggestCityEntity = await _apiProvider.sendRequestCitySuggestion(cityName);
        return suggestCityEntity.items ?? [];
      } catch (e) {
        print(e.toString());
        throw Exception("please check your connection...");
      }
    }

    @override
    Future<DataState<AirQualityEntity>> getAirQuality(ForecastParams params) async {
      try {
        AirQualityEntity airQualityEntity = await _apiProvider.getAirQuality(params);
        return DataSuccess(airQualityEntity);
      } catch (e) {
        return DataFailed("خطا در دریافت پیش‌بینی: ${e.toString()}");
      }
    }
}