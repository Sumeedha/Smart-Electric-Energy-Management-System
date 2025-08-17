# ⚡ Smart Electric Energy Management System (SEEMS)

**Duration:** Jan 2024 – Mar 2024  
**Tech Stack:** ESP32, ACS712, SIM900, MQTT, Firebase, Flutter & Dart  

---

## **🔎 Overview**
The **Smart Electric Energy Management System (SEEMS)** is a hardware-integrated IoT project that enables **real-time energy monitoring and remote appliance control**.  
It uses **ESP32 with sensors & relays**, **MQTT for communication**, **Firebase for cloud storage**, and a **Flutter mobile app** for user interaction.  

---

## **✨ Features**
- 📊 Real-time monitoring of Voltage, Current, Power  
- 🔌 Remote appliance ON/OFF control  
- ☁️ Cloud integration with Firebase  
- 📱 Cross-platform mobile app (Flutter + Dart)   
- 💰 Energy cost calculation  

---

## **📂 Repository Structure**
Smart-Electric-Energy-Management-System/

├── code/

│ ├── esp32/

│ │

│ └── flutter_app/

│ ├── lib/

│ │ ├── main.dart

│ │ ├── services/mqtt_service.dart

│ │ └── pages/

│ │ ├── dashboard.dart

│ │ ├── rooms.dart

│ │ ├── analysis.dart

│ │ └── notifications.dart

│

├── docs/

│ ├── SEEMS_Document.pdf

│ └── demo_video.mp4

│

├── README.md

└── LICENSE

---

## **🚀 How It Works**
1. **ESP32** collects voltage & current data via sensors and publishes it over **MQTT**.  
2. **MQTT broker (HiveMQ)** transfers data between hardware and app.  
3. **Flutter app** receives data, shows analytics, and lets users control appliances.  
4. **Firebase** stores energy usage history and user authentication.  
5. **SIM900 GSM module** allows SMS-based appliance control in areas without internet.  

## **📊 Energy Cost Formula**
```dart
Power (W)   = Voltage × Current
Energy (kWh) = Power × Time (hours) / 1000
Cost (₹)     = Energy × Tariff

🎥 Demo
[View Project Demo](https://github.com/Sumeedha/Smart-Electric-Energy-Management-System/blob/main/docs/SEEMS%20_output%20(1)%20(1).mp4)
[Read Full Project Report](https://github.com/Sumeedha/Smart-Electric-Energy-Management-System/blob/main/docs/SEEMS_Document.pdf.pdf)

## **🚀 Future Enhancements**

- 🎙️ **Voice control with Google Assistant / Alexa**  
- 🤖 **AI-based usage predictions (TensorFlow Lite)**  
- 🔔 **Push Notifications via Firebase Cloud Messaging (FCM)**  
- ☀️ **Integration with solar energy monitoring**  

---

## **👥 Contributors**

This project was collaboratively developed by **4 members**:  
- **Sumeedha**  
- **Member 2**  
- **Member 3**  
- **Member 4**  

📜 License

This project is licensed under the MIT License.
