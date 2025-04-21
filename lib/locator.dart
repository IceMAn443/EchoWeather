

import 'package:dio/dio.dart';
import 'package:echo_weather/core/services/weather_service.dart';
import 'package:echo_weather/features/feature_bookmark/data/data_source/local/database.dart';
import 'package:echo_weather/features/feature_bookmark/data/repository/city_repositoryImpl.dart';
import 'package:echo_weather/features/feature_bookmark/domain/repository/city_repository.dart';
import 'package:echo_weather/features/feature_bookmark/domain/usecases/delete_city_usecase.dart';
import 'package:echo_weather/features/feature_bookmark/domain/usecases/get_all_city_usecase.dart';
import 'package:echo_weather/features/feature_bookmark/domain/usecases/get_city_usecase.dart';
import 'package:echo_weather/features/feature_bookmark/domain/usecases/save_city_usecase.dart';
import 'package:echo_weather/features/feature_bookmark/presentation/bloc/bookmark_bloc.dart';
import 'package:echo_weather/features/feature_weather/data/data_source/remote/api_provider.dart';

import 'package:echo_weather/features/feature_weather/data/repository/weather_repositoryImpl.dart';
import 'package:echo_weather/features/feature_weather/domain/repository/weather_repository.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_air_quality_usecase.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_current_weather_usecase.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_forecast_weather_usecase.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_bloc.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;

setup() async {

  locator.registerLazySingleton<Dio>(() => Dio());

  locator.registerSingleton<ApiProvider>(ApiProvider());

  final database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();
  locator.registerSingleton<AppDatabase>(database);

  locator.registerSingleton<WeatherService>(WeatherService());

  ///repositories
  locator.registerSingleton<WeatherRepository>(WeatherRepositoryImpl(locator()));
  locator.registerSingleton<CityRepository>(CityRepositoryImpl(database.cityDao));


  ///use_case
  locator.registerSingleton<GetCurrentWeatherUseCase>(GetCurrentWeatherUseCase(locator()));
  locator.registerSingleton<GetForecastWeatherUseCase>(GetForecastWeatherUseCase(locator()));
  locator.registerSingleton<GetCityUseCase>(GetCityUseCase(locator()));
  locator.registerSingleton<SaveCityUseCase>(SaveCityUseCase(locator()));
  locator.registerSingleton<GetAllCityUseCase>(GetAllCityUseCase(locator()));
  locator.registerSingleton<DeleteCityUseCase>(DeleteCityUseCase(locator()));
  locator.registerLazySingleton<GetAirQualityUseCase>(() => GetAirQualityUseCase(locator()));


  locator.registerSingleton<HomeBloc>(HomeBloc(locator(),locator(),locator()));
  locator.registerSingleton<BookmarkBloc>(BookmarkBloc(locator(),locator(),locator(),locator()));
}