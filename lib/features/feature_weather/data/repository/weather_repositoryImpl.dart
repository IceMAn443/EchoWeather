
import 'package:dio/dio.dart';
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/features/feature_weather/data/data_source/remote/api_provider.dart';
import 'package:echo_weather/features/feature_weather/data/models/current_city_model.dart';
import 'package:echo_weather/features/feature_weather/data/models/forecast_model.dart';
import 'package:echo_weather/features/feature_weather/data/models/suggest_city_model.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/current_city_entities.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/forecast_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/suggest_city_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/repository/weather_repository.dart';

import '../models/forecast_model.dart';


class WeatherRepositoryImpl extends WeatherRepository{
  ApiProvider apiProvider;

  WeatherRepositoryImpl(this.apiProvider);

  @override
  Future<DataState<CurrentCityEntity>> fetchCurrentWeatherData(String cityName) async {

    try{
      Response response = await apiProvider.callCurrentWeather(cityName);
      if(response.statusCode == 200){
        CurrentCityEntity currentCityEntity = CurrentCityModel.fromJson(response.data);

        return DataSuccess(currentCityEntity);
      }else{
        return const DataFailed("Something Went Wrong. try again...");
      }
    }catch(e){
      return const DataFailed("please check your connection...");
    }
  }


  @override
  Future<DataState<ForecastEntity>> fetchForecast(ForecastParams params) async {
    try {
      final json = await apiProvider.getForecastWeather(params);
      final forecast = ForecastModel.fromJson(json);
      return DataSuccess(forecast);
    } catch (e) {
      return DataFailed("خطا در دریافت پیش‌بینی: ${e.toString()}");
    }
  }

  @override
  Future<List<Data>> fetchSuggestData(cityName) async {

    Response response = await apiProvider.sendRequestCitySuggestion(cityName);

    SuggestCityEntity suggestCityEntity = SuggestCityModel.fromJson(response.data);

    return suggestCityEntity.data!;

  }
}