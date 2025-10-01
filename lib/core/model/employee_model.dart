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
  final JobPosition? jobPosition;
  final Department? department;
  final Reward? reward;

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
    this.jobPosition,
    this.department,
    this.reward,
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
      jobPosition: json['job_position'] != null ? JobPosition.fromJson(json['job_position']) : null,
      department: json['department'] != null ? Department.fromJson(json['department']) : null,
      reward: json['reward'] != null ? Reward.fromJson(json['reward']) : null,
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
      'job_position': jobPosition?.toJson(),
      'department': department?.toJson(),
      'reward': reward?.toJson(),
    };
  }
}

class Individual {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? photo;

  Individual({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.photo,
  });

  factory Individual.fromJson(Map<String, dynamic> json) {
    return Individual(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      phone: json['phone'],
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'photo': photo,
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

class JobPosition {
  final int? id;
  final String? name;

  JobPosition({
    this.id,
    this.name,
  });

  factory JobPosition.fromJson(Map<String, dynamic> json) {
    return JobPosition(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Department {
  final int? id;
  final String? name;

  Department({
    this.id,
    this.name,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Reward {
  final int? id;
  final String? name;
  final double? amount;
  final String? type;

  Reward({
    this.id,
    this.name,
    this.amount,
    this.type,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      name: json['name'],
      amount: json['amount']?.toDouble(),
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type,
    };
  }
}