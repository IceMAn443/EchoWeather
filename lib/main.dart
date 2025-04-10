import 'package:echo_weather/core/widgets/mainwrapper.dart';
import 'package:echo_weather/features/feature_weather/presentation/bloc/home_bloc.dart';
import 'package:echo_weather/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ///init locator
  await setup();

  runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_)=> locator<HomeBloc>()),
        ],
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: MainWrapper()),
      )
  );
}
