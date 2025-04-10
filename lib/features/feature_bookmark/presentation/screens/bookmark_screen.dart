
import 'package:flutter/material.dart';

class BookmarkScreen extends StatelessWidget {

  final PageController pageController;
  const BookmarkScreen({super.key,required this.pageController});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Bookmark',style: TextStyle(color: Colors.white),),
    );
  }
}
