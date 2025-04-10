
import 'package:echo_weather/features/feature_weather/domain/entities/current_city_entities.dart';
import 'package:flutter/cupertino.dart';

@immutable
abstract class CwStatus{}

class CwLoading extends CwStatus{}


class CwCompleted extends CwStatus{
  final CurrentCityEntity currentCityEntity;
  CwCompleted(this.currentCityEntity);
}


class CwError extends CwStatus{
  final String message;

  CwError(this.message);
}
