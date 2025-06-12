import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/theme_provider.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>>? _forecast;
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather('Delhi'); // Default to Delhi
  }

  Future<void> _fetchWeather(String city) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final currentWeather = await _weatherService.getCurrentWeather(city);
      final forecast = await _weatherService.getForecast(city);
      
      setState(() {
        _currentWeather = currentWeather;
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load weather data. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌡️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('India Weather'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter Indian city name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _fetchWeather(_searchController.text);
                    }
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _fetchWeather(value);
                }
              },
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: SpinKitDoubleBounce(
                  color: Colors.blue,
                  size: 50.0,
                ),
              ),
            )
          else if (_error.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (_currentWeather != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentWeather(),
                    const SizedBox(height: 24),
                    const Text(
                      '5-Day Forecast',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildForecast(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final temp = _currentWeather!['main']['temp'].toStringAsFixed(1);
    final condition = _currentWeather!['weather'][0]['main'];
    final humidity = _currentWeather!['main']['humidity'];
    final city = _currentWeather!['name'];
    final feelsLike = _currentWeather!['main']['feels_like'].toStringAsFixed(1);
    final windSpeed = _currentWeather!['wind']['speed'].toStringAsFixed(1);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  city,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getWeatherIcon(condition),
                  style: const TextStyle(fontSize: 32),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$temp°C',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Feels like $feelsLike°C',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      condition,
                      style: const TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'Wind: $windSpeed m/s',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Humidity: $humidity%',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Pressure: ${_currentWeather!['main']['pressure']} hPa',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecast() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _forecast!.length,
      itemBuilder: (context, index) {
        final forecast = _forecast![index];
        final date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
        final temp = forecast['main']['temp'].toStringAsFixed(1);
        final condition = forecast['weather'][0]['main'];
        final humidity = forecast['main']['humidity'];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text(
              _getWeatherIcon(condition),
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Humidity: $humidity%'),
            trailing: Text(
              '$temp°C',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 