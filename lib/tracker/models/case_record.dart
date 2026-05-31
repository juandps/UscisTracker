import 'package:intl/intl.dart';

enum CaseStage {
  intake,
  biometrics,
  review,
  evidence,
  interview,
  decision,
  closed,
}

extension CaseStageLabel on CaseStage {
  String get label {
    switch (this) {
      case CaseStage.intake:
        return 'Intake';
      case CaseStage.biometrics:
        return 'Biometrics';
      case CaseStage.review:
        return 'Review';
      case CaseStage.evidence:
        return 'Evidence';
      case CaseStage.interview:
        return 'Interview';
      case CaseStage.decision:
        return 'Decision';
      case CaseStage.closed:
        return 'Closed';
    }
  }

  double get progress {
    switch (this) {
      case CaseStage.intake:
        return .14;
      case CaseStage.biometrics:
        return .28;
      case CaseStage.review:
        return .48;
      case CaseStage.evidence:
        return .62;
      case CaseStage.interview:
        return .78;
      case CaseStage.decision:
        return .92;
      case CaseStage.closed:
        return 1;
    }
  }
}

class ImmigrationCase {
  ImmigrationCase({
    required this.id,
    required this.receiptNumber,
    required this.formType,
    required this.nickname,
    required this.applicantName,
    required this.stage,
    required this.statusTitle,
    required this.statusDescription,
    required this.filedDate,
    this.priorityDate,
    this.serviceCenter = '',
    this.lastCheckedAt,
    this.lastStatusChangeAt,
    this.statusSource = 'local',
    this.nextStep = '',
    this.notes = '',
    this.notifyOnStatusChange = true,
    List<CaseEvent>? history,
    List<CaseTask>? checklist,
  })  : history = history ?? const [],
        checklist = checklist ?? defaultChecklistFor(formType);

  final String id;
  final String receiptNumber;
  final String formType;
  final String nickname;
  final String applicantName;
  final CaseStage stage;
  final String statusTitle;
  final String statusDescription;
  final DateTime filedDate;
  final DateTime? priorityDate;
  final String serviceCenter;
  final DateTime? lastCheckedAt;
  final DateTime? lastStatusChangeAt;
  final String statusSource;
  final String nextStep;
  final String notes;
  final bool notifyOnStatusChange;
  final List<CaseEvent> history;
  final List<CaseTask> checklist;

  String get displayName => nickname.trim().isEmpty ? formType : nickname;

  String get shortReceipt {
    if (receiptNumber.length <= 6) {
      return receiptNumber;
    }
    return '${receiptNumber.substring(0, 3)} ${receiptNumber.substring(3)}';
  }

  int get daysOpen {
    final days = DateTime.now().difference(filedDate).inDays;
    return days < 0 ? 0 : days.clamp(0, 9999).toInt();
  }

  bool get isClosed => stage == CaseStage.closed;

  int get completedTasks => checklist.where((task) => task.isDone).length;

  String get filedDateLabel => DateFormat.yMMMd().format(filedDate);

  String get priorityDateLabel => priorityDate == null
      ? 'Not set'
      : DateFormat.yMMMd().format(priorityDate!);

  String get lastCheckedLabel {
    if (lastCheckedAt == null) {
      return 'Not checked yet';
    }
    return DateFormat.yMMMd().add_jm().format(lastCheckedAt!);
  }

  ImmigrationCase copyWith({
    String? id,
    String? receiptNumber,
    String? formType,
    String? nickname,
    String? applicantName,
    CaseStage? stage,
    String? statusTitle,
    String? statusDescription,
    DateTime? filedDate,
    Object? priorityDate = _sentinel,
    String? serviceCenter,
    Object? lastCheckedAt = _sentinel,
    Object? lastStatusChangeAt = _sentinel,
    String? statusSource,
    String? nextStep,
    String? notes,
    bool? notifyOnStatusChange,
    List<CaseEvent>? history,
    List<CaseTask>? checklist,
  }) {
    return ImmigrationCase(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      formType: formType ?? this.formType,
      nickname: nickname ?? this.nickname,
      applicantName: applicantName ?? this.applicantName,
      stage: stage ?? this.stage,
      statusTitle: statusTitle ?? this.statusTitle,
      statusDescription: statusDescription ?? this.statusDescription,
      filedDate: filedDate ?? this.filedDate,
      priorityDate: priorityDate == _sentinel
          ? this.priorityDate
          : priorityDate as DateTime?,
      serviceCenter: serviceCenter ?? this.serviceCenter,
      lastCheckedAt: lastCheckedAt == _sentinel
          ? this.lastCheckedAt
          : lastCheckedAt as DateTime?,
      lastStatusChangeAt: lastStatusChangeAt == _sentinel
          ? this.lastStatusChangeAt
          : lastStatusChangeAt as DateTime?,
      statusSource: statusSource ?? this.statusSource,
      nextStep: nextStep ?? this.nextStep,
      notes: notes ?? this.notes,
      notifyOnStatusChange: notifyOnStatusChange ?? this.notifyOnStatusChange,
      history: history ?? this.history,
      checklist: checklist ?? this.checklist,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiptNumber': receiptNumber,
      'formType': formType,
      'nickname': nickname,
      'applicantName': applicantName,
      'stage': stage.name,
      'statusTitle': statusTitle,
      'statusDescription': statusDescription,
      'filedDate': filedDate.toIso8601String(),
      'priorityDate': priorityDate?.toIso8601String(),
      'serviceCenter': serviceCenter,
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
      'lastStatusChangeAt': lastStatusChangeAt?.toIso8601String(),
      'statusSource': statusSource,
      'nextStep': nextStep,
      'notes': notes,
      'notifyOnStatusChange': notifyOnStatusChange,
      'history': history.map((event) => event.toJson()).toList(),
      'checklist': checklist.map((task) => task.toJson()).toList(),
    };
  }

