// neshan_city_model.dart

import 'package:echo_weather/features/feature_weather/domain/entities/neshan_city_entity.dart';

class NeshanCityModel extends NeshanCityEntity {
  NeshanCityModel({
    int? count,
    List<NeshanCityItem>? items,
  }) : super(count: count, items: items);

  factory NeshanCityModel.fromJson(dynamic json) {
    List<NeshanCityItem> items = [];
    if (json['items'] != null) {
      json['items'].forEach((v) {
        final locationJson = v['location'];
        items.add(NeshanCityItem(
          title: v['title'],
          address: v['address'],
          location: locationJson != null
              ? Location(
            x: locationJson['x']?.toDouble(),
            y: locationJson['y']?.toDouble(),
          )
              : null,
        ));
      });
    }

    return NeshanCityModel(
      count: json['count'],
      items: items,
    );
  }
}