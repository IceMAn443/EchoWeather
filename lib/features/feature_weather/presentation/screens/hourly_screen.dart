import 'dart:async';
import 'package:echo_weather/features/feature_weather/presentation/bloc/fw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_bloc.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class HourlyScreen extends StatefulWidget {
  const HourlyScreen({super.key});

  @override
  State<HourlyScreen> createState() => _HourlyScreenState();
}

class _HourlyScreenState extends State<HourlyScreen> with AutomaticKeepAliveClientMixin {
  Timer? _timer;
  DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    // تنظیم Timer برای به‌روزرسانی هر 5 دقیقه (300 ثانیه)
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      final now = DateTime.now();
      // اگر آخرین بارگذاری بیش از 5 دقیقه پیش بوده یا روز تغییر کرده
      if (_lastFetchTime == null ||
          now.difference(_lastFetchTime!).inMinutes >= 5 ||
          now.day != _lastFetchTime!.day) {
        final cityName = "Amol"; // همون شهر استفاده‌شده توی MainWrapper
        context.read<HomeBloc>().add(LoadCwEvent(cityName));
        _lastFetchTime = now;
      }
    });
  }

  @override
  void dispose() {
    // لغو Timer هنگام بسته شدن صفحه
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // برای AutomaticKeepAliveClientMixin
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      bottom: true, // اطمینان از عدم نفوذ محتوا به زیر BottomNavigationBar
      child: BlocBuilder<HomeBloc, HomeState>(
        buildWhen: (prev, curr) => prev.fwStatus != curr.fwStatus,
        builder: (context, state) {
          if (state.fwStatus is FwLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.fwStatus is FwError) {
            return const Center(
              child: Text(
                "Error loading forecast",
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          if (state.fwStatus is FwCompleted) {
            final forecast = (state.fwStatus as FwCompleted).forecastEntity;

            // گرفتن تاریخ امروز در هر رندر
            final today = DateTime.now();
            final todayDate = DateTime(today.year, today.month, today.day);
            // تاریخ 3 روز بعد از امروز
            final threeDaysFromToday = todayDate.add(const Duration(days: 2)); // امروز + 2 روز بعد = 3 روز

            // فیلتر کردن ساعت‌ها برای فقط نمایش از امروز تا 3 روز بعد
            final filteredHours = forecast.hours.where((hour) {
              final hourDate = DateTime.parse(hour.time);
              final hourDay = DateTime(hourDate.year, hourDate.month, hourDate.day);
              // فقط ساعت‌هایی که از امروز تا 3 روز بعد هستن رو نگه می‌داریم
              return (hourDay.isAtSameMomentAs(todayDate) || hourDay.isAfter(todayDate)) &&
                  (hourDay.isBefore(threeDaysFromToday) || hourDay.isAtSameMomentAs(threeDaysFromToday));
            }).toList();

            // اگر هیچ ساعتی برای بازه مورد نظر وجود نداشت، داده‌ها را دوباره بارگذاری کن
            if (filteredHours.isEmpty && (_lastFetchTime == null || DateTime.now().difference(_lastFetchTime!).inMinutes >= 1)) {
              final cityName = "Amol";
              context.read<HomeBloc>().add(LoadCwEvent(cityName));
              _lastFetchTime = DateTime.now();
              return const Center(child: CircularProgressIndicator());
            }

            // گروه‌بندی ساعت‌ها بر اساس روز
            Map<String, List<dynamic>> groupedHours = {};
            for (var hour in filteredHours) {
              final hourDate = DateTime.parse(hour.time);
              final dayLabel = DateFormat('EEEE').format(hourDate);
              if (!groupedHours.containsKey(dayLabel)) {
                groupedHours[dayLabel] = [];
              }
              groupedHours[dayLabel]!.add(hour);
            }

            // مرتب‌سازی گروه‌ها بر اساس تاریخ واقعی (از امروز شروع می‌شه)
            List<MapEntry<String, List<dynamic>>> groupedEntries = groupedHours.entries.toList()
              ..sort((a, b) {
                final firstHourA = DateTime.parse(a.value.first.time);
                final firstHourB = DateTime.parse(b.value.first.time);
                return firstHourA.compareTo(firstHourB);
              });

            return SizedBox(
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: height * 0.16), // فاصله با اپ‌بار
                  // بنر تبلیغاتی
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C4B4), Color(0xFF0288D1)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock, color: Colors.white, size: 25),
                            SizedBox(width: 8),
                            Text(
                              'Unlock access to the next 10 days,\nso you know what’s coming.',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                  // لیست گروه‌بندی‌شده بر اساس روز
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80), // پدینگ برای جلوگیری از نفوذ به BottomNavigationBar
                      scrollDirection: Axis.vertical,
                      itemCount: groupedEntries.length,
                      itemBuilder: (context, index) {
                        final dayEntry = groupedEntries[index];
                        final dayLabel = dayEntry.key;
                        final hours = dayEntry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // هدر روز
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                dayLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // خط جداکننده (Divider)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(
                                color: Colors.white54,
                                thickness: 1,
                              ),
                            ),
                            // لیست ساعت‌ها برای این روز
                            ...hours.asMap().entries.map((entry) {
                              final hourIndex = entry.key;
                              final hour = entry.value;
                              final timeLabel = DateFormat('HH:mm').format(DateTime.parse(hour.time));

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4), // پس‌زمینه شفاف‌تر برای دیده شدن بک‌گراند
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // زمان
                                    Text(
                                      timeLabel,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                    const SizedBox(width: 22),
                                    // آیکن آب‌وهوا
                                    Image.asset(
                                      hour.conditionIcon,
                                      width: 42,
                                      height: 42,
                                    ),
                                    const SizedBox(width: 18),
                                    // دما و حس واقعی
                                    Row(
                                      children: [
                                        Text(
                                          '${hour.temperature.round()}°',
                                          style: const TextStyle(color: Colors.white, fontSize: 25),
                                        ),
                                        const SizedBox(width: 15),
                                        Text(
                                          'RealFeel ${hour.temperature.round() - 1}°', // باید منطق حس واقعی رو تنظیم کنید
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 44),
                                    // احتمال بارش
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.water_drop_outlined,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(hourIndex * 5 + 40)}%', // داده تستی برای احتمال بارش
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}