import 'dart:ui';
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/utils/date_converter.dart';
import 'package:echo_weather/core/widgets/dot_loading.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/current_city_entities.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/cw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isForecastLoaded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // تنظیم انیمیشن‌ها
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: height * 0.15), // فاصله با اپ‌بار
          Expanded(
            child: BlocBuilder<HomeBloc, HomeState>(
              buildWhen: (previous, current) => previous.cwStatus != current.cwStatus,
              builder: (context, state) {
                if (state.cwStatus is CwLoading) {
                  return const Center(child: DotLoadingWidget());
                }
                if (state.cwStatus is CwCompleted) {
                  final cwComplete = state.cwStatus as CwCompleted;
                  final CurrentCityEntity currentCityEntity = cwComplete.currentCityEntity;

                  if (!_isForecastLoaded) {
                    final forecastParams = ForecastParams(
                      currentCityEntity.coord!.lat!,
                      currentCityEntity.coord!.lon!,
                    );
                    BlocProvider.of<HomeBloc>(context).add(LoadFwEvent(forecastParams));
                    _isForecastLoaded = true;
                  }

                  final sunrise = DateConverter.changeDtToDateTimeHour(
                    currentCityEntity.sys!.sunrise,
                    currentCityEntity.timezone,
                  );
                  final sunset = DateConverter.changeDtToDateTimeHour(
                    currentCityEntity.sys!.sunset,
                    currentCityEntity.timezone,
                  );

                  return Stack(
                    children: [
                      // پس‌زمینه تصویری
                      Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/images/picture.jpg"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // محتوای اصلی
                      Column(
                        children: [
                          // بخش وسط (دما و وضعیت آب‌وهوا) با هاله گرد
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                                child: AnimatedBuilder(
                                  animation: _glowAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: width * 0.55, // اندازه دایره
                                      height: width * 0.55,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.05),
                                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.3),
                                            blurRadius: _glowAnimation.value,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _getWeatherIcon(currentCityEntity.weather?[0].main ?? ''),
                                              size: 60,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              currentCityEntity.weather?[0].description ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.white70,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              "${currentCityEntity.main?.temp?.round() ?? 0}\u00B0",
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
                          // جداکننده
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
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
                          // کارت‌های پایین
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        _buildGlassCard("Wind Speed", "${currentCityEntity.wind?.speed ?? 0} m/s", Icons.air),
                                        const SizedBox(height: 10),
                                        _buildGlassCard("Sunrise", sunrise, Icons.wb_sunny),
                                        const SizedBox(height: 10),
                                        _buildGlassCard("Sunset", sunset, Icons.nights_stay),
                                        const SizedBox(height: 10),
                                        _buildGlassCard("Humidity", "${currentCityEntity.main?.humidity ?? 0}%", Icons.opacity),
                                        const SizedBox(height: 10),
                                        _buildGlassCard("Pressure", "${currentCityEntity.main?.pressure ?? 0} hPa", Icons.compress),
                                        const SizedBox(height: 10),
                                        _buildGlassCard("Feels Like", "${currentCityEntity.main?.feelsLike?.round() ?? 0}\u00B0", Icons.thermostat),
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
          SizedBox(height: height * 0.02), // کاهش فضای خالی بالای باتم‌نو
        ],
      ),
    );
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
              AnimatedIcon(
                icon: icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
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

  // تابع برای انتخاب آیکون آب‌وهوا
  IconData _getWeatherIcon(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.umbrella;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_cloudy;
    }
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

class _AnimatedIconState extends State<AnimatedIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      child: Icon(
        widget.icon,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}