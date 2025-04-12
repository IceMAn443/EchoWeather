
import 'package:flutter/material.dart';

class HourlyScreen extends StatelessWidget {
  const HourlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.blue,
        child: Center(
          child: Text('Hourly',style: TextStyle(color: Colors.white),),
        ),
      ),
    );
  }
}
