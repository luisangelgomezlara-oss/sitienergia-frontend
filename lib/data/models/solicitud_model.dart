class SolicitudRequest {
  final String tipoServicio;
  final String fechaProgramada; // Lo enviaremos como String "YYYY-MM-DD"

  SolicitudRequest({
    required this.tipoServicio,
    required this.fechaProgramada,
  });

  Map<String, dynamic> toJson() {
    return {
      "tipoServicio": tipoServicio,
      "fechaProgramada": fechaProgramada,
    };
  }
}