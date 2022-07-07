import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_app/utils/weather_utils.dart';

import 'city_page.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({
    Key key,
  }) : super(key: key);

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String _celcius = '';

  String _icons;
  String _description = '';
  String _cityName = '';
  bool _isLoading = false;
  @override
  void initState() {
    _showWeatherByLocation();

    super.initState();
  }

  Future<void> _showWeatherByLocation() async {
    setState(() {
      _isLoading = true;
    });
    final position = await _getCurrentLocation();
    await getWeatherByLocation(position: position);
    // log('Position.latitude==>${position.latitude}');
    // log('Position. longitude==>${position.longitude}');
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> getWeatherByLocation({@required Position position}) async {
    final client = http.Client();

    try {
      setState(() {
        _isLoading = true;
      });
      Uri uri = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=a0d770bbd492c6c9b59c8a6d766682ef');
      final response = await client.get(uri);

      // final body = response.body;
      // log('response.body===>${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        // log('AIP===>>$body');
        final _data = jsonDecode(body) as Map<String, dynamic>;
        // ekinchi jolu
        // final data = json.decode(response.body);
        // log('Data ===>$data');
        // log('Data ===>$_data');
        final kelvin = _data['main']['temp'] as num;
        _cityName = _data['name'];
        _celcius = WeatherUtils.kelvinToCelcius(kelvin).toString();
        _description = WeatherUtils.getDescription(int.parse(_celcius));
        _icons = WeatherUtils.getWeatherIcon(kelvin);
        setState(() {
          _isLoading = false;
        });
        log('_data ==>$_cityName');
      }

      // log('AIP===>>${response}');

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw Exception(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        leading: const Icon(
          Icons.near_me,
          size: 60.0,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 30.0),
            child: IconButton(
              onPressed: () async {
                setState(() {});
                final _typedCity = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: ((context) => CityPage()),
                  ),
                );
                log('typedCity -===> $_typedCity');
                await _getWeatherByCityName(_typedCity).toString();
              },
              icon: const Icon(
                Icons.location_city,
                size: 60.0,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator(
                backgroundColor: Colors.blue,
                color: Colors.teal,
              )
            : Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/weather1.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _celcius.isEmpty
                          ? '$_celcius\u00B0 ☀'
                          : '$_celcius  \u00B0 $_icons',
                      style: const TextStyle(
                        fontSize: 100.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 35.0),
                      child: Text(
                        // 'Ожидается аномально жаркая погода.',
                        _cityName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 50.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.01,
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 150.0),
                      child: Text(
                        // _cityName ?? 'Shaardyn aty kelish kerek',
                        _description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 35.0,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  _getWeatherByCityName(typedCity) {}
}
