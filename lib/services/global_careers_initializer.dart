// lib/services/global_careers_initializer.dart
// Servicio para inicializar carreras globales comunes

import 'package:supabase_flutter/supabase_flutter.dart';

class GlobalCareersInitializer {
  static final SupabaseClient _client = Supabase.instance.client;

  // Lista de carreras globales comunes
  static final List<Map<String, dynamic>> globalCareers = [
    // Ingenierías
    {
      'name': 'Ingeniería de Sistemas',
      'code': 'ING-SIS',
      'careerCode': 'ING-SIS',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el desarrollo de software y sistemas informáticos',
      'category': 'Ingeniería',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Ingeniería Industrial',
      'code': 'ING-IND',
      'careerCode': 'ING-IND',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la optimización de procesos industriales',
      'category': 'Ingeniería',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Ingeniería Civil',
      'code': 'ING-CIV',
      'careerCode': 'ING-CIV',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la construcción y diseño de infraestructura',
      'category': 'Ingeniería',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Ingeniería Mecánica',
      'code': 'ING-MEC',
      'careerCode': 'ING-MEC',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el diseño y mantenimiento de sistemas mecánicos',
      'category': 'Ingeniería',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Ingeniería Electrónica',
      'code': 'ING-ELE',
      'careerCode': 'ING-ELE',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en sistemas electrónicos y circuitos',
      'category': 'Ingeniería',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Ingeniería Química',
      'code': 'ING-QUI',
      'careerCode': 'ING-QUI',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en procesos químicos industriales',
      'category': 'Ingeniería',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },

    // Ciencias de la Salud
    {
      'name': 'Medicina',
      'code': 'MED-GEN',
      'careerCode': 'MED-GEN',
      'duration': 12,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el diagnóstico y tratamiento de enfermedades',
      'category': 'Ciencias de la Salud',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Enfermería',
      'code': 'ENF-GEN',
      'careerCode': 'ENF-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el cuidado y atención de pacientes',
      'category': 'Ciencias de la Salud',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Odontología',
      'code': 'ODO-GEN',
      'careerCode': 'ODO-GEN',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la salud bucal y dental',
      'category': 'Ciencias de la Salud',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Psicología',
      'code': 'PSI-GEN',
      'careerCode': 'PSI-GEN',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio del comportamiento humano',
      'category': 'Ciencias de la Salud',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },

    // Ciencias Económicas y Administrativas
    {
      'name': 'Administración de Empresas',
      'code': 'ADM-EMP',
      'careerCode': 'ADM-EMP',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la gestión y administración empresarial',
      'category': 'Ciencias Económicas',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Contaduría Pública',
      'code': 'CON-PUB',
      'careerCode': 'CON-PUB',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la contabilidad y finanzas',
      'category': 'Ciencias Económicas',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Economía',
      'code': 'ECO-GEN',
      'careerCode': 'ECO-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio de los sistemas económicos',
      'category': 'Ciencias Económicas',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Mercadeo',
      'code': 'MER-GEN',
      'careerCode': 'MER-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en estrategias de mercado y ventas',
      'category': 'Ciencias Económicas',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },

    // Ciencias Sociales y Humanas
    {
      'name': 'Derecho',
      'code': 'DER-GEN',
      'careerCode': 'DER-GEN',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio de las leyes y la justicia',
      'category': 'Ciencias Sociales',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Comunicación Social',
      'code': 'COM-SOC',
      'careerCode': 'COM-SOC',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en medios de comunicación y periodismo',
      'category': 'Ciencias Sociales',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Trabajo Social',
      'code': 'TRA-SOC',
      'careerCode': 'TRA-SOC',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el apoyo y desarrollo social',
      'category': 'Ciencias Sociales',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },

    // Ciencias Básicas
    {
      'name': 'Matemáticas',
      'code': 'MAT-GEN',
      'careerCode': 'MAT-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio de las matemáticas puras',
      'category': 'Ciencias Básicas',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Física',
      'code': 'FIS-GEN',
      'careerCode': 'FIS-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio de las leyes físicas',
      'category': 'Ciencias Básicas',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Química',
      'code': 'QUI-GEN',
      'careerCode': 'QUI-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio de la materia y sus transformaciones',
      'category': 'Ciencias Básicas',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Biología',
      'code': 'BIO-GEN',
      'careerCode': 'BIO-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio de los seres vivos',
      'category': 'Ciencias Básicas',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },

    // Artes y Diseño
    {
      'name': 'Arquitectura',
      'code': 'ARQ-GEN',
      'careerCode': 'ARQ-GEN',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el diseño y construcción de espacios',
      'category': 'Artes y Diseño',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Diseño Gráfico',
      'code': 'DIS-GRA',
      'careerCode': 'DIS-GRA',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la comunicación visual y diseño',
      'category': 'Artes y Diseño',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Artes Plásticas',
      'code': 'ART-PLA',
      'careerCode': 'ART-PLA',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la expresión artística y creativa',
      'category': 'Artes y Diseño',
      'is_global': true,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
  ];

  // Inicializar carreras globales en la base de datos
  static Future<Map<String, dynamic>> initializeGlobalCareers() async {
    try {
      int addedCount = 0;
      int skippedCount = 0;

      for (final career in globalCareers) {
        // Verificar si la carrera ya existe
        final existingCareer = await _client
            .from('programs')
            .select('id')
            .eq('name', career['name'])
            .eq('is_global', true)
            .limit(1);

        if (existingCareer.isEmpty) {
          // Agregar la carrera global
          await _client.from('programs').insert(career);
          addedCount++;
        } else {
          skippedCount++;
        }
      }

      return {
        'success': true,
        'message': 'Carreras globales inicializadas exitosamente',
        'added': addedCount,
        'skipped': skippedCount,
        'total': globalCareers.length,
      };
    } catch (e) {
      print('Error inicializando carreras globales: $e');
      return {
        'success': false,
        'message': 'Error al inicializar carreras globales: $e',
        'added': 0,
        'skipped': 0,
        'total': globalCareers.length,
      };
    }
  }

  // Obtener todas las carreras globales
  static Future<List<Map<String, dynamic>>> getGlobalCareers() async {
    try {
      final response = await _client
          .from('programs')
          .select('*')
          .eq('is_global', true)
          .eq('status', 'active');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo carreras globales: $e');
      return [];
    }
  }

  // Agregar una nueva carrera global
  static Future<Map<String, dynamic>> addGlobalCareer(Map<String, dynamic> careerData) async {
    try {
      // Verificar si ya existe
      final existingCareer = await _client
          .from('programs')
          .select('id')
          .eq('name', careerData['name'])
          .eq('is_global', true)
          .limit(1);

      if (existingCareer.isNotEmpty) {
        return {
          'success': false,
          'message': 'La carrera ya existe en el sistema global',
        };
      }

      // Agregar como carrera global
      final globalCareer = {
        ...careerData,
        'is_global': true,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client.from('programs').insert(globalCareer);

      return {
        'success': true,
        'message': 'Carrera global agregada exitosamente',
      };
    } catch (e) {
      print('Error agregando carrera global: $e');
      return {
        'success': false,
        'message': 'Error al agregar carrera global: $e',
      };
    }
  }
}
