import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/case_record.dart';

class CaseStatusService {
  CaseStatusService({http.Client? client}) : _client = client ?? http.Client();

  static const proxyBaseUrl =
      String.fromEnvironment('CASE_STATUS_API_BASE_URL');

  final http.Client _client;

  static final _uscisReceiptPattern = RegExp(
    r'^(EAC|IOE|LIN|MCT|MGL|MSC|NBC|SRC|WAC|YSC|ZAR|ZCH|ZHN)\d{10}$',
  );

  bool isValidReceipt(String value) {
    return _uscisReceiptPattern.hasMatch(normalizeReceipt(value));
  }

  String normalizeReceipt(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  }

  Uri officialStatusUri(String receiptNumber) {
    return Uri.https('egov.uscis.gov', '/casestatus/mycasestatus.do', {
      'appReceiptNum': normalizeReceipt(receiptNumber),
    });
  }

  Future<CaseStatusSnapshot> refresh(ImmigrationCase item) async {
    final receipt = normalizeReceipt(item.receiptNumber);
    if (!isValidReceipt(receipt)) {
      throw CaseStatusException('Receipt number must look like IOE1234567890.');
    }

    if (proxyBaseUrl.trim().isEmpty) {
      return CaseStatusSnapshot(
        title: item.statusTitle.isEmpty ? 'Ready to verify' : item.statusTitle,
        description: item.statusDescription.isEmpty
            ? 'Open the official USCIS case page or configure CASE_STATUS_API_BASE_URL for live background refresh.'
            : item.statusDescription,
        stage: item.stage,
        checkedAt: DateTime.now(),
        source: 'local',
      );
    }

    final base = Uri.parse(proxyBaseUrl);
    final path = [
      ...base.pathSegments.where((part) => part.isNotEmpty),
      'case-status',
      receipt,
    ];
    final uri = base.replace(pathSegments: path);
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CaseStatusException(
        'Status service returned ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw CaseStatusException('Status service returned an unexpected shape.');
    }

    return CaseStatusSnapshot.fromJson(decoded, fallbackStage: item.stage);
  }
}

class CaseStatusSnapshot {
  const CaseStatusSnapshot({
    required this.title,
    required this.description,
    required this.stage,
    required this.checkedAt,
    required this.source,
    this.statusDate,
    this.nextStep = '',
  });

  final String title;
  final String description;
  final CaseStage stage;
  final DateTime checkedAt;
  final DateTime? statusDate;
  final String nextStep;
  final String source;

  factory CaseStatusSnapshot.fromJson(
    Map<String, dynamic> json, {
    required CaseStage fallbackStage,
  }) {
    final nested = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final title = _firstString(nested, const [
      'statusTitle',
      'caseStatus',
      'status',
      'title',
      'current_status',
    ]);
    final description = _firstString(nested, const [
      'statusDescription',
      'description',
      'details',
      'message',
    ]);
    final stageName = _firstString(nested, const ['stage', 'phase']);

    return CaseStatusSnapshot(
      title: title.isEmpty ? 'Status checked' : title,
      description: description,
      stage: _stageFromText(stageName.isEmpty ? title : stageName) ??
          fallbackStage,
      checkedAt: DateTime.now(),
      statusDate: _dateFromValue(nested['statusDate'] ?? nested['date']),
      nextStep: _firstString(nested, const ['nextStep', 'next_step']),
      source: _firstString(nested, const ['source']).isEmpty
          ? 'proxy'
          : _firstString(nested, const ['source']),
    );
  }
}

class CaseStatusException implements Exception {
  const CaseStatusException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}

CaseStage? _stageFromText(String value) {
  final text = value.toLowerCase();
  if (text.contains('fingerprint') || text.contains('biometric')) {
    return CaseStage.biometrics;
  }
  if (text.contains('request for evidence') || text.contains('rfe')) {
    return CaseStage.evidence;
  }
  if (text.contains('interview')) {
    return CaseStage.interview;
  }
  if (text.contains('approved') ||
      text.contains('denied') ||
      text.contains('decision')) {
    return CaseStage.decision;
  }
  if (text.contains('closed') || text.contains('card was delivered')) {
    return CaseStage.closed;
  }
  if (text.contains('received') || text.contains('notice')) {
    return CaseStage.intake;
  }
  if (text.contains('review')) {
    return CaseStage.review;
  }
  return null;
}

DateTime? _dateFromValue(dynamic value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
