import 'package:api_request/api_request.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ttw/models/city.dart';
import 'package:ttw/models/forecast.dart';

void main() {
  ApiRequestOptions.instance?.config(
    baseUrl: 'https://api.openweathermap.org/',
    defaultQueryParameters: {'appid': ''},
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: const TextTheme(
          headline1: TextStyle(
            color: Colors.white,
            fontSize: 64,
          ),
          headline3: TextStyle(
            color: Colors.white,
            fontSize: 32,
          ),
          bodyText1: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.normal,
          ),
          caption: TextStyle(
            color: Colors.white70,
            fontSize: 24,
          ),
          subtitle1: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Position badPosition = Position(
    longitude: 0,
    latitude: 0,
    timestamp: DateTime.fromMicrosecondsSinceEpoch(0),
    accuracy: 0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
  );
  final City badCity = City(
    country: "Miracle",
    latitude: 0,
    longitude: 0,
    name: "Unknown",
  );

  late final Future<Position> _positionFuture;
  Future<Forecast?>? _forecastFuture;

  @override
  void initState() {
    super.initState();

    _positionFuture = _getCurrentPosition();
  }

  Future<Forecast?> _queryForecast(double longitude, double latitude) {
    _forecastFuture ??= ForecastRequest(
      latitude: latitude,
      longitude: longitude,
    ).execute();
    return _forecastFuture!;
  }

  String printLatitude(double latitude) {
    return "${latitude.toStringAsFixed(3)}° ${latitude < 0 ? 'S' : 'N'}";
  }

  String printLongitude(double longitude) {
    return "${longitude.toStringAsFixed(3)}° ${longitude < 0 ? 'W' : 'E'}";
  }

  Widget buildHeader(SharedPreferences prefs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            highlightColor: const Color.fromARGB(255, 236, 67, 0),
            splashColor: const Color.fromARGB(255, 236, 67, 0),
            customBorder: const CircleBorder(),
            radius: 30,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Icon(
                Icons.settings_outlined,
                color: Colors.white,
              ),
            ),
            onTap: () {
              print("a");
            },
          ),
        ),
        Text(
          Jiffy().MMMMEEEEd,
          style: Theme.of(context).textTheme.caption,
        ),
      ],
    );
  }

  Widget buildPlace(SharedPreferences prefs) {
    return FutureBuilder<Position>(
      future: _positionFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final position = snapshot.data!;
          final cityRequest = CityRequest(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          return FutureBuilder<City?>(
            future: cityRequest.execute(),
            builder: (_, citySnapshot) {
              if (citySnapshot.hasData) {
                if (citySnapshot.data != null) {
                  final city = citySnapshot.data!;
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          city.name,
                          style: Theme.of(context).textTheme.headline1,
                        ),
                      ),
                      trailing: InkWell(
                        highlightColor: Colors.white24,
                        splashColor: Colors.white24,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.bookmark,
                            color: Colors.red,
                          ),
                        ),
                        onTap: () {
                          print("a");
                        },
                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            printLatitude(city.latitude),
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            printLongitude(city.longitude),
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  Fluttertoast.showToast(msg: "Invalid geocoding request!");
                }
              }
              if (snapshot.hasError) {
                Fluttertoast.showToast(msg: snapshot.error.toString());
              }
              return buildWaiter();
            },
          );
        }
        if (snapshot.hasError) {
          Fluttertoast.showToast(msg: snapshot.error.toString());
        }
        return buildWaiter();
      },
    );
  }

  Widget buildSuggest(SharedPreferences prefs) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Text(
        "Here will be suggest",
        style: Theme.of(context).textTheme.headline3,
      ),
    );
  }

  Widget weatherIcon(List<Weather> weather) {
    return const Icon(
      Icons.cloud_queue_sharp,
      color: Colors.white70,
    );
  }

  Widget buildHour(PeriodForecast hour) {
    final dateStyle = Theme.of(context).textTheme.bodyText1!.copyWith(
          fontSize: 12,
          color: Colors.white70,
        );
    final tempStyle = Theme.of(context).textTheme.caption!.copyWith(
          fontWeight: FontWeight.w300,
        );
    final date = Jiffy(hour.date);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          date.isSame(Jiffy(), Units.HOUR)
              ? Text(
                  "Now",
                  style: dateStyle,
                )
              : Text(
                  date.j,
                  style: dateStyle,
                ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              "${(hour.temperature.day).toStringAsFixed(1)}°",
              style: tempStyle,
            ),
          ),
          weatherIcon(hour.weather),
        ],
      ),
    );
  }

  List<Widget> buildHourly(Forecast forecast) {
    if (forecast.hourly.isEmpty) {
      return [Container()];
    }

    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          height: 0.75,
          color: Colors.white54,
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < 7; i++) buildHour(forecast.hourly[i]),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          height: 0.75,
          color: Colors.white54,
        ),
      ),
    ];
  }

  Widget buildDay(PeriodForecast day) {
    final dateStyle = Theme.of(context).textTheme.bodyText1!.copyWith(
          fontSize: 12,
          color: Colors.white70,
        );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            Jiffy(day.date).MMMEd,
            style: dateStyle,
          )
        ],
      ),
    );
  }

  List<Widget> buildDaily(Forecast forecast) {
    // return forecast.daily.map((day) => buildDay(day)).toList();

    // return SingleChildScrollView(
    //   physics: const ScrollPhysics(),
    //   child: Column(
    //     children: forecast.daily.map((day) => buildDay(day)).toList(),
    //   ),
    // );

    // return Expanded(
    //   child: ListView.separated(
    //     itemBuilder: (context, index) => buildDay(forecast.daily[index]),
    //     separatorBuilder: (context, index) => const Divider(
    //       color: Colors.white54,
    //       height: 0.75,
    //     ),
    //     itemCount: forecast.daily.length,
    //   ),
    // );

    return [
      SizedBox(
        height: 300,
        child: ListView.separated(
          itemBuilder: (context, index) => buildDay(forecast.daily[index]),
          separatorBuilder: (context, index) => const Divider(
            color: Colors.white54,
            height: 0.75,
          ),
          itemCount: forecast.daily.length,
        ),
      ),
    ];
  }

  Widget buildForecast(SharedPreferences prefs) {
    return FutureBuilder<Position>(
      future: _positionFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final position = snapshot.data!;
          return FutureBuilder<Forecast?>(
            future: _queryForecast(position.longitude, position.latitude),
            builder: (context, snapshotForecast) {
              if (snapshotForecast.hasData) {
                if (snapshotForecast.data != null) {
                  final forecast = snapshotForecast.data!;
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        ...buildHourly(forecast),
                        ...buildDaily(forecast),
                      ],
                    ),
                  );
                } else {
                  Fluttertoast.showToast(msg: "Invalid forecast request!");
                }
              }
              if (snapshot.hasError) {
                Fluttertoast.showToast(msg: snapshot.error.toString());
              }
              return buildWaiter();
            },
          );
        }
        return buildWaiter();
      },
    );
  }

  Widget buildWaiter() {
    return const CircularProgressIndicator(
      color: Color.fromARGB(128, 236, 67, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height,
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 255, 139, 58),
            Color.fromARGB(255, 255, 87, 19),
          ],
        ),
      ),
      child: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            final prefs = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                buildHeader(prefs),
                buildPlace(prefs),
                buildSuggest(prefs),
                buildForecast(prefs)
              ],
            );
          }

          return buildWaiter();
        },
      ),
    );
  }

  Future<Position> _getCurrentPosition() async {
    final hasPermission = await _handlePermission();

    if (!hasPermission) {
      return badPosition;
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
  }

  Future<bool> _handlePermission() async {
    final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }
}
