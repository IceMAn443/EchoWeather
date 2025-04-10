

import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/core/usecases/use_case.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/current_city_entities.dart';
import 'package:echo_weather/features/feature_weather/domain/repository/weather_repository.dart';

class GetCurrentWeatherUseCase extends UseCase<DataState<CurrentCityEntity>, String>{
  final WeatherRepository weatherRepository;
  GetCurrentWeatherUseCase(this.weatherRepository);

  @override
  Future<DataState<CurrentCityEntity>> call(String param) {
    // TODO: implement call
    return weatherRepository.fetchCurrentWeatherData(param);
  }
  
  
}