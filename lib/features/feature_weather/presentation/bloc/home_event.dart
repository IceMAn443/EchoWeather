import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class LoadCwEvent extends HomeEvent {
  final String cityName;
  const LoadCwEvent(this.cityName);

  @override
  List<Object> get props => [cityName];
}

class LoadFwEvent extends HomeEvent {
  final ForecastParams forecastParams;
  const LoadFwEvent(this.forecastParams);

  @override
  List<Object> get props => [forecastParams];
}

class LoadAirQualityEvent extends HomeEvent {
  final ForecastParams forecastParams;

  const LoadAirQualityEvent(this.forecastParams);

  @override
  List<Object> get props => [ forecastParams];
}