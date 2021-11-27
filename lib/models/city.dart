import 'package:api_request/api_request.dart';

class City {
  final String name;
  final String country;
  final String? state;
  final double latitude;
  final double longitude;
  final Map<String, String>? localNames;

  City({
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.name,
    this.localNames,
    this.state,
  });

  factory City.fromNetwork(dynamic data) {
    if (data is List && data.isNotEmpty) {
      final map = data[0] as Map<String, dynamic>;
      final Map<String, String> local = Map.from(map["local_names"]);
      return City(
        name: map["name"],
        latitude: map["lat"] ?? 0,
        longitude: map["lon"] ?? 0,
        country: map["country"] ?? "",
        state: map["state"] ?? "",
        localNames: local,
      );
    } else {
      throw "Invalid network response";
    }
  }
}

class CityRequest extends ApiRequestAction<City> {
  final double latitude;
  final double longitude;

  CityRequest({
    required this.latitude,
    required this.longitude,
  });

  @override
  Map<String, dynamic> get toMap => {
        "lat": latitude,
        "lon": longitude,
      };

  @override
  RequestMethod get method => RequestMethod.GET;

  @override
  String get path => "geo/1.0/reverse";

  @override
  ResponseBuilder<City> get responseBuilder => (data) => City.fromNetwork(data);
}
