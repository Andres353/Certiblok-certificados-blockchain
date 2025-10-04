// lib/constants/emisor_types.dart
// Tipos de emisores en el sistema multi-tenant

enum EmisorType {
  general,    // Puede emitir certificados para toda la universidad
  carrera,    // Solo para su carrera específica
  facultad,   // Solo para su facultad específica
}

extension EmisorTypeExtension on EmisorType {
  String get displayName {
    switch (this) {
      case EmisorType.general:
        return 'General';
      case EmisorType.carrera:
        return 'Por Carrera';
      case EmisorType.facultad:
        return 'Por Facultad';
    }
  }

  String get description {
    switch (this) {
      case EmisorType.general:
        return 'Puede emitir certificados para toda la universidad';
      case EmisorType.carrera:
        return 'Solo puede emitir certificados de su carrera específica';
      case EmisorType.facultad:
        return 'Solo puede emitir certificados de su facultad específica';
    }
  }

  String get icon {
    switch (this) {
      case EmisorType.general:
        return 'school';
      case EmisorType.carrera:
        return 'menu_book';
      case EmisorType.facultad:
        return 'account_balance';
    }
  }
}

// Convertir desde string (Firestore)
EmisorType emisorTypeFromString(String type) {
  switch (type.toLowerCase()) {
    case 'general':
      return EmisorType.general;
    case 'carrera':
      return EmisorType.carrera;
    case 'facultad':
      return EmisorType.facultad;
    default:
      return EmisorType.general;
  }
}

// Convertir a string (Firestore)
String emisorTypeToString(EmisorType type) {
  switch (type) {
    case EmisorType.general:
      return 'general';
    case EmisorType.carrera:
      return 'carrera';
    case EmisorType.facultad:
      return 'facultad';
  }
}
