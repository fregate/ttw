import 'package:api_request/api_request.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ttw/models/city.dart';

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
          headline1: TextStyle(color: Colors.white, fontSize: 64),
          bodyText1: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
          caption: TextStyle(color: Colors.white, fontSize: 24),
          subtitle1: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w300),
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

  late final Future<Position> _positionFuture;

  @override
  void initState() {
    super.initState();

    _positionFuture = _getCurrentPosition();
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
          return FutureBuilder(
            future: cityRequest.get(),
            builder: (_, citySnapshot) {
              if (citySnapshot.hasData) {
                final response = CityResponse.fromNetwork(citySnapshot.data);
                final city = response.city!;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.name,
                      style: Theme.of(context).textTheme.headline1,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          city.latitude.toString(),
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                        const SizedBox(width: 4,),
                        Text(
                          city.longitude.toString(),
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                      ],
                    ),
                  ],
                );
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
    return Container();
  }

  Widget buildForecast(SharedPreferences prefs) {
    return Container();
  }

  Widget buildWaiter() {
    return const CircularProgressIndicator(
      color: Color.fromARGB(128, 236, 67, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 1.0,
      widthFactor: 1.0,
      child: Container(
        padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 255, 131, 43),
              Color.fromARGB(255, 236, 67, 0),
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
