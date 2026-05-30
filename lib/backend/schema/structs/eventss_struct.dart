// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EventssStruct extends BaseStruct {
  EventssStruct({
    String? title,
    DateTime? dayy,
  })  : _title = title,
        _dayy = dayy;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  set title(String? val) => _title = val;

  bool hasTitle() => _title != null;

  // "dayy" field.
  DateTime? _dayy;
  DateTime? get dayy => _dayy;
  set dayy(DateTime? val) => _dayy = val;

  bool hasDayy() => _dayy != null;

  static EventssStruct fromMap(Map<String, dynamic> data) => EventssStruct(
        title: data['title'] as String?,
        dayy: data['dayy'] as DateTime?,
      );

  static EventssStruct? maybeFromMap(dynamic data) =>
      data is Map ? EventssStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'title': _title,
        'dayy': _dayy,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'title': serializeParam(
          _title,
          ParamType.String,
        ),
        'dayy': serializeParam(
          _dayy,
          ParamType.DateTime,
        ),
      }.withoutNulls;

  static EventssStruct fromSerializableMap(Map<String, dynamic> data) =>
      EventssStruct(
        title: deserializeParam(
          data['title'],
          ParamType.String,
          false,
        ),
        dayy: deserializeParam(
          data['dayy'],
          ParamType.DateTime,
          false,
        ),
      );

  @override
  String toString() => 'EventssStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is EventssStruct && title == other.title && dayy == other.dayy;
  }

  @override
  int get hashCode => const ListEquality().hash([title, dayy]);
}

EventssStruct createEventssStruct({
  String? title,
  DateTime? dayy,
}) =>
    EventssStruct(
      title: title,
      dayy: dayy,
    );