  factory ImmigrationCase.fromJson(Map<String, dynamic> json) {
    final formType = (json['formType'] as String?)?.trim().isNotEmpty == true
        ? json['formType'] as String
        : 'I-485';
    return ImmigrationCase(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      receiptNumber: json['receiptNumber'] as String? ?? '',
      formType: formType,
      nickname: json['nickname'] as String? ?? '',
      applicantName: json['applicantName'] as String? ?? '',
      stage: CaseStage.values.firstWhere(
        (stage) => stage.name == json['stage'],
        orElse: () => CaseStage.review,
      ),
      statusTitle: json['statusTitle'] as String? ?? 'Ready to verify',
      statusDescription: json['statusDescription'] as String? ?? '',
      filedDate: _dateFromJson(json['filedDate']) ?? DateTime.now(),
      priorityDate: _dateFromJson(json['priorityDate']),
      serviceCenter: json['serviceCenter'] as String? ?? '',
      lastCheckedAt: _dateFromJson(json['lastCheckedAt']),
      lastStatusChangeAt: _dateFromJson(json['lastStatusChangeAt']),
      statusSource: json['statusSource'] as String? ?? 'local',
      nextStep: json['nextStep'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      notifyOnStatusChange: json['notifyOnStatusChange'] as bool? ?? true,
      history: (json['history'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CaseEvent.fromJson)
          .toList(),
      checklist: (json['checklist'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CaseTask.fromJson)
          .toList(),
    );
  }
}

class CaseEvent {
  const CaseEvent({
    required this.id,
    required this.title,
    required this.date,
    this.description = '',
    this.source = 'manual',
  });

  final String id;
  final String title;
  final DateTime date;
  final String description;
  final String source;

  String get dateLabel => DateFormat.yMMMd().format(date);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
      'source': source,
    };
  }

  factory CaseEvent.fromJson(Map<String, dynamic> json) {
    return CaseEvent(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      date: _dateFromJson(json['date']) ?? DateTime.now(),
      description: json['description'] as String? ?? '',
      source: json['source'] as String? ?? 'manual',
    );
  }
}

class CaseTask {
  const CaseTask({
    required this.id,
    required this.title,
    this.description = '',
    this.isDone = false,
    this.dueDate,
  });

  final String id;
  final String title;
  final String description;
  final bool isDone;
  final DateTime? dueDate;

  CaseTask copyWith({
    String? id,
    String? title,
    String? description,
    bool? isDone,
    Object? dueDate = _sentinel,
  }) {
    return CaseTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory CaseTask.fromJson(Map<String, dynamic> json) {
    return CaseTask(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
      dueDate: _dateFromJson(json['dueDate']),
    );
  }
}

class CaseDraft {
  const CaseDraft({
    required this.receiptNumber,
    required this.formType,
    required this.nickname,
    required this.applicantName,
    required this.filedDate,
    this.priorityDate,
    this.serviceCenter = '',
  });

  final String receiptNumber;
  final String formType;
  final String nickname;
  final String applicantName;
  final DateTime filedDate;
  final DateTime? priorityDate;
  final String serviceCenter;
}

List<CaseTask> defaultChecklistFor(String formType) {
  final normalized = formType.toUpperCase();
  final interviewTask = normalized.contains('485') ||
      normalized.contains('130') ||
      normalized.contains('400');
  return [
    const CaseTask(
      id: 'receipt',
      title: 'Save receipt notice',
      description: 'Store the I-797 notice and receipt number.',
      isDone: true,
    ),
    const CaseTask(
      id: 'account',
      title: 'Link to USCIS account',
      description: 'Add the receipt number to your USCIS online account.',
    ),
    const CaseTask(
      id: 'biometrics',
      title: 'Watch for biometrics notice',
      description: 'Track appointment date, location, and reschedule window.',
    ),
    if (interviewTask)
      const CaseTask(
        id: 'interview',
        title: 'Prepare interview packet',
        description:
            'Keep IDs, notices, originals, and updated evidence ready.',
      ),
    const CaseTask(
      id: 'address',
      title: 'Confirm address stays current',
      description: 'File AR-11 promptly after any move.',
    ),
  ];
}

DateTime? _dateFromJson(dynamic value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

const Object _sentinel = Object();
