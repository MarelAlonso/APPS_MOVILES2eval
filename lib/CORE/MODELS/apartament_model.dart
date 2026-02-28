// Modelo apartamento, guarda datos piso
class Apartamento {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? miniDescripcion;
  final double? precioPorNoche;
  final int? maxHuespedes;
  final int? habitaciones;
  final int? banos;
  final List<String> servicios;
  final List<String> imagenes;
  final String? urlImagen;
  final double? latitud;
  final double? longitud;

  Apartamento({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.miniDescripcion,
    this.precioPorNoche,
    this.maxHuespedes,
    this.habitaciones,
    this.banos,
    this.servicios = const [],
    this.imagenes = const [],
    this.urlImagen,
    this.latitud,
    this.longitud,
  });

  // Convierte valor a lista de texto, para servicios e imágenes
  static List<String> _aListaTexto(dynamic valor) {
    if (valor == null) return const [];
    if (valor is List) {
      return valor
          .where((elemento) => elemento != null)
          .map((elemento) => elemento.toString())
          .toList();
    }
    return [valor.toString()];
  }

  // Crea apartamento desde json, para pillar datos guardados
  factory Apartamento.fromJson(Map<String, dynamic> json) {
    return Apartamento(
      id: json['id'].toString(),
      nombre: (json['name'] ?? '').toString(),
      descripcion: json['description']?.toString(),
      miniDescripcion: json['short_description']?.toString(),
      precioPorNoche: (json['price_per_night'] as num?)?.toDouble(),
      maxHuespedes: (json['max_guests'] as num?)?.toInt(),
      habitaciones: (json['bedrooms'] as num?)?.toInt(),
      banos: (json['bathrooms'] as num?)?.toInt(),
      servicios: _aListaTexto(json['amenities']),
      imagenes: _aListaTexto(json['images']),
      urlImagen: json['image_url']?.toString(),
      latitud: (json['latitude'] as num?)?.toDouble(),
      longitud: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
