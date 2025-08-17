import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class RoomsScreen extends StatefulWidget {
  final MqttService mqttService;

  const RoomsScreen({Key? key, required this.mqttService}) : super(key: key);

  @override
  _RoomsScreenState createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<String> rooms = ['Hall', 'Living room', 'Bedroom', 'Kitchen'];

  void _addRoom() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Room'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter room name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => rooms.add(controller.text.trim()));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteRoom(int index) {
    setState(() => rooms.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home Rooms'),
        elevation: 4,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Icon(Icons.room, color: Theme.of(context).primaryColor),
            title: Text(
              rooms[index],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red[300]),
              onPressed: () => _deleteRoom(index),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppliancesScreen(
                  room: rooms[index],
                  mqttService: widget.mqttService,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRoom,
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

class AppliancesScreen extends StatefulWidget {
  final String room;
  final MqttService mqttService;

  const AppliancesScreen({
    Key? key,
    required this.room,
    required this.mqttService,
  }) : super(key: key);

  @override
  _AppliancesScreenState createState() => _AppliancesScreenState();
}

class _AppliancesScreenState extends State<AppliancesScreen> {
  List<Map<String, dynamic>> switches = [
    {'name': 'Switch 1', 'isOn': false},
    {'name': 'Switch 2', 'isOn': false},
    {'name': 'Switch 3', 'isOn': false},
  ];

  void _renameSwitch(int index) {
    TextEditingController controller = TextEditingController(
      text: switches[index]['name'],
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename ${switches[index]['name']}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter appliance name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => switches[index]['name'] = controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateSwitchState(int index, bool newState) {
    setState(() => switches[index]['isOn'] = newState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.room} Appliances'),
        elevation: 4,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView.separated(
            padding: EdgeInsets.all(constraints.maxWidth > 600 ? 24 : 16),
            itemCount: switches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 600 ? 24 : 16,
                  vertical: 12,
                ),
                leading: Icon(Icons.power, color: Colors.blue[700]),
                title: Text(
                  switches[index]['name'],
                  style: TextStyle(
                    fontSize: constraints.maxWidth > 600 ? 20 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit, color: Colors.grey[600]),
                  onPressed: () => _renameSwitch(index),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SwitchDetailScreen(
                      switchData: switches[index],
                      room: widget.room,
                      mqttService: widget.mqttService,
                      onStateChanged: (newState) =>
                          _updateSwitchState(index, newState),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SwitchDetailScreen extends StatefulWidget {
  final Map<String, dynamic> switchData;
  final String room;
  final MqttService mqttService;
  final ValueChanged<bool> onStateChanged;

  const SwitchDetailScreen({
    Key? key,
    required this.switchData,
    required this.room,
    required this.mqttService,
    required this.onStateChanged,
  }) : super(key: key);

  @override
  _SwitchDetailScreenState createState() => _SwitchDetailScreenState();
}

class _SwitchDetailScreenState extends State<SwitchDetailScreen> {
  late bool isOn;
  List<Map<String, dynamic>> schedules = [];
  // Energy metrics
  double voltage = 0.0;
  double current = 0.0;
  double power = 0.0;
  double cost = 0.0;

  @override
  void initState() {
    super.initState();
    isOn = widget.switchData['isOn'];
    _subscribeToEnergyMetrics();
  }

  // Subscribe to the MQTT topics for energy metrics
  void _subscribeToEnergyMetrics() {
    final topics = ['voltage', 'current', 'power', 'cost'];
    for (var metric in topics) {
      final topic = 'home/${widget.room}/$metric';
      widget.mqttService.subscribe(topic, (receivedTopic, payload) {
        final value = double.tryParse(payload) ?? 0.0;
        setState(() {
          if (metric == 'voltage') {
            voltage = value;
          } else if (metric == 'current') {
            current = value;
          } else if (metric == 'power') {
            power = value;
          } else if (metric == 'cost') {
            cost = value;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    // Unsubscribe from the topics if your mqttService supports it.
    super.dispose();
  }

  void _togglePower(bool value) {
    setState(() => isOn = value);
    widget.mqttService.publishMessage(
      'home/${widget.room}/${widget.switchData['name']}',
      value ? 'ON' : 'OFF',
    );
    widget.onStateChanged(value);
  }

  Future<void> _addSchedule() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ScheduleDialog(),
    );

    if (result != null) {
      setState(() => schedules.add(result));
      final message = result['isDuration']
          ? 'Schedule after ${result['duration']} hours'
          : 'Scheduled at ${result['time'].format(context)}';
      widget.mqttService.publishMessage(
        'home/${widget.room}/${widget.switchData['name']}/schedule',
        message,
      );
    }
  }

  void _removeSchedule(int index) {
    setState(() => schedules.removeAt(index));
  }

  Widget _buildMetricCard(String title, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.switchData['name']),
        elevation: 4,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text(
                    'Power Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  value: isOn,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: _togglePower,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Energy Metrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  return GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    children: [
                      _buildMetricCard('Voltage', '${voltage.toStringAsFixed(1)} V'),
                      _buildMetricCard('Current', '${current.toStringAsFixed(2)} A'),
                      _buildMetricCard('Power', '${power.toStringAsFixed(1)} W'),
                      _buildMetricCard('Cost', '₹${cost.toStringAsFixed(2)}'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scheduling',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: const Text('Add Schedule'),
                      onPressed: _addSchedule,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              schedules.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No schedules set',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(
                    schedules.length,
                        (index) => Chip(
                      label: Text(schedules[index]['isDuration']
                          ? 'After ${schedules[index]['duration']} hrs'
                          : 'At ${schedules[index]['time'].format(context)}'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeSchedule(index),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScheduleDialog extends StatefulWidget {
  @override
  _ScheduleDialogState createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<ScheduleDialog> {
  bool isDurationBased = true;
  TimeOfDay selectedTime = TimeOfDay.now();
  double duration = 1;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Schedule',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Duration'),
                      selected: isDurationBased,
                      onSelected: (v) => setState(() => isDurationBased = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Specific Time'),
                      selected: !isDurationBased,
                      onSelected: (v) => setState(() => isDurationBased = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isDurationBased) ...[
                Slider(
                  min: 0.5,
                  max: 24,
                  divisions: 48,
                  label: '${duration.toStringAsFixed(1)} hours',
                  value: duration,
                  onChanged: (v) => setState(() => duration = v),
                ),
                Text('Schedule after ${duration.toStringAsFixed(1)} hours'),
              ] else ...[
                ListTile(
                  title: const Text('Select Time'),
                  trailing: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) setState(() => selectedTime = time);
                  },
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, {
                      'isDuration': isDurationBased,
                      'duration': duration,
                      'time': selectedTime,
                    }),
                    child: const Text('Save Schedule'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
