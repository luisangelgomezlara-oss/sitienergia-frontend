class IncidenciaRequest {
  final int categoriaId;
  final String nic; 
  final String descripcion;
  final String ubicacion;
  final double? latitud;  
  final double? longitud; 

  IncidenciaRequest({
    required this.categoriaId,
    required this.nic,
    required this.descripcion,
    required this.ubicacion,
    this.latitud,
    this.longitud,
  });


  Map<String, dynamic> toJson() {
    return {
      "categoriaId": categoriaId,
      "nic": nic,
      "descripcion": descripcion,
      "ubicacion": ubicacion,
      "latitud": latitud,
      "longitud": longitud,
    };
  }
}