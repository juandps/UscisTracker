import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'home_widget.dart' show HomeWidget;
import 'package:flutter/material.dart';

class HomeModel extends FlutterFlowModel<HomeWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Backend Call - API (UscisToken)] action in Button widget.
  ApiCallResponse? apitoken;
  // Stores action output result for [Backend Call - API (getstatus)] action in Button widget.
  ApiCallResponse? apiResult1mf;
  // Stores action output result for [Backend Call - API (UscisToken)] action in Button widget.
  ApiCallResponse? apitoken2;
  // Stores action output result for [Backend Call - API (getstatus)] action in Button widget.
  ApiCallResponse? apiResult1mf2;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
