import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend_app/services/supabase/supabase_config.dart';
import 'package:frontend_app/services/supabase/setup_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend_app/screens/inicio/main_menu.dart';
import 'package:frontend_app/screens/inicio/set_password_page.dart';
import 'package:frontend_app/screens/admin/manage_emisores_screen.dart';
import 'package:frontend_app/screens/admin/faculties_programs_screen.dart';
import 'package:frontend_app/screens/certificates/my_certificates_screen.dart';
import 'package:frontend_app/screens/inicio/register_student.dart';
import 'package:frontend_app/screens/programs/programs_opportunities_screen.dart';
import 'package:frontend_app/screens/programs/my_applications_screen.dart';
import 'package:frontend_app/screens/programs/applications_management_screen.dart';
import 'package:frontend_app/screens/programs/programs_management_screen.dart';
import 'package:frontend_app/screens/programs/create_program_screen.dart';
import 'package:frontend_app/services/database_initializer.dart';
import 'package:frontend_app/services/super_admin_initializer.dart';
import 'package:frontend_app/services/user_context_service.dart';
import 'package:frontend_app/services/adapters/certificate_adapter.dart';
import 'package:frontend_app/screens/home_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e, stackTrace) {
    print('❌ Error inicializando Firebase: $e');
    print('Stack trace: $stackTrace');
    // Continuar aunque Firebase falle
  }

  try {
    // Inicializar Supabase
    await SupabaseConfig.initialize();
    print('✅ Supabase inicializado correctamente');
  } catch (e, stackTrace) {
    print('❌ Error inicializando Supabase: $e');
    print('Stack trace: $stackTrace');
    // Continuar aunque Supabase falle
  }

  try {
    // Activar Supabase automáticamente
    await SetupAuth.enableSupabaseAuth();
    print('✅ Supabase Auth activado');
  } catch (e, stackTrace) {
    print('❌ Error activando Supabase Auth: $e');
    print('Stack trace: $stackTrace');
  }

  try {
    // Inicializar datos de ejemplo en la base de datos (silenciosamente)
    await DatabaseInitializer.initializeSampleData();
  } catch (e) {
    // Solo mostrar error si no es un error esperado (datos ya existen)
    final errorStr = e.toString().toLowerCase();
    if (!errorStr.contains('already exists') && 
        !errorStr.contains('duplicate')) {
      print('⚠️ Error inicializando datos de ejemplo: $e');
    }
  }
  
  try {
    // Inicializar Super Admin (silenciosamente)
    await SuperAdminInitializer.initializeSuperAdmin();
  } catch (e) {
    // Solo mostrar error si no es un error esperado (usuario ya existe)
    final errorStr = e.toString().toLowerCase();
    if (!errorStr.contains('already exists') && 
        !errorStr.contains('email-already-in-use') &&
        !errorStr.contains('already-in-use')) {
      print('⚠️ Error inicializando Super Admin: $e');
    }
  }

  try {
    // Cargar contexto del usuario si existe
    await UserContextService.loadUserContext();
    print('✅ Contexto de usuario cargado');
  } catch (e, stackTrace) {
    print('❌ Error cargando contexto de usuario: $e');
    print('Stack trace: $stackTrace');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<Widget>? _initialRouteFuture;
  
  @override
  void initState() {
    super.initState();
    // Cachear el future para evitar múltiples llamadas
    _initialRouteFuture = _getInitialRoute();
  }

  Future<Widget> _getInitialRoute() async {
    try {
      // Verificar si la URL actual es una verificación de certificados
      final uri = Uri.base;
      final fragment = uri.fragment;
      
      // Verificar si es una URL de verificación de certificados (con hash routing)
      if (fragment.startsWith('/verify/certificate/')) {
        final fragmentSegments = fragment.split('/');
        if (fragmentSegments.length >= 4 && fragmentSegments[1] == 'verify' && fragmentSegments[2] == 'certificate') {
          final certificateId = fragmentSegments[3];
          return _CertificateLoadingScreen(certificateId: certificateId);
        }
      }
      
      // Verificar si es una URL de verificación de múltiples certificados
      if (fragment.startsWith('/verify/certificates/')) {
        final fragmentSegments = fragment.split('/');
        if (fragmentSegments.length >= 4 && fragmentSegments[1] == 'verify' && fragmentSegments[2] == 'certificates') {
          final certificateIds = fragmentSegments[3];
          return _CertificateLoadingScreen(certificateId: certificateIds, isMultiple: true);
        }
      }
      
      // Verificar si hay un usuario autenticado
      // Primero verificar la sesión de Supabase (fuente de verdad)
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser == null) {
        // No hay sesión activa en Supabase, limpiar contexto y mostrar login
        await UserContextService.clearUserContext();
        return const MainMenu();
      }
      
      // Hay sesión en Supabase, verificar contexto
      // Intentar cargar contexto con timeout para evitar bucles infinitos
      try {
        final userContext = await UserContextService.loadUserContext()
            .timeout(Duration(seconds: 5));
        
        if (userContext != null) {
          // Redirigir al dashboard correspondiente según el rol
          return HomePage(role: userContext.userRole);
        }
      } catch (e) {
        print('⚠️ Error cargando contexto, limpiando: $e');
        await UserContextService.clearUserContext();
        return const MainMenu();
      }
      
      // Si no hay contexto después de intentar cargarlo, mostrar loading
      return _UserContextLoadingScreen();
    } catch (e, stackTrace) {
      print('❌ Error en _getInitialRoute: $e');
      print('Stack trace: $stackTrace');
      // En caso de error, limpiar y mostrar login
      try {
        await UserContextService.clearUserContext();
      } catch (_) {}
      return const MainMenu();
    }
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certiblock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés (fallback)
      ],
      locale: Locale('es', 'ES'), // Idioma por defecto: español
      home: Builder(
        builder: (context) {
          return FutureBuilder<Widget>(
            future: _initialRouteFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                print('❌ Error en _getInitialRoute: ${snapshot.error}');
                return _ErrorScreen(error: snapshot.error.toString());
              }
              return snapshot.data ?? const MainMenu();
            },
          );
        },
      ),
      builder: (context, child) {
        // Capturar errores de renderizado
        ErrorWidget.builder = (FlutterErrorDetails details) {
          print('❌ Error de renderizado: ${details.exception}');
          print('Stack trace: ${details.stack}');
          return _ErrorScreen(error: details.exception.toString());
        };
        return child ?? _ErrorScreen(error: 'Widget nulo');
      },

      onGenerateRoute: (settings) {
        print('🔍 DEBUG - onGenerateRoute llamado con: ${settings.name}');
        
        // Ignorar rutas de certificados - se manejan en _getInitialRoute
        if (settings.name != null && 
            (settings.name!.startsWith('/verify/certificate/') || 
             settings.name!.startsWith('certiblock://verify/certificate/'))) {
          print('⚠️ Ignorando ruta de certificado en onGenerateRoute: ${settings.name}');
          return null;
        }
        
        if (settings.name != null && settings.name!.startsWith('/set-password')) {
          final uri = Uri.parse(settings.name!);
          final userId = uri.queryParameters['userId'] ?? '';
          return MaterialPageRoute(
            builder: (_) => SetPasswordPage(userId: userId),
          );
        }
        
        // Ruta para gestión de emisores
        if (settings.name == '/manage_emisores') {
          return MaterialPageRoute(
            builder: (_) => ManageEmisoresScreen(),
          );
        }
        
        // Ruta para facultades y programas
        if (settings.name == '/faculties_programs') {
          return MaterialPageRoute(
            builder: (_) => ProgramsScreen(),
          );
        }
        
        // Ruta para mis certificados
        if (settings.name == '/my-certificates') {
          return MaterialPageRoute(
            builder: (_) => MyCertificatesScreen(),
          );
        }
        
        // Ruta para registro de estudiante
        if (settings.name == '/register-student') {
          return MaterialPageRoute(
            builder: (_) => RegisterStudent(),
          );
        }
        
        // Rutas para programas y postulaciones
        if (settings.name == '/programs-opportunities') {
          return MaterialPageRoute(
            builder: (_) => ProgramsOpportunitiesScreen(),
          );
        }
        
        if (settings.name == '/my-applications') {
          return MaterialPageRoute(
            builder: (_) => MyApplicationsScreen(),
          );
        }
        
        if (settings.name == '/applications-management') {
          return MaterialPageRoute(
            builder: (_) => ApplicationsManagementScreen(),
          );
        }
        
        if (settings.name == '/programs-management') {
          return MaterialPageRoute(
            builder: (_) => ProgramsManagementScreen(),
          );
        }
        
        if (settings.name == '/create-program') {
          return MaterialPageRoute(
            builder: (_) => CreateProgramScreen(),
          );
        }
        
        // Las rutas de certificados se manejan en _getInitialRoute
        
        // Otras rutas...
        return null;
      },
      
    );
  }
}

