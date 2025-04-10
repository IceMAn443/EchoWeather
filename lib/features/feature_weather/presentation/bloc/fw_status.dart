
import 'package:echo_weather/features/feature_weather/domain/entities/forecast_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
abstract class FwStatus extends Equatable {}

/// حالت Loading
class FwLoading extends FwStatus {
  @override
  List<Object?> get props => [];
}

/// حالت Loaded - شامل پیش‌بینی روزانه و ساعتی با ForecastEntity
class FwCompleted extends FwStatus {
  final ForecastEntity forecastEntity;

  FwCompleted(this.forecastEntity);

  @override
  List<Object?> get props => [forecastEntity];
}

/// حالت Error
class FwError extends FwStatus {
  final String? message;

  FwError(this.message);

  @override
  List<Object?> get props => [message];
}
