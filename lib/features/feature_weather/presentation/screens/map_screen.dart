
import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Container(
        color: Colors.orange,
        child: Center(
          child: Text('map',style: TextStyle(color: Colors.white),),
        ),
      ),
    );
  }
}
