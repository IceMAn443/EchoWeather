import 'dart:ui';
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/widgets/app_background.dart';
import 'package:echo_weather/core/widgets/dot_loading.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/aq_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/cw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/fw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_bloc.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_event.dart';
import 'package:echo_weather/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isForecastLoaded = false;
  bool _isAirQualityLoaded = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;
  late final HomeBloc _homeBloc;

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // تنظیم انیمیشن‌ها
    _homeBloc = locator<HomeBloc>()..add(LoadCwEvent("امل"));
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 8.0, end: 15.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // فقط یک بار اجرا می‌شود
    _animationController.forward();
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return '--:--';
    try {
      final dateTime = DateTime.parse(isoTime);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '--:--';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return MultiBlocProvider(
      providers: [BlocProvider.value(value: _homeBloc)],
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: height * 0.15), // فاصله با اپ‌بار
            Expanded(
              child: BlocBuilder<HomeBloc, HomeState>(
                buildWhen:
                    (previous, current) =>
                        previous.cwStatus != current.cwStatus,
                builder: (context, state) {
                  if (state.cwStatus is CwLoading) {
                    return const Center(child: DotLoadingWidget());
                  }
                  if (state.cwStatus is CwCompleted) {
                    final city =
                        (state.cwStatus as CwCompleted)
                            .meteoCurrentWeatherEntity;
                    if (!_isForecastLoaded) {
                      final lat = city.coord?.lat;
                      final lon = city.coord?.lon;
                      print('مختصات از آب‌وهوای فعلی: lat=$lat, lon=$lon');
                      if (lat != null && lon != null) {
                        final params = ForecastParams(lat, lon);
                        _homeBloc.add(LoadFwEvent(params));
                        _homeBloc.add(LoadAirQualityEvent(params));
                        _isForecastLoaded = true;
                        _isAirQualityLoaded = true;
                      } else {
                        print('مختصات آب‌وهوای فعلی نامعتبر است');
                      }
                    }

                    // لاگ برای بررسی مقادیر humidity و pressure
                    print('Humidity: ${city.main?.humidity}');
                    print('Pressure: ${city.main?.pressure}');

                    double maxTemp = 0.0;
                    if (state.fwStatus is FwCompleted) {
                      final forecast =
                          (state.fwStatus as FwCompleted).forecastEntity;
                      if (forecast.days.isNotEmpty) {
                        maxTemp = forecast.days[0].maxTempC;
                      }
                    }
                    final sunrise = _formatTime(city.sys?.sunrise);
                    final sunset = _formatTime(city.sys?.sunset);
                    return Stack(
                      children: [
                        ///background image
                        Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage("assets/images/picture.jpg"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        ///Body
                        Column(
                          children: [
                            ///center circle
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 30,
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _glowAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        width: width * 0.65,
                                        height: width * 0.65,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.01),
                                          border: Border.all(color: Colors.grey.withOpacity(0.09)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.2),
                                              blurRadius: _glowAnimation.value,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // آیکون آب‌وهوا
                                              AppBackground.setIconForMain(
                                                city.weather != null && city.weather!.isNotEmpty
                                                    ? city.weather![0].description ?? ''
                                                    : '',
                                              ),
                                              const SizedBox(height: 8),
                                              // توضیحات آب‌وهوا
                                              Text(
                                                city.weather != null && city.weather!.isNotEmpty
                                                    ? city.weather![0].description ?? 'نامشخص'
                                                    : 'نامشخص',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              // دما
                                              Text(
                                                "${city.main?.temp?.round() ?? 0}\u00B0",
                                                style: TextStyle(
                                                  fontSize: width * 0.13,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            ///Divider
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),

                            ///Cards
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: SlideTransition(
                                    position: _slideAnimation,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          _buildGlassCard(
                                            "Wind Speed",
                                            "${city.wind?.speed ?? 0} m/s",
                                            Icons.air,
                                          ),
                                          const SizedBox(height: 10),
                                          _buildGlassCard(
                                            "Sunrise",
                                            sunrise,
                                            Icons.wb_sunny,
                                          ),
                                          const SizedBox(height: 10),
                                          _buildGlassCard(
                                            "Sunset",
                                            sunset,
                                            Icons.nights_stay,
                                          ),
                                          const SizedBox(height: 10),
                                          _buildGlassCard(
                                            "Humidity",
                                            city.main?.humidity != null
                                                ? "${city.main!.humidity}%"
                                                : "N/A",
                                            Icons.opacity,
                                          ),
                                          const SizedBox(height: 10),
                                          _buildGlassCard(
                                            "Pressure",
                                            city.main?.pressure != null
                                                ? "${city.main!.pressure} hPa"
                                                : "N/A",
                                            Icons.compress,
                                          ),
                                          const SizedBox(height: 10),
                                          // کارت کیفیت هوا
                                          BlocBuilder<HomeBloc, HomeState>(
                                            buildWhen: (previous, current) =>
                                            previous.aqStatus != current.aqStatus,
                                            builder: (context, state) {
                                              if (state.aqStatus is AirQualityLoading) {
                                                return _buildGlassCard(
                                                  "Air Quality",
                                                  "ُLoading",
                                                  Icons.cloud,
                                                );
                                              } else if (state.aqStatus is AirQualityCompleted) {
                                                final airQuality = state.aqStatus as AirQualityCompleted;
                                                return _buildGlassCard(
                                                  "Air Quality",
                                                  "${airQuality.aqi} - ${airQuality.category}",
                                                  Icons.cloud,
                                                );
                                              } else {
                                                return _buildGlassCard(
                                                  "Air Quality",
                                                  "Not Found",
                                                  Icons.cloud,
                                                );
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  if (state.cwStatus is CwError) {
                    return const Center(
                      child: Icon(Icons.error, color: Colors.red, size: 35),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            SizedBox(height: height * 0.001), // کاهش فضای خالی بالای باتم‌نو
          ],
        ),
      ),
    );
  }
  String _getAirQualityText(int? aqi) {
    if (aqi == null) return "N/A";
    switch (aqi) {
      case 1:
        return "Good";
      case 2:
        return "Fair";
      case 3:
        return "Moderate";
      case 4:
        return "Poor";
      case 5:
        return "Very Poor";
      default:
        return "Unknown";
    }
  }

  // تابع ساخت کارت‌های شیشه‌ای
  Widget _buildGlassCard(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Row(
            children: [
              AnimatedIcon(icon: icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// ویجت برای آیکون متحرک
class AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const AnimatedIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}
