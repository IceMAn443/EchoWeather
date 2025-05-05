import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/core/services/weather_service.dart';
import 'package:echo_weather/features/feature_weather/data/models/air_quality_model.dart';
import 'package:echo_weather/features/feature_weather/data/models/weather_news_model.dart';
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

import '../../domain/entities/air_quality_entity.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCurrentWeatherUseCase getCurrentWeatherUseCase;
  final GetForecastWeatherUseCase getForecastWeatherUseCase;
  final GetAirQualityUseCase getAirQualityUseCase;
  final WeatherService weatherService = locator<WeatherService>();

  HomeBloc(this.getCurrentWeatherUseCase, this.getForecastWeatherUseCase, this.getAirQualityUseCase)
      : super(HomeState(
    cwStatus: CwLoading(),
    fwStatus: FwLoading(),
    aqStatus: AirQualityLoading(),
    weatherNews: [], // مقدار اولیه برای اخبار
  )) {
    print('HomeBloc initialized with WeatherService: $weatherService');

    // رویداد دریافت آب‌وهوای کنونی
    on<LoadCwEvent>((event, emit) async {
      emit(state.copyWith(newCwStatus: CwLoading()));
      try {
        DataState dataState;
        if (event.lat != null && event.lon != null) {
          dataState = await getCurrentWeatherUseCase({
            'cityName': event.cityName,
            'lat': event.lat!,
            'lon': event.lon!,
          });
        } else {
          dataState = await getCurrentWeatherUseCase({
            'cityName': event.cityName,
          });
        }
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

    // رویداد دریافت پیش‌بینی آب‌وهوا
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

    // رویداد دریافت کیفیت هوا
    on<LoadAirQualityEvent>((event, emit) async {
      emit(state.copyWith(newAirQualityStatus: AirQualityLoading()));
      try {
        print('درخواست کیفیت هوا برای مختصات: lat=${event.forecastParams.lat}, lon=${event.forecastParams.lon}');
        DataState dataState = await getAirQualityUseCase(event.forecastParams);
        if (dataState is DataSuccess && dataState.data != null) {
          final airQuality = dataState.data as AirQualityModel;
          final aqiResult = airQuality.calculateAqi();
          print('AQI محاسبه‌شده: ${aqiResult['aqi']}, دسته‌بندی: ${aqiResult['category']}, آلاینده غالب: ${aqiResult['dominantPollutant']}');
          emit(state.copyWith(
            newAirQualityStatus: AirQualityCompleted(
              airQualityEntity: airQuality,
              aqi: aqiResult['aqi'] as int,
              category: aqiResult['category'] as String, dominantPollutant: '',
            ),
          ));
        } else {
          final errorMessage = dataState.error ?? 'داده‌های کیفیت هوا در دسترس نیست';
          print('Air quality loading failed: $errorMessage');
          emit(state.copyWith(newAirQualityStatus: AirQualityError(errorMessage)));
        }
      } catch (e) {
        print('Error loading air quality: $e');
        emit(state.copyWith(newAirQualityStatus: AirQualityError('خطا در بارگذاری داده‌های کیفیت هوا')));
      }
    });

    // رویداد جدید برای دریافت اخبار آب‌وهوایی
    on<LoadWeatherNewsEvent>((event, emit) async {
      try {
        print('پردازش LoadWeatherNewsEvent برای شهر: ${event.cityName}');
        final news = await weatherService.fetchWeatherNews(event.cityName);
        print('اخبار دریافت‌شده: $news');
        emit(state.copyWith(weatherNews: news));
      } catch (e) {
        print('Error loading weather news: $e');
        emit(state.copyWith(weatherNews: [])); // در صورت خطا، لیست خالی
      }
    });
  }
}