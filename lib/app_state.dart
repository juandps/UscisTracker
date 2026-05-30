import 'package:flutter/material.dart';
import '/backend/schema/structs/index.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'dart:convert';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _titlee = '';
  String get titlee => _titlee;
  set titlee(String value) {
    _titlee = value;
  }

  List<EventssStruct> _eventsss = [
    EventssStruct.fromSerializableMap(
        jsonDecode('{\"title\":\"test event\",\"dayy\":\"1719525060000\"}'))
  ];
  List<EventssStruct> get eventsss => _eventsss;
  set eventsss(List<EventssStruct> value) {
    _eventsss = value;
  }

  void addToEventsss(EventssStruct value) {
    eventsss.add(value);
  }

  void removeFromEventsss(EventssStruct value) {
    eventsss.remove(value);
  }

  void removeAtIndexFromEventsss(int index) {
    eventsss.removeAt(index);
  }

  void updateEventsssAtIndex(
    int index,
    EventssStruct Function(EventssStruct) updateFn,
  ) {
    eventsss[index] = updateFn(_eventsss[index]);
  }

  void insertAtIndexInEventsss(int index, EventssStruct value) {
    eventsss.insert(index, value);
  }

  DateTime? _dayyy = DateTime.fromMillisecondsSinceEpoch(1701634080000);
  DateTime? get dayyy => _dayyy;
  set dayyy(DateTime? value) {
    _dayyy = value;
  }

  List<DateTime> _blockDays = [
    DateTime.fromMillisecondsSinceEpoch(1719611460000),
    DateTime.fromMillisecondsSinceEpoch(1719786660000)
  ];
  List<DateTime> get blockDays => _blockDays;
  set blockDays(List<DateTime> value) {
    _blockDays = value;
  }

  void addToBlockDays(DateTime value) {
    blockDays.add(value);
  }

  void removeFromBlockDays(DateTime value) {
    blockDays.remove(value);
  }

  void removeAtIndexFromBlockDays(int index) {
    blockDays.removeAt(index);
  }

  void updateBlockDaysAtIndex(
    int index,
    DateTime Function(DateTime) updateFn,
  ) {
    blockDays[index] = updateFn(_blockDays[index]);
  }

  void insertAtIndexInBlockDays(int index, DateTime value) {
    blockDays.insert(index, value);
  }

  dynamic _RespuestaCaso;
  dynamic get RespuestaCaso => _RespuestaCaso;
  set RespuestaCaso(dynamic value) {
    _RespuestaCaso = value;
  }

  String _RespuestaChatGPT = '';
  String get RespuestaChatGPT => _RespuestaChatGPT;
  set RespuestaChatGPT(String value) {
    _RespuestaChatGPT = value;
  }

  int _CaseAPIResponseCode = 0;
  int get CaseAPIResponseCode => _CaseAPIResponseCode;
  set CaseAPIResponseCode(int value) {
    _CaseAPIResponseCode = value;
  }
}
