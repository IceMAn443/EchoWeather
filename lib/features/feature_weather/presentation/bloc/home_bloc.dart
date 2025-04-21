import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/core/services/weather_service.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_air_quality_usecase.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_current_weather_usecase.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_forecast_weather_usecase.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/aq_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/cw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/fw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_event.dart';
import 'package:echo_weather/locator.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCurrentWeatherUseCase getCurrentWeatherUseCase;
  final GetForecastWeatherUseCase getForecastWeatherUseCase;
  final GetAirQualityUseCase getAirQualityUseCase;
  final WeatherService weatherService = locator<WeatherService>();

  HomeBloc(this.getCurrentWeatherUseCase, this.getForecastWeatherUseCase, this.getAirQualityUseCase)
      : super(HomeState(cwStatus: CwLoading(), fwStatus: FwLoading(), aqStatus: AirQualityLoading())) {
    print('HomeBloc initialized with WeatherService: $weatherService');
    on<LoadCwEvent>((event, emit) async {
      emit(state.copyWith(newCwStatus: CwLoading()));
      try {
        DataState dataState = await getCurrentWeatherUseCase(event.cityName);
        if (dataState is DataSuccess) {
          emit(state.copyWith(newCwStatus: CwCompleted(dataState.data)));
        } else {
          emit(state.copyWith(newCwStatus: CwError(dataState.error)));
        }
      } catch (e) {
        print('Error loading current weather: $e');
        emit(state.copyWith(newCwStatus: CwError(e.toString())));
      }
    });

    on<LoadFwEvent>((event, emit) async {
      emit(state.copyWith(newFwStatus: FwLoading()));
      try {
        DataState dataState = await getForecastWeatherUseCase(event.forecastParams);
        if (dataState is DataSuccess) {
          emit(state.copyWith(newFwStatus: FwCompleted(dataState.data)));
        } else {
          emit(state.copyWith(newFwStatus: FwError(dataState.error)));
        }
      } catch (e) {
        print('Error loading forecast: $e');
        emit(state.copyWith(newFwStatus: FwError(e.toString())));
      }
    });

    on<LoadAirQualityEvent>((event, emit) async {
      emit(state.copyWith(newAirQualityStatus: AirQualityLoading()));
      try {
        print('درخواست کیفیت هوا برای مختصات: lat=${event.forecastParams.lat}, lon=${event.forecastParams.lon}');
        DataState dataState = await getAirQualityUseCase(event.forecastParams);
        if (dataState is DataSuccess) {
          final airQuality = dataState.data;
          final aqiResult = airQuality.calculateAqi();
          print('AQI محاسبه‌شده: ${aqiResult['aqi']}, دسته‌بندی: ${aqiResult['category']}, آلاینده غالب: ${aqiResult['dominantPollutant']}');
          emit(state.copyWith(
            newAirQualityStatus: AirQualityCompleted(
              airQualityEntity: airQuality,
              aqi: aqiResult['aqi'],
              category: aqiResult['category'],
              dominantPollutant: aqiResult['dominantPollutant'],
            ),
          ));
        } else {
          print('Air quality loading failed: ${dataState.error}');
          emit(state.copyWith(newAirQualityStatus: AirQualityError(dataState.error)));
        }
      } catch (e) {
        print('Error loading air quality: $e');
        emit(state.copyWith(newAirQualityStatus: AirQualityError(e.toString())));
      }
    });
  }
}