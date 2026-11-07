import 'dart:convert';

class IncidenciaModel {
  final int? id;
  final int categoriaId;
  final String nic;
  final String descripcion;
  final String ubicacion;
  final double? latitud;
  final double? longitud;
  final String? estado;
  final String? fechaCreacion;
  final String? imagen;
  final String? cuadrillaAsignada;

  IncidenciaModel({
    this.id,
    required this.categoriaId,
    required this.nic,
    required this.descripcion,
    required this.ubicacion,
    this.latitud,
    this.longitud,
    this.estado,
    this.fechaCreacion,
    this.imagen,
    this.cuadrillaAsignada,
  });

  factory IncidenciaModel.fromJson(Map<String, dynamic> json) {
    // Manejo seguro del ID de la categoría por si viene anidado o plano
    int parsedCategoriaId = 0;
    if (json['categoria'] != null && json['categoria'] is Map) {
      parsedCategoriaId = int.tryParse(json['categoria']['id']?.toString() ?? '0') ?? 0;
    } else if (json['categoriaId'] != null) {
      parsedCategoriaId = int.tryParse(json['categoriaId'].toString()) ?? 0;
    }

    return IncidenciaModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      categoriaId: parsedCategoriaId,
      nic: json['nic']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      ubicacion: json['ubicacion']?.toString() ?? '',
      latitud: json['latitud'] != null ? double.tryParse(json['latitud'].toString()) : null,
      longitud: json['longitud'] != null ? double.tryParse(json['longitud'].toString()) : null,
      estado: json['estado']?.toString() ?? 'PENDIENTE',
      fechaCreacion: json['fechaCreacion']?.toString(),
      imagen: json['imagen']?.toString(),
      cuadrillaAsignada: json['cuadrillaAsignada']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoriaId': categoriaId,
      'nic': nic,
      'descripcion': descripcion,
      'ubicacion': ubicacion,
      'latitud': latitud,
      'longitud': longitud,
      'imagen': imagen,
    };
  }
}