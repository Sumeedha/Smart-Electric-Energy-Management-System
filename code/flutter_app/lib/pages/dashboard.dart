import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class DashboardPage extends StatefulWidget {
  final MqttService mqttService;

  const DashboardPage({Key? key, required this.mqttService}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double totalVoltage = 220.0, totalCurrent = 0.40, totalPower = 88.0, totalCost = 13.20;
  // Store shared voltage under the "voltage" key and each switch’s data under its own key.
  Map<String, Map<String, double>> roomData = {};
  bool _isSubscribed = false;

  final Color primaryColor = const Color(0xFF1E3A8A);
  final Color secondaryColor = const Color(0xFF93C5FD);
  final Color backgroundColor = const Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _subscribeToMqtt();
  }

  void _subscribeToMqtt() {
    if (_isSubscribed) return;

    widget.mqttService.connectAndSubscribe(
      topics: [
        "home/voltage",   // Shared voltage topic
        "home/+/current",
        "home/+/power",
        "home/+/cost"
      ],
      onMessageReceived: (topic, payload) {
        if (payload.isNotEmpty && mounted) {
          final newValue = double.tryParse(payload);
          if (newValue != null) {
            setState(() {
              final parts = topic.split('/');
              if (parts.length == 2) {
                // This is for shared metrics (e.g., "home/voltage")
                final metric = parts[1];
                if (metric == "voltage") {
                  roomData["voltage"] = {"voltage": newValue};
                }
              } else if (parts.length == 3) {
                // Topics in the form "home/Switch1/current"
                final room = parts[1];
                final metric = parts[2];
                roomData.putIfAbsent(room, () => {'current': 0.0, 'power': 0.0, 'cost': 0.0});
                roomData[room]?[metric] = newValue;
              }
              _updateTotalMetrics();
            });
          }
        }
      },
    );

    _isSubscribed = true;
  }

  void _updateTotalMetrics() {
    // Update the shared voltage (only one value)
    totalVoltage = roomData["voltage"]?["voltage"] ?? 0.0;
    totalCurrent = 0.0;
    totalPower = 0.0;
    totalCost = 0.0;

    // Sum metrics for each switch (ignore the "voltage" key)
    roomData.forEach((key, metrics) {
      if (key != "voltage") {
        totalCurrent += metrics['current'] ?? 0.0;
        totalPower += metrics['power'] ?? 0.0;
        totalCost += metrics['cost'] ?? 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Smart Energy Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 5,
      ),
      body: Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTotalMetricsGrid(),
            const SizedBox(height: 20),
            Expanded(child: _buildRoomList()),
            const SizedBox(height: 20),
            _buildEnergySuggestionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      "Live Energy Monitoring",
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
    );
  }

  Widget _buildTotalMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 1.2,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildMetricCard("Voltage", totalVoltage, "V", Icons.bolt),
        _buildMetricCard("Current", totalCurrent, "A", Icons.power_input),
        _buildMetricCard("Power", totalPower, "W", Icons.offline_bolt),
        _buildMetricCard("Cost", totalCost, "₹", Icons.currency_rupee),
      ],
    );
  }

  Widget _buildMetricCard(String title, double value, String unit, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: primaryColor),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text("${value.toStringAsFixed(1)} $unit", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    // Display only switch data (ignoring the "voltage" key)
    List<String> switchRooms = roomData.keys.where((key) => key != "voltage").toList();

    return ListView.separated(
      itemCount: switchRooms.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final room = switchRooms[index];
        return _buildRoomCard(room);
      },
    );
  }

  Widget _buildRoomCard(String room) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(room.toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 8),
          Text("Current: ${roomData[room]!['current']?.toStringAsFixed(1) ?? '0.0'} A", style: TextStyle(fontSize: 16, color: Colors.black87)),
          Text("Power: ${roomData[room]!['power']?.toStringAsFixed(1) ?? '0.0'} W", style: TextStyle(fontSize: 16, color: Colors.black87)),
          Text("Cost: ₹${roomData[room]!['cost']?.toStringAsFixed(1) ?? '0.0'}", style: TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildEnergySuggestionCard() {
    return Container(
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(15)),
      padding: const EdgeInsets.all(16),
      child: Text(
        totalPower > 3000 ? "⚠️ High energy usage! Reduce load." : "✅ Energy usage is efficient!",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}
