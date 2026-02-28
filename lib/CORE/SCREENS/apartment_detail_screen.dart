import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../MODELS/apartament_model.dart';
import '../RESERVAS/reserva_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../RESERVAS/reservas_provider.dart';

class ApartmentDetailScreen extends StatefulWidget {
  final Apartamento apartamento;
  final bool modoCliente;

  const ApartmentDetailScreen({
    super.key,
    required this.apartamento,
    this.modoCliente = false,
  });

  @override
  State<ApartmentDetailScreen> createState() => _ApartmentDetailScreenState();
}

class _ApartmentDetailScreenState extends State<ApartmentDetailScreen> {
  void _mostrarCalendarioReserva() async {
    // Aquí deberías obtener las reservas existentes para este apartamento desde la base de datos
    // Por ahora, ejemplo vacío:
    final reservasNoDisponibles = <DateTimeRange>[];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecciona fechas de reserva'),
          content: SizedBox(
            width: 350,
            height: 400,
            child: ReservaCalendar(
              reservasNoDisponibles: reservasNoDisponibles,
              onReservaSeleccionada: (rango) async {
                Navigator.of(context).pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar reserva'),
                    content: Text('¿Está seguro que desea reservar del '
                        '${rango.start.day}/${rango.start.month}/${rango.start.year} al '
                        '${rango.end.day}/${rango.end.month}/${rango.end.year}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Reservar'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;

                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debes iniciar sesión para reservar.')),
                    );
                  }
                  return;
                }

                try {
                  final booking = {
                    'apartment_id': widget.apartamento.id,
                    'guest_name': user.userMetadata?['full_name'] ?? user.email ?? 'Invitado',
                    'guest_email': user.email,
                    'check_in': rango.start.toIso8601String(),
                    'check_out': rango.end.toIso8601String(),
                    'total_price': 0.0,
                    'status': 'confirmed',
                  };
                  final response = await Supabase.instance.client.from('bookings').insert(booking).select();
                  // Confirmación visual SIEMPRE
                  if (mounted) {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reserva confirmada'),
                        content: const Text('La reserva se ha realizado correctamente.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                  // Refresca la pantalla de reservas usando el contexto de Riverpod correcto
                  try {
                    final element = context as Element;
                    final owner = ProviderScope.containerOf(element, listen: false);
                    owner.invalidate(reservasProvider);
                  } catch (_) {}
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al reservar: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }
  final ImagePicker _imagePicker = ImagePicker();
  bool _subiendoImagen = false;
  late Apartamento _apartamentoActual;

  @override
  void initState() {
    super.initState();
    _apartamentoActual = widget.apartamento;
  }

  String _contentTypeDesdeExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  String _formatearError(Object error) {
    if (error is PostgrestException) {
      return 'PostgrestException\n'
          'message: ${error.message}\n'
          'code: ${error.code}\n'
          'details: ${error.details}\n'
          'hint: ${error.hint}';
    }
    if (error is StorageException) {
      return 'StorageException\nmessage: ${error.message}\nstatusCode: ${error.statusCode}\nerror: ${error.error}';
    }
    return '${error.runtimeType}: $error';
  }

  Future<void> _mostrarErrorCopiable(String titulo, String texto) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: SizedBox(
            width: 520,
            child: SelectableText(texto),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: texto));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error copiado al portapapeles')),
                );
              },
              child: const Text('Copiar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<XFile?> _seleccionarImagenCompatible() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return openFile(
          acceptedTypeGroups: const [
            XTypeGroup(
              label: 'imágenes',
              extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
            ),
          ],
          confirmButtonText: 'Seleccionar imagen',
        );
      default:
        return _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    }
  }

  Future<void> _anadirImagenDirecta() async {
    final usuario = Supabase.instance.client.auth.currentSession?.user;
    if (usuario == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión')),
        );
      }
      return;
    }

    final propietarioId = await Supabase.instance.client
        .from('apartments')
        .select('owner_id')
        .eq('id', _apartamentoActual.id)
        .maybeSingle();

    if (propietarioId == null || propietarioId['owner_id']?.toString() != usuario.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permiso para modificar este apartamento.')),
        );
      }
      return;
    }

    final archivo = await _seleccionarImagenCompatible();
    if (archivo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ninguna imagen.')),
        );
      }
      return;
    }

    setState(() => _subiendoImagen = true);

    try {
      final bytes = await archivo.readAsBytes();
      final nombre = archivo.name;
      final extension = nombre.contains('.') ? nombre.split('.').last.toLowerCase() : 'jpg';
      final ruta = '${usuario.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await Supabase.instance.client.storage.from('apartments').uploadBinary(
        ruta,
        bytes,
        fileOptions: FileOptions(
          contentType: _contentTypeDesdeExtension(extension),
          upsert: false,
        ),
      );

      final urlPublica = Supabase.instance.client.storage.from('apartments').getPublicUrl(ruta);
      final nuevasImagenes = [..._apartamentoActual.imagenes, urlPublica];

      await Supabase.instance.client
          .from('apartments')
          .update({'images': nuevasImagenes})
          .eq('id', _apartamentoActual.id)
          .eq('owner_id', usuario.id);

      if (!mounted) return;
      setState(() {
        _apartamentoActual = Apartamento(
          id: _apartamentoActual.id,
          nombre: _apartamentoActual.nombre,
          descripcion: _apartamentoActual.descripcion,
          miniDescripcion: _apartamentoActual.miniDescripcion,
          precioPorNoche: _apartamentoActual.precioPorNoche,
          maxHuespedes: _apartamentoActual.maxHuespedes,
          habitaciones: _apartamentoActual.habitaciones,
          banos: _apartamentoActual.banos,
          servicios: _apartamentoActual.servicios,
          imagenes: nuevasImagenes,
          urlImagen: nuevasImagenes.isNotEmpty ? nuevasImagenes.first : null,
          latitud: _apartamentoActual.latitud,
          longitud: _apartamentoActual.longitud,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen añadida correctamente')),
      );
    } catch (error) {
      if (mounted) {
        final detalle = _formatearError(error);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al añadir imagen (abre el detalle para copiar)')),
        );
        await _mostrarErrorCopiable('Error al añadir imagen', detalle);
      }
    } finally {
      if (mounted) {
        setState(() => _subiendoImagen = false);
      }
    }
  }

  Future<void> _abrirGaleriaPantallaCompleta(List<String> imagenes, int indiceInicial) async {
    if (imagenes.isEmpty) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) {
        int indiceActual = indiceInicial;
        final pageController = PageController(initialPage: indiceInicial);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Center(
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: imagenes.length,
                      onPageChanged: (index) {
                        setDialogState(() {
                          indiceActual = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Image.network(
                            imagenes[index],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined, color: Colors.white70),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 36,
                    right: 16,
                    child: IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    ),
                  ),
                  if (imagenes.length > 1)
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          onPressed: indiceActual > 0
                              ? () {
                                  pageController.previousPage(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                  if (imagenes.length > 1)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          onPressed: indiceActual < imagenes.length - 1
                              ? () {
                                  pageController.nextPage(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.chevron_right, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderBackground(List<String> imagenes, String? urlImagen) {
    if (imagenes.length > 1) {
      return PageView.builder(
        itemCount: imagenes.length,
        itemBuilder: (context, index) {
          final imagen = imagenes[index];
          return GestureDetector(
            onTap: () => _abrirGaleriaPantallaCompleta(imagenes, index),
            child: Image.network(
              imagen,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.grey);
              },
            ),
          );
        },
      );
    }

    if (imagenes.length == 1) {
      return GestureDetector(
        onTap: () => _abrirGaleriaPantallaCompleta(imagenes, 0),
        child: Image.network(
          imagenes.first,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Colors.grey);
          },
        ),
      );
    }

    if (urlImagen != null && urlImagen.isNotEmpty) {
      return GestureDetector(
        onTap: () => _abrirGaleriaPantallaCompleta([urlImagen], 0),
        child: Image.network(
          urlImagen,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Colors.grey);
          },
        ),
      );
    }

    return Container(color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    final apartamento = _apartamentoActual;
    final imagenes = apartamento.imagenes;
    final urlImagen = apartamento.urlImagen;

    return Scaffold(
      bottomNavigationBar: widget.modoCliente
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: _mostrarCalendarioReserva,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Reservar ahora'),
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            actions: widget.modoCliente
                ? null
                : [
                    IconButton(
                      tooltip: 'Añadir imágenes',
                      icon: _subiendoImagen
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                      onPressed: _subiendoImagen ? null : _anadirImagenDirecta,
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push('/add-apartment', extra: apartamento),
                    ),
                  ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                apartamento.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                ),
              ),
              background: _buildHeaderBackground(imagenes, urlImagen),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${apartamento.precioPorNoche ?? '-'} € / noche',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Icon(Icons.star, color: Colors.amber),
                      ],
                    ),
                    if (apartamento.miniDescripcion != null &&
                        apartamento.miniDescripcion!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        apartamento.miniDescripcion!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(
                          Icons.people,
                          '${apartamento.maxHuespedes ?? '-'} huéspedes',
                        ),
                        _buildInfoItem(
                          Icons.bed,
                          '${apartamento.habitaciones ?? '-'} hab.',
                        ),
                        _buildInfoItem(
                          Icons.bathtub,
                          '${apartamento.banos ?? '-'} baños',
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      'Descripción',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      apartamento.descripcion ?? 'Sin descripción detallada.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    if (apartamento.servicios.isNotEmpty) ...[
                      Text(
                        'Servicios',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: apartamento.servicios.map((servicio) {
                          return Chip(
                            label: Text(servicio),
                            avatar: const Icon(Icons.check, size: 18),
                          );
                        }).toList(),
                      ),
                      if (apartamento.latitud != null && apartamento.longitud != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Ubicación',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 220,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  apartamento.latitud!,
                                  apartamento.longitud!,
                                ),
                                initialZoom: 14,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.flutter_booking',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(
                                        apartamento.latitud!,
                                        apartamento.longitud!,
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icono, String texto) {
    return Column(
      children: [
        Icon(icono, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
