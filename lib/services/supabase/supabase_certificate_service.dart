// lib/services/supabase/supabase_certificate_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:web3dart/web3dart.dart';
import '../user_context_service.dart';
import '../emisor_permission_service.dart';
import 'supabase_config.dart';
import '../blockchain/blockchain_service.dart';
import '../blockchain/blockchain_config.dart';
import '../certificate_notification_service.dart';

class SupabaseCertificate {
  final String id;
  final String uniqueHash;
  final String institutionId;
  final String institutionName;
  final String institutionCode;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String studentIdInInstitution;
  final String programId;
  final String programName;
  final String facultyId;
  final String facultyName;
  final String certificateType;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final String? blockchainHash;
  final String qrCode;
  final DateTime issuedAt;
  final String issuedBy;
  final String issuedByName;
  final String issuedByRole;
  final String status;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String? revokedBy;
  final String? revokedReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, dynamic>> validationHistory;

  SupabaseCertificate({
    required this.id,
    required this.uniqueHash,
    required this.institutionId,
    required this.institutionName,
    required this.institutionCode,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.studentIdInInstitution,
    required this.programId,
    required this.programName,
    required this.facultyId,
    required this.facultyName,
    required this.certificateType,
    required this.title,
    required this.description,
    required this.data,
    this.blockchainHash,
    required this.qrCode,
    required this.issuedAt,
    required this.issuedBy,
    required this.issuedByName,
    required this.issuedByRole,
    required this.status,
    this.expiresAt,
    this.revokedAt,
    this.revokedBy,
    this.revokedReason,
    required this.createdAt,
    required this.updatedAt,
    required this.validationHistory,
  });

  // Constructor desde Supabase
  factory SupabaseCertificate.fromSupabase(Map<String, dynamic> data) {
    return SupabaseCertificate(
      id: data['id'] ?? '',
      uniqueHash: data['unique_hash'] ?? '',
      institutionId: data['institution_id'] ?? '',
      institutionName: data['institution_name'] ?? '',
      institutionCode: data['institution_code'] ?? '',
      studentId: data['student_id'] ?? '',
      studentName: data['student_name'] ?? '',
      studentEmail: data['student_email'] ?? '',
      studentIdInInstitution: data['student_id_in_institution'] ?? '',
      programId: data['program_id'] ?? '',
      programName: data['program_name'] ?? '',
      facultyId: data['faculty_id'] ?? '',
      facultyName: data['faculty_name'] ?? '',
      certificateType: data['certificate_type'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      blockchainHash: data['blockchain_hash'],
      qrCode: data['qr_code'] ?? '',
      issuedAt: data['issued_at'] != null 
          ? DateTime.parse(data['issued_at'])
          : DateTime.now(),
      issuedBy: data['issued_by'] ?? '',
      issuedByName: data['issued_by_name'] ?? '',
      issuedByRole: data['issued_by_role'] ?? '',
      status: data['status'] ?? 'active',
      expiresAt: data['expires_at'] != null 
          ? DateTime.parse(data['expires_at'])
          : null,
      revokedAt: data['revoked_at'] != null 
          ? DateTime.parse(data['revoked_at'])
          : null,
      revokedBy: data['revoked_by'] ?? (data['data'] != null && data['data'] is Map ? (data['data'] as Map<String, dynamic>)['revoked_by'] : null),
      revokedReason: data['revoked_reason'] ?? (data['data'] != null && data['data'] is Map ? (data['data'] as Map<String, dynamic>)['revoked_reason'] : null),
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null 
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
      validationHistory: List<Map<String, dynamic>>.from(data['validation_history'] ?? []),
    );
  }

  // Convertir a Map para Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'unique_hash': uniqueHash,
      'institution_id': institutionId,
      'institution_name': institutionName,
      'institution_code': institutionCode,
      'student_id': studentId,
      'student_name': studentName,
      'student_email': studentEmail,
      'student_id_in_institution': studentIdInInstitution,
      'program_id': programId,
      'program_name': programName,
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'certificate_type': certificateType,
      'title': title,
      'description': description,
      'data': data,
      'blockchain_hash': blockchainHash,
      'qr_code': qrCode,
      'issued_at': issuedAt.toIso8601String(),
      'issued_by': issuedBy,
      'issued_by_name': issuedByName,
      'issued_by_role': issuedByRole,
      'status': status,
      'expires_at': expiresAt?.toIso8601String(),
      'revoked_at': revokedAt?.toIso8601String(),
      'revoked_by': revokedBy,
      'revoked_reason': revokedReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'validation_history': validationHistory,
    };
  }

  // Convertir a Map genérico
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unique_hash': uniqueHash,
      'institution_id': institutionId,
      'institution_name': institutionName,
      'institution_code': institutionCode,
      'student_id': studentId,
      'student_name': studentName,
      'student_email': studentEmail,
      'student_id_in_institution': studentIdInInstitution,
      'program_id': programId,
      'program_name': programName,
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'certificate_type': certificateType,
      'title': title,
      'description': description,
      'data': data,
      'blockchain_hash': blockchainHash,
      'qr_code': qrCode,
      'issued_at': issuedAt.toIso8601String(),
      'issued_by': issuedBy,
      'issued_by_name': issuedByName,
      'issued_by_role': issuedByRole,
      'status': status,
      'expires_at': expiresAt?.toIso8601String(),
      'revoked_at': revokedAt?.toIso8601String(),
      'revoked_by': revokedBy,
      'revoked_reason': revokedReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'validation_history': validationHistory,
    };
  }
}

