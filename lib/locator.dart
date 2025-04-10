

import 'package:echo_weather/features/feature_weather/data/data_source/remote/api_provider.dart';

import 'package:echo_weather/features/feature_weather/data/repository/weather_repositoryImpl.dart';
import 'package:echo_weather/features/feature_weather/domain/repository/weather_repository.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_current_weather_usecase.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_forecast_weather_usecase.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_bloc.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;

setup(){

  locator.registerSingleton<ApiProvider>(ApiProvider());

  ///repositories
  locator.registerSingleton<WeatherRepository>(WeatherRepositoryImpl(locator()));
  
  ///use_case
  locator.registerSingleton<GetCurrentWeatherUseCase>(GetCurrentWeatherUseCase(locator()));
  locator.registerSingleton<GetForecastWeatherUseCase>(GetForecastWeatherUseCase(locator()));

  locator.registerSingleton<HomeBloc>(HomeBloc(locator(),locator()));
}