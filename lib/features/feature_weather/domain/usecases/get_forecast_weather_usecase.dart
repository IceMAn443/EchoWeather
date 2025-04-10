

import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/core/usecases/use_case.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/forecast_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/repository/weather_repository.dart';

class GetForecastWeatherUseCase implements UseCase<DataState<ForecastEntity>, ForecastParams>{
  final WeatherRepository _weatherRepository;
  GetForecastWeatherUseCase(this._weatherRepository);

  @override
  Future<DataState<ForecastEntity>> call(ForecastParams params) {
    return _weatherRepository.fetchForecast(params);
  }

}