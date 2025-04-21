

import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/core/usecases/use_case.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/air_quality_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/repository/weather_repository.dart';

class GetAirQualityUseCase implements UseCase<DataState<AirQualityEntity>, ForecastParams>{
  final WeatherRepository _weatherRepository;

  GetAirQualityUseCase(this._weatherRepository);

  @override
  Future<DataState<AirQualityEntity>> call(ForecastParams params) {
    return _weatherRepository.getAirQuality(params);
  }
}