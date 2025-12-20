class FaceVerificationResult {
  final bool success;
  final String? employeeId;
  final String? employeeName;
  final String? employeePhoto;
  final String? message;
  final DateTime? verificationTime;
  final Map<String, dynamic>? additionalData;

  FaceVerificationResult({
    required this.success,
    this.employeeId,
    this.employeeName,
    this.employeePhoto,
    this.message,
    this.verificationTime,
    this.additionalData,
  });

  factory FaceVerificationResult.fromJson(Map<String, dynamic> json) {
    return FaceVerificationResult(
      success: json['success'] ?? false,
      employeeId: json['employeeId']?.toString(),
      employeeName: json['employeeName'],
      employeePhoto: json['employeePhoto'],
      message: json['message'],
      verificationTime: json['verificationTime'] != null
          ? DateTime.parse(json['verificationTime'])
          : null,
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeePhoto': employeePhoto,
      'message': message,
      'verificationTime': verificationTime?.toIso8601String(),
      'additionalData': additionalData,
    };
  }
}
