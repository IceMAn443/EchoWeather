import 'package:echo_weather/core/widgets/app_background.dart';
import 'package:echo_weather/core/widgets/custom_appbar.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_bloc.dart';
import 'package:echo_weather/features/feature_weather/presentation/screens/daily_screen.dart';
import 'package:echo_weather/features/feature_weather/presentation/screens/home_screen.dart';
import 'package:echo_weather/features/feature_weather/presentation/screens/hourly_screen.dart';
import 'package:echo_weather/features/feature_weather/presentation/screens/map_screen.dart';
import 'package:echo_weather/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/bottom_nav.dart';

class MainWrapper extends StatelessWidget {
  MainWrapper({Key? key}) : super(key: key);

  final PageController _myPage = PageController(initialPage: 0);
  final String cityName = "Amol";

  @override
  Widget build(BuildContext context) {
    final List<Widget> pageViewWidget = [
      const HomeScreen(),
      const HourlyScreen(),
      const DailyScreen(),
      const MapScreen(),
    ];

    var height = MediaQuery.of(context).size.height;

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('kk').format(now);

    return BlocProvider<HomeBloc>(
      create: (context) => locator<HomeBloc>()..add(LoadCwEvent(cityName)),
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: BottomNav(controller: _myPage),
        body: Container(
          height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/picture.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              PageView(
                controller: _myPage,
                children: pageViewWidget,
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: CustomAppBar(
                    onCityTap: (context, cityName) {
                      // این تابع حالا نیازی نیست، اما برای سازگاری نگه داشته شده
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}