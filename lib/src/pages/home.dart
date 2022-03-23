import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import '../widgets/snackbar_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
    required this.characteristics,
    required this.device,
  }) : super(key: key);

  ///Retrieves all available bluetooth services
  final BluetoothCharacteristic characteristics;

  ///Retrieves device info
  final BluetoothDevice device;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late BluetoothCharacteristic _characteristics;
  late StreamSubscription<List<int>> bleReceive;

  double temperature = 0;
  double humidity = 0;

  bool isRedOn = false;
  bool isGreenOn = false;
  bool isBlueOn = false;

  bool isReconnect = false;
  Timer? timer;

  //Initiate variables when screen starts
  @override
  void initState() {
    super.initState();
    _characteristics = widget.characteristics;
    _listenBluetoothConnectionStatus();
    _receiveFromBT();
  }

  //Cancel or remove all listeners when leaves
  @override
  void dispose() {
    bleReceive.cancel();
    timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arduino Flutter Night'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              await widget.device.disconnect();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(
                      Icons.thermostat_outlined,
                      color: getTempColor(temperature),
                      size: 120,
                    ),
                    const Text(
                      'Temperature',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$temperature °C',
                      style: const TextStyle(
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(
                      Icons.water_outlined,
                      color: Colors.blue,
                      size: 120,
                    ),
                    const Text(
                      'Humidity',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$humidity %',
                      style: const TextStyle(
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16 * 4),
            const Text(
              'Lights Controller',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (!isRedOn) {
                      _sendToBT(text: 'red on');
                    } else {
                      _sendToBT(text: 'red off');
                    }
                  },
                  iconSize: 64,
                  icon: isRedOn
                      ? const Icon(
                          Icons.light_mode,
                          color: Colors.red,
                        )
                      : const Icon(
                          Icons.light_mode_outlined,
                          color: Colors.red,
                        ),
                ),
                IconButton(
                  onPressed: () {
                    if (!isGreenOn) {
                      _sendToBT(text: 'green on');
                    } else {
                      _sendToBT(text: 'green off');
                    }
                  },
                  iconSize: 64,
                  icon: isGreenOn
                      ? const Icon(
                          Icons.light_mode,
                          color: Colors.green,
                        )
                      : const Icon(
                          Icons.light_mode_outlined,
                          color: Colors.green,
                        ),
                ),
                IconButton(
                  onPressed: () {
                    if (!isBlueOn) {
                      _sendToBT(text: 'blue on');
                    } else {
                      _sendToBT(text: 'blue off');
                    }
                  },
                  iconSize: 64,
                  icon: isBlueOn
                      ? const Icon(
                          Icons.light_mode,
                          color: Colors.blue,
                        )
                      : const Icon(
                          Icons.light_mode_outlined,
                          color: Colors.blue,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _listenBluetoothConnectionStatus() {
    widget.device.state.listen((event) {
      if (event == BluetoothDeviceState.disconnected) {
        CustomSnackbar(
          context,
          status: Status.error,
          text: 'Device Disconnected',
        );

        timer = Timer.periodic(const Duration(seconds: 30), (_) async {
          await widget.device.connect();
          isReconnect = true;
          CustomSnackbar(
            context,
            status: Status.warning,
            text: 'Device is attempting to Reconnect.',
          );
        });
      } else if (event == BluetoothDeviceState.connected && isReconnect) {
        if (timer != null) {
          timer!.cancel();
        }
        CustomSnackbar(
          context,
          status: Status.success,
          text: 'Device Successfully Reconnected',
        );
        isReconnect = false;
      } else if (event == BluetoothDeviceState.connecting) {
        CustomSnackbar(
          context,
          status: Status.warning,
          text: 'Device is Reconnecting',
        );
      }
    });
  }

  _receiveFromBT() async {
    /// This is the sample data you receive from the arduino project
    /// TP:35.45;
    /// HD:56.46;
    /// Thats why we need to splice the value into something readable
    bleReceive = _characteristics.value.listen((value) {
      var splitComma = utf8.decode(value).split(',');
      for (var split in splitComma) {
        var splitNewLine = split.split('\n');
        for (var element in splitNewLine) {
          if (RegExp("[TP|HD|RD|GR|BL]+:").hasMatch(element)) {
            var prefix = element.substring(0, 2);
            var value =
                element.substring(3).replaceAll(';', '').replaceAll(' ', '');
            switch (prefix) {
              case 'TP':
                setState(() {
                  temperature = double.parse(value);
                });
                break;
              case 'HD':
                setState(() {
                  humidity = double.parse(value);
                });
                break;
              case 'RD':
                setState(() {
                  isRedOn = int.parse(value) == 1;
                });
                break;
              case 'GR':
                setState(() {
                  isGreenOn = int.parse(value) == 1;
                });
                break;
              case 'BL':
                setState(() {
                  isBlueOn = int.parse(value) == 1;
                });
                break;
            }
          }
        }
      }
    });

    //This listens to all incoming bluetooth data
    await _characteristics.setNotifyValue(true);
  }

  _sendToBT({required String text, bool withoutResponse = true}) async {
    _characteristics.write(
      utf8.encode('$text\n'),
      withoutResponse: withoutResponse,
    );
  }

  //Function to get color depending on the temperature
  Color getTempColor(double temperature) {
    if (temperature < 30) {
      return Colors.blue;
    } else if (temperature > 30 && temperature < 37) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
