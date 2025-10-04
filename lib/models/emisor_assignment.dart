class EmisorAssignment {
  final String id;
  final String type; // 'general', 'facultad', 'carrera', 'programa'
  final String areaId;
  final String areaName;
  final String? parentAreaId; // Para carreras, el ID de la facultad padre
  final String? parentAreaName; // Para carreras, el nombre de la facultad padre

  EmisorAssignment({
    required this.id,
    required this.type,
    required this.areaId,
    required this.areaName,
    this.parentAreaId,
    this.parentAreaName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'areaId': areaId,
      'areaName': areaName,
      'parentAreaId': parentAreaId,
      'parentAreaName': parentAreaName,
    };
  }

  factory EmisorAssignment.fromMap(Map<String, dynamic> map) {
    return EmisorAssignment(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      areaId: map['areaId'] ?? '',
      areaName: map['areaName'] ?? '',
      parentAreaId: map['parentAreaId'],
      parentAreaName: map['parentAreaName'],
    );
  }

  // Método para verificar si esta asignación cubre a un estudiante
  bool coversStudent({
    required String? studentFacultyId,
    required String? studentCareerId,
    required String? studentProgramId,
  }) {
    switch (type) {
      case 'general':
        return true;
      case 'facultad':
        return studentFacultyId == areaId;
      case 'carrera':
        return studentCareerId == areaId;
      case 'programa':
        return studentProgramId == areaId;
      default:
        return false;
    }
  }

  // Método para obtener el nivel de la asignación
  int get level {
    switch (type) {
      case 'general':
        return 0;
      case 'facultad':
        return 1;
      case 'carrera':
        return 2;
      case 'programa':
        return 3;
      default:
        return 4;
    }
  }

  // Método para obtener el texto descriptivo
  String get displayText {
    switch (type) {
      case 'general':
        return 'Todos los estudiantes';
      case 'facultad':
        return 'Facultad: $areaName';
      case 'carrera':
        return 'Carrera: $areaName';
      case 'programa':
        return 'Programa: $areaName';
      default:
        return areaName;
    }
  }

  // Método para obtener el icono
  String get icon {
    switch (type) {
      case 'general':
        return '🌐';
      case 'facultad':
        return '🏛️';
      case 'carrera':
        return '🎓';
      case 'programa':
        return '📚';
      default:
        return '📋';
    }
  }
}
