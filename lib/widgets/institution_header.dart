// lib/widgets/institution_header.dart
// Widget para mostrar información de la institución actual

import 'package:flutter/material.dart';
import '../services/user_context_service.dart';
import '../models/institution.dart';

class InstitutionHeader extends StatelessWidget {
  final VoidCallback? onInstitutionChange;
  final bool showChangeButton;

  const InstitutionHeader({
    Key? key,
    this.onInstitutionChange,
    this.showChangeButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final context = UserContextService.currentContext;
    final institution = UserContextService.currentInstitution;

    // Si no hay contexto o institución, no mostrar nada
    if (context == null || institution == null) {
      return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))),
            Color(int.parse(institution.colors.secondary.replaceAll('#', '0xFF'))),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo de la institución
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                institution.shortName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 16),
          
          // Información de la institución
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institution.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  institution.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      institution.status.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${institution.settings.supportedPrograms.length} programas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Botón para cambiar institución (si está habilitado)
          if (showChangeButton && context.isSuperAdmin)
            IconButton(
              onPressed: onInstitutionChange,
              icon: Icon(
                Icons.swap_horiz,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'Cambiar institución',
            ),
        ],
      ),
    );
  }
}

// Widget compacto para mostrar solo el nombre de la institución
class InstitutionNameChip extends StatelessWidget {
  const InstitutionNameChip({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final institution = UserContextService.currentInstitution;
    
    if (institution == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            institution.shortName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar el estado de la institución
class InstitutionStatusBadge extends StatelessWidget {
  const InstitutionStatusBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final institution = UserContextService.currentInstitution;
    
    if (institution == null) {
      return SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    
    switch (institution.status) {
      case InstitutionStatus.active:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case InstitutionStatus.inactive:
        statusColor = Colors.grey;
        statusIcon = Icons.pause_circle;
        break;
      case InstitutionStatus.suspended:
        statusColor = Colors.red;
        statusIcon = Icons.block;
        break;
      case InstitutionStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            institution.status.displayName,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
