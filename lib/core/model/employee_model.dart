// employee_model.dart
class Employee {
  final int? id;
  final int? companyId;
  final int? branchId;
  final int? jobPositionId;
  final int? departmentId;
  final int? individualId;
  final String? faceUuid;
  final int? rewardId;
  final String? status;
  final Individual? individual;
  final Branch? branch;

  Employee({
    this.id,
    this.companyId,
    this.branchId,
    this.jobPositionId,
    this.departmentId,
    this.individualId,
    this.faceUuid,
    this.rewardId,
    this.status,
    this.individual,
    this.branch,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      companyId: json['company_id'],
      branchId: json['branch_id'],
      jobPositionId: json['job_position_id'],
      departmentId: json['department_id'],
      individualId: json['individual_id'],
      faceUuid: json['face_uuid'],
      rewardId: json['reward_id'],
      status: json['status'],
      individual: json['individual'] != null ? Individual.fromJson(json['individual']) : null,
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'branch_id': branchId,
      'job_position_id': jobPositionId,
      'department_id': departmentId,
      'individual_id': individualId,
      'face_uuid': faceUuid,
      'reward_id': rewardId,
      'status': status,
      'individual': individual?.toJson(),
      'branch': branch?.toJson(),
    };
  }
}

class Individual {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;

  Individual({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
  });

  factory Individual.fromJson(Map<String, dynamic> json) {
    return Individual(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
    };
  }
}

class Branch {
  final int? id;
  final String? name;
  final String? address;

  Branch({
    this.id,
    this.name,
    this.address,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
    };
  }
}