import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../widgets/service_tile.dart';
import '../widgets/characteristic_tile.dart';
//import '../widgets/descriptor_tile.dart';
import '../utils/snackbar.dart';
import '../utils/extra.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  //var targetServiceUUID;
  BluetoothCharacteristic? _characteristicTX;
  final CHARACTERISTIC_UUID_RX = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  final CHARACTERISTIC_UUID_TX = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  List<int> _value = [];
  List<int> msg = [];
  late StreamSubscription<List<int>> _lastValueSubscription;

  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;

  final List<bool> isSelected = [true];

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription =
        widget.device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // must rediscover services
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await widget.device.readRssi();
      }
      if (mounted) {
        setState(() {});
      }
    });

    _mtuSubscription = widget.device.mtu.listen((value) {
      _mtuSize = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isConnectingSubscription = widget.device.isConnecting.listen((value) {
      _isConnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isDisconnectingSubscription =
        widget.device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    _lastValueSubscription.cancel();
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future onConnectPressed() async {
    try {
      await widget.device.connectAndUpdateStream();
      Snackbar.show(ABC.c, "Connect: Success", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ABC.c, prettyException("Connect Error:", e),
            success: false);
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ABC.c, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Cancel Error:", e), success: false);
    }
  }

  Future onDisconnectPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream();
      Snackbar.show(ABC.c, "Disconnect: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Disconnect Error:", e),
          success: false);
    }
  }

  Future onDiscoverServicesPressed() async {
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }
    try {
      _services = await widget.device.discoverServices();
      Snackbar.show(ABC.c, "Discover Services: Success", success: true);

      final targetServiceUUID = _services.singleWhere(
          (item) => item.serviceUuid.str.toUpperCase() == SERVICE_UUID);
      print("Service is not empty");

      final targetCharacterUUID = targetServiceUUID.characteristics.singleWhere(
          (item) =>
              item.characteristicUuid.str.toUpperCase() ==
              CHARACTERISTIC_UUID_RX);
      print("Character valid");

      //await targetCharacterUUID.setNotifyValue(true);

      List<int> msg = await targetCharacterUUID.read();

      _lastValueSubscription =
          targetCharacterUUID.lastValueStream.listen((value) {
        _value = value;
        setState(() {});
      });

      //BluetoothCharacteristic get c => targetCharacterUUID;

      _characteristicTX = targetServiceUUID.characteristics.singleWhere(
          (item) =>
              item.characteristicUuid.str.toUpperCase() ==
              CHARACTERISTIC_UUID_TX);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Discover Services Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  Widget reading(BuildContext context) {
    var decoded = ascii.decode(_value);
    flutterTts.speak(decoded);
    return Center(
        child:
            Text(decoded, style: TextStyle(fontSize: 30, color: Colors.grey)));
  }

  // Widget buildUuid(BuildContext context) {
  //   String uuid = '0x${widget.characteristic.uuid.str.toUpperCase()}';
  //   return Text(uuid, style: TextStyle(fontSize: 13));
  // }

  Future onRequestMtuPressed() async {
    try {
      await widget.device.requestMtu(223, predelay: 0);
      Snackbar.show(ABC.c, "Request Mtu: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Change Mtu Error:", e),
          success: false);
    }
  }

  // List<Widget> _buildServiceTiles(BuildContext context, BluetoothDevice d) {
  //   return _services
  //       .map(
  //         (s) => ServiceTile(
  //           service: s,
  //           characteristicTiles: s.characteristics
  //               // .map((c) => _buildCharacteristicTile(c))
  //               .toList(),
  //         ),
  //       )
  //       .toList();
  // }

  // CharacteristicTile _buildCharacteristicTile(BluetoothCharacteristic c) {
  //   return CharacteristicTile(
  //     characteristic: c,
  //   );
  // }

  Widget buildSpinner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  Widget buildRemoteId(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('${widget.device.remoteId}'),
    );
  }

  Widget buildRssiTile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isConnected
            ? const Icon(Icons.bluetooth_connected)
            : const Icon(Icons.bluetooth_disabled),
        Text(((isConnected && _rssi != null) ? '${_rssi!} dBm' : ''),
            style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

  Widget buildGetServices(BuildContext context) {
    return IndexedStack(
      index: (_isDiscoveringServices) ? 1 : 0,
      children: <Widget>[
        // reading(context),
        ToggleButtons(
          // <Widget>[
          //   reading(context),
          //   TextButton(
          //     child: const Text("Get Services"),
          //     onPressed: onDiscoverServicesPressed,
          //   ),
          // ],
          onPressed: (index) {
            setState(() {
              // for (int i = 0; i < isSelected.length; i++) {
              isSelected[index] = !isSelected[index];

              if (isSelected[index]) {
                onDiscoverServicesPressed();
                reading(context);
              }

              // onDiscoverServicesPressed();
              // reading(context);
              //}
              print("working........");
            });
          },
          isSelected: isSelected,
          children: [const Text("Get Services")],
        ),
        // TextButton(
        //   child: const Text("Get Services"),
        //   onPressed: onDiscoverServicesPressed,
        // ),
        const IconButton(
          icon: SizedBox(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.grey),
            ),
            width: 18.0,
            height: 18.0,
          ),
          onPressed: (null),
        )
      ],
    );
  }

  Widget buildMtuTile(BuildContext context) {
    return ListTile(
        title: const Text('MTU Size'),
        subtitle: Text('$_mtuSize bytes'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onRequestMtuPressed,
        ));
  }

  Widget buildConnectButton(BuildContext context) {
    return Row(children: [
      if (_isConnecting || _isDisconnecting) buildSpinner(context),
      TextButton(
          onPressed: _isConnecting
              ? onCancelPressed
              : (isConnected ? onDisconnectPressed : onConnectPressed),
          child: Text(
            _isConnecting ? "CANCEL" : (isConnected ? "DISCONNECT" : "CONNECT"),
            style: Theme.of(context)
                .primaryTextTheme
                .labelLarge
                ?.copyWith(color: Colors.white),
          ))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyC,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.device.platformName),
          actions: [buildConnectButton(context)],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              buildRemoteId(context),
              ListTile(
                leading: buildRssiTile(context),
                title: Text(
                    'Device is ${_connectionState.toString().split('.')[1]}.'),
                trailing: buildGetServices(context),
              ),
              Column(
                children: [
                  reading(context),
                  const SizedBox(
                    height: 50,
                  ),
                  // reading(context),
                  const SizedBox(
                    height: 200,
                  ),
                  ToggleSwitch(
                    customWidths: [90.0, 50.0],
                    cornerRadius: 20.0,
                    activeBgColors: [
                      [Colors.cyan],
                      [Colors.redAccent]
                    ],
                    activeFgColor: Colors.white,
                    inactiveBgColor: Colors.grey,
                    inactiveFgColor: Colors.white,
                    totalSwitches: 2,
                    labels: ['READ', 'x'],
                    onToggle: (index) {
                      onDiscoverServicesPressed();
                      reading(context);
                    },
                  )
                ],
              ),
              //buildMtuTile(context),
              // ..._buildServiceTiles(context, widget.device),
              //String uuid='0x${service.uuid.str.toUpperCase()}';
              //Text('0x${targetServiceUUID.str.toUpperCase()}'),
            ],
          ),
        ),
      ),
    );
  }
}
