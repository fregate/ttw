import 'package:api_request/api_request.dart';

class Weather {
  final int weatherCode;
  final String main;
  final String desc;
  final String iconName;

  Weather({
    required this.weatherCode,
    required this.main,
    required this.desc,
    required this.iconName,
  });

  factory Weather.fromMap(Map<String, dynamic> map) {
    return Weather(
      weatherCode: map["id"],
      main: map["main"],
      desc: map["description"],
      iconName: map["icon"],
    );
  }
}

List<Weather> _parseWeather(Map<String, dynamic> map) {
  final List<Weather> weather = [];
  if (map["weather"] is List) {
    map["weather"].forEach((item) => weather.add(Weather.fromMap(item)));
  }

  return weather;
}

class Temperature {
  final double morning;
  final double day;
  final double evening;
  final double night;
  final double min;
  final double max;

  Temperature({
    required this.morning,
    required this.day,
    required this.evening,
    required this.night,
    required this.min,
    required this.max,
  });

  factory Temperature.fromMap(Map<String, dynamic> map, String field) {
    if (map.containsKey(field) && map[field] is Map) {
      final tempMap = map[field] as Map<String, dynamic>;
      return Temperature(
        morning: tempMap["morn"].toDouble(),
        day: tempMap["day"].toDouble(),
        evening: tempMap["eve"].toDouble(),
        night: tempMap["night"].toDouble(),
        min: tempMap["min"]?.toDouble() ?? 0.0,
        max: tempMap["max"]?.toDouble() ?? 0.0,
      );
    } else {
      final double temp = map[field].toDouble();
      return Temperature(
        morning: temp,
        day: temp,
        evening: temp,
        night: temp,
        min: temp,
        max: temp,
      );
    }
  }
}

class WeatherConditions {
  final DateTime date;
  final Temperature temperature;
  final Temperature feelsLike;
  final int pressure;
  final int humidity;
  final double dewPoint;
  final double? rain;
  final double? snow;
  List<Weather> weather;

  WeatherConditions({
    required this.date,
    required this.temperature,
    required this.feelsLike,
    required this.pressure,
    required this.humidity,
    required this.dewPoint,
    required this.weather,
    this.rain,
    this.snow,
  });
}

double? _parsePrecipitation(Map<String, dynamic> map, String precipName) {
  if (map.containsKey("precipName")) {
    return map["precipName"]["1h"];
  }

  return null;
}

class CurrentConditions extends WeatherConditions {
  CurrentConditions({
    required DateTime date,
    required Temperature temperature,
    required Temperature feelsLike,
    required int pressure,
    required int humidity,
    required double dewPoint,
    required List<Weather> weather,
    double? rain,
    double? snow,
  }) : super(
            date: date,
            temperature: temperature,
            feelsLike: feelsLike,
            pressure: pressure,
            humidity: humidity,
            dewPoint: dewPoint,
            weather: weather,
            rain: rain,
            snow: snow);

  factory CurrentConditions.fromMap(Map<String, dynamic> map) {
    double? rain = _parsePrecipitation(map, "rain");
    double? snow = _parsePrecipitation(map, "snow");

    return CurrentConditions(
      temperature: Temperature.fromMap(map, "temp"),
      date: DateTime.fromMillisecondsSinceEpoch(map["dt"] * 1000),
      feelsLike: Temperature.fromMap(map, "feels_like"),
      pressure: map["pressure"],
      humidity: map["humidity"],
      dewPoint: map['dew_point'].toDouble(),
      rain: rain,
      snow: snow,
      weather: _parseWeather(map),
    );
  }
}

class PeriodForecast extends WeatherConditions {
  final double probability;

  PeriodForecast({
    required this.probability,
    required DateTime date,
    required Temperature temperature,
    required Temperature feelsLike,
    required int pressure,
    required int humidity,
    required double dewPoint,
    required List<Weather> weather,
    double? rain,
    double? snow,
  }) : super(
            date: date,
            temperature: temperature,
            feelsLike: feelsLike,
            pressure: pressure,
            humidity: humidity,
            dewPoint: dewPoint,
            weather: weather,
            rain: rain,
            snow: snow);

  factory PeriodForecast.fromMap(Map<String, dynamic> map) {
    double? rain = _parsePrecipitation(map, "rain");
    double? snow = _parsePrecipitation(map, "snow");
    return PeriodForecast(
      temperature: Temperature.fromMap(map, "temp"),
      probability: map["pop"].toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map["dt"] * 1000),
      feelsLike: Temperature.fromMap(map, "feels_like"),
      pressure: map["pressure"],
      humidity: map["humidity"],
      dewPoint: map['dew_point'].toDouble(),
      weather: _parseWeather(map),
      rain: rain,
      snow: snow,
    );
  }
}

class Alert {
  final String senderName;
  final String event;
  final DateTime start;
  final DateTime end;
  final String desc;
  final List<String>? tags;

  Alert({
    required this.senderName,
    required this.event,
    required this.start,
    required this.end,
    required this.desc,
    this.tags,
  });
}

class Forecast {
  final double latitude;
  final double longitude;
  final String timezone;
  final Duration tzOffset;
  final CurrentConditions current;
  final List<PeriodForecast> daily;
  final List<PeriodForecast> hourly;
  final List<Alert>? alerts;

  Forecast({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.tzOffset,
    required this.current,
    required this.daily,
    required this.hourly,
    this.alerts,
  });

  factory Forecast.fromNetwork(dynamic data) {
    if (data is Map) {
      final map = data as Map<String, dynamic>;

      final List<PeriodForecast> hourly = [];
      if (map["hourly"] is List) {
        map["hourly"].forEach((item) => hourly.add(PeriodForecast.fromMap(item)));
      }

      final List<PeriodForecast> daily = [];
      if (map["daily"] is List) {
        map["daily"].forEach((item) => daily.add(PeriodForecast.fromMap(item)));
      }

      return Forecast(
        timezone: map["timezone"],
        tzOffset: Duration(seconds: map["timezone_offset"]),
        latitude: map["lat"] ?? 0,
        longitude: map["lon"] ?? 0,
        current: CurrentConditions.fromMap(map["current"]),
        daily: daily,
        hourly: hourly,
      );
    } else {
      throw "Invalid network response";
    }
  }
}

class ForecastRequest extends ApiRequestAction<Forecast> {
  ForecastRequest({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  RequestMethod get method => RequestMethod.GET;

  @override
  String get path => "data/2.5/onecall";

  // TODO request alerts
  @override
  Map<String, dynamic> get toMap => {
        "exclude": "minutely,alerts",
        "units": "metric",
        "lat": latitude,
        "lon": longitude,
      };

  @override
  ResponseBuilder<Forecast> get responseBuilder => (data) => Forecast.fromNetwork(data);
}
