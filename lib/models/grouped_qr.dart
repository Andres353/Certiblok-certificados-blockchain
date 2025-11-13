// lib/models/grouped_qr.dart
// Modelo para QRs agrupados guardados

class GroupedQR {
  final String id;
  final String name;
  final String qrUrl;
  final List<String> certificateIds;
  final List<String> certificateTitles;
  final DateTime createdAt;
  final String studentId;
  final String studentName;

  GroupedQR({
    required this.id,
    required this.name,
    required this.qrUrl,
    required this.certificateIds,
    required this.certificateTitles,
    required this.createdAt,
    required this.studentId,
    required this.studentName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'qrUrl': qrUrl,
      'certificateIds': certificateIds,
      'certificateTitles': certificateTitles,
      'createdAt': createdAt.toIso8601String(),
      'studentId': studentId,
      'studentName': studentName,
    };
  }

  factory GroupedQR.fromMap(Map<String, dynamic> map) {
    return GroupedQR(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      qrUrl: map['qrUrl'] ?? '',
      certificateIds: List<String>.from(map['certificateIds'] ?? []),
      certificateTitles: List<String>.from(map['certificateTitles'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
    );
  }

  factory GroupedQR.fromSupabase(Map<String, dynamic> data) {
    return GroupedQR(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      qrUrl: data['qr_url'] ?? '',
      certificateIds: List<String>.from(data['certificate_ids'] ?? []),
      certificateTitles: List<String>.from(data['certificate_titles'] ?? []),
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      studentId: data['student_id']?.toString() ?? '',
      studentName: data['student_name'] ?? '',
    );
  }

  GroupedQR copyWith({
    String? id,
    String? name,
    String? qrUrl,
    List<String>? certificateIds,
    List<String>? certificateTitles,
    DateTime? createdAt,
    String? studentId,
    String? studentName,
  }) {
    return GroupedQR(
      id: id ?? this.id,
      name: name ?? this.name,
      qrUrl: qrUrl ?? this.qrUrl,
      certificateIds: certificateIds ?? this.certificateIds,
      certificateTitles: certificateTitles ?? this.certificateTitles,
      createdAt: createdAt ?? this.createdAt,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
    );
  }
}
