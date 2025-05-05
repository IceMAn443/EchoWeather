import 'package:echo_weather/features/feature_weather/domain/entities/forecast_entity.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/fw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> with AutomaticKeepAliveClientMixin {
  // ثابت‌ها برای مقادیر ثابت
  static const double columnWidth = 80;
  static const double tempBarHeight = 120;
  static const double tempBarWidth = 40; // عرض جدید برای نوار دما
  static const double spacingSmall = 14;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
          child: BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (prev, curr) => prev.fwStatus != curr.fwStatus,
            builder: (context, state) {
              if (state.fwStatus is FwLoading) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (state.fwStatus is FwError) {
                return const Center(
                  child: Text(
                    "Error loading forecast",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                );
              }

              if (state.fwStatus is FwCompleted) {
                final forecast = (state.fwStatus as FwCompleted).forecastEntity;
                final forecastDays = forecast.days;

                // دیباگ
                print("Forecast Days: $forecastDays");
                for (var day in forecastDays) {
                  print("Day: ${day.date}, Chance of Rain: ${day.chanceOfRain}");
                }

                if (forecastDays.isEmpty) {
                  return const Center(
                    child: Text(
                      "No forecast data available",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: spacingSmall),
                      child: Text(
                        DateFormat('MMMM').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: spacingMedium),
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: forecastDays.length,
                        itemBuilder: (context, index) {
                          return _buildDayForecastItem(forecastDays[index], index);
                        },
                        separatorBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 45),
                          child: Container(
                            width: 1,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDayForecastItem(ForecastDayEntity day, int index) {
    final date = _parseDate(day.date);
    final minTemp = day.minTempC.round();
    final maxTemp = day.maxTempC.round();

    return Container(
      width: columnWidth,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        children: [
          // Day and Date
          Text(
            DateFormat('E').format(date),
            style: TextStyle(
              color: index == 0 ? Colors.white : Colors.white70,
              fontSize: 16,
              fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: spacingLarge),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == 0 ? Colors.white : Colors.transparent,
            ),
            child: Text(
              DateFormat('d').format(date),
              style: TextStyle(
                color: index == 0 ? Colors.black : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: spacingLarge),
          // Weather Icon
          Image.asset(
            day.conditionIcon,
            width: 52,
            height: 52,
            errorBuilder: (c, e, s) => Image.asset(
              'assets/images/default_weather.png',
              width: 52,
              height: 52,
            ),
          ),
          const SizedBox(height: spacingLarge),
          // Temperature Range
          Text(
            '$maxTemp°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: spacingSmall),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: tempBarHeight,
            margin: const EdgeInsets.symmetric(vertical: spacingSmall),
            child: Center( // برای مرکزی کردن نوار
              child: SizedBox(
                width: tempBarWidth, // عرض جدید نوار
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // نوار پس‌زمینه
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    // نوار پرشده
                    FractionallySizedBox(
                      heightFactor: _calculateHeightFactor(maxTemp, minTemp),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C4B4), Color(0xFF0288D1)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: spacingSmall),
          Text(
            '$minTemp°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.white24),
          const SizedBox(height: 5),
          // Chance of Rain
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.water_drop,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                day.chanceOfRain != null ? "${day.chanceOfRain}%" : "N/A",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: spacingMedium),
        ],
      ),
    );
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      print("Error parsing date: $e");
      return DateTime.now();
    }
  }

  double _calculateHeightFactor(int maxTemp, int minTemp) {
    final tempDiff = (maxTemp - minTemp).abs();
    return (tempDiff / 20).clamp(0.2, 0.8);
  }

  @override
  bool get wantKeepAlive => true;
}