// Pantalla simple para mostrar mientras se carga el certificado
class _CertificateLoadingScreen extends StatefulWidget {
  final String certificateId;
  final String instanceId;
  final bool isMultiple;
  
  _CertificateLoadingScreen({required this.certificateId, this.isMultiple = false}) : instanceId = DateTime.now().millisecondsSinceEpoch.toString();
  
  @override
  _CertificateLoadingScreenState createState() {
    print('🔍 DEBUG - Creando _CertificateLoadingScreen para certificado: $certificateId (Instancia: ${instanceId})');
    return _CertificateLoadingScreenState();
  }
}

class _CertificateLoadingScreenState extends State<_CertificateLoadingScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasOpenedPdf = false;
  Map<String, dynamic>? _certificateData;
  List<Map<String, dynamic>>? _multipleCertificates;
  late String _instanceId;
  
  @override
  void initState() {
    super.initState();
    _instanceId = DateTime.now().millisecondsSinceEpoch.toString();
    print('🔍 DEBUG - _CertificateLoadingScreenState initState - Instancia: $_instanceId para certificado: ${widget.certificateId}');
    // Cargar información del certificado sin abrir PDF automáticamente
    _loadCertificateInfo();
  }

  Future<void> _loadCertificateInfo() async {
    try {
      print('🚀 CARGANDO INFORMACIÓN DEL CERTIFICADO (Instancia: ${widget.instanceId})');
      print('🔄 Obteniendo información del certificado: ${widget.certificateId}');
      print('🔄 Es múltiple: ${widget.isMultiple}');
      
      if (widget.isMultiple) {
        await _loadMultipleCertificates();
      } else {
        await _loadSingleCertificate();
      }
      
    } catch (e) {
      print('❌ Error cargando certificado: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error cargando certificado: $e';
      });
    }
  }

  Future<void> _loadSingleCertificate() async {
    // Obtener el certificado usando el adapter
    print('🔍 Llamando a CertificateAdapter.getCertificatePublic...');
    dynamic certificateData;
    try {
      certificateData = await CertificateAdapter.getCertificatePublic(widget.certificateId);
      print('🔍 Respuesta de getCertificatePublic: $certificateData');
    } catch (e) {
      print('❌ Error en getCertificatePublic: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error obteniendo certificado: $e';
      });
      return;
    }
    
    if (certificateData == null) {
      print('❌ No se encontró certificado con ID: ${widget.certificateId}');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Certificado no encontrado';
      });
      return;
    }
    
    // Convertir a Map si es necesario
    Map<String, dynamic> certificate;
    if (certificateData is Map<String, dynamic>) {
      certificate = certificateData;
    } else {
      certificate = certificateData.toMap();
    }
    
    print('📋 Certificado obtenido exitosamente:');
    print('  - ID: ${certificate['id']}');
    print('  - Título: ${certificate['title']}');
    print('  - Estado: ${certificate['status']}');
    print('  - Estudiante: ${certificate['studentName']}');
    print('  - Institución: ${certificate['institutionName']}');
    
    setState(() {
      _isLoading = false;
      _certificateData = certificate;
    });
  }

  Future<void> _loadMultipleCertificates() async {
    // Dividir los IDs de certificados
    final certificateIds = widget.certificateId.split(',');
    print('🔍 Cargando ${certificateIds.length} certificados: $certificateIds');
    
    List<Map<String, dynamic>> certificates = [];
    
    for (String id in certificateIds) {
      try {
        print('🔍 Cargando certificado: $id');
        dynamic certificateData = await CertificateAdapter.getCertificatePublic(id.trim());
        
        if (certificateData != null) {
          Map<String, dynamic> certificate;
          if (certificateData is Map<String, dynamic>) {
            certificate = certificateData;
          } else {
            certificate = certificateData.toMap();
          }
          certificates.add(certificate);
          print('✅ Certificado $id cargado exitosamente');
        } else {
          print('⚠️ Certificado $id no encontrado');
        }
      } catch (e) {
        print('❌ Error cargando certificado $id: $e');
      }
    }
    
    if (certificates.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se encontraron certificados válidos';
      });
      return;
    }
    
    print('📋 ${certificates.length} certificados cargados exitosamente');
    
    setState(() {
      _isLoading = false;
      _multipleCertificates = certificates;
    });
  }

  Future<void> _openCertificatePdf() async {
    if (_hasOpenedPdf) {
      print('⚠️ PDF ya se abrió, evitando duplicado (Instancia: ${widget.instanceId})');
      return;
    }
    
    _hasOpenedPdf = true;
    
    try {
      print('🚀 INICIANDO PROCESO DE APERTURA DE PDF (Instancia: ${widget.instanceId})');
      print('🔄 Abriendo certificado PDF desde _CertificateLoadingScreen: ${widget.certificateId}');
      
      // Obtener el certificado usando el adapter
      print('🔍 Llamando a CertificateAdapter.getCertificatePublic...');
      dynamic certificateData;
      try {
        certificateData = await CertificateAdapter.getCertificatePublic(widget.certificateId);
        print('🔍 Respuesta de getCertificatePublic: $certificateData');
      } catch (e) {
        print('❌ Error en getCertificatePublic: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error obteniendo certificado: $e';
        });
        return;
      }
      
      if (certificateData == null) {
        print('❌ Certificado no encontrado: ${widget.certificateId}');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Certificado no encontrado';
        });
        return;
      }
      
             // Convertir a objeto Certificate si es necesario
             dynamic certificate;
             print('🔍 DEBUG - Tipo de certificateData: ${certificateData.runtimeType}');
             
             if (certificateData is Map<String, dynamic>) {
               certificate = certificateData;
               print('✅ Certificado ya es Map, usando directamente');
             } else {
               print('🔄 Intentando convertir objeto a Map...');
               print('🔍 DEBUG - Tipo exacto: ${certificateData.runtimeType}');
               print('🔍 DEBUG - toString: ${certificateData.toString()}');
               
               try {
                 // Intentar llamar al método toMap() directamente
                 certificate = certificateData.toMap();
                 print('✅ Certificado convertido a Map exitosamente');
               } catch (e) {
                 print('❌ Error convirtiendo certificado: $e');
                 print('❌ Tipo recibido: ${certificateData.runtimeType}');
                 setState(() {
                   _isLoading = false;
                   _errorMessage = 'Error procesando certificado: $e';
                 });
                 return;
               }
             }
             
             // Guardar datos del certificado para mostrar en la UI
             setState(() {
               _certificateData = certificate;
             });
      
      print('📊 Estructura de datos del certificado: ${certificate['data']?.keys.toList()}');
      
      // Buscar el PDF en los datos del certificado (misma lógica que el botón "Ver Certificado")
      String? pdfData;
      
      // Verificar si hay PDF en data.pdfData
      if (certificate['data'] != null && certificate['data']['pdfData'] != null) {
        final pdfDataValue = certificate['data']['pdfData'];
        print('📄 Tipo de pdfData: ${pdfDataValue.runtimeType}');
        
        if (pdfDataValue is String) {
          print('📄 PDF encontrado en data.pdfData (String), abriendo...');
          pdfData = pdfDataValue;
        } else if (pdfDataValue is Map<String, dynamic>) {
          print('📄 Claves de pdfData: ${pdfDataValue.keys.toList()}');
          // Si es un mapa, buscar el campo 'data' o 'content'
          pdfData = pdfDataValue['data'] ?? 
                   pdfDataValue['content'] ?? 
                   pdfDataValue['base64'] ??
                   pdfDataValue['fileData'] ??
                   pdfDataValue['certificateData'];
          if (pdfData is String && pdfData.isNotEmpty) {
            print('📄 PDF encontrado en data.pdfData (Map), abriendo...');
          } else {
            print('❌ No se encontró PDF en pdfData con los campos: data, content, base64, fileData, certificateData');
          }
        }
      }
      
      // Verificar si hay PDF en data.customCertificateData
      if (pdfData == null && certificate['data'] != null && certificate['data']['customCertificateData'] != null) {
        final customData = certificate['data']['customCertificateData'];
        print('📄 Tipo de customCertificateData: ${customData.runtimeType}');
        
        if (customData is String) {
          print('📄 PDF encontrado en data.customCertificateData (String), abriendo...');
          pdfData = customData;
        } else if (customData is Map<String, dynamic>) {
          print('📄 Claves de customCertificateData: ${customData.keys.toList()}');
          
          // Buscar en múltiples campos posibles
          pdfData = customData['data'] ?? 
                   customData['content'] ?? 
                   customData['base64'] ?? 
                   customData['pdfData'] ??
                   customData['fileData'] ??
                   customData['certificateData'];
          
          if (pdfData is String && pdfData.isNotEmpty) {
            print('📄 PDF encontrado en data.customCertificateData (Map), abriendo...');
          } else {
            print('❌ No se encontró PDF en customCertificateData con los campos: data, content, base64, pdfData, fileData, certificateData');
          }
        }
      }
      
      if (pdfData != null && pdfData.isNotEmpty) {
        print('📄 PDF encontrado, abriendo...');
        print('📄 Tamaño del PDF: ${pdfData.length} caracteres');
        print('📄 Primeros 100 caracteres: ${pdfData.substring(0, pdfData.length > 100 ? 100 : pdfData.length)}');
        _openPdfWithBlob(pdfData);
        
        // Esperar un poco y mostrar mensaje de éxito
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      } else {
        print('❌ No se encontró PDF para el certificado: ${widget.certificateId}');
        print('❌ Estructura completa del certificado:');
        print('  - data: ${certificate['data']}');
        if (certificate['data'] != null) {
          print('  - data.pdfData: ${certificate['data']['pdfData']}');
          print('  - data.customCertificateData: ${certificate['data']['customCertificateData']}');
        }
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se encontró PDF para este certificado';
        });
      }
      
    } catch (e) {
      print('❌ Error abriendo certificado: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error abriendo certificado: $e';
      });
    }
  }

  void _openPdfWithBlob(String pdfContent) async {
    // Determinar si es base64 puro o data URL
    final String dataUrl = pdfContent.startsWith('data:') 
        ? pdfContent 
        : 'data:application/pdf;base64,$pdfContent';
    
    try {
      print('🔄 Abriendo PDF del certificado automáticamente...');
      print('📄 Contenido original: ${pdfContent.substring(0, pdfContent.length > 100 ? 100 : pdfContent.length)}...');
      print('📄 Data URL generada: ${dataUrl.substring(0, 100)}...');
      print('📄 Tamaño total: ${dataUrl.length} caracteres');
      
      // Usar JavaScript para crear blob URL y abrir en nueva pestaña
      await _openPdfWithBlobUrl(dataUrl);
      
    } catch (e) {
      print('❌ Error al abrir PDF: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _openPdfWithBlobUrl(String dataUrl) async {
    try {
      print('🔄 Creando blob URL con JavaScript...');
      print('🔍 DEBUG - _openPdfWithBlobUrl llamado para certificado: ${widget.certificateId}');
      
      // Extraer el base64 del data URL
      final String base64Data = dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
      print('📊 Base64 extraído: ${base64Data.substring(0, 50)}...');
      
      // Decodificar base64 a bytes
      final List<int> bytes = base64Decode(base64Data);
      print('📊 Bytes decodificados: ${bytes.length} bytes');
      
      // Crear blob usando JavaScript
      final blob = html.Blob([bytes], 'application/pdf');
      
      // Crear URL del blob
      final blobUrl = html.Url.createObjectUrl(blob);
      print('📄 Blob URL creada: $blobUrl');
      
      // Abrir en nueva pestaña
      print('🚀 ABRIENDO PDF EN NUEVA PESTAÑA...');
      html.window.open(blobUrl, '_blank');
      
      print('✅ Certificado abierto exitosamente con blob URL');
      
      // Limpiar la URL del blob después de un tiempo
      Future.delayed(Duration(seconds: 30), () {
        html.Url.revokeObjectUrl(blobUrl);
        print('🧹 Blob URL limpiada');
      });
      
    } catch (e) {
      print('❌ Error con blob URL: $e');
         }
       }
       
       
       String _formatDate(dynamic date) {
         if (date == null) return 'N/A';
         try {
           if (date is String) {
             final parsedDate = DateTime.parse(date);
             return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
           }
           return date.toString();
         } catch (e) {
           return 'N/A';
         }
       }
       
       String _getStatusText(String? status) {
         switch (status?.toLowerCase()) {
           case 'active':
             return 'VÁLIDO';
           case 'revoked':
             return 'REVOCADO';
           case 'expired':
             return 'EXPIRADO';
           default:
             return 'DESCONOCIDO';
         }
       }
       
       @override
       Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff1a1a2e),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff1a1a2e),
              Color(0xff16213e),
              Color(0xff0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading) ...[
                    _buildLoadingState(),
                  ] else if (_errorMessage != null) ...[
                    _buildErrorState(),
                  ] else ...[
                    if (widget.isMultiple && _multipleCertificates != null) ...[
                      _buildMultipleCertificatesValidation(),
                    ] else if (_certificateData != null) ...[
                      _buildCertificateValidation(),
                    ] else ...[
                      _buildSuccessState(),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                'Verificando Certificado...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Validando autenticidad y estado',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 80,
              ),
              SizedBox(height: 20),
              Text(
                'Error de Verificación',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 80,
              ),
              SizedBox(height: 20),
              Text(
                'Certificado Abierto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'El PDF del certificado se ha abierto en una nueva ventana',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultipleCertificatesValidation() {
    return Column(
      children: [
        // Header con logo y título
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.shade700],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Logo/Icono
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: Colors.blue,
                  size: 50,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'CERTIFICADOS VERIFICADOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Sistema de Verificación CertiBlock',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${_multipleCertificates!.length} certificados encontrados',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 30),
        
        // Lista de certificados
        ..._multipleCertificates!.map((certificate) => 
          Container(
            margin: EdgeInsets.only(bottom: 20),
            child: _buildCertificateCard(certificate),
          )
        ).toList(),
      ],
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> certificate) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la tarjeta
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff2c3e50), Color(0xff34495e)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'INFORMACIÓN DEL CERTIFICADO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ESTADO: ${_getStatusText(certificate['status'])}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido del certificado
          Padding(
            padding: EdgeInsets.all(25),
            child: Column(
              children: [
                // Información del estudiante
                _buildSectionHeader('INFORMACIÓN DEL ESTUDIANTE'),
                SizedBox(height: 15),
                _buildInfoCard([
                  _buildInfoItem('Nombre Completo', certificate['student_name'] ?? 'N/A'),
                  _buildInfoItem('Email', certificate['student_email'] ?? 'N/A'),
                ]),
                
                SizedBox(height: 25),
                
                // Información académica
                _buildSectionHeader('INFORMACIÓN ACADÉMICA'),
                SizedBox(height: 15),
                _buildInfoCard([
                  _buildInfoItem('Institución', certificate['institution_name'] ?? 'N/A'),
                  _buildInfoItem('Programa', certificate['program_name'] ?? 'N/A'),
                ]),
                
                SizedBox(height: 25),
                
                // Información del certificado
                _buildSectionHeader('DETALLES DEL CERTIFICADO'),
                SizedBox(height: 15),
                _buildInfoCard([
                  _buildInfoItem('Certificado', _getCertificateTypeLabel(certificate['certificate_type'] ?? 'N/A')),
                  _buildInfoItem('Título', certificate['title'] ?? 'N/A'),
                  if (certificate['description'] != null && certificate['description'].toString().trim().isNotEmpty)
                    _buildInfoItem('Descripción', certificate['description']),
                  _buildInfoItem('Emitido por', certificate['issued_by_name'] ?? 'N/A'),
                  _buildInfoItem('Fecha de Emisión', _formatDate(certificate['issued_at'])),
                ]),
                
                SizedBox(height: 25),
                
                // Botones para ver/descargar PDF del certificado individual
                _buildPdfButtonsForCertificate(certificate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateValidation() {
    return Column(
      children: [
        // Header con logo y título
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.shade700],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Logo/Icono
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: Colors.blue,
                  size: 50,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'CERTIFICADO VERIFICADO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Sistema de Verificación CertiBlock',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 30),
        
        // Tarjeta principal del certificado
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header de la tarjeta
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff2c3e50), Color(0xff34495e)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'INFORMACIÓN DEL CERTIFICADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ESTADO: ${_getStatusText(_certificateData!['status'])}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido del certificado
              Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  children: [
                    // Información del estudiante
                    _buildSectionHeader('INFORMACIÓN DEL ESTUDIANTE'),
                    SizedBox(height: 15),
                    _buildInfoCard([
                      _buildInfoItem('Nombre Completo', _certificateData!['student_name'] ?? 'N/A'),
                      _buildInfoItem('Email', _certificateData!['student_email'] ?? 'N/A'),
                    ]),
                    
                    SizedBox(height: 25),
                    
                    // Información académica
                    _buildSectionHeader('INFORMACIÓN ACADÉMICA'),
                    SizedBox(height: 15),
                    _buildInfoCard([
                      _buildInfoItem('Institución', _certificateData!['institution_name'] ?? 'N/A'),
                      _buildInfoItem('Programa', _certificateData!['program_name'] ?? 'N/A'),
                    ]),
                    
                    SizedBox(height: 25),
                    
                    // Información del certificado
                    _buildSectionHeader('DETALLES DEL CERTIFICADO'),
                    SizedBox(height: 15),
                    _buildInfoCard([
                      _buildInfoItem('Certificado', _getCertificateTypeLabel(_certificateData!['certificate_type'] ?? 'N/A')),
                      _buildInfoItem('Título', _certificateData!['title'] ?? 'N/A'),
                      if (_certificateData!['description'] != null && _certificateData!['description'].toString().trim().isNotEmpty)
                        _buildInfoItem('Descripción', _certificateData!['description']),
                      _buildInfoItem('Emitido por', _certificateData!['issued_by_name'] ?? 'N/A'),
                      _buildInfoItem('Fecha de Emisión', _formatDate(_certificateData!['issued_at'])),
                    ]),
                    
                    
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 30),
        
        // Botones para ver/descargar PDF
        _buildPdfButtons(),
      ],
    );
  }

  Widget _buildPdfButtons() {
    return Container(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openCertificatePdf(),
              icon: Icon(Icons.visibility, size: 20),
              label: Text('Ver PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _downloadCertificatePdf(),
              icon: Icon(Icons.download, size: 20),
              label: Text('Descargar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfButtonsForCertificate(Map<String, dynamic> certificate) {
    return Container(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openCertificatePdfForCertificate(certificate),
              icon: Icon(Icons.visibility, size: 20),
              label: Text('Ver Certificado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _downloadCertificatePdfForCertificate(certificate),
              icon: Icon(Icons.download, size: 20),
              label: Text('Descargar PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadCertificatePdf() async {
    try {
      print('🔍 Descargando PDF para certificado individual...');
      
      // Obtener el certificado usando el adapter
      dynamic certificateData = await CertificateAdapter.getCertificatePublic(widget.certificateId);
      
      if (certificateData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificado no encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Convertir a Map si es necesario
      Map<String, dynamic> certMap;
      if (certificateData is Map<String, dynamic>) {
        certMap = certificateData;
      } else {
        certMap = certificateData.toMap();
      }
      
      // Buscar el PDF en diferentes campos posibles
      String? pdfData;
      
      // Primero buscar en campos de URL
      String? pdfUrl = certMap['pdf_url'] ?? 
                      certMap['pdfUrl'] ?? 
                      certMap['pdf'] ?? 
                      certMap['file_url'] ?? 
                      certMap['fileUrl'] ?? 
                      certMap['url'];
      
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        print('🔍 DEBUG - PDF URL encontrada: $pdfUrl');
        // Descargar PDF desde URL
        final fileName = _generateFileName(certMap);
        await _downloadPdfFromUrl(pdfUrl, fileName);
        return;
      }
      
      // Si no hay URL, buscar en el campo data.customCertificateData
      if (certMap['data'] != null && certMap['data'] is Map<String, dynamic>) {
        final data = certMap['data'] as Map<String, dynamic>;
        final customData = data['customCertificateData'];
        print('🔍 DEBUG - customCertificateData tipo: ${customData.runtimeType}');
        
        if (customData is String) {
          pdfData = customData;
          print('🔍 DEBUG - PDF Data encontrada como String: Sí');
        } else if (customData is Map<String, dynamic>) {
          // Si es un Map, buscar campos comunes de PDF
          pdfData = customData['data'] ?? 
                   customData['content'] ?? 
                   customData['base64'] ??
                   customData['fileData'] ??
                   customData['certificateData'] ??
                   customData['pdfData'];
          print('🔍 DEBUG - PDF Data encontrada en Map: ${pdfData != null ? 'Sí' : 'No'}');
          if (pdfData != null) {
            print('🔍 DEBUG - Campo encontrado: ${customData.keys.where((k) => customData[k] == pdfData).first}');
          }
        }
      }
      
      if (pdfData == null || pdfData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF no disponible para este certificado'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Procesar PDF desde base64
      final fileName = _generateFileName(certMap);
      await _downloadPdfFromBase64(pdfData, fileName);
      
    } catch (e) {
      print('❌ Error descargando PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error descargando PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openCertificatePdfForCertificate(Map<String, dynamic> certificate) async {
    try {
      final certificateId = certificate['id'];
      print('🔍 Abriendo PDF para certificado individual: $certificateId');
      
      // Obtener el certificado usando el adapter
      dynamic certificateData = await CertificateAdapter.getCertificatePublic(certificateId);
      
      if (certificateData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificado no encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Convertir a Map si es necesario
      Map<String, dynamic> certMap;
      if (certificateData is Map<String, dynamic>) {
        certMap = certificateData;
      } else {
        certMap = certificateData.toMap();
      }
      
      // Debug: Mostrar todos los campos disponibles
      print('🔍 DEBUG - Campos disponibles en el certificado:');
      certMap.forEach((key, value) {
        print('  $key: $value');
      });
      
      // Buscar el PDF en diferentes campos posibles
      String? pdfData;
      
      // Primero buscar en campos de URL
      String? pdfUrl = certMap['pdf_url'] ?? 
                      certMap['pdfUrl'] ?? 
                      certMap['pdf'] ?? 
                      certMap['file_url'] ?? 
                      certMap['fileUrl'] ?? 
                      certMap['url'];
      
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        print('🔍 DEBUG - PDF URL encontrada: $pdfUrl');
        // Abrir PDF en nueva pestaña
        final Uri pdfUri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(pdfUri)) {
          await launchUrl(pdfUri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('No se pudo abrir el PDF');
        }
        return;
      }
      
      // Si no hay URL, buscar en el campo data.customCertificateData
      if (certMap['data'] != null && certMap['data'] is Map<String, dynamic>) {
        final data = certMap['data'] as Map<String, dynamic>;
        final customData = data['customCertificateData'];
        print('🔍 DEBUG - customCertificateData tipo: ${customData.runtimeType}');
        
        if (customData is String) {
          pdfData = customData;
          print('🔍 DEBUG - PDF Data encontrada como String: Sí');
        } else if (customData is Map<String, dynamic>) {
          // Si es un Map, buscar campos comunes de PDF
          pdfData = customData['data'] ?? 
                   customData['content'] ?? 
                   customData['base64'] ??
                   customData['fileData'] ??
                   customData['certificateData'] ??
                   customData['pdfData'];
          print('🔍 DEBUG - PDF Data encontrada en Map: ${pdfData != null ? 'Sí' : 'No'}');
          if (pdfData != null) {
            print('🔍 DEBUG - Campo encontrado: ${customData.keys.where((k) => customData[k] == pdfData).first}');
          }
        }
      }
      
      if (pdfData == null || pdfData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF no disponible para este certificado'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Procesar PDF desde base64
      await _openPdfFromBase64(pdfData);
      
    } catch (e) {
      print('❌ Error abriendo PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error abriendo PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openPdfFromBase64(String base64Data) async {
    try {
      print('🔄 Abriendo PDF desde base64...');
      print('📄 Contenido base64: ${base64Data.substring(0, base64Data.length > 100 ? 100 : base64Data.length)}...');
      
      // Crear data URL
      final dataUrl = 'data:application/pdf;base64,$base64Data';
      print('📄 Data URL generada: ${dataUrl.substring(0, 100)}...');
      
      // Usar JavaScript para crear blob URL y abrir en nueva pestaña
      await _openPdfWithBlobUrl(dataUrl);
      
    } catch (e) {
      print('❌ Error al abrir PDF desde base64: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadCertificatePdfForCertificate(Map<String, dynamic> certificate) async {
    try {
      final certificateId = certificate['id'];
      print('🔍 Descargando PDF para certificado individual: $certificateId');
      
      // Obtener el certificado usando el adapter
      dynamic certificateData = await CertificateAdapter.getCertificatePublic(certificateId);
      
      if (certificateData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificado no encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Convertir a Map si es necesario
      Map<String, dynamic> certMap;
      if (certificateData is Map<String, dynamic>) {
        certMap = certificateData;
      } else {
        certMap = certificateData.toMap();
      }
      
      // Debug: Mostrar todos los campos disponibles
      print('🔍 DEBUG - Campos disponibles en el certificado:');
      certMap.forEach((key, value) {
        print('  $key: $value');
      });
      
      // Buscar el PDF en diferentes campos posibles
      String? pdfData;
      
      // Primero buscar en campos de URL
      String? pdfUrl = certMap['pdf_url'] ?? 
                      certMap['pdfUrl'] ?? 
                      certMap['pdf'] ?? 
                      certMap['file_url'] ?? 
                      certMap['fileUrl'] ?? 
                      certMap['url'];
      
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        print('🔍 DEBUG - PDF URL encontrada: $pdfUrl');
        // Descargar PDF desde URL
        final fileName = _generateFileName(certMap);
        await _downloadPdfFromUrl(pdfUrl, fileName);
        return;
      }
      
      // Si no hay URL, buscar en el campo data.customCertificateData
      if (certMap['data'] != null && certMap['data'] is Map<String, dynamic>) {
        final data = certMap['data'] as Map<String, dynamic>;
        final customData = data['customCertificateData'];
        print('🔍 DEBUG - customCertificateData tipo: ${customData.runtimeType}');
        
        if (customData is String) {
          pdfData = customData;
          print('🔍 DEBUG - PDF Data encontrada como String: Sí');
        } else if (customData is Map<String, dynamic>) {
          // Si es un Map, buscar campos comunes de PDF
          pdfData = customData['data'] ?? 
                   customData['content'] ?? 
                   customData['base64'] ??
                   customData['fileData'] ??
                   customData['certificateData'] ??
                   customData['pdfData'];
          print('🔍 DEBUG - PDF Data encontrada en Map: ${pdfData != null ? 'Sí' : 'No'}');
          if (pdfData != null) {
            print('🔍 DEBUG - Campo encontrado: ${customData.keys.where((k) => customData[k] == pdfData).first}');
          }
        }
      }
      
      if (pdfData == null || pdfData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF no disponible para este certificado'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Procesar PDF desde base64
      final fileName = _generateFileName(certMap);
      await _downloadPdfFromBase64(pdfData, fileName);
      
    } catch (e) {
      print('❌ Error descargando PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error descargando PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateFileName(Map<String, dynamic> certMap) {
    try {
      // Obtener título del certificado
      String title = certMap['title'] ?? 'Certificado';
      
      // Obtener nombre del estudiante
      String studentName = certMap['student_name'] ?? 'Estudiante';
      
      // Limpiar caracteres especiales que pueden causar problemas en nombres de archivo
      String cleanTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      String cleanStudentName = studentName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      
      // Generar nombre del archivo
      String fileName = '${cleanTitle}_${cleanStudentName}.pdf';
      
      // Limitar longitud del nombre de archivo (máximo 100 caracteres)
      if (fileName.length > 100) {
        fileName = fileName.substring(0, 100) + '.pdf';
      }
      
      print('📄 Nombre de archivo generado: $fileName');
      return fileName;
      
    } catch (e) {
      print('❌ Error generando nombre de archivo: $e');
      return 'certificado.pdf'; // Fallback
    }
  }

  Future<void> _downloadPdfFromBase64(String base64Data, String fileName) async {
    try {
      print('🔄 Descargando PDF desde base64...');
      print('📄 Contenido base64: ${base64Data.substring(0, base64Data.length > 100 ? 100 : base64Data.length)}...');
      
      // Crear data URL
      final dataUrl = 'data:application/pdf;base64,$base64Data';
      print('📄 Data URL generada: ${dataUrl.substring(0, 100)}...');
      
      // Usar JavaScript para crear blob URL y descargar el archivo
      await _downloadPdfWithBlobUrl(dataUrl, fileName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF descargado correctamente como: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('❌ Error al descargar PDF desde base64: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadPdfWithBlobUrl(String dataUrl, String fileName) async {
    try {
      print('🔄 Descargando PDF con blob URL...');
      
      // Extraer el base64 del data URL
      final String base64Data = dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
      print('📊 Base64 extraído: ${base64Data.substring(0, 50)}...');
      
      // Decodificar base64 a bytes
      final List<int> bytes = base64Decode(base64Data);
      print('📊 Bytes decodificados: ${bytes.length} bytes');
      
      // Crear blob usando JavaScript
      final blob = html.Blob([bytes], 'application/pdf');
      
      // Crear URL del blob
      final blobUrl = html.Url.createObjectUrl(blob);
      print('📄 Blob URL creada: $blobUrl');
      
      // Crear elemento anchor para descarga
      final anchor = html.AnchorElement(href: blobUrl);
      anchor.download = fileName; // Nombre personalizado del archivo
      anchor.style.display = 'none';
      
      // Agregar al DOM temporalmente
      html.document.body?.children.add(anchor);
      
      // Simular click para iniciar descarga
      anchor.click();
      
      // Limpiar
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(blobUrl);
      
      print('✅ PDF descargado exitosamente como: $fileName');
      
    } catch (e) {
      print('❌ Error al descargar PDF con blob URL: $e');
      throw e;
    }
  }

  Future<void> _downloadPdfFromUrl(String pdfUrl, String fileName) async {
    try {
      print('🔄 Descargando PDF desde URL: $pdfUrl');
      
      // Crear elemento anchor para descarga directa
      final anchor = html.AnchorElement(href: pdfUrl);
      anchor.download = fileName; // Nombre personalizado del archivo
      anchor.target = '_blank'; // Abrir en nueva pestaña como fallback
      anchor.style.display = 'none';
      
      // Agregar al DOM temporalmente
      html.document.body?.children.add(anchor);
      
      // Simular click para iniciar descarga
      anchor.click();
      
      // Limpiar
      html.document.body?.children.remove(anchor);
      
      print('✅ PDF descargado desde URL exitosamente como: $fileName');
      
    } catch (e) {
      print('❌ Error al descargar PDF desde URL: $e');
      throw e;
    }
  }

  String _getCertificateTypeLabel(String type) {
    print('🔍 DEBUG - Tipo de certificado recibido: "$type"');
    
    if (type.isEmpty || type == 'N/A') {
      return 'Certificado';
    }
    
    switch (type.toLowerCase().trim()) {
      case 'graduation':
        return 'Certificado de Graduación';
      case 'constancy':
        return 'Constancia de Estudios';
      case 'achievement':
        return 'Certificado de Logro';
      case 'participation':
        return 'Certificado de Participación';
      case 'certificate':
        return 'Certificado';
      case 'diploma':
        return 'Diploma';
      case 'degree':
        return 'Título Profesional';
      default:
        print('⚠️ Tipo de certificado no reconocido: "$type"');
        return 'Certificado ($type)';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: Color(0xff2c3e50),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Color(0xff2c3e50),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar errores
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Error al cargar la aplicación',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  error,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Recargar la página
                  html.window.location.reload();
                },
                icon: Icon(Icons.refresh),
                label: Text('Recargar Página'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6C4DDC),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para cargar el contexto del usuario cuando hay sesión pero no contexto
class _UserContextLoadingScreen extends StatefulWidget {
  const _UserContextLoadingScreen();

  @override
  State<_UserContextLoadingScreen> createState() => _UserContextLoadingScreenState();
}

class _UserContextLoadingScreenState extends State<_UserContextLoadingScreen> {
  bool _isLoading = false; // Bandera para evitar múltiples llamadas

  @override
  void initState() {
    super.initState();
    // Usar un pequeño delay para evitar problemas de inicialización
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted && !_isLoading) {
        _loadContext();
      }
    });
  }

  Future<void> _loadContext() async {
    if (_isLoading) return; // Evitar múltiples llamadas
    _isLoading = true;

    try {
      final loadedContext = await UserContextService.loadUserContext();
      if (!mounted) return;
      
      if (loadedContext != null) {
        print('✅ Contexto cargado: ${loadedContext.userRole}');
        // Usar Navigator.of(context, rootNavigator: true) para evitar problemas
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(role: loadedContext.userRole),
          ),
        );
      } else {
        // No se pudo cargar el contexto, limpiar y mostrar login
        await UserContextService.clearUserContext();
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainMenu()),
        );
      }
    } catch (e) {
      print('❌ Error cargando contexto: $e');
      if (!mounted) return;
      await UserContextService.clearUserContext();
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainMenu()),
      );
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando sesión...'),
          ],
        ),
      ),
    );
  }
}

