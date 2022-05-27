import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

typedef DeviceList = List<UartDevice>;

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

ThemeData getTheme(Brightness brightness) {
  return ThemeData(
    colorSchemeSeed: Colors.brown,
    brightness: brightness,
    useMaterial3: true,
  );
}

extension IntToString on int {
  String toHex() => '0x${toRadixString(16)}';
  String toPadded([int width = 3]) => toString().padLeft(width, '0');
  String toTransport() {
    switch (this) {
      case SerialPortTransport.usb:
        return 'USB';
      case SerialPortTransport.bluetooth:
        return 'Bluetooth';
      case SerialPortTransport.native:
        return 'Native';
      default:
        return 'Unknown';
    }
  }
}

class _ExampleAppState extends State<ExampleApp> {
  var availablePorts = <UartDevice>[];
  late final UniversalSerialPort port;

  @override
  void initState() {
    super.initState();
    port = UniversalSerialPort.getSerialPort();
    initPorts();
  }

  @override
  void dispose() {
    port.close();
    super.dispose();
  }

  void initPorts() {
    port.availablePorts.then((ports) {
      setState(() => availablePorts = ports);
    });
  }

  Widget _buildCloseButton(BuildContext context) {
    return TextButton(
        child: const Text("Close"),
        onPressed: () {
          port.close();
          Navigator.pop(context);
        });
  }

  Widget _buildActions(BuildContext context, UartDevice device) {
    const iconSize = 35.0;
    const padding = 4.0;
    return IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () async {
          if (port.isConnected) {
            port.close();
          }
          await port.connect(device);
          final config = UartConfig(
              baudRate: BaudRates.bps_115200.value,
              dataBits: DataBits.bits_5.value,
              stopBits: StopBits.bits_1.value,
              parity: Parities.none.value);
          await port.open(config);
          showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                return StreamBuilder<Uint8List>(
                    stream: port.inputStream,
                    builder: (context, snapshot) {
                      if (snapshot.data == null) {
                        return _buildCloseButton(context);
                      }
                      final data = snapshot.data!.toString();
                      return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [Text(data), _buildCloseButton(context)]);
                    });
              });
        },
        iconSize: iconSize,
        splashRadius: (iconSize + padding) / 2,
        padding: const EdgeInsets.all(padding));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: getTheme(Brightness.light),
      darkTheme: getTheme(Brightness.dark),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Serial Port example'),
        ),
        body: Scrollbar(
          child: ListView(
            children: [
              for (final device in availablePorts)
                Builder(builder: (context) {
                  return ExpansionTile(
                    title: Text(device.deviceName),
                    trailing: _buildActions(context, device),
                    controlAffinity: ListTileControlAffinity.leading,
                    children: [
                      //*CardListTile('Description', port.description),
                      //*CardListTile('Transport', port.transport.toTransport()),
                      //*CardListTile('USB Bus', port.busNumber?.toPadded()),
                      CardListTile('USB Device', device.deviceId?.toPadded()),
                      CardListTile('Vendor ID', device.vid?.toHex()),
                      CardListTile('Product ID', device.pid?.toHex()),
                      CardListTile('Manufacturer', device.manufacturerName),
                      CardListTile('Product Name', device.productName),
                      CardListTile('Serial Number', device.serial),
                      //*CardListTile('MAC Address', device.macAddress),
                    ],
                  );
                }),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: initPorts,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class CardListTile extends StatelessWidget {
  final String name;
  final String? value;

  const CardListTile(this.name, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(value ?? 'N/A'),
        subtitle: Text(name),
      ),
    );
  }
}
