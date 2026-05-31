import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/backend/schema/structs/index.dart';
import 'tracker/models/case_record.dart';
import 'tracker/services/case_repository.dart';
import 'tracker/services/case_status_service.dart';

enum CaseSortMode {
  priority,
  lastChecked,
  filedDate,
  stage,
  name,
}

extension CaseSortModeLabel on CaseSortMode {
  String get label {
    switch (this) {
      case CaseSortMode.priority:
        return 'Priority';
      case CaseSortMode.lastChecked:
        return 'Last checked';
      case CaseSortMode.filedDate:
        return 'Filed date';
      case CaseSortMode.stage:
        return 'Stage';
      case CaseSortMode.name:
        return 'Name';
    }
  }
}

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  final CaseRepository _caseRepository = CaseRepository();
  final CaseStatusService _caseStatusService = CaseStatusService();

  bool _trackerInitialized = false;
  bool get trackerInitialized => _trackerInitialized;

  List<ImmigrationCase> _cases = [];
  List<ImmigrationCase> get cases => List.unmodifiable(_cases);

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  CaseSortMode _sortMode = CaseSortMode.priority;
  CaseSortMode get sortMode => _sortMode;

  String? _selectedCaseId;
  String? get selectedCaseId => _selectedCaseId;

  String? _lastError;
  String? get lastError => _lastError;

  final Set<String> _refreshingCaseIds = {};

  Future initializePersistedState() async {
    if (_trackerInitialized) {
      return;
    }
    _cases = await _caseRepository.loadCases();
    _selectedCaseId = _cases.isEmpty ? null : _sortedCases(_cases).first.id;
    _trackerInitialized = true;
    notifyListeners();
  }

  List<ImmigrationCase> get visibleCases {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _cases
        : _cases.where((item) {
            final haystack = [
              item.receiptNumber,
              item.formType,
              item.nickname,
              item.applicantName,
              item.statusTitle,
              item.serviceCenter,
            ].join(' ').toLowerCase();
            return haystack.contains(query);
          }).toList();
    return _sortedCases(filtered);
  }

  ImmigrationCase? get selectedCase {
    if (_cases.isEmpty) {
      return null;
    }
    return _cases.where((item) => item.id == _selectedCaseId).firstOrNull ??
        visibleCases.firstOrNull ??
        _cases.first;
  }

  int get activeCaseCount => _cases.where((item) => !item.isClosed).length;

  int get closedCaseCount => _cases.length - activeCaseCount;

  int get changedThisMonth {
    final threshold = DateTime.now().subtract(const Duration(days: 30));
    return _cases
        .where((item) =>
            item.lastStatusChangeAt != null &&
            item.lastStatusChangeAt!.isAfter(threshold))
        .length;
  }

  double get checklistProgress {
    final tasks = _cases.expand((item) => item.checklist).toList();
    if (tasks.isEmpty) {
      return 0;
    }
    return tasks.where((task) => task.isDone).length / tasks.length;
  }

  bool isRefreshing(String caseId) => _refreshingCaseIds.contains(caseId);

  void selectCase(String caseId) {
    if (_selectedCaseId == caseId) {
      return;
    }
    _selectedCaseId = caseId;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setSortMode(CaseSortMode value) {
    _sortMode = value;
    notifyListeners();
  }

  Future<void> addCase(CaseDraft draft) async {
    final receipt = _caseStatusService.normalizeReceipt(draft.receiptNumber);
    final now = DateTime.now();
    final item = ImmigrationCase(
      id: now.microsecondsSinceEpoch.toString(),
      receiptNumber: receipt,
      formType: draft.formType.trim().isEmpty ? 'I-485' : draft.formType.trim(),
      nickname: draft.nickname.trim(),
      applicantName: draft.applicantName.trim(),
      serviceCenter: draft.serviceCenter.trim(),
      filedDate: draft.filedDate,
      priorityDate: draft.priorityDate,
      stage: CaseStage.intake,
      statusTitle: 'Ready to verify',
      statusDescription:
          'Open the official USCIS status page or connect a private status proxy for background refresh.',
      nextStep:
          'Save the receipt notice and verify the status from the official source.',
      lastStatusChangeAt: now,
      statusSource: 'local',
      history: [
        CaseEvent(
          id: '${now.microsecondsSinceEpoch}-added',
          title: 'Case added',
          date: now,
          description: 'Started tracking ${receipt.toUpperCase()}.',
          source: 'local',
        ),
      ],
    );
    _cases = [..._cases, item];
    _selectedCaseId = item.id;
    _lastError = null;
    await _save();
  }

  Future<void> addDemoCase() async {
    await addCase(
      CaseDraft(
        receiptNumber: 'IOE0923456789',
        formType: 'I-485',
        nickname: 'Adjustment of status',
        applicantName: 'Personal case',
        filedDate: DateTime.now().subtract(const Duration(days: 126)),
        priorityDate: DateTime.now().subtract(const Duration(days: 220)),
        serviceCenter: 'National Benefits Center',
      ),
    );
    final item = selectedCase;
    if (item == null) {
      return;
    }
    await updateCase(
      item.copyWith(
        stage: CaseStage.review,
        statusTitle: 'Case Is Being Actively Reviewed By USCIS',
        statusDescription:
            'USCIS is reviewing the case. Keep evidence, notices, and address information current.',
        nextStep: 'Watch for biometrics, RFE, interview, or decision notices.',
        history: [
          ...item.history,
          CaseEvent(
            id: '${DateTime.now().microsecondsSinceEpoch}-review',
            title: 'Case moved to active review',
            date: DateTime.now().subtract(const Duration(days: 88)),
            description: 'Sample status history for layout testing.',
            source: 'demo',
          ),
        ],
      ),
    );
  }

  Future<void> updateCase(ImmigrationCase updated) async {
    _cases =
        _cases.map((item) => item.id == updated.id ? updated : item).toList();
    _lastError = null;
    await _save();
  }

  Future<void> deleteCase(String caseId) async {
    _cases = _cases.where((item) => item.id != caseId).toList();
    if (_selectedCaseId == caseId) {
      _selectedCaseId = _cases.isEmpty ? null : _sortedCases(_cases).first.id;
    }
    _lastError = null;
    await _save();
  }

  Future<void> refreshCase(String caseId) async {
    final item = _cases.where((caseItem) => caseItem.id == caseId).firstOrNull;
    if (item == null || _refreshingCaseIds.contains(caseId)) {
      return;
    }

    _refreshingCaseIds.add(caseId);
    _lastError = null;
    notifyListeners();

    try {
      final snapshot = await _caseStatusService.refresh(item);
      final changed = snapshot.title != item.statusTitle ||
          snapshot.description != item.statusDescription ||
          snapshot.stage != item.stage;
      final checkedAt = snapshot.checkedAt;
      final nextHistory = changed
          ? [
              CaseEvent(
                id: '${checkedAt.microsecondsSinceEpoch}-status',
                title: snapshot.title,
                date: snapshot.statusDate ?? checkedAt,
                description: snapshot.description,
                source: snapshot.source,
              ),
              ...item.history,
            ]
          : item.history;

      await updateCase(
        item.copyWith(
          statusTitle: snapshot.title,
          statusDescription: snapshot.description,
          stage: snapshot.stage,
          lastCheckedAt: checkedAt,
          lastStatusChangeAt: changed
              ? (snapshot.statusDate ?? checkedAt)
              : item.lastStatusChangeAt,
          statusSource: snapshot.source,
          nextStep:
              snapshot.nextStep.isEmpty ? item.nextStep : snapshot.nextStep,
          history: nextHistory,
        ),
      );
    } on CaseStatusException catch (error) {
      _lastError = error.message;
    } catch (error) {
      _lastError = 'Could not refresh this case right now.';
    } finally {
      _refreshingCaseIds.remove(caseId);
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    for (final item in List<ImmigrationCase>.from(_cases)) {
      await refreshCase(item.id);
    }
  }

  Future<void> toggleTask(
    String caseId,
    String taskId, {
    required bool isDone,
  }) async {
    final item = _cases.where((caseItem) => caseItem.id == caseId).firstOrNull;
    if (item == null) {
      return;
    }

    final checklist = item.checklist
        .map((task) => task.id == taskId ? task.copyWith(isDone: isDone) : task)
        .toList();
    await updateCase(item.copyWith(checklist: checklist));
  }

  Future<void> appendNote(String caseId, String note) async {
    final clean = note.trim();
    if (clean.isEmpty) {
      return;
    }
    final item = _cases.where((caseItem) => caseItem.id == caseId).firstOrNull;
    if (item == null) {
      return;
    }
    final timestamp = DateFormat.yMMMd().add_jm().format(DateTime.now());
    final nextNotes = item.notes.trim().isEmpty
        ? '[$timestamp] $clean'
        : '${item.notes}\n\n[$timestamp] $clean';
    await updateCase(item.copyWith(notes: nextNotes));
  }

  Uri officialStatusUri(String receiptNumber) {
    return _caseStatusService.officialStatusUri(receiptNumber);
  }

  bool isValidReceipt(String receiptNumber) {
    return _caseStatusService.isValidReceipt(receiptNumber);
  }

  Future<void> _save() async {
    await _caseRepository.saveCases(_cases);
    notifyListeners();
  }

  List<ImmigrationCase> _sortedCases(List<ImmigrationCase> source) {
    final sorted = List<ImmigrationCase>.from(source);
    sorted.sort((a, b) {
      switch (_sortMode) {
        case CaseSortMode.priority:
          return _priorityRank(a).compareTo(_priorityRank(b));
        case CaseSortMode.lastChecked:
          return (b.lastCheckedAt ?? DateTime(1900))
              .compareTo(a.lastCheckedAt ?? DateTime(1900));
        case CaseSortMode.filedDate:
          return b.filedDate.compareTo(a.filedDate);
        case CaseSortMode.stage:
          return a.stage.index.compareTo(b.stage.index);
        case CaseSortMode.name:
          return a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase());
      }
    });
    return sorted;
  }

  int _priorityRank(ImmigrationCase item) {
    if (item.isClosed) {
      return 9000 + item.daysOpen;
    }
    final staleDays = item.lastCheckedAt == null
        ? 90
        : DateTime.now().difference(item.lastCheckedAt!).inDays;
    return item.stage.index * 100 - staleDays;
  }

  // Compatibility fields retained for the original FlutterFlow-generated files.
  String _titlee = '';
  String get titlee => _titlee;
  set titlee(String value) {
    _titlee = value;
  }

  List<EventssStruct> _eventsss = [
    EventssStruct.fromSerializableMap(
      jsonDecode('{"title":"test event","dayy":"1719525060000"}'),
    ),
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
    DateTime.fromMillisecondsSinceEpoch(1719786660000),
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

  dynamic _respuestaCaso;
  dynamic get RespuestaCaso => _respuestaCaso;
  set RespuestaCaso(dynamic value) {
    _respuestaCaso = value;
  }

  String _respuestaChatGPT = '';
  String get RespuestaChatGPT => _respuestaChatGPT;
  set RespuestaChatGPT(String value) {
    _respuestaChatGPT = value;
  }

  int _caseAPIResponseCode = 0;
  int get CaseAPIResponseCode => _caseAPIResponseCode;
  set CaseAPIResponseCode(int value) {
    _caseAPIResponseCode = value;
  }
}
