// ✅ Login Request Model
class LoginRequestModel {
  final String email;
  final String password;

  LoginRequestModel({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

// ✅ Login Response Model
class LoginResponseModel {
  final String date;
  final String entry;
  final String message;
  final String token;
  final UserDetailsModel details;
  final OfflineDataModel offlineData;
  final TimeStatsModel times;

  LoginResponseModel({
    required this.date,
    required this.entry,
    required this.message,
    required this.token,
    required this.details,
    required this.offlineData,
    required this.times,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      date: json['date'],
      entry: json['entry'],
      message: json['message'],
      token: json['token'],
      details: UserDetailsModel.fromJson(json['details']),
      offlineData: OfflineDataModel.fromJson(json['offline_data']),
      times: TimeStatsModel.fromJson(json['times']),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'entry': entry,
    'message': message,
    'token': token,
    'details': details.toJson(),
    'offline_data': offlineData.toJson(),
    'times': times.toJson(),
  };
}

// ✅ User Details Model
class UserDetailsModel {
  final String? bio;
  final String? company;
  final String? department;
  final String? dob;
  final String? email;
  final String? employeeId;
  final String? gender;
  final String? hourlyEmp;
  final String? id;
  final String? job;
  final String? name;
  final String? phone;
  final String? profilePic;
  final String? userType;

  UserDetailsModel({
    this.bio,
    this.company,
    this.department,
    this.dob,
    this.email,
    this.employeeId,
    this.gender,
    this.hourlyEmp,
    this.id,
    this.job,
    this.name,
    this.phone,
    this.profilePic,
    this.userType,
  });

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) {
    return UserDetailsModel(
      bio: json['bio'],
      company: json['company'],
      department: json['department'],
      dob: json['dob'],
      email: json['email'],
      employeeId: json['employee_id'],
      gender: json['gender'],
      hourlyEmp: json['hourlyEmp'],
      id: json['id'],
      job: json['job'],
      name: json['name'],
      phone: json['phone'],
      profilePic: json['profile_pic'],
      userType: json['userType'],
    );
  }

  Map<String, dynamic> toJson() => {
    'bio': bio,
    'company': company,
    'department': department,
    'dob': dob,
    'email': email,
    'employee_id': employeeId,
    'gender': gender,
    'hourlyEmp': hourlyEmp,
    'id': id,
    'job': job,
    'name': name,
    'phone': phone,
    'profile_pic': profilePic,
    'userType': userType,
  };
}

// ✅ Offline Data Model
class OfflineDataModel {
  final List<String> response;
  String startTime;

  OfflineDataModel({required this.response, required this.startTime});

  factory OfflineDataModel.fromJson(Map<String, dynamic> json) {
    return OfflineDataModel(response: List<String>.from(json['response']), startTime: json['startTime']);
  }

  Map<String, dynamic> toJson() => {'response': response, 'startTime': startTime};
}

// ✅ Time Stats Model
class TimeStatsModel {
  final String callTime;
  final String elapsedTime;
  final String totalElapsedTime;

  TimeStatsModel({required this.callTime, required this.elapsedTime, required this.totalElapsedTime});

  factory TimeStatsModel.fromJson(Map<String, dynamic> json) {
    return TimeStatsModel(
      callTime: json['call_time'],
      elapsedTime: json['elapsed_time'],
      totalElapsedTime: json['total_elapsed_time'],
    );
  }

  Map<String, dynamic> toJson() => {
    'call_time': callTime,
    'elapsed_time': elapsedTime,
    'total_elapsed_time': totalElapsedTime,
  };
}
