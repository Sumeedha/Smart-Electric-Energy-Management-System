import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'dart:convert';
import 'mqtt_service.dart';

class AnalysisPage extends StatefulWidget {
  final MqttService mqttService;
  const AnalysisPage({Key? key, required this.mqttService}) : super(key: key);

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  double dailyConsumption = 0.0;
  List<double> weeklyData = List.filled(7, 0.0);
  List<double> yearlyData = List.filled(12, 0.0);
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _subscribeToMqtt();
  }

  void _subscribeToMqtt() {
    widget.mqttService.connectAndSubscribe(
      topics: ["seems/energy/daily", "seems/energy/weekly", "seems/energy/yearly"],
      onMessageReceived: _handleMqttMessage,
    );
  }

  void _handleMqttMessage(String topic, String payload) {
    try {
      final data = jsonDecode(payload);
      if (!mounted) return;

      setState(() {
        switch (topic) {
          case "seems/energy/daily":
            dailyConsumption = (data['value'] ?? 0.0).toDouble();
            break;
          case "seems/energy/weekly":
            weeklyData = List<double>.from((data['values'] as List).map((e) => (e as num).toDouble()));
            break;
          case "seems/energy/yearly":
            yearlyData = List<double>.from((data['values'] as List).map((e) => (e as num).toDouble()));
            break;
        }
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Energy Analysis"),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _subscribeToMqtt,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _subscribeToMqtt,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDailySection(),
          const SizedBox(height: 24),
          _buildWeeklySection(),
          const SizedBox(height: 24),
          _buildYearlySection(),
        ],
      ),
    );
  }

  Widget _buildDailySection() {
    return _buildCard(
      title: "Today's Consumption",
      child: Column(
        children: [
          Text("${dailyConsumption.toStringAsFixed(1)} kWh", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          LinearProgressIndicator(
            value: (dailyConsumption / 50).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(dailyConsumption > 40 ? Colors.redAccent : Colors.blueAccent),
          ),
          const SizedBox(height: 10),
          Text('Max recommended: 50 kWh', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildWeeklySection() {
    return _buildCard(
      title: 'Weekly Consumption Trend',
      child: SizedBox(height: 250, child: _buildLineChart(weeklyData, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])),
    );
  }

  Widget _buildYearlySection() {
    return _buildCard(
      title: 'Yearly Consumption Overview',
      child: SizedBox(height: 250, child: _buildBarChart(yearlyData)),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<double> data, List<String> labels) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: labels.length - 1,
        minY: 0,
        maxY: data.isNotEmpty ? data.reduce(max) * 1.2 : 1.0,
        titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true))),
        lineBarsData: [
          LineChartBarData(spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])), isCurved: true, color: Colors.blue, barWidth: 4)
        ],
      ),
    );
  }

  Widget _buildBarChart(List<double> data) {
    return BarChart(
      BarChartData(
        barGroups: List.generate(data.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: data[i], color: Colors.blue)])),
      ),
    );
  }
}
