// lib/models/certificate_template.dart
// Modelo para plantillas de certificados

import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateTemplate {
  final String id;
  final String name;
  final String description;
  final String institutionId;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final TemplateDesign design;
  final TemplateLayout layout;
  final List<TemplateField> fields;

  CertificateTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.institutionId,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.design,
    required this.layout,
    required this.fields,
  });

  factory CertificateTemplate.fromMap(Map<String, dynamic> data, String id) {
    return CertificateTemplate(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      institutionId: data['institutionId'] ?? '',
      isDefault: data['isDefault'] ?? false,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      design: TemplateDesign.fromMap(data['design'] ?? {}),
      layout: TemplateLayout.fromMap(data['layout'] ?? {}),
      fields: (data['fields'] as List<dynamic>?)
          ?.map((field) => TemplateField.fromMap(field))
          .toList() ?? [],
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'institutionId': institutionId,
      'isDefault': isDefault,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'design': design.toMap(),
      'layout': layout.toMap(),
      'fields': fields.map((field) => field.toMap()).toList(),
    };
  }

  CertificateTemplate copyWith({
    String? name,
    String? description,
    bool? isDefault,
    DateTime? updatedAt,
    TemplateDesign? design,
    TemplateLayout? layout,
    List<TemplateField>? fields,
  }) {
    return CertificateTemplate(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      institutionId: institutionId,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      design: design ?? this.design,
      layout: layout ?? this.layout,
      fields: fields ?? this.fields,
    );
  }
}

class TemplateDesign {
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String textColor;
  final String headerBackgroundColor;
  final String headerTextColor;
  final String borderColor;
  final double borderWidth;
  final double borderRadius;
  final String fontFamily;
  final double titleFontSize;
  final double subtitleFontSize;
  final double bodyFontSize;
  final double smallFontSize;
  final String logoUrl;
  final String backgroundImageUrl;
  final double backgroundOpacity;
  // Fuentes individuales para cada elemento
  final String titleFontFamily;
  final String subtitleFontFamily;
  final String bodyFontFamily;
  final String smallFontFamily;
  // Imágenes personalizables
  final String institutionLogoUrl;
  final String certificateBackgroundUrl;
  final double logoOpacity;
  final String logoPosition; // 'top-left', 'top-right', 'top-center', 'bottom-left', 'bottom-right', 'bottom-center'
  
  // Textos de firmas personalizables
  final String issuerSignatureLabel; // "Firma del Emisor", "Director Académico", etc.
  final String issuerTitleLabel; // "Director", "Rector", etc.
  final String dateLabel; // "Fecha", "Fecha de Emisión", etc.
  final String issuerName; // "Dr. María González", "Lic. Juan Pérez", etc.

  TemplateDesign({
    this.primaryColor = '#6C4DDC',
    this.secondaryColor = '#9C27B0',
    this.backgroundColor = '#FFFFFF',
    this.textColor = '#000000',
    this.headerBackgroundColor = '#6C4DDC',
    this.headerTextColor = '#FFFFFF',
    this.borderColor = '#E0E0E0',
    this.borderWidth = 1.0,
    this.borderRadius = 8.0,
    this.fontFamily = 'Roboto',
    this.titleFontSize = 32.0,
    this.subtitleFontSize = 18.0,
    this.bodyFontSize = 16.0,
    this.smallFontSize = 12.0,
    this.logoUrl = '',
    this.backgroundImageUrl = '',
    this.backgroundOpacity = 0.1,
    this.titleFontFamily = 'Roboto',
    this.subtitleFontFamily = 'Roboto',
    this.bodyFontFamily = 'Roboto',
    this.smallFontFamily = 'Roboto',
    this.institutionLogoUrl = '',
    this.certificateBackgroundUrl = '',
    this.logoOpacity = 1.0,
    this.logoPosition = 'top-center',
    this.issuerSignatureLabel = 'Firma del Emisor',
    this.issuerTitleLabel = 'Director Académico',
    this.dateLabel = 'Fecha',
    this.issuerName = 'Dr. María González',
  });

