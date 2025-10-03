class HistoryRecord {
  final int? id;
  final int? employeeId;
  final int? branchId;
  final String? title;
  final String? description;
  final String? type;
  final DateTime? createdAt;
  final Branch? branch;

  HistoryRecord({
    this.id,
    this.employeeId,
    this.branchId,
    this.title,
    this.description,
    this.type,
    this.createdAt,
    this.branch,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      id: json['id'],
      employeeId: json['employee_id'],
      branchId: json['branch_id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      branch: json['branch'] != null 
          ? Branch.fromJson(json['branch']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'branch_id': branchId,
      'title': title,
      'description': description,
      'type': type,
      'created_at': createdAt?.toIso8601String(),
      'branch': branch?.toJson(),
    };
  }

  // Helper to format date and time
  String get formattedDateTime {
    if (createdAt == null) return '';
    return '${createdAt!.day.toString().padLeft(2, '0')}-${createdAt!.month.toString().padLeft(2, '0')}-${createdAt!.year} ${createdAt!.hour.toString().padLeft(2, '0')}:${createdAt!.minute.toString().padLeft(2, '0')}:${createdAt!.second.toString().padLeft(2, '0')}';
  }

  // Helper to get branch name
  String get branchName => branch?.name ?? 'Unknown';

  // Helper to get display type
  String get displayType => type ?? 'Unknown';
  
  // Helper to get display title
  String get displayTitle => title ?? type ?? 'Unknown';
  
  // Helper to get display description
  String get displayDescription => description ?? 'No description';
}

class Branch {
  final int? id;
  final String? name;
  final String? code;
  final String? timezone;
  final String? startWork;
  final String? endWork;
  final int? isHq;
  final String? workDays;
  final String? lat;
  final String? lng;
  final DateTime? createdAt;

  Branch({
    this.id,
    this.name,
    this.code,
    this.timezone,
    this.startWork,
    this.endWork,
    this.isHq,
    this.workDays,
    this.lat,
    this.lng,
    this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      timezone: json['timezone'],
      startWork: json['start_work'],
      endWork: json['end_work'],
      isHq: json['is_hq'],
      workDays: json['work_days'],
      lat: json['lat']?.toString(),
      lng: json['lng']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'timezone': timezone,
      'start_work': startWork,
      'end_work': endWork,
      'is_hq': isHq,
      'work_days': workDays,
      'lat': lat,
      'lng': lng,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
