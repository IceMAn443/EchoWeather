import 'package:bloc/bloc.dart';
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/resources/data_state.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_current_weather_usecase.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_forecast_weather_usecase.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/cw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/fw_status.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCurrentWeatherUseCase getCurrentWeatherUseCase;
  final GetForecastWeatherUseCase getForecastWeatherUseCase;

  HomeBloc(this.getCurrentWeatherUseCase,this.getForecastWeatherUseCase) : super(HomeState(cwStatus: CwLoading(),fwStatus: FwLoading())) {
    on<LoadCwEvent>((event, emit) async {

      /// emit State to Loading for just Cw
      emit(state.copyWith(newCwStatus: CwLoading()));

      DataState dataState = await getCurrentWeatherUseCase(event.cityName);

      /// emit State to Completed for Just Cw
      if(dataState is DataSuccess){
        emit(state.copyWith(newCwStatus: CwCompleted(dataState.data)));
      }

      /// emit State to Error for Just Cw
      if(dataState is DataFailed){
        emit(state.copyWith(newCwStatus: CwError(dataState.error!)));
      }
    });

    on<LoadFwEvent>((event, emit) async {

      /// emit State to Loading for just Fw
      emit(state.copyWith(newFwStatus: FwLoading()));

      DataState dataState = await getForecastWeatherUseCase(event.forecastParams);

      /// emit State to Completed for just Fw
      if(dataState is DataSuccess){
        emit(state.copyWith(newFwStatus: FwCompleted(dataState.data)));
      }

      /// emit State to Error for just Fw
      if(dataState is DataFailed){
        emit(state.copyWith(newFwStatus: FwError(dataState.error)));
      }

    });
  }
}