  factory TemplateDesign.fromMap(Map<String, dynamic> data) {
    return TemplateDesign(
      primaryColor: data['primaryColor'] ?? '#6C4DDC',
      secondaryColor: data['secondaryColor'] ?? '#9C27B0',
      backgroundColor: data['backgroundColor'] ?? '#FFFFFF',
      textColor: data['textColor'] ?? '#000000',
      headerBackgroundColor: data['headerBackgroundColor'] ?? '#6C4DDC',
      headerTextColor: data['headerTextColor'] ?? '#FFFFFF',
      borderColor: data['borderColor'] ?? '#E0E0E0',
      borderWidth: (data['borderWidth'] ?? 1.0).toDouble(),
      borderRadius: (data['borderRadius'] ?? 8.0).toDouble(),
      fontFamily: data['fontFamily'] ?? 'Roboto',
      titleFontSize: (data['titleFontSize'] ?? 32.0).toDouble(),
      subtitleFontSize: (data['subtitleFontSize'] ?? 18.0).toDouble(),
      bodyFontSize: (data['bodyFontSize'] ?? 16.0).toDouble(),
      smallFontSize: (data['smallFontSize'] ?? 12.0).toDouble(),
      logoUrl: data['logoUrl'] ?? '',
      backgroundImageUrl: data['backgroundImageUrl'] ?? '',
      backgroundOpacity: (data['backgroundOpacity'] ?? 0.1).toDouble(),
      titleFontFamily: data['titleFontFamily'] ?? 'Roboto',
      subtitleFontFamily: data['subtitleFontFamily'] ?? 'Roboto',
      bodyFontFamily: data['bodyFontFamily'] ?? 'Roboto',
      smallFontFamily: data['smallFontFamily'] ?? 'Roboto',
      institutionLogoUrl: data['institutionLogoUrl'] ?? '',
      certificateBackgroundUrl: data['certificateBackgroundUrl'] ?? '',
      logoOpacity: (data['logoOpacity'] ?? 1.0).toDouble(),
      logoPosition: data['logoPosition'] ?? 'top-center',
      issuerSignatureLabel: data['issuerSignatureLabel'] ?? 'Firma del Emisor',
      issuerTitleLabel: data['issuerTitleLabel'] ?? 'Director Académico',
      dateLabel: data['dateLabel'] ?? 'Fecha',
      issuerName: data['issuerName'] ?? 'Dr. María González',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'headerBackgroundColor': headerBackgroundColor,
      'headerTextColor': headerTextColor,
      'borderColor': borderColor,
      'borderWidth': borderWidth,
      'borderRadius': borderRadius,
      'fontFamily': fontFamily,
      'titleFontSize': titleFontSize,
      'subtitleFontSize': subtitleFontSize,
      'bodyFontSize': bodyFontSize,
      'smallFontSize': smallFontSize,
      'logoUrl': logoUrl,
      'backgroundImageUrl': backgroundImageUrl,
      'backgroundOpacity': backgroundOpacity,
      'titleFontFamily': titleFontFamily,
      'subtitleFontFamily': subtitleFontFamily,
      'bodyFontFamily': bodyFontFamily,
      'smallFontFamily': smallFontFamily,
      'institutionLogoUrl': institutionLogoUrl,
      'certificateBackgroundUrl': certificateBackgroundUrl,
      'logoOpacity': logoOpacity,
      'logoPosition': logoPosition,
      'issuerSignatureLabel': issuerSignatureLabel,
      'issuerTitleLabel': issuerTitleLabel,
      'dateLabel': dateLabel,
      'issuerName': issuerName,
    };
  }
}

class TemplateLayout {
  final String orientation; // 'portrait' or 'landscape'
  final double width;
  final double height;
  final EdgeInsetsData padding;
  final EdgeInsetsData margin;
  final String alignment; // 'left', 'center', 'right'
  final bool showHeader;
  final bool showFooter;
  final bool showBorder;
  final bool showBackground;
  final String backgroundPattern; // 'none', 'dots', 'lines', 'geometry', 'waves', 'hexagons'
  final String patternColor;
  final double patternOpacity;
  final bool showShadow;
  final double shadowBlur;
  final double shadowOffset;
  final String shadowColor;

  TemplateLayout({
    this.orientation = 'portrait',
    this.width = 800.0,
    this.height = 600.0,
    this.padding = const EdgeInsetsData(top: 32, bottom: 32, left: 32, right: 32),
    this.margin = const EdgeInsetsData(top: 16, bottom: 16, left: 16, right: 16),
    this.alignment = 'center',
    this.showHeader = true,
    this.showFooter = true,
    this.showBorder = true,
    this.showBackground = true,
    this.backgroundPattern = 'none',
    this.patternColor = '#E0E0E0',
    this.patternOpacity = 0.3,
    this.showShadow = true,
    this.shadowBlur = 8.0,
    this.shadowOffset = 4.0,
    this.shadowColor = '#000000',
  });

