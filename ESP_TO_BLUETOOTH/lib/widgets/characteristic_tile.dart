// import 'dart:async';
// import 'dart:math';
// import 'dart:convert';
// import 'package:flutter_tts/flutter_tts.dart';

// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// import "../utils/snackbar.dart";

// class CharacteristicTile extends StatefulWidget {
//   final BluetoothCharacteristic characteristic;

//   const CharacteristicTile({
//     Key? key,
//     required this.characteristic,
//   }) : super(key: key);

//   @override
//   State<CharacteristicTile> createState() => _CharacteristicTileState();
// }

// class _CharacteristicTileState extends State<CharacteristicTile> {
//   final FlutterTts flutterTts = FlutterTts();
//   List<int> _value = [];
//   late StreamSubscription<List<int>> _lastValueSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _lastValueSubscription =
//         widget.characteristic.lastValueStream.listen((value) {
//       _value = value;
//       if (mounted) {
//         setState(() {});
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _lastValueSubscription.cancel();
//     super.dispose();
//   }

//   BluetoothCharacteristic get c => widget.characteristic;

//   List<int> _getRandomBytes() {
//     final math = Random();
//     return [
//       math.nextInt(255),
//       math.nextInt(255),
//       math.nextInt(255),
//       math.nextInt(255)
//     ];
//   }


// }



//         ToggleSwitch(
//             customWidths: [90.0, 50.0],
//   cornerRadius: 20.0,
//   activeBgColors: [[Colors.cyan], [Colors.redAccent]],
//   activeFgColor: Colors.white,
//   inactiveBgColor: Colors.grey,
//   inactiveFgColor: Colors.white,
//   totalSwitches: 2,
//         labels: ["Get Services"],
//         // icons: [null, FontAwesomeIcons.times],
//   onToggle:
  
//    (index) {
//       reading(context)
//     print('switched to: $index');
//   },
// ),