class SupabaseCertificateService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Generar hash único del certificado
  static String generateUniqueHash(String certificateId, DateTime issuedAt, String studentId, String institutionId) {
    final data = '$certificateId-$issuedAt-$studentId-$institutionId';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generar código QR para validación
  static String generateQRCode(String certificateId, String institutionCode) {
    // Detectar el puerto automáticamente basado en la URL actual
    final currentUrl = Uri.base.toString();
    String port = '8081'; // Puerto por defecto
    
    if (currentUrl.contains(':8080')) {
      port = '8080';
    } else if (currentUrl.contains(':8081')) {
      port = '8081';
    } else if (currentUrl.contains(':8082')) {
      port = '8082';
    }
    
    return 'http://localhost:$port/#/verify/certificate/$certificateId';
  }

  // Crear nuevo certificado
  static Future<String> createCertificate({
    required String studentId,
    required String certificateType,
    required String title,
    required String description,
    required Map<String, dynamic> data,
    String? institutionId,
    DateTime? expiresAt,
  }) async {
    try {
      // Verificar contexto de usuario
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener información del estudiante
      final studentResponse = await _client
          .from('users')
          .select('*')
          .eq('id', studentId)
          .single();

      if (studentResponse.isEmpty) {
        throw Exception('Estudiante no encontrado');
      }

      final studentData = studentResponse;
      final studentName = studentData['full_name'] ?? '';
      final studentEmail = studentData['email'] ?? '';
      final studentIdInInstitution = studentData['student_id'] ?? '';

      // Determinar institución según el rol
      String targetInstitutionId;
      String institutionName;
      String institutionCode;

      if (context.isSuperAdmin) {
        targetInstitutionId = institutionId ?? '';
        if (targetInstitutionId.isEmpty) {
          throw Exception('Super admin debe especificar institución');
        }
        
        final institutionResponse = await _client
            .from('institutions')
            .select('*')
            .eq('id', targetInstitutionId)
            .single();

        if (institutionResponse.isEmpty) {
          throw Exception('Institución no encontrada');
        }
        
        final institutionData = institutionResponse;
        institutionName = institutionData['name'] ?? '';
        institutionCode = institutionData['institution_code'] ?? '';
      } else {
        targetInstitutionId = context.institutionId ?? '';
        if (targetInstitutionId.isEmpty) {
          throw Exception('Usuario debe tener institución asignada');
        }
        
        final institutionResponse = await _client
            .from('institutions')
            .select('*')
            .eq('id', targetInstitutionId)
            .single();

        if (institutionResponse.isEmpty) {
          throw Exception('Institución no encontrada');
        }
        
        final institutionData = institutionResponse;
        institutionName = institutionData['name'] ?? '';
        institutionCode = institutionData['institution_code'] ?? '';
      }

      // Verificar permisos según el rol
      if (context.userRole == 'emisor') {
        final canEmit = await EmisorPermissionService.canEmitForStudent(
          studentId: studentId,
          institutionId: targetInstitutionId,
        );
        
        if (!canEmit) {
          throw Exception('No tienes permisos para emitir certificados para este estudiante');
        }
      } else if (!['super_admin', 'admin_institution'].contains(context.userRole)) {
        throw Exception('No tienes permisos para emitir certificados');
      }

      // Obtener información adicional del estudiante
      final programId = studentData['program_id'] ?? '';
      final programName = studentData['program'] ?? '';
      final facultyId = studentData['faculty_id'] ?? '';
      final facultyName = studentData['faculty'] ?? '';

      // Generar ID único para el certificado
      final certificateId = const Uuid().v4();
      final issuedAt = DateTime.now();
      final uniqueHash = generateUniqueHash(certificateId, issuedAt, studentId, targetInstitutionId);
      final qrCode = generateQRCode(certificateId, institutionCode);

      // Crear el certificado
      final certificateData = {
        'id': certificateId,
        'unique_hash': uniqueHash,
        'institution_id': targetInstitutionId,
        'institution_name': institutionName,
        'institution_code': institutionCode,
        'student_id': studentId,
        'student_name': studentName,
        'student_email': studentEmail,
        'student_id_in_institution': studentIdInInstitution,
        'program_id': programId,
        'program_name': programName,
        'faculty_id': facultyId,
        'faculty_name': facultyName,
        'certificate_type': certificateType,
        'title': title,
        'description': description,
        'data': data,
        'qr_code': qrCode,
        'issued_at': issuedAt.toIso8601String(),
        'issued_by': context.userId,
        'issued_by_name': context.userName,
        'issued_by_role': context.userRole,
        'status': 'active',
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'validation_history': [],
      };

      // OBLIGATORIO: Emitir en blockchain antes de guardar en base de datos
      String blockchainTransactionHash;
      String certificateBlockchainHash; // Hash del certificado (no de la transacción)
      try {
        final blockchainService = BlockchainService();
        certificateBlockchainHash = BlockchainService.generateCertificateHash(
          certificateId: certificateId,
          studentId: studentId,
          institutionId: targetInstitutionId,
          issuedAt: issuedAt,
        );
        
        // Verificar que el servicio esté inicializado
        final contractAddress = BlockchainConfig.contractAddress;
        if (contractAddress == '0x0000000000000000000000000000000000000000') {
          throw Exception('El contrato blockchain no está configurado. Contacta al administrador del sistema para configurar la wallet blockchain.');
        }
        
        await blockchainService.initialize(contractAddress);
        
        // Verificar si hay wallet configurada, si no, generar una automáticamente
        final currentAddress = await blockchainService.getCurrentWalletAddress();
        if (currentAddress == null) {
          print('⚠️ No se encontró wallet. Generando nueva wallet automáticamente...');
          final newWallet = await blockchainService.generateNewWallet();
          final walletAddress = newWallet['address'];
          print('✅ Wallet generada: $walletAddress');
          print('⚠️ IMPORTANTE: Envía MATIC a esta dirección desde MetaMask para poder emitir certificados en blockchain.');
          print('   Dirección: $walletAddress');
          print('   Necesitas enviar al menos 0.1 MATIC para empezar a emitir certificados.');
          throw Exception('Wallet generada pero sin MATIC. Envía MATIC a $walletAddress y vuelve a intentar. El certificado NO se guardará hasta que se complete la emisión en blockchain.');
        }
        
        // Verificar balance antes de intentar emitir
        final balance = await blockchainService.getBalance();
        final balanceInEther = balance.getValueInUnit(EtherUnit.ether);
        if (balanceInEther < 0.01) {
          final address = await blockchainService.getCurrentWalletAddress();
          print('⚠️ Balance insuficiente. Envía más MATIC a: $address');
          print('   Balance actual: ${balanceInEther.toStringAsFixed(6)} MATIC');
          print('   Se requiere al menos 0.01 MATIC para emitir certificados.');
          throw Exception('Balance insuficiente en la wallet blockchain. Envía al menos 0.01 MATIC a $address y vuelve a intentar. El certificado NO se guardará hasta que se complete la emisión en blockchain.');
        }
        
        // Emitir en blockchain (OBLIGATORIO)
        blockchainTransactionHash = await blockchainService.issueCertificate(
          certificateId: certificateId,
          studentId: studentId,
          institutionId: targetInstitutionId,
          certificateHash: certificateBlockchainHash,
        );
        
        if (blockchainTransactionHash.isEmpty) {
          throw Exception('No se pudo obtener el hash de transacción de blockchain. El certificado NO se guardará.');
        }
        
        print('✅ Certificado emitido exitosamente en blockchain');
        print('   Hash del certificado: $certificateBlockchainHash');
        print('   Longitud del hash: ${certificateBlockchainHash.length} caracteres');
        print('   Hash de transacción: $blockchainTransactionHash');
        print('   Longitud del hash de transacción: ${blockchainTransactionHash.length} caracteres');
        
        // Validar que el hash del certificado tenga el formato correcto (64 caracteres hexadecimales)
        if (certificateBlockchainHash.length != 64) {
          throw Exception('Hash del certificado inválido: debe tener 64 caracteres. Longitud actual: ${certificateBlockchainHash.length}');
        }
        if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(certificateBlockchainHash)) {
          throw Exception('Hash del certificado inválido: debe contener solo caracteres hexadecimales');
        }
      } catch (e) {
        print('❌ Error emitiendo en blockchain. El certificado NO se guardará: $e');
        // Lanzar error para evitar que se guarde el certificado en la BD
        throw Exception('Error al emitir certificado en blockchain: $e. El certificado NO se guardará hasta que se complete exitosamente la emisión en blockchain.');
      }

      // Agregar hash de blockchain (obligatorio)
      // IMPORTANTE: Guardar el hash del certificado, no el hash de la transacción
      // Asegurar que el hash esté limpio (sin espacios, sin 0x, exactamente 64 caracteres)
      String cleanCertificateHash = certificateBlockchainHash.trim();
      
      // Remover prefijo 0x si existe
      if (cleanCertificateHash.startsWith('0x')) {
        cleanCertificateHash = cleanCertificateHash.substring(2);
        print('⚠️ Hash tenía prefijo 0x, removido');
      }
      
      // Asegurar que tenga exactamente 64 caracteres
      if (cleanCertificateHash.length > 64) {
        print('⚠️ ADVERTENCIA: Hash tiene ${cleanCertificateHash.length} caracteres, recortando a 64');
        cleanCertificateHash = cleanCertificateHash.substring(0, 64);
      } else if (cleanCertificateHash.length < 64) {
        throw Exception('ERROR CRÍTICO: Hash del certificado tiene solo ${cleanCertificateHash.length} caracteres. Debe tener 64. Hash: $cleanCertificateHash');
      }
      
      // Validar formato hexadecimal
      if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(cleanCertificateHash)) {
        throw Exception('ERROR CRÍTICO: Hash del certificado contiene caracteres no hexadecimales. Hash: $cleanCertificateHash');
      }
      
      certificateData['blockchain_hash'] = cleanCertificateHash;
      print('💾 Guardando hash en BD: $cleanCertificateHash (${cleanCertificateHash.length} caracteres)');
      certificateData['blockchain_network'] = BlockchainConfig.useTestnet ? 'polygon-mumbai' : 'polygon-mainnet';
      
      // Guardar el hash de transacción en el campo data (JSONB) para referencia
      if (certificateData['data'] == null) {
        certificateData['data'] = <String, dynamic>{};
      }
      final dataMap = Map<String, dynamic>.from(certificateData['data'] as Map? ?? {});
      dataMap['blockchain_transaction_hash'] = blockchainTransactionHash;
      certificateData['data'] = dataMap;

      final response = await _client
          .from('certificates')
          .insert(certificateData)
          .select()
          .single();

      return response['id'].toString();
    } catch (e) {
      print('Error creando certificado: $e');
      rethrow;
    }
  }

  // Obtener certificado por ID
  static Future<SupabaseCertificate?> getCertificate(String id) async {
    try {
      final response = await _client
          .from('certificates')
          .select('*')
          .eq('id', id)
          .single();

      if (response.isNotEmpty) {
        return SupabaseCertificate.fromSupabase(response);
      }
      return null;
    } catch (e) {
      print('Error obteniendo certificado: $e');
      return null;
    }
  }

  // Método para verificación pública (sin autenticación)
  static Future<SupabaseCertificate?> getCertificatePublic(String id) async {
    try {
      // Usar cliente anónimo para acceso público
      final response = await Supabase.instance.client
          .from('certificates')
          .select('*')
          .eq('id', id)
          .eq('status', 'active') // Solo certificados activos
          .single();

      if (response.isNotEmpty) {
        return SupabaseCertificate.fromSupabase(response);
      }
      return null;
    } catch (e) {
      print('Error obteniendo certificado público: $e');
      return null;
    }
  }

  // Obtener certificados por estudiante
  static Future<List<SupabaseCertificate>> getCertificatesByStudent(String studentId) async {
    try {
      final response = await _client
          .from('certificates')
          .select('*')
          .eq('student_id', studentId)
          .order('issued_at', ascending: false);

      return response.map((data) {
        return SupabaseCertificate.fromSupabase(data);
      }).toList();
    } catch (e) {
      print('Error obteniendo certificados del estudiante: $e');
      return [];
    }
  }

  // Obtener certificados por institución
  static Future<List<SupabaseCertificate>> getCertificatesByInstitution(String institutionId) async {
    try {
      final response = await _client
          .from('certificates')
          .select('*')
          .eq('institution_id', institutionId)
          .order('issued_at', ascending: false);

      return response.map((data) {
        return SupabaseCertificate.fromSupabase(data);
      }).toList();
    } catch (e) {
      print('Error obteniendo certificados de la institución: $e');
      return [];
    }
  }

  // Obtener certificados emitidos por un emisor específico
  static Future<List<SupabaseCertificate>> getCertificatesByEmisor(String emisorId) async {
    try {
      final response = await _client
          .from('certificates')
          .select('*')
          .eq('issued_by', emisorId)
          .order('issued_at', ascending: false);

      return response.map((data) {
        return SupabaseCertificate.fromSupabase(data);
      }).toList();
    } catch (e) {
      print('Error obteniendo certificados del emisor: $e');
      return [];
    }
  }

  // Validar certificado
  static Future<bool> validateCertificate(String certificateId) async {
    try {
      final response = await _client
          .from('certificates')
          .select('status')
          .eq('id', certificateId)
          .single();

      if (response.isNotEmpty) {
        final status = response['status'] as String;
        return status == 'active';
      }
      return false;
    } catch (e) {
      print('Error validando certificado: $e');
      return false;
    }
  }

  // Revocar certificado
  static Future<bool> revokeCertificate(String certificateId, String reason) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar permisos - solo admins y emisores pueden revocar
      if (!['super_admin', 'admin_institution', 'emisor'].contains(context.userRole)) {
        throw Exception('No tienes permisos para revocar certificados');
      }

      // Obtener el certificado completo para tener todos los datos necesarios
      final certificate = await getCertificate(certificateId);
      if (certificate == null) {
        throw Exception('Certificado no encontrado');
      }

      // Verificar que no esté ya revocado
      if (certificate.status.toLowerCase() == 'revoked') {
        throw Exception('El certificado ya está revocado');
      }

      // 1. Revocar en blockchain si tiene blockchainHash (OBLIGATORIO si existe)
      String? revocationTransactionHash;
      bool blockchainRevocationSuccess = false;
      
      if (certificate.blockchainHash != null && certificate.blockchainHash!.isNotEmpty) {
        try {
          // Validar formato del hash antes de enviar
          String cleanHash = certificate.blockchainHash!.trim();
          if (cleanHash.startsWith('0x')) {
            cleanHash = cleanHash.substring(2);
          }
          if (cleanHash.length != 64 || !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(cleanHash)) {
            throw Exception('Hash del certificado inválido: debe tener 64 caracteres hexadecimales');
          }
          
          final blockchainService = BlockchainService();
          final contractAddress = BlockchainConfig.contractAddress;
          if (contractAddress.isEmpty || contractAddress == '0x0000000000000000000000000000000000000000') {
            throw Exception('El contrato blockchain no está configurado. No se puede revocar en blockchain.');
          }
          
          await blockchainService.initialize(contractAddress);
          revocationTransactionHash = await blockchainService.revokeCertificate(cleanHash);
          blockchainRevocationSuccess = true;
          print('✅ Certificado revocado en blockchain: $cleanHash');
          print('   Hash de transacción de revocación: $revocationTransactionHash');
        } catch (e) {
          print('❌ Error revocando en blockchain: $e');
          // Si el certificado tiene blockchainHash, la revocación en blockchain es OBLIGATORIA
          // No continuar con revocación en BD si falla blockchain para mantener consistencia
          throw Exception('Error al revocar certificado en blockchain: $e. La revocación NO se completó. Verifica que la wallet tenga permisos de admin en el contrato y suficiente balance de MATIC.');
        }
      } else {
        print('ℹ️ Certificado no tiene blockchainHash, revocando solo en base de datos');
        blockchainRevocationSuccess = true; // No hay blockchain, así que es exitoso
      }

      // 2. Actualizar en base de datos (solo si blockchain fue exitoso o no hay blockchainHash)
      if (!blockchainRevocationSuccess) {
        throw Exception('No se puede actualizar BD: la revocación en blockchain falló');
      }
      
      // Nota: La tabla solo tiene revoked_at, no revoked_by ni revoked_reason
      // Guardamos el motivo, quién revocó y el hash de transacción en el campo data (JSONB)
      final updatedData = Map<String, dynamic>.from(certificate.data);
      updatedData['revoked_by'] = context.userId;
      updatedData['revoked_reason'] = reason;
      updatedData['revoked_at'] = DateTime.now().toIso8601String();
      if (revocationTransactionHash != null && revocationTransactionHash.isNotEmpty) {
        updatedData['revocation_transaction_hash'] = revocationTransactionHash;
      }
      
      await _client
          .from('certificates')
          .update({
            'status': 'revoked',
            'revoked_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'data': updatedData,
          })
          .eq('id', certificateId);

      print('✅ Certificado revocado en base de datos: $certificateId');

      // 3. Enviar notificación por EmailJS
      try {
        await CertificateNotificationService.notifyCertificateRevoked(
          studentEmail: certificate.studentEmail,
          studentName: certificate.studentName,
          certificateTitle: certificate.title,
          institutionName: certificate.institutionName,
          certificateId: certificateId,
          reason: reason,
        );
        print('✅ Notificación de revocación enviada al estudiante');
      } catch (e) {
        print('⚠️ Error enviando notificación (la revocación se completó): $e');
        // No fallar la revocación si falla la notificación
      }

      return true;
    } catch (e) {
      print('❌ Error revocando certificado: $e');
      return false;
    }
  }

  // Obtener estadísticas de certificados
  static Future<Map<String, int>> getCertificateStats() async {
    try {
      final response = await _client
          .from('certificates')
          .select('status');

      int total = response.length;
      int active = 0;
      int revoked = 0;
      int expired = 0;

      for (var certificate in response) {
        switch (certificate['status']) {
          case 'active':
            active++;
            break;
          case 'revoked':
            revoked++;
            break;
          case 'expired':
            expired++;
            break;
        }
      }

      return {
        'total': total,
        'active': active,
        'revoked': revoked,
        'expired': expired,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {'total': 0, 'active': 0, 'revoked': 0, 'expired': 0};
    }
  }

  // Buscar certificados
  static Future<List<SupabaseCertificate>> searchCertificates(String query) async {
    try {
      final response = await _client
          .from('certificates')
          .select('*')
          .or('title.ilike.%$query%,student_name.ilike.%$query%,institution_name.ilike.%$query%')
          .order('issued_at', ascending: false);

      return response.map((data) {
        return SupabaseCertificate.fromSupabase(data);
      }).toList();
    } catch (e) {
      print('Error buscando certificados: $e');
      return [];
    }
  }
}
