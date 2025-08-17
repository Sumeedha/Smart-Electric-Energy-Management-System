import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mqtt_service.dart';
import 'dashboard.dart';
import 'rooms.dart';
import 'analysis.dart';
import 'notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SEEMSApp());
}

class SEEMSApp extends StatelessWidget {
  const SEEMSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SEEMS',
      theme: ThemeData(
        primaryColor: const Color(0xFF2D5DED),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2D5DED),
          secondary: Color(0xFF4BCBEB),
          background: Color(0xFFF8F9FD),
        ),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2D5DED),
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: HomeScreen(mqttService: MqttService()),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final MqttService mqttService;

  const HomeScreen({Key? key, required this.mqttService}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _connectToMqtt();
    _pages = [
      DashboardPage(mqttService: widget.mqttService),
      RoomsScreen(mqttService: widget.mqttService),
      AnalysisPage(mqttService: widget.mqttService),
      NotificationsScreen(mqttService: widget.mqttService),
    ];
  }

  void _connectToMqtt() async {
    try {
      await widget.mqttService.connectAndSubscribe(
        topics: ["energy/voltage", "energy/current", "energy/power", "energy/cost"],
        onMessageReceived: (topic, payload) {
          debugPrint('MQTT Message: $topic - $payload');
        },
      );
    } catch (error) {
      debugPrint('MQTT Connection Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to MQTT: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEEMS'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: 'Rooms'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.mqttService.disconnect();
    super.dispose();
  }
}
