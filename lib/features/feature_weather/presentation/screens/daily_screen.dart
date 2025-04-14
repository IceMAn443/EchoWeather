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
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent, // Keep transparent to show MainWrapper background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: height * 0.10),
                    // Header: Month and Toggle Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMMM').format(DateTime.now()), // e.g., "April"
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white54,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text("BY DAY"),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "45 DAYS",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Forecast List - Horizontal, expanded to fill the screen
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, // Horizontal scrolling
                        itemCount: forecast.days.length,
                        itemBuilder: (context, index) {
                          final day = forecast.days[index];
                          final date = DateTime.parse(day.date);
                          final height = MediaQuery.of(context).size.height;
                          return Row(
                            children: [
                              Container(
                                width: 80, // Fixed width for each day column
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),

                                child: Column(

                                  children: [
                                    // Day and Date
                                    Text(
                                      DateFormat('E').format(date), // e.g., "F"
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: index == 0 ? Colors.white : Colors.transparent,
                                      ),
                                      child: Text(
                                        DateFormat('d').format(date), // e.g., "11"
                                        style: TextStyle(
                                          color: index == 0 ? Colors.black : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    // Weather Icon
                                    Image.asset(
                                      day.conditionIcon,
                                      width: 52,
                                      height: 52,
                                      errorBuilder: (c, e, s) => const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 70),
                                    // Temperature Range - Displayed as a single line
                                    Text(
                                      "${day.maxTempC.round()}° ",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      height: 130,
                                      width: 20,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF00C4B4), Color(0xFF0288D1)],
                                          begin:Alignment.topCenter ,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      
                                    ),
                                    Text(
                                      "${day.maxTempC.round()}° ",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: height * 0.10),
                                    Divider(color:Colors.white24 ,),
                                    SizedBox(height: 5,),
                                    // Precipitation Chance
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
                                          "${day.chanceOfRain}%",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Add Divider (except for the last item)
                              if (index < forecast.days.length - 1)
                                Container(
                                  height: double.infinity, // Divider stretches to the bottom
                                  width: 1,
                                  color: Colors.white24, // Divider color
                                ),
                            ],
                          );
                        },
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

  @override
  bool get wantKeepAlive => true;
}