import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class NotificationsScreen extends StatefulWidget {
  final MqttService mqttService;

  const NotificationsScreen({Key? key, required this.mqttService}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<Map<String, dynamic>>> notifications = {
    'seems/alerts': [],
    'seems/reports': [],
    'seems/schedules': []
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Subscribe to topics only once (globally)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.mqttService.connectAndSubscribe(
        topics: notifications.keys.toList(),
        onMessageReceived: _handleMQTTMessage,
      );
    });
  }

  void _handleMQTTMessage(String topic, String message) {
    if (message.trim().isEmpty) return;
    setState(() {
      notifications[topic]?.insert(0, {
        "title": "New ${_getCategoryName(topic)}",
        "message": message,
        "time": _formattedTime(),
      });
    });
  }

  void _clearCategory() {
    setState(() {
      notifications[notifications.keys.toList()[_tabController.index]]?.clear();
    });
  }

  String _formattedTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  String _getCategoryName(String topic) {
    return {
      'seems/alerts': "Alert",
      'seems/reports': "Report",
      'seems/schedules': "Schedule",
    }[topic] ?? "Notification";
  }

  IconData _getCategoryIcon(String topic) {
    return {
      'seems/alerts': Icons.warning_amber_rounded,
      'seems/reports': Icons.insert_chart,
      'seems/schedules': Icons.schedule,
    }[topic] ?? Icons.notifications;
  }

  Widget _buildNotificationList(String topic) {
    final list = notifications[topic]!;
    return list.isEmpty
        ? const Center(
      child: Text("No notifications available", style: TextStyle(fontSize: 16, color: Colors.grey)),
    )
        : ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        return Dismissible(
          key: Key(list[index].hashCode.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            setState(() {
              list.removeAt(index);
            });
          },
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade700,
                child: Icon(_getCategoryIcon(topic), color: Colors.white),
              ),
              title: Text(list[index]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(list[index]['message'], style: const TextStyle(color: Colors.black87)),
              trailing: Text(list[index]['time'], style: const TextStyle(color: Colors.grey)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Real-Time Notifications"),
          backgroundColor: Colors.blue.shade800,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            tabs: const [
              Tab(icon: Icon(Icons.warning_amber_rounded), text: "Alerts"),
              Tab(icon: Icon(Icons.insert_chart), text: "Reports"),
              Tab(icon: Icon(Icons.schedule), text: "Schedules"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearCategory,
              tooltip: "Clear All",
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TabBarView(
            controller: _tabController,
            children: notifications.keys.map((topic) => _buildNotificationList(topic)).toList(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
