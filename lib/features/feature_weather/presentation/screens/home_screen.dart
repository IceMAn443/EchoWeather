import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/core/utils/date_converter.dart';
import 'package:echo_weather/core/widgets/app_background.dart';
import 'package:echo_weather/core/widgets/dot_loading.dart';
import 'package:echo_weather/features/feature_bookmark/domain/entities/city_entity.dart';
import 'package:echo_weather/features/feature_bookmark/domain/usecases/save_city_usecase.dart';
import 'package:echo_weather/features/feature_bookmark/presentation/bloc/bookmark_bloc.dart';
import 'package:echo_weather/features/feature_bookmark/presentation/bloc/get_all_city_status.dart';
import 'package:echo_weather/features/feature_bookmark/presentation/bloc/save_city_status.dart';
import 'package:echo_weather/features/feature_weather/data/models/suggest_city_model.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/current_city_entities.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_suggestion_city_usecase.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/cw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/fw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_bloc.dart';
import 'package:echo_weather/features/feature_weather/presentation/widgets/forecast_next_day.dart';
import 'package:echo_weather/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController textEditingController;
  late FocusNode focusNode;
  final PageController _pageController = PageController();
  bool _isForecastLoaded = false;
  GetSuggestionCityUseCase getSuggestionCityUseCase = GetSuggestionCityUseCase(
    locator(),
  );

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    focusNode = FocusNode();

    // پاک کردن متن هنگام بارگذاری اولیه صفحه
    textEditingController.clear();

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          textEditingController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textEditingController.text.length,
          );
        });
      }
    });

    // اضافه کردن listener برای نویگیشن
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ModalRoute.of(context)?.addScopedWillPopCallback(() async {
        textEditingController.clear(); // پاک کردن متن هنگام بازگشت
        return true;
      });
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    focusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    // پاک کردن متن هنگام بازگشت به صفحه (در صورت استفاده از Navigator.pop)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        textEditingController.clear();
      }
    });

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: height * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.02),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.white, size: 15),
                    const SizedBox(width: 5),
                    Text(
                      'ECHO_WEATHER',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                BlocBuilder<HomeBloc, HomeState>(
                  buildWhen: (previous, current) {
                    return previous.cwStatus != current.cwStatus;
                  },
                  builder: (context, state) {
                    if (state.cwStatus is CwCompleted) {
                      final CwCompleted cwComplete = state.cwStatus as CwCompleted;
                      final CurrentCityEntity currentCityEntity = cwComplete.currentCityEntity;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showCityDropdown(context, currentCityEntity.name ?? '');
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentCityEntity.name ?? '',
                                  style: const TextStyle(
                                    fontSize: 27, // کوچیک‌تر کردن نام شهر
                                    color: Colors.white,
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down,color: Colors.white,),
                              ],
                            ),
                          ),
                          SizedBox(width: 10,),
                          BlocBuilder<BookmarkBloc, BookmarkState>(
                            builder: (context, bookmarkState) {
                              bool isBookmarked = false;
                              if (bookmarkState.getAllCityStatus is GetAllCityCompleted) {
                                final cities = (bookmarkState.getAllCityStatus as GetAllCityCompleted).cities;
                                isBookmarked = cities.any((city) => city.name == currentCityEntity.name);
                              }
                              return Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isBookmarked ? Icons.push_pin : Icons.push_pin_outlined,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    onPressed: () {
                                      if (isBookmarked) {
                                        BlocProvider.of<BookmarkBloc>(context).add(DeleteCityEvent(currentCityEntity.name!));
                                      } else {
                                        BlocProvider.of<BookmarkBloc>(context).add(SaveCwEvent(currentCityEntity.name!));
                                      }
                                      // به‌روزرسانی لیست بوکمارک‌ها
                                      BlocProvider.of<BookmarkBloc>(context).add(GetAllCityEvent());
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    }
                    return const Text(
                      "Select a city",
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.white24, thickness: 2),
              ],
            ),
          ),
          BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (previous, current) =>
            previous.cwStatus != current.cwStatus ||
                previous.fwStatus != current.fwStatus,
            builder: (context, state) {
              if (state.cwStatus is CwLoading) {
                return const Expanded(child: DotLoadingWidget());
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
                return Expanded(
                  child: ListView(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: height * 0.5,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: 2,
                          itemBuilder: (context, position) {
                            if (position == 0) {
                              return Column(
                                children: [
                                  const SizedBox(height: 50),
                                  Text(
                                    currentCityEntity.weather?[0].description ?? '',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  AppBackground.setIconForMain(
                                    currentCityEntity.weather?[0].description ?? '',
                                  ),
                                  SizedBox(height: height * 0.02),
                                  Text(
                                    "${currentCityEntity.main?.temp?.round() ?? 0}\u00B0",
                                    style: TextStyle(
                                      fontSize: width * 0.15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Column(
                                          children: [
                                            Text(
                                              "max",
                                              style: TextStyle(
                                                fontSize: width * 0.05,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              "${currentCityEntity.main?.tempMax?.round() ?? 0}\u00B0",
                                              style: TextStyle(
                                                fontSize: width * 0.05,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Container(
                                        width: 2,
                                        height: 60,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 20),
                                      Flexible(
                                        child: Column(
                                          children: [
                                            Text(
                                              "min",
                                              style: TextStyle(
                                                fontSize: width * 0.05,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              "${currentCityEntity.main?.tempMin?.round() ?? 0}\u00B0",
                                              style: TextStyle(
                                                fontSize: width * 0.05,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            } else {
                              return const Center(
                                child: Text(
                                  "More details...",
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: 2,
                          effect: const ExpandingDotsEffect(
                            dotWidth: 10,
                            dotHeight: 10,
                            spacing: 8,
                            activeDotColor: Colors.white,
                          ),
                          onDotClicked: (index) => _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.bounceOut,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<HomeBloc, HomeState>(
                        buildWhen: (prev, curr) => prev.fwStatus != curr.fwStatus,
                        builder: (context, state) {
                          if (state.fwStatus is FwLoading) {
                            return const DotLoadingWidget();
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

                            return Column(
                              children: [
                                ForecastNextDaysWidget(forecastDays: forecast.days),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 110,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: forecast.hours.length,
                                    itemBuilder: (context, index) {
                                      final hour = forecast.hours[index];
                                      final timeLabel = DateFormat('HH:mm').format(DateTime.parse(hour.time));
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(timeLabel, style: const TextStyle(color: Colors.white70)),
                                            const SizedBox(height: 6),
                                            Image.asset(hour.conditionIcon, width: 50, height: 50),
                                            const SizedBox(height: 6),
                                            Text('${hour.temperature.round()}°',
                                                style: const TextStyle(color: Colors.white)),
                                          ],
                                        ),
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

                      Divider(color: Colors.white24, thickness: 2),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: _buildInfoItem(
                                "wind speed",
                                "${currentCityEntity.wind?.speed ?? 0} m/s",
                                height,
                              ),
                            ),
                            _buildDivider(),
                            Flexible(
                              child: _buildInfoItem(
                                "sunrise",
                                sunrise,
                                height,
                              ),
                            ),
                            _buildDivider(),
                            Flexible(
                              child: _buildInfoItem(
                                "sunset",
                                sunset,
                                height,
                              ),
                            ),
                            _buildDivider(),
                            Flexible(
                              child: _buildInfoItem(
                                "humidity",
                                "${currentCityEntity.main?.humidity ?? 0}%",
                                height,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (state.cwStatus is CwError) {
                return const Icon(Icons.error, color: Colors.red, size: 35);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  void showCityDropdown(BuildContext context, String cityName) {
    // بارگذاری شهرهای بوکمارک‌شده
    BlocProvider.of<BookmarkBloc>(context).add(GetAllCityEvent());

    showGeneralDialog(
      context: context,
      barrierDismissible: true, // با کلیک بیرون منو بسته می‌شه
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5), // پس‌زمینه نیمه‌شفاف
      transitionDuration: Duration(milliseconds: 300), // مدت زمان انیمیشن
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter, // منو از بالا نشون داده می‌شه
          child: Container(
            height: MediaQuery.of(context).size.height, // کل ارتفاع صفحه
            width: MediaQuery.of(context).size.width,
            child: Material(
              color: Color(0xFF34495E),
              child: Padding(
                padding:  EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Padding(
                      padding:  EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // بستن منو
                            },
                            icon: Icon(Icons.close, color: Colors.white,size: 30,),
                          ),
                          Text(
                            'Locations', // تغییر نام به WatchList برای هماهنگی
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 48), // برای بالانس کردن فضا
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    TypeAheadField<Data>(
                      controller: textEditingController,
                      focusNode: focusNode,
                      suggestionsCallback: (String pattern) async {
                        return await getSuggestionCityUseCase(pattern);
                      },
                      itemBuilder: (context, Data model) {
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(model.name ?? ''),
                          subtitle: Text('${model.region ?? ''}, ${model.country ?? ''}'),
                        );
                      },
                      onSelected: (Data model) async {
                        // غیرفعال کردن کیبورد
                        FocusScope.of(context).unfocus();

                        // تنظیم اسم شهر توی باکس سرچ
                        textEditingController.text = model.name ?? '';
                        textEditingController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: textEditingController.text.length,
                        );

                        // گرفتن مختصات شهر و ارسال درخواست برای بارگذاری اطلاعات
                        final cityName = model.name;
                        final latLon = await getCoordinatesFromCityName(cityName!);
                        BlocProvider.of<HomeBloc>(context).add(LoadCwEvent(cityName));
                        BlocProvider.of<HomeBloc>(context).add(
                          LoadFwEvent(ForecastParams(latLon.latitude, latLon.longitude)),
                        );

                        // بستن منوی کشویی و برگشتن به هوم اسکرین
                        Navigator.of(context).pop();
                      },
                      loadingBuilder: (context) => const SizedBox.shrink(),
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onTap: () {
                            Future.delayed(const Duration(milliseconds: 50), () {
                              textEditingController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: textEditingController.text.length,
                              );
                            });
                          },
                          onChanged: (value) {
                            if (controller.text != value) {
                              controller.text = value;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length),
                              );
                            }
                          },
                          onSubmitted: (value) {
                            BlocProvider.of<HomeBloc>(context).add(LoadCwEvent(value));
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Find Location",
                            hintStyle: TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white38),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: BlocBuilder<BookmarkBloc, BookmarkState>(
                        buildWhen: (previous, current) {
                          return current.getAllCityStatus != previous.getAllCityStatus;
                        },
                        builder: (context, state) {
                          // وضعیت لودینگ
                          if (state.getAllCityStatus is GetAllCityLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          // وضعیت تکمیل‌شده
                          if (state.getAllCityStatus is GetAllCityCompleted) {
                            final GetAllCityCompleted getAllCityCompleted =
                            state.getAllCityStatus as GetAllCityCompleted;
                            final List<City> cities = getAllCityCompleted.cities;

                            return cities.isEmpty
                                ? const Center(
                              child: Text(
                                'there is no bookmark city',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                                : ListView.builder(
                              itemCount: cities.length,
                              itemBuilder: (context, index) {
                                final city = cities[index];
                                return GestureDetector(
                                  onTap: () {
                                    BlocProvider.of<HomeBloc>(context)
                                        .add(LoadCwEvent(city.name));
                                    Navigator.of(context).pop();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRect(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                        child: Container(
                                          width: double.infinity,
                                          height: 60.0,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            const BorderRadius.all(Radius.circular(20)),
                                            color: Colors.grey.withOpacity(0.1),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 20.0),
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  city.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    BlocProvider.of<BookmarkBloc>(context)
                                                        .add(DeleteCityEvent(city.name));
                                                    BlocProvider.of<BookmarkBloc>(context)
                                                        .add(GetAllCityEvent());
                                                  },
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          // وضعیت خطا
                          if (state.getAllCityStatus is GetAllCityError) {
                            final GetAllCityError getAllCityError =
                            state.getAllCityStatus as GetAllCityError;
                            return Center(
                              child: Text(
                                getAllCityError.message!,
                                style: TextStyle(color: Colors.red),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, -1), // شروع از بالای صفحه
            end: Offset(0, 0),   // پایان در موقعیت اصلی
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  Widget _buildInfoItem(String title, String value, double height) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: height * 0.015, color: Colors.amber),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(fontSize: height * 0.015, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: VerticalDivider(color: Colors.white24, thickness: 2, width: 10),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

final dio = Dio();
Future<LatLon> getCoordinatesFromCityName(String cityName) async {
  final response = await dio.get('https://geocoding-api.open-meteo.com/v1/search?name=$cityName');
  final results = response.data['results'];
  final lat = results[0]['latitude'];
  final lon = results[0]['longitude'];
  return LatLon(lat, lon);
}

class LatLon {
  final double latitude;
  final double longitude;

  LatLon(this.latitude, this.longitude);
}