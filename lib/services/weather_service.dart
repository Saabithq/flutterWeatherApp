import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = '7e30a921df5986bcbca49200c5eafe73'; 

  // List of major Indian cities for quick access
  static const List<String> majorIndianCities = [
    'Delhi',
    'Mumbai',
    'Bangalore',
    'Hyderabad',
    'Chennai',
    'Kolkata',
    'Pune',
    'Ahmedabad',
    'Jaipur',
    'Lucknow'
  ];

  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/weather?q=$city,IN&appid=$_apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('City not found. Please check the city name.');
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Network error. Please check your internet connection.');
    }
  }

  Future<List<Map<String, dynamic>>> getForecast(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/forecast?q=$city,IN&appid=$_apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        // Get one forecast per day (excluding today)
        final List<Map<String, dynamic>> dailyForecasts = [];
        final Set<String> processedDays = {};

        for (var forecast in forecastList) {
          final date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
          final day = '${date.year}-${date.month}-${date.day}';
          
          if (!processedDays.contains(day)) {
            processedDays.add(day);
            dailyForecasts.add(forecast);
            
            if (dailyForecasts.length >= 5) break;
          }
        }

        return dailyForecasts;
      } else if (response.statusCode == 404) {
        throw Exception('City not found. Please check the city name.');
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      throw Exception('Network error. Please check your internet connection.');
    }
  }

  // Get weather alerts for Indian cities (if available)
  Future<List<Map<String, dynamic>>> getWeatherAlerts(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/onecall?q=$city,IN&appid=$_apiKey&units=metric&exclude=current,minutely,hourly,daily'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['alerts'] != null) {
          return List<Map<String, dynamic>>.from(data['alerts']);
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
} 