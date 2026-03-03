class WorkEntryPhoto {
  final int? id;
  final String? path;
  final String? thumbnail;
  final String? name;
  final String? format;

  WorkEntryPhoto({
    this.id,
    this.path,
    this.thumbnail,
    this.name,
    this.format,
  });

  factory WorkEntryPhoto.fromJson(Map<String, dynamic> json) {
    return WorkEntryPhoto(
      id: json['id'],
      path: json['path'],
      thumbnail: json['thumbnail'],
      name: json['name'],
      format: json['format'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'thumbnail': thumbnail,
      'name': name,
      'format': format,
    };
  }

  String? get fullUrl {
    if (name == null) return null;
    final ext = format ?? 'jpg';
    return 'https://sieveserp.ams3.cdn.digitaloceanspaces.com/work-entries/full/$name.$ext';
  }
}

class WorkEntry {
  final int? id;
  final int? employeeId;
  final int? branchId;
  final String? checkInTime;
  final String? checkOutTime;
  final String? status;
  final String? type;
  final String? note;
  final int? checkInPhotoId;
  final int? checkOutPhotoId;
  final DateTime? createdAt;
  final WorkEntryPhoto? checkInPhoto;
  final WorkEntryPhoto? checkOutPhoto;

  WorkEntry({
    this.id,
    this.employeeId,
    this.branchId,
    this.checkInTime,
    this.checkOutTime,
    this.status,
    this.type,
    this.note,
    this.checkInPhotoId,
    this.checkOutPhotoId,
    this.createdAt,
    this.checkInPhoto,
    this.checkOutPhoto,
  });

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      id: json['id'],
      employeeId: json['employee_id'],
      branchId: json['branch_id'],
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      status: json['status'],
      type: json['type'],
      note: json['note']?.toString(),
      checkInPhotoId: json['check_in_photo_id'],
      checkOutPhotoId: json['check_out_photo_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      checkInPhoto: json['checkInPhoto'] != null
          ? WorkEntryPhoto.fromJson(json['checkInPhoto'])
          : null,
      checkOutPhoto: json['checkOutPhoto'] != null
          ? WorkEntryPhoto.fromJson(json['checkOutPhoto'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'branch_id': branchId,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'status': status,
      'type': type,
      'note': note,
      'check_in_photo_id': checkInPhotoId,
      'check_out_photo_id': checkOutPhotoId,
      'created_at': createdAt?.toIso8601String(),
      'checkInPhoto': checkInPhoto?.toJson(),
      'checkOutPhoto': checkOutPhoto?.toJson(),
    };
  }

  // Helper to check if entry is open (no check out time)
  bool get isOpen => checkOutTime == null || checkOutTime!.isEmpty;

  // Helper to format check-in date
  String get formattedDate {
    if (checkInTime == null) return '';
    try {
      final dateTime = DateTime.parse(checkInTime!);
      return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  // Helper to format check-in time
  String get formattedCheckInTime {
    if (checkInTime == null) return '';
    try {
      final dateTime = DateTime.parse(checkInTime!);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  // Helper to format check-out time
  String get formattedCheckOutTime {
    if (checkOutTime == null) return '-';
    try {
      final dateTime = DateTime.parse(checkOutTime!);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }

  // Helper to get display status
  String get displayStatus => status ?? 'Unknown';

  // Helper to get mood emoji based on note value
  String get moodEmoji {
    if (note == null) return '-';
    
    final noteValue = int.tryParse(note!) ?? 60;
    
    if (noteValue <= 20) {
      return '😡'; // angry
    } else if (noteValue <= 40) {
      return '😕'; // sad
    } else if (noteValue <= 60) {
      return '😐'; // neutral
    } else if (noteValue <= 80) {
      return '😊'; // good mood
    } else {
      return '🤩'; // great mood
    }
  }
}
