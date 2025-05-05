import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/features/feature_bookmark/domain/entities/city_entity.dart';
import 'package:echo_weather/features/feature_bookmark/presentation/bloc/bookmark_bloc.dart';
import 'package:echo_weather/features/feature_bookmark/presentation/bloc/get_all_city_status.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/meteo_current_weather_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/neshan_city_entity.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_suggestion_city_usecase.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/cw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_bloc.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_event.dart';
import 'package:echo_weather/locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/feature_weather/data/data_source/remote/api_provider.dart';

class CustomAppBar extends StatefulWidget {
  final Function(BuildContext, String) onCityTap;

  const CustomAppBar({super.key, required this.onCityTap});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late TextEditingController textEditingController;
  late FocusNode focusNode;
  bool _isForecastLoaded = false;
  bool _isAirQualityLoaded = false;
  bool _isLoadingLocation = false;
  GetSuggestionCityUseCase getSuggestionCityUseCase = GetSuggestionCityUseCase(locator());

  late final HomeBloc _homeBloc;
  final _suggestionUseCase = locator<GetSuggestionCityUseCase>();

  String _currentCity = 'تهران';
  double _currentLat = 35.6892;
  double _currentLon = 51.3890;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
    _homeBloc = locator<HomeBloc>();

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

    _loadInitialData();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    print('شروع بارگذاری اولیه داده‌ها...');
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      print('چک کردن سرویس موقعیت‌یابی...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('سرویس موقعیت‌یابی غیرفعال است');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'لطفاً سرویس موقعیت‌یابی را فعال کنید',
              style: TextStyle(
                fontFamily: 'Vazir',
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            backgroundColor: const Color(0xFF2C3E50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            elevation: 8,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'تنظیمات',
              textColor: Colors.blueAccent,
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
            ),
          ),
        );
        return _loadFallbackCity();
      }

      print('چک کردن مجوز موقعیت‌یابی...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print('درخواست مجوز موقعیت‌یابی...');
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          print('مجوز موقعیت‌یابی رد شد');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'لطفاً دسترسی به موقعیت مکانی را فعال کنید',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              backgroundColor: const Color(0xFF2C3E50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 8,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'تنظیمات',
                textColor: Colors.blueAccent,
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
            ),
          );
          return _loadFallbackCity();
        }
      }

      print('در حال گرفتن موقعیت فعلی...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('گرفتن موقعیت مکانی بیش از حد طول کشید');
      });
      print('موقعیت دریافت شد: lat=${position.latitude}, lon=${position.longitude}');

      print('در حال دریافت نام شهر...');
      final apiProvider = locator<ApiProvider>();
      final cityItem = await apiProvider.getCityByCoordinates(position.latitude, position.longitude);
      String cityName = cityItem?.title ?? 'موقعیت نامشخص';
      print('نام شهر دریافت شد: $cityName');

      setState(() {
        _currentCity = cityName;
        _currentLat = position.latitude;
        _currentLon = position.longitude;
      });

      print('در حال بارگذاری داده‌های آب‌وهوا برای $cityName...');
      final params = ForecastParams(position.latitude, position.longitude);
      _homeBloc.add(LoadCwEvent(cityName, lat: position.latitude, lon: position.longitude));
      if (!_isForecastLoaded) {
        _homeBloc.add(LoadFwEvent(params));
        _isForecastLoaded = true;
      }
      if (!_isAirQualityLoaded) {
        _homeBloc.add(LoadAirQualityEvent(params));
        _isAirQualityLoaded = true;
      }
    } catch (e, stackTrace) {
      print('خطا در گرفتن موقعیت مکانی: $e');
      print('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در گرفتن موقعیت مکانی: $e',
            style: const TextStyle(
              fontFamily: 'Vazir',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          backgroundColor: const Color(0xFF2C3E50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          elevation: 8,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'تلاش دوباره',
            textColor: Colors.blueAccent,
            onPressed: () => _getCurrentLocation(),
          ),
        ),
      );
      await _loadFallbackCity();
    } finally {
      print('اتمام فرآیند لودینگ موقعیت مکانی');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadFallbackCity() async {
    print('فال‌بک به شهر پیش‌فرض: تهران');
    double defaultLat = 35.6892;
    double defaultLon = 51.3890;
    final params = ForecastParams(defaultLat, defaultLon);
    try {
      _homeBloc.add(LoadCwEvent("تهران"));
      if (!_isForecastLoaded) {
        _homeBloc.add(LoadFwEvent(params));
        _isForecastLoaded = true;
      }
      if (!_isAirQualityLoaded) {
        _homeBloc.add(LoadAirQualityEvent(params));
        _isAirQualityLoaded = true;
      }
      setState(() {
        _currentCity = 'تهران';
        _currentLat = defaultLat;
        _currentLon = defaultLon;
      });
      print('داده‌های پیش‌فرض برای تهران لود شد');
    } catch (e) {
      print('خطا در لود داده‌های پیش‌فرض: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در بارگذاری داده‌های پیش‌فرض: $e',
            style: const TextStyle(
              fontFamily: 'Vazir',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          backgroundColor: const Color(0xFF2C3E50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          elevation: 8,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'تلاش دوباره',
            textColor: Colors.blueAccent,
            onPressed: () => _getCurrentLocation(),
          ),
        ),
      );
    }
  }

  void showCityDropdown(BuildContext context, String cityName) {
    BlocProvider.of<BookmarkBloc>(context).add(GetAllCityEvent());

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Material(
              color: const Color(0xFF34495E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                          ),
                          const Text(
                            'Locations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TypeAheadField<NeshanCityItem>(
                      controller: textEditingController,
                      focusNode: focusNode,
                      suggestionsCallback: (String pattern) async {
                        if (pattern.isEmpty) {
                          return [];
                        }
                        return await getSuggestionCityUseCase(pattern);
                      },
                      itemBuilder: (context, NeshanCityItem model) {
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(model.title ?? ''),
                          subtitle: Text('${model.address?.split(', ')[0] ?? ''}, ${model.address?.split(', ').last ?? ''}'),
                        );
                      },
                      onSelected: (NeshanCityItem model) async {
                        FocusScope.of(context).unfocus();

                        textEditingController.text = model.title ?? '';
                        textEditingController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: textEditingController.text.length,
                        );

                        final lat = model.location?.y;
                        final lon = model.location?.x;
                        print('مختصات شهر انتخاب‌شده (${model.title}): lat=$lat, lon=$lon');
                        if (lat != null && lon != null) {
                          final params = ForecastParams(lat, lon);
                          context.read<HomeBloc>().add(LoadCwEvent(model.title!));
                          context.read<HomeBloc>().add(LoadFwEvent(params));
                          context.read<HomeBloc>().add(LoadAirQualityEvent(params));
                          _isForecastLoaded = false;
                          _isAirQualityLoaded = false;
                        } else {
                          print('مختصات شهر پیدا نشد');
                        }

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
                            print('Text submitted: $value');
                            context.read<HomeBloc>().add(LoadCwEvent(value));
                            _isForecastLoaded = false;
                            _isAirQualityLoaded = false;
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
                    const SizedBox(height: 20),
                    Expanded(
                      child: BlocBuilder<BookmarkBloc, BookmarkState>(
                        buildWhen: (previous, current) {
                          return current.getAllCityStatus != previous.getAllCityStatus;
                        },
                        builder: (context, state) {
                          if (state.getAllCityStatus is GetAllCityLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
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
                                    BlocProvider.of<HomeBloc>(context).add(LoadCwEvent(city.name));
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
                                            borderRadius: const BorderRadius.all(Radius.circular(20)),
                                            color: Colors.grey.withOpacity(0.1),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 20.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                    Icons.close,
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
                          if (state.getAllCityStatus is GetAllCityError) {
                            final GetAllCityError getAllCityError =
                            state.getAllCityStatus as GetAllCityError;
                            return Center(
                              child: Text(
                                getAllCityError.message!,
                                style: const TextStyle(color: Colors.red),
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
            begin: const Offset(0, -1),
            end: const Offset(0, 0),
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(right: width * 0.02, top: height * 0.02),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny, color: Colors.white, size: 15),
              const SizedBox(width: 5),
              const Text(
                'ECHO_WEATHER',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (previous, current) {
              return previous.cwStatus != current.cwStatus;
            },
            builder: (context, state) {
              if (state.cwStatus is CwCompleted) {
                final CwCompleted cwComplete = state.cwStatus as CwCompleted;
                final MeteoCurrentWeatherEntity meteoCurrentWeatherEntity = cwComplete.meteoCurrentWeatherEntity;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showCityDropdown(context, meteoCurrentWeatherEntity.name ?? '');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            meteoCurrentWeatherEntity.name ?? '',
                            style: const TextStyle(
                              fontSize: 27,
                              color: Colors.white ,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                        ],
                      ),
                    ),
                    AnimatedBookmarkIcon(
                      meteoCurrentWeatherEntity: meteoCurrentWeatherEntity,
                    ),
                    AnimatedLocationIcon(
                      isLoading: _isLoadingLocation,
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
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
          const Divider(color: Colors.white24, thickness: 2),
        ],
      ),
    );
  }
}

class AnimatedLocationIcon extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const AnimatedLocationIcon({Key? key, required this.isLoading, required this.onPressed}) : super(key: key);

  @override
  _AnimatedLocationIconState createState() => _AnimatedLocationIconState();
}

class _AnimatedLocationIconState extends State<AnimatedLocationIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _previousLoadingState = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isLoading) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedLocationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_previousLoadingState != widget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
      _previousLoadingState = widget.isLoading;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: IconButton(
                icon: widget.isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.my_location, color: Colors.white, size: 26),
                onPressed: widget.onPressed,
                tooltip: 'استفاده از موقعیت فعلی',
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedBookmarkIcon extends StatefulWidget {
  final MeteoCurrentWeatherEntity meteoCurrentWeatherEntity;

  const AnimatedBookmarkIcon({Key? key, required this.meteoCurrentWeatherEntity}) : super(key: key);

  @override
  _AnimatedBookmarkIconState createState() => _AnimatedBookmarkIconState();
}

class _AnimatedBookmarkIconState extends State<AnimatedBookmarkIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _previousBookmarkState = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleBookmarkAnimation(bool isBookmarked) {
    if (_previousBookmarkState != isBookmarked) {
      _controller.forward().then((_) => _controller.reverse());
      _previousBookmarkState = isBookmarked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      child: BlocBuilder<BookmarkBloc, BookmarkState>(
        builder: (context, bookmarkState) {
          bool isBookmarked = false;
          if (bookmarkState.getAllCityStatus is GetAllCityCompleted) {
            final cities = (bookmarkState.getAllCityStatus as GetAllCityCompleted).cities;
            isBookmarked = cities.any((city) => city.name == widget.meteoCurrentWeatherEntity.name);
          }

          _toggleBookmarkAnimation(isBookmarked);

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: IconButton(
                    icon: Icon(
                      isBookmarked ? CupertinoIcons.bookmark_solid : CupertinoIcons.bookmark,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      if (isBookmarked) {
                        BlocProvider.of<BookmarkBloc>(context)
                            .add(DeleteCityEvent(widget.meteoCurrentWeatherEntity.name!));
                      } else {
                        BlocProvider.of<BookmarkBloc>(context)
                            .add(SaveCwEvent(widget.meteoCurrentWeatherEntity.name!));
                      }
                      BlocProvider.of<BookmarkBloc>(context).add(GetAllCityEvent());
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}