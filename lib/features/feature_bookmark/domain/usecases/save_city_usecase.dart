import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/core/usecases/use_case.dart';
import 'package:echo_weather/features/feature_bookmark/domain/entities/city_entity.dart';
import 'package:echo_weather/features/feature_bookmark/domain/repository/city_repository.dart';

class SaveCityUseCase implements UseCase<DataState<City>, String>{
  final CityRepository _cityRepository;
  SaveCityUseCase(this._cityRepository);

  @override
  Future<DataState<City>> call(String params) {
    return _cityRepository.saveCityToDB(params);
  }
}