  factory TemplateLayout.fromMap(Map<String, dynamic> data) {
    return TemplateLayout(
      orientation: data['orientation'] ?? 'portrait',
      width: (data['width'] ?? 800.0).toDouble(),
      height: (data['height'] ?? 600.0).toDouble(),
      padding: EdgeInsetsData.fromMap(data['padding'] ?? {}),
      margin: EdgeInsetsData.fromMap(data['margin'] ?? {}),
      alignment: data['alignment'] ?? 'center',
      showHeader: data['showHeader'] ?? true,
      showFooter: data['showFooter'] ?? true,
      showBorder: data['showBorder'] ?? true,
      showBackground: data['showBackground'] ?? true,
      backgroundPattern: data['backgroundPattern'] ?? 'none',
      patternColor: data['patternColor'] ?? '#E0E0E0',
      patternOpacity: (data['patternOpacity'] ?? 0.3).toDouble(),
      showShadow: data['showShadow'] ?? true,
      shadowBlur: (data['shadowBlur'] ?? 8.0).toDouble(),
      shadowOffset: (data['shadowOffset'] ?? 4.0).toDouble(),
      shadowColor: data['shadowColor'] ?? '#000000',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orientation': orientation,
      'width': width,
      'height': height,
      'padding': padding.toMap(),
      'margin': margin.toMap(),
      'alignment': alignment,
      'showHeader': showHeader,
      'showFooter': showFooter,
      'showBorder': showBorder,
      'showBackground': showBackground,
      'backgroundPattern': backgroundPattern,
      'patternColor': patternColor,
      'patternOpacity': patternOpacity,
      'showShadow': showShadow,
      'shadowBlur': shadowBlur,
      'shadowOffset': shadowOffset,
      'shadowColor': shadowColor,
    };
  }
}

class EdgeInsetsData {
  final double top;
  final double bottom;
  final double left;
  final double right;

  const EdgeInsetsData({
    this.top = 0.0,
    this.bottom = 0.0,
    this.left = 0.0,
    this.right = 0.0,
  });

  factory EdgeInsetsData.fromMap(Map<String, dynamic> data) {
    return EdgeInsetsData(
      top: (data['top'] ?? 0.0).toDouble(),
      bottom: (data['bottom'] ?? 0.0).toDouble(),
      left: (data['left'] ?? 0.0).toDouble(),
      right: (data['right'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'top': top,
      'bottom': bottom,
      'left': left,
      'right': right,
    };
  }
}

class TemplateField {
  final String id;
  final String type; // 'text', 'image', 'qr', 'signature', 'date', 'custom'
  final String label;
  final String value;
  final FieldPosition position;
  final FieldStyle style;
  final bool isVisible;
  final int order;

  TemplateField({
    required this.id,
    required this.type,
    required this.label,
    required this.value,
    required this.position,
    required this.style,
    this.isVisible = true,
    required this.order,
  });

  factory TemplateField.fromMap(Map<String, dynamic> data) {
    return TemplateField(
      id: data['id'] ?? '',
      type: data['type'] ?? 'text',
      label: data['label'] ?? '',
      value: data['value'] ?? '',
      position: FieldPosition.fromMap(data['position'] ?? {}),
      style: FieldStyle.fromMap(data['style'] ?? {}),
      isVisible: data['isVisible'] ?? true,
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'label': label,
      'value': value,
      'position': position.toMap(),
      'style': style.toMap(),
      'isVisible': isVisible,
      'order': order,
    };
  }
}

class FieldPosition {
  final double x;
  final double y;
  final double width;
  final double height;
  final String alignment; // 'left', 'center', 'right'

  FieldPosition({
    this.x = 0.0,
    this.y = 0.0,
    this.width = 200.0,
    this.height = 50.0,
    this.alignment = 'center',
  });

  factory FieldPosition.fromMap(Map<String, dynamic> data) {
    return FieldPosition(
      x: (data['x'] ?? 0.0).toDouble(),
      y: (data['y'] ?? 0.0).toDouble(),
      width: (data['width'] ?? 200.0).toDouble(),
      height: (data['height'] ?? 50.0).toDouble(),
      alignment: data['alignment'] ?? 'center',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'alignment': alignment,
    };
  }
}

class FieldStyle {
  final String fontFamily;
  final double fontSize;
  final String fontWeight; // 'normal', 'bold'
  final String color;
  final String backgroundColor;
  final double borderRadius;
  final String textAlign; // 'left', 'center', 'right'
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  FieldStyle({
    this.fontFamily = 'Roboto',
    this.fontSize = 16.0,
    this.fontWeight = 'normal',
    this.color = '#000000',
    this.backgroundColor = 'transparent',
    this.borderRadius = 0.0,
    this.textAlign = 'center',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
  });

  factory FieldStyle.fromMap(Map<String, dynamic> data) {
    return FieldStyle(
      fontFamily: data['fontFamily'] ?? 'Roboto',
      fontSize: (data['fontSize'] ?? 16.0).toDouble(),
      fontWeight: data['fontWeight'] ?? 'normal',
      color: data['color'] ?? '#000000',
      backgroundColor: data['backgroundColor'] ?? 'transparent',
      borderRadius: (data['borderRadius'] ?? 0.0).toDouble(),
      textAlign: data['textAlign'] ?? 'center',
      isBold: data['isBold'] ?? false,
      isItalic: data['isItalic'] ?? false,
      isUnderline: data['isUnderline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontWeight': fontWeight,
      'color': color,
      'backgroundColor': backgroundColor,
      'borderRadius': borderRadius,
      'textAlign': textAlign,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
    };
  }
}
