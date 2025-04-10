
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/features/feature_weather/data/models/suggest_city_model.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/current_city_entities.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/forecast_entity.dart';

abstract class WeatherRepository{

  Future<DataState<CurrentCityEntity>> fetchCurrentWeatherData(String cityName);

  Future<DataState<ForecastEntity>> fetchForecast(ForecastParams params);

  Future<List<Data>> fetchSuggestData(cityName);

}