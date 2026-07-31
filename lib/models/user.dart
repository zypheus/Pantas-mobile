class User {
  final String id;
  final String name;
  final String email;
  final String? role;
  final String? studentId;
  final String? studentNumber;
  final String? employeeId;
  final String? department;
  final String? designation;
  final String? firstName;
  final String? lastName;
  final String? middleInitial;
  final String? course;
  final String? year;
  final String? birthday;
  final String? mobileNumber;
  final String? address;
  final String? emergencyContact;
  final String? emergencyPerson;
  final String? emergencyRelationship;
  final String? emergencyNumber;
  final String? emergencyAddress;
  final String? profilePicture;
  final String accountStatus; // e.g., Active, Suspended
  final String? libraryQrCode;
  final int borrowingLimit;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.studentId,
    this.studentNumber,
    this.employeeId,
    this.department,
    this.designation,
    this.firstName,
    this.lastName,
    this.middleInitial,
    this.course,
    this.year,
    this.birthday,
    this.mobileNumber,
    this.address,
    this.emergencyContact,
    this.emergencyPerson,
    this.emergencyRelationship,
    this.emergencyNumber,
    this.emergencyAddress,
    this.profilePicture,
    required this.accountStatus,
    this.libraryQrCode,
    required this.borrowingLimit,
  });

  bool get isFaculty => role?.toLowerCase() == 'faculty';
  bool get isStudent => role?.toLowerCase() == 'student' || (!isFaculty && studentNumber != null);

  factory User.fromApiJson(Map<String, dynamic> json) {
    final userJson = _asMap(json['user'] ?? json);
    final studentJson = _asMap(json['student']);
    final facultyJson = _asMap(json['faculty']);
    final role = userJson['role']?.toString();
    final isFaculty = role?.toLowerCase() == 'faculty';
    final profileJson = isFaculty ? facultyJson : studentJson;

    return User(
      id: _stringValue(userJson['id']),
      name: _stringValue(
        userJson['name'] ??
            _personName(profileJson) ??
            userJson['email'] ??
            'User',
      ),
      email: _stringValue(userJson['email'] ?? facultyJson['email']),
      role: role,
      studentId: _nullableString(studentJson['id'] ?? userJson['student_id']),
      studentNumber: _nullableString(studentJson['id_number']),
      employeeId: _nullableString(facultyJson['employee_id']),
      department: _nullableString(facultyJson['department']),
      designation: _nullableString(facultyJson['designation']),
      firstName: _nullableString(
        profileJson['firstname'] ?? userJson['fname'] ?? userJson['first_name'],
      ),
      lastName: _nullableString(
        profileJson['lastname'] ?? userJson['lname'] ?? userJson['last_name'],
      ),
      middleInitial: _nullableString(
        profileJson['middle_initial'] ?? profileJson['middle_name'],
      ),
      course: _nullableString(studentJson['course']),
      year: _nullableString(studentJson['year']),
      birthday: _nullableString(profileJson['birthday'] ?? profileJson['birth_date']),
      mobileNumber: _nullableString(profileJson['mobile_number']),
      address: _nullableString(studentJson['address']),
      emergencyContact: _nullableString(
        studentJson['emergency_contact'] ?? studentJson['emergency_contact_name'],
      ),
      emergencyPerson: _nullableString(
        studentJson['emergency_person'] ?? studentJson['emergency_contact_person'],
      ),
      emergencyRelationship: _nullableString(
        studentJson['emergency_relationship'] ?? studentJson['relationship'],
      ),
      emergencyNumber: _nullableString(
        studentJson['emergency_number'] ?? studentJson['emergency_phone'],
      ),
      emergencyAddress: _nullableString(
        studentJson['emergency_address'] ?? studentJson['emergency_contact_address'],
      ),
      profilePicture: _nullableString(
        profileJson['profile_picture'] ?? userJson['profile_picture'] ?? userJson['avatar'],
      ),
      accountStatus: _stringValue(
        userJson['account_status'] ??
            facultyJson['account_status'] ??
            studentJson['status'] ??
            'Active',
      ),
      libraryQrCode: _nullableString(
        studentJson['qr_code'] ??
            studentJson['qr_code_data'] ??
            studentJson['library_qr_code'],
      ),
      borrowingLimit: _intValue(userJson['borrowing_limit'], fallback: 0),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (lastName != null) 'last_name': lastName,
      if (firstName != null) 'first_name': firstName,
      if (middleInitial != null) 'middle_initial': middleInitial,
      if (birthday != null) 'birthday': birthday,
      if (course != null) 'course': course,
      if (year != null) 'year': year,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      if (address != null) 'address': address,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
      if (emergencyPerson != null) 'emergency_person': emergencyPerson,
      if (emergencyRelationship != null) 'emergency_relationship': emergencyRelationship,
      if (emergencyNumber != null) 'emergency_number': emergencyNumber,
      if (emergencyAddress != null) 'emergency_address': emergencyAddress,
    };
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static String _stringValue(Object? value) => value?.toString() ?? '';

  static String? _nullableString(Object? value) {
    final stringValue = value?.toString();
    return stringValue == null || stringValue.isEmpty ? null : stringValue;
  }

  static int _intValue(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String? _personName(Map<String, dynamic> personJson) {
    final firstName = _nullableString(
      personJson['firstname'] ?? personJson['first_name'],
    );
    final lastName = _nullableString(
      personJson['lastname'] ?? personJson['last_name'],
    );

    final parts = [firstName, lastName].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(' ');
  }
}
