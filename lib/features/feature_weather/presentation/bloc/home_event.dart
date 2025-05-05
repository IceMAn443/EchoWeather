import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class LoadCwEvent extends HomeEvent {
  final String cityName;
  final double? lat;
  final double? lon;

  const LoadCwEvent(this.cityName, {this.lat, this.lon});

  @override
  List<Object> get props => [cityName, lat ?? 0.0, lon ?? 0.0];
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

class LoadWeatherNewsEvent extends HomeEvent {
  final String cityName;
  LoadWeatherNewsEvent(this.cityName);
  @override
  List<Object> get props => [cityName];
}