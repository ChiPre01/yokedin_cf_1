
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Widget currentTime(DateTime? dateTime) {
  if (dateTime == null) {
    return const Text('--:--');
  }

  final time = DateFormat('h:mm a').format(dateTime);

  return Text(" $time", style: TextStyle(fontSize: 12));
}
