import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_with_institution.dart';
import 'guest_page.dart';
import '../../header/HeaderHome.dart';
import '../../services/user_context_service.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  Map<String, dynamic> _pageData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPageData();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    try {
      print('🔍 DEBUG - Cargando contexto de usuario en MainMenu...');
      await UserContextService.loadUserContext();
      print('✅ Contexto cargado en MainMenu');
    } catch (e) {
      print('❌ Error cargando contexto en MainMenu: $e');
    }
  }

  Future<void> _loadPageData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('page_content')
          .doc('main_page')
          .get();
      
      if (doc.exists) {
        setState(() {
          _pageData = doc.data()!;
          _isLoading = false;
        });
      } else {
        // Usar datos por defecto si no existen
        setState(() {
          _pageData = _getDefaultPageData();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando datos de página: $e');
      setState(() {
        _pageData = _getDefaultPageData();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getDefaultPageData() {
    return {
      'title': 'Bienvenido a Certiblock',
      'description': 'Esta plataforma permite registrar y validar certificados académicos a través de la tecnología Blockchain, garantizando seguridad y trazabilidad.',
      'welcomeMessage': 'Bienvenido a nuestra plataforma de certificados digitales',
      'companyName': 'Certiblock',
      'companyDescription': 'Plataforma líder en certificados digitales con tecnología Blockchain',
      'companyWebsite': 'https://certiblock.com',
      'companyEmail': 'info@certiblock.com',
      'companyPhone': '+1 (555) 123-4567',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Breakpoint más estándar y responsive
            final isWeb = constraints.maxWidth > 600;
            
            return Stack(
              children: [
                // Contenido principal
                Column(
                  children: [
                    // Barra de navegación superior con logo y botones
                    _buildTopNavigationBar(context, isWeb),
                    
                    // Headers fijos como fondo
                    HeaderHome(),
                    
                    // Contenido principal con scroll
                    Expanded(
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                        child: Column(
                          children: [
                                  // Hero Section
                                  _buildHeroSection(),
                                  
                                  // Services/Features Section
                                  _buildServicesSection(),
                                  
                                  // Company Info Section
                                  _buildCompanyInfoSection(),
                                  
                                  // Mobile buttons (solo en móvil)
                                  if (!isWeb) 
                                    Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: _buildMobileButtons(context),
                                    ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Método para construir la barra de navegación superior
  Widget _buildTopNavigationBar(BuildContext context, bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            height: 50,
            child: Image.asset(
              'assets/images/logodegrado.PNG',
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          
          // Espaciador para empujar los botones a la derecha
          Spacer(),
          
          // Botones de navegación (solo en web)
          if (isWeb) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 3,
                shadowColor: Color(0xff6C4DDC).withOpacity(0.3),
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: () => _navigateToLogin(context),
              child: const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xff6C4DDC),
                side: BorderSide(color: Color(0xff6C4DDC), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: () => _navigateToRegister(context),
              child: const Text(
                'Registrarse',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Método para construir el hero section
  Widget _buildHeroSection() {
    return Container(
      height: 550,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff2E2F44),
            Color(0xff1a1a2e),
          ],
        ),
        image: DecorationImage(
          image: AssetImage('assets/images/logodegrado.PNG'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Stack(
        children: [
          // Overlay oscuro
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Contenido del hero
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icono central
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Color(0xff6C4DDC),
        borderRadius: BorderRadius.circular(20),
                    boxShadow: [
          BoxShadow(
                        color: Color(0xff6C4DDC).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: 30),
                
                // Título principal
                Text(
                  _pageData['title'] ?? 'Bienvenido a Certiblock',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 16),
                
                // Subtítulo 1
                Text(
                  'Certificados digitales con tecnología Blockchain',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 8),
                
                // Subtítulo 2
                Text(
                  'Garantizando seguridad y trazabilidad',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  // Método para construir información de contacto individual
  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Color(0xff6C4DDC)),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Método para construir la sección de servicios
  Widget _buildServicesSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          // Título de la sección
          Text(
            'Nuestros Servicios',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xff2E2F44),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
          
          Text(
            'Soluciones completas para la gestión de certificados digitales',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 50),
          
          // Grid de servicios
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                                 constraints.maxWidth > 800 ? 3 : 
                                 constraints.maxWidth > 600 ? 2 : 1;
              
              // Calcular aspect ratio dinámico basado en el ancho disponible
              double childAspectRatio;
              if (constraints.maxWidth > 1200) {
                childAspectRatio = 2.2; // Más ancho para pantallas grandes
              } else if (constraints.maxWidth > 800) {
                childAspectRatio = 2.0; // Estándar para tablets
              } else if (constraints.maxWidth > 600) {
                childAspectRatio = 1.8; // Más alto para pantallas medianas
              } else {
                childAspectRatio = 1.5; // Más alto para móviles
              }
              
              return GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildServiceCard(
                    Icons.verified_user,
                    'Certificados Seguros',
                    'Emisión de certificados digitales con tecnología Blockchain, garantizando autenticidad y seguridad total.',
                  ),
                  _buildServiceCard(
                    Icons.search,
                    'Validación Instantánea',
                    'Sistema de verificación en tiempo real que permite validar la autenticidad de cualquier certificado emitido.',
                  ),
                  _buildServiceCard(
                    Icons.architecture,
                    'Gestión Institucional',
                    'Plataforma completa para instituciones educativas gestionar sus programas y emitir certificados.',
                  ),
                  _buildServiceCard(
                    Icons.support_agent,
                    'Soporte Técnico',
                    'Asistencia especializada y consultoría para implementar y mantener el sistema de certificados.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Método para construir una tarjeta de servicio
  Widget _buildServiceCard(IconData icon, String title, String description) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xff6C4DDC),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              size: 25,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: 12),
          
          // Contenido
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título
                Text(
                  title,
      style: TextStyle(
                    fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xff2E2F44),
      ),
      textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 6),
                
                // Descripción
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir la sección de información de la empresa
  Widget _buildCompanyInfoSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Título
          Text(
            _pageData['companyName'] ?? 'Certiblock',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xff6C4DDC),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
          
          // Descripción
          if (_pageData['companyDescription'] != null && _pageData['companyDescription'].isNotEmpty)
            Text(
              _pageData['companyDescription'],
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w300,
              ),
      textAlign: TextAlign.center,
            ),
          
          SizedBox(height: 40),
          
          // Información de contacto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_pageData['companyEmail'] != null && _pageData['companyEmail'].isNotEmpty)
                _buildContactInfo(Icons.email, _pageData['companyEmail']),
              if (_pageData['companyPhone'] != null && _pageData['companyPhone'].isNotEmpty)
                _buildContactInfo(Icons.phone, _pageData['companyPhone']),
              if (_pageData['companyWebsite'] != null && _pageData['companyWebsite'].isNotEmpty)
                _buildContactInfo(Icons.language, _pageData['companyWebsite']),
            ],
          ),
        ],
      ),
    );
  }

  // Método para construir botones móviles
  Widget _buildMobileButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6C4DDC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              shadowColor: Colors.black26,
            ),
            onPressed: () => _navigateToLogin(context),
            child: const Text(
              'Iniciar Sesión',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xff6C4DDC), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => _navigateToRegister(context),
            child: const Text(
              'Registrarse',
              style: TextStyle(fontSize: 18, color: Color(0xff6C4DDC)),
            ),
          ),
        ),
      ],
    );
  }


  // Método para navegar al login
  void _navigateToLogin(BuildContext context) {
    print('=== NAVEGACIÓN: Iniciar Sesión ===');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginWithInstitution()),
    );
  }

  // Método para navegar al registro (ambos tipos van al mismo lugar)
  void _navigateToRegister(BuildContext context) {
    print('=== NAVEGACIÓN: Registro ===');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GuestPage()),
    );
  }
}
