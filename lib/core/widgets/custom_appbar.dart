import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:echo_weather/core/params/forcast_params.dart';
import 'package:echo_weather/features/feature_bookmark/domain/entities/city_entity.dart';
import 'package:echo_weather/features/feature_bookmark/presentation/bloc/bookmark_bloc.dart';
import 'package:echo_weather/features/feature_bookmark/presentation/bloc/get_all_city_status.dart';
import 'package:echo_weather/features/feature_weather/data/models/suggest_city_model.dart';
import 'package:echo_weather/features/feature_weather/domain/entities/current_city_entities.dart';
import 'package:echo_weather/features/feature_weather/domain/usecases/get_suggestion_city_usecase.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/cw_status.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_bloc.dart';
import 'package:echo_weather/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class CustomAppBar extends StatefulWidget {
  final Function(BuildContext, String) onCityTap;

  const CustomAppBar({super.key, required this.onCityTap});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late TextEditingController textEditingController;
  late FocusNode focusNode;
  GetSuggestionCityUseCase getSuggestionCityUseCase = GetSuggestionCityUseCase(locator());

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
  }

  @override
  void dispose() {
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void showCityDropdown(BuildContext context, String cityName) {
    // بارگذاری شهرهای بوکمارک‌شده
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
          child: Container(
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
                        FocusScope.of(context).unfocus();

                        textEditingController.text = model.name ?? '';
                        textEditingController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: textEditingController.text.length,
                        );

                        final cityName = model.name;
                        final latLon = await getCoordinatesFromCityName(cityName!);
                        BlocProvider.of<HomeBloc>(context).add(LoadCwEvent(cityName));
                        BlocProvider.of<HomeBloc>(context).add(
                          LoadFwEvent(ForecastParams(latLon.latitude, latLon.longitude)),
                        );

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
              Text(
                'ECHO_WEATHER',
                style: const TextStyle(
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
                final CurrentCityEntity currentCityEntity = cwComplete.currentCityEntity;
                return Stack(
                  alignment: Alignment.center,
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
                              fontSize: 27,
                              color: Colors.white,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: BlocBuilder<BookmarkBloc, BookmarkState>(
                        builder: (context, bookmarkState) {
                          bool isBookmarked = false;
                          if (bookmarkState.getAllCityStatus is GetAllCityCompleted) {
                            final cities = (bookmarkState.getAllCityStatus as GetAllCityCompleted).cities;
                            isBookmarked = cities.any((city) => city.name == currentCityEntity.name);
                          }
                          return IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.push_pin : Icons.push_pin_outlined,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              if (isBookmarked) {
                                BlocProvider.of<BookmarkBloc>(context)
                                    .add(DeleteCityEvent(currentCityEntity.name!));
                              } else {
                                BlocProvider.of<BookmarkBloc>(context)
                                    .add(SaveCwEvent(currentCityEntity.name!));
                              }
                              BlocProvider.of<BookmarkBloc>(context).add(GetAllCityEvent());
                            },
                          );
                        },
                      ),
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