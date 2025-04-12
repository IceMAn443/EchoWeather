
import 'package:flutter/material.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Container(
        color: Colors.blue,
        child: Center(
          child: Text('Daily',style: TextStyle(color: Colors.white),),
        ),
      ),
    );
  }
}
