import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_app/models/institution.dart';
import 'package:frontend_app/services/user_context_service.dart';

class UserInfoCard extends StatelessWidget {
  final UserContext userContext;
  final bool isWeb;

  const UserInfoCard({
    Key? key,
    required this.userContext,
    this.isWeb = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (userContext.userRole) {
      case 'admin_institution':
        return _buildAdminInfoCard(context);
      case 'emisor':
        return _buildEmisorInfoCard(context);
      case 'student':
        return _buildStudentInfoCard(context);
      default:
        return _buildStudentInfoCard(context); // O un widget genérico
    }
  }

  Widget _buildAdminInfoCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showInstitutionInfoModal(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Color(0xff6C4DDC).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido, ${userContext.userName ?? 'Administrador'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWeb ? 28 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Administrador de ${userContext.currentInstitution?.name ?? 'Institución'}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isWeb ? 18 : 16,
                        ),
                      ),
                      if (userContext.currentInstitution?.shortName != null) ...[
                        SizedBox(height: 4),
                        Text(
                          '(${userContext.currentInstitution!.shortName})',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: isWeb ? 16 : 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  color: Colors.white70,
                  size: isWeb ? 24 : 20,
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Toca para ver información detallada de la institución',
              style: TextStyle(
                color: Colors.white60,
                fontSize: isWeb ? 14 : 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmisorInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Color(0xff6C4DDC).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido, ${userContext.userName ?? 'Emisor'}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 28 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Emisor en ${userContext.currentInstitution?.name ?? 'Institución'}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isWeb ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido, ${userContext.userName ?? 'Estudiante'}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 28 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (userContext.institutionName != null || userContext.institution != null || userContext.institutionId != null) ...[
            SizedBox(height: 8),
            Text(
              'Estudiante de ${userContext.institutionName ?? userContext.institution}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isWeb ? 16 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showInstitutionInfoModal(BuildContext context) {
    final institution = userContext.currentInstitution;
    if (institution == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 600,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información de la Institución',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                institution.name,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: _buildInstitutionInfoContent(context, institution),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstitutionInfoContent(BuildContext context, Institution institution) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xff6C4DDC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.qr_code,
                    color: Color(0xff6C4DDC),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Código de Institución',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        institution.institutionCode,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff6C4DDC),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _copyInstitutionCode(context, institution.institutionCode),
                    icon: Icon(Icons.copy, color: Color(0xff6C4DDC)),
                    tooltip: 'Copiar código',
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Comparte este código con tus estudiantes para que puedan registrarse en tu institución',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        if (institution.description.isNotEmpty) ...[
          Text(
            'Descripción:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xff2E2F44),
            ),
          ),
          SizedBox(height: 4),
          Text(
            institution.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
        ],
        
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Estado',
                institution.status.displayName,
                Icons.info_outline,
                isWeb: true,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'Programas',
                '${institution.settings.supportedPrograms.length}',
                Icons.menu_book,
                isWeb: true,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Registro de Estudiantes',
                institution.settings.allowStudentRegistration ? 'Habilitado' : 'Deshabilitado',
                Icons.person_add,
                isWeb: true,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'Verificación Pública',
                institution.settings.allowPublicVerification ? 'Habilitada' : 'Deshabilitada',
                Icons.verified,
                isWeb: true,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Blockchain',
                institution.settings.enableBlockchain ? 'Habilitado' : 'Deshabilitado',
                Icons.link,
                isWeb: true,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'Idioma',
                institution.settings.defaultLanguage.toUpperCase(),
                Icons.language,
                isWeb: true,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 20),
        
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fechas de Registro',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Creado',
                      institution.createdAt != null 
                          ? '${institution.createdAt!.day}/${institution.createdAt!.month}/${institution.createdAt!.year}'
                          : 'No disponible',
                      Icons.calendar_today,
                      isWeb: true,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(
                      'Actualizado',
                      institution.updatedAt != null 
                          ? '${institution.updatedAt!.day}/${institution.updatedAt!.month}/${institution.updatedAt!.year}'
                          : 'No disponible',
                      Icons.update,
                      isWeb: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {required bool isWeb}) {
    return Row(
      children: [
        Icon(
          icon,
          size: isWeb ? 16 : 14,
          color: Color(0xff6C4DDC),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isWeb ? 12 : 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isWeb ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff2E2F44),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copyInstitutionCode(BuildContext context, String code) {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código no disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código copiado al portapapeles: $code'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
}