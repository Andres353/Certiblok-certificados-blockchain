// lib/services/supabase/migration_config.dart
// Configuración para migración gradual de Firebase a Supabase

class MigrationConfig {
  // Flags para controlar qué servicios usan Supabase
  static bool _useSupabaseAuth = false;
  static bool _useSupabaseInstitutionRequests = false;
  static bool _useSupabaseInstitutions = false;
  static bool _useSupabaseCertificates = false;
  static bool _useSupabaseTemplates = false;
  static bool _useSupabaseUsers = false;

  // Getters para verificar qué servicios usar
  static bool get useSupabaseAuth => _useSupabaseAuth;
  static bool get useSupabaseInstitutionRequests => _useSupabaseInstitutionRequests;
  static bool get useSupabaseInstitutions => _useSupabaseInstitutions;
  static bool get useSupabaseCertificates => _useSupabaseCertificates;
  static bool get useSupabaseTemplates => _useSupabaseTemplates;
  static bool get useSupabaseUsers => _useSupabaseUsers;

  // Setters para activar/desactivar servicios
  static void setSupabaseAuth(bool value) {
    _useSupabaseAuth = value;
    print('🔄 MigrationConfig: Auth ${value ? "migrado a Supabase" : "usando Firebase"}');
    
    // Actualizar el adaptador de Auth
    if (value) {
      // Importar y configurar el adaptador
      try {
        // Esto se hará dinámicamente cuando se use el adaptador
        print('✅ AuthService configurado para usar Supabase');
      } catch (e) {
        print('❌ Error configurando AuthService: $e');
      }
    }
  }

  static void setSupabaseInstitutionRequests(bool value) {
    _useSupabaseInstitutionRequests = value;
    print('🔄 MigrationConfig: InstitutionRequests ${value ? "migrado a Supabase" : "usando Firebase"}');
  }

  static void setSupabaseInstitutions(bool value) {
    _useSupabaseInstitutions = value;
    print('🔄 MigrationConfig: Institutions ${value ? "migrado a Supabase" : "usando Firebase"}');
    
    // Actualizar el adaptador de Institutions
    if (value) {
      try {
        print('✅ InstitutionService configurado para usar Supabase');
      } catch (e) {
        print('❌ Error configurando InstitutionService: $e');
      }
    }
  }

  static void setSupabaseCertificates(bool value) {
    _useSupabaseCertificates = value;
    print('🔄 MigrationConfig: Certificates ${value ? "migrado a Supabase" : "usando Firebase"}');
    
    // Actualizar el adaptador de Certificates
    if (value) {
      try {
        print('✅ CertificateService configurado para usar Supabase');
      } catch (e) {
        print('❌ Error configurando CertificateService: $e');
      }
    }
  }

  static void setSupabaseTemplates(bool value) {
    _useSupabaseTemplates = value;
    print('🔄 MigrationConfig: Templates ${value ? "migrado a Supabase" : "usando Firebase"}');
    
    // Actualizar el adaptador de Templates
    if (value) {
      try {
        print('✅ CertificateTemplateService configurado para usar Supabase');
      } catch (e) {
        print('❌ Error configurando CertificateTemplateService: $e');
      }
    }
  }

  static void setSupabaseUsers(bool value) {
    _useSupabaseUsers = value;
    print('🔄 MigrationConfig: Users ${value ? "migrado a Supabase" : "usando Firebase"}');
  }

  // Migrar todos los servicios a Supabase
  static void migrateAllToSupabase() {
    setSupabaseAuth(true);
    setSupabaseInstitutionRequests(true);
    setSupabaseInstitutions(true);
    setSupabaseCertificates(true);
    setSupabaseTemplates(true);
    setSupabaseUsers(true);
    print('🎉 MigrationConfig: Todos los servicios migrados a Supabase');
  }

  // Revertir todos los servicios a Firebase
  static void revertAllToFirebase() {
    setSupabaseAuth(false);
    setSupabaseInstitutionRequests(false);
    setSupabaseInstitutions(false);
    setSupabaseCertificates(false);
    setSupabaseTemplates(false);
    setSupabaseUsers(false);
    print('🔄 MigrationConfig: Todos los servicios revertidos a Firebase');
  }

  // Estado actual de migración
  static Map<String, bool> getMigrationStatus() {
    return {
      'auth': _useSupabaseAuth,
      'institutionRequests': _useSupabaseInstitutionRequests,
      'institutions': _useSupabaseInstitutions,
      'certificates': _useSupabaseCertificates,
      'templates': _useSupabaseTemplates,
      'users': _useSupabaseUsers,
    };
  }

  // Verificar si algún servicio está usando Supabase
  static bool get isAnyServiceUsingSupabase {
    return _useSupabaseAuth ||
           _useSupabaseInstitutionRequests ||
           _useSupabaseInstitutions ||
           _useSupabaseCertificates ||
           _useSupabaseTemplates ||
           _useSupabaseUsers;
  }

  // Verificar si todos los servicios están usando Supabase
  static bool get areAllServicesUsingSupabase {
    return _useSupabaseAuth &&
           _useSupabaseInstitutionRequests &&
           _useSupabaseInstitutions &&
           _useSupabaseCertificates &&
           _useSupabaseTemplates &&
           _useSupabaseUsers;
  }
}
