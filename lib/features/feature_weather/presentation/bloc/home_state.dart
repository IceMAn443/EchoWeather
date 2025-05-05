part of 'home_bloc.dart';

class HomeState extends Equatable {
  final CwStatus cwStatus;
  final FwStatus fwStatus;
  final AirQualityStatus aqStatus;
  final List<WeatherNews> weatherNews;

  HomeState({
    required this.cwStatus,
    required this.fwStatus,
    required this.aqStatus,
    required this.weatherNews,
  });

  HomeState copyWith({
    CwStatus? newCwStatus,
    FwStatus? newFwStatus,
    AirQualityStatus? newAirQualityStatus,
    List<WeatherNews>? weatherNews,
  }) {
    return HomeState(
      cwStatus: newCwStatus ?? this.cwStatus,
      fwStatus: newFwStatus ?? this.fwStatus,
      aqStatus: newAirQualityStatus ?? this.aqStatus,
      weatherNews: weatherNews ?? this.weatherNews,
    );
  }

  @override
  // TODO: implement props
  List<Object?> get props => [cwStatus, fwStatus, aqStatus, weatherNews];
}
