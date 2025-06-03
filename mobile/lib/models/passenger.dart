class Passenger {
  final String fullName;
  final int age;
  final String gender;
  final String idType;
  final String idNumber;
  final String seat;
  final bool isSenior;
  final String passengerType;

  Passenger({
    required this.fullName,
    required this.age,
    required this.gender,
    required this.idType,
    required this.idNumber,
    required this.seat,
    this.isSenior = false,
    this.passengerType = 'Adult',
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      fullName: json['name'] ?? json['fullName'] ?? '',
      age: int.tryParse(json['age'].toString()) ?? 30,
      gender: json['gender'] ?? 'male',
      idType: json['id_type'] ?? json['idType'] ?? '',
      idNumber: json['id_number'] ?? json['idNumber'] ?? '',
      seat: json['seat'] ?? '',
      isSenior: json['is_senior'] ?? json['isSenior'] ?? false,
      passengerType: json['passengerType'] ?? 'Adult',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': fullName,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'id_type': idType,
      'idType': idType,
      'id_number': idNumber,
      'idNumber': idNumber,
      'seat': seat,
      'is_senior': isSenior,
      'isSenior': isSenior,
      'passengerType': passengerType,
    };
  }

  @override
  String toString() {
    return 'Passenger{fullName: $fullName, age: $age, gender: $gender, seat: $seat, passengerType: $passengerType}';
  }
}
