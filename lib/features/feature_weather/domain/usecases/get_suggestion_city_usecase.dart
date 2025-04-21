
import 'package:echo_weather/core/usecases/use_case.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/neshan_city_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/repository/weather_repository.dart';

class GetSuggestionCityUseCase implements UseCase<List<NeshanCityItem>, String> {
  final WeatherRepository _weatherRepository;
  GetSuggestionCityUseCase(this._weatherRepository);

  @override
  Future<List<NeshanCityItem>> call(String params) {
    return _weatherRepository.fetchSuggestData(params);
  }
}