// lib/services/global_careers_initializer.dart
// Servicio para inicializar carreras globales comunes

import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalCareersInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Ingeniería Industrial',
      'code': 'ING-IND',
      'careerCode': 'ING-IND',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la optimización de procesos industriales',
      'category': 'Ingeniería',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Ingeniería Civil',
      'code': 'ING-CIV',
      'careerCode': 'ING-CIV',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la construcción y diseño de infraestructura',
      'category': 'Ingeniería',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Ingeniería Mecánica',
      'code': 'ING-MEC',
      'careerCode': 'ING-MEC',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el diseño y mantenimiento de sistemas mecánicos',
      'category': 'Ingeniería',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Ingeniería Electrónica',
      'code': 'ING-ELE',
      'careerCode': 'ING-ELE',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en sistemas electrónicos y circuitos',
      'category': 'Ingeniería',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Ingeniería Química',
      'code': 'ING-QUI',
      'careerCode': 'ING-QUI',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en procesos químicos industriales',
      'category': 'Ingeniería',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
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
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Enfermería',
      'code': 'ENF-GEN',
      'careerCode': 'ENF-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el cuidado y atención de pacientes',
      'category': 'Ciencias de la Salud',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Odontología',
      'code': 'ODO-GEN',
      'careerCode': 'ODO-GEN',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la salud bucal y dental',
      'category': 'Ciencias de la Salud',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Psicología',
      'code': 'PSI-GEN',
      'careerCode': 'PSI-GEN',
      'duration': 10,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio del comportamiento humano',
      'category': 'Ciencias de la Salud',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
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
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Contaduría Pública',
      'code': 'CON-PUB',
      'careerCode': 'CON-PUB',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la contabilidad y finanzas',
      'category': 'Ciencias Económicas',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Economía',
      'code': 'ECO-GEN',
      'careerCode': 'ECO-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio de los sistemas económicos',
      'category': 'Ciencias Económicas',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Mercadeo',
      'code': 'MER-GEN',
      'careerCode': 'MER-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en estrategias de mercado y ventas',
      'category': 'Ciencias Económicas',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
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
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Comunicación Social',
      'code': 'COM-SOC',
      'careerCode': 'COM-SOC',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en medios de comunicación y periodismo',
      'category': 'Ciencias Sociales',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Trabajo Social',
      'code': 'TRA-SOC',
      'careerCode': 'TRA-SOC',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el apoyo y desarrollo social',
      'category': 'Ciencias Sociales',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
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
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Física',
      'code': 'FIS-GEN',
      'careerCode': 'FIS-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio de las leyes físicas',
      'category': 'Ciencias Básicas',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Química',
      'code': 'QUI-GEN',
      'careerCode': 'QUI-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio de la materia y sus transformaciones',
      'category': 'Ciencias Básicas',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Biología',
      'code': 'BIO-GEN',
      'careerCode': 'BIO-GEN',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en el estudio de los seres vivos',
      'category': 'Ciencias Básicas',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
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
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Diseño Gráfico',
      'code': 'DIS-GRA',
      'careerCode': 'DIS-GRA',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la comunicación visual y diseño',
      'category': 'Artes y Diseño',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Artes Plásticas',
      'code': 'ART-PLA',
      'careerCode': 'ART-PLA',
      'duration': 8,
      'modality': 'presencial',
      'description': 'Carrera enfocada en la expresión artística y creativa',
      'category': 'Artes y Diseño',
      'isGlobal': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  // Inicializar carreras globales en la base de datos
  static Future<Map<String, dynamic>> initializeGlobalCareers() async {
    try {
      int addedCount = 0;
      int skippedCount = 0;

      for (final career in globalCareers) {
        // Verificar si la carrera ya existe
        QuerySnapshot existingCareer = await _firestore
            .collection('programs')
            .where('name', isEqualTo: career['name'])
            .where('isGlobal', isEqualTo: true)
            .get();

        if (existingCareer.docs.isEmpty) {
          // Agregar la carrera global
          await _firestore.collection('programs').add(career);
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
      QuerySnapshot querySnapshot = await _firestore
          .collection('programs')
          .where('isGlobal', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error obteniendo carreras globales: $e');
      return [];
    }
  }

  // Agregar una nueva carrera global
  static Future<Map<String, dynamic>> addGlobalCareer(Map<String, dynamic> careerData) async {
    try {
      // Verificar si ya existe
      QuerySnapshot existingCareer = await _firestore
          .collection('programs')
          .where('name', isEqualTo: careerData['name'])
          .where('isGlobal', isEqualTo: true)
          .get();

      if (existingCareer.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'La carrera ya existe en el sistema global',
        };
      }

      // Agregar como carrera global
      final globalCareer = {
        ...careerData,
        'isGlobal': true,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('programs').add(globalCareer);

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
