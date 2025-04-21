

import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/core/usecases/use_case.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/meteo_murrent_weather_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/repository/weather_repository.dart';


class GetCurrentWeatherUseCase implements UseCase<DataState<MeteoCurrentWeatherEntity>, String> {
  final WeatherRepository _weatherRepository;
  GetCurrentWeatherUseCase(this._weatherRepository);

  @override
  Future<DataState<MeteoCurrentWeatherEntity>> call(String params) {
    return _weatherRepository.fetchCurrentWeatherData(params);
  }
}