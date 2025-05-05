import 'package:equatable/equatable.dart';

class WeatherNews extends Equatable {
  final String? title;
  final String? description;
  final String? url;
  final String? publishedAt;

  WeatherNews({this.title, this.description, this.url, this.publishedAt});

  factory WeatherNews.fromJson(Map<String, dynamic> json) {
    return WeatherNews(
      title: json['title'] as String?,
      description: json['description'] as String?,
      url: json['url'] as String?,
      publishedAt: json['publishedAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [title, description, url, publishedAt];

  @override
  bool get stringify => true;
}