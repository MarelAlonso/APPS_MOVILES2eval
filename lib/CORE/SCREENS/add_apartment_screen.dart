import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../MODELS/apartament_model.dart';

class AddApartmentScreen extends StatefulWidget {
  final Apartamento? apartamento;
  final bool enfocarImagenes;

  const AddApartmentScreen({
    super.key,
    this.apartamento,
    this.enfocarImagenes = false,
  });

  @override
  State<AddApartmentScreen> createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final List<String> _serviciosDisponibles = const [
    'Wifi',
    'Aire acondicionado',
    'Cocina equipada',
    'Terraza',
    'Parking',
    'Piscina',
    'Lavadora',
    'Calefacción',
  ];
  final Set<String> _serviciosSeleccionados = {};

  final _nameController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _guestsController = TextEditingController(text: '1');
  final _bedroomsController = TextEditingController(text: '1');
  final _bathroomsController = TextEditingController(text: '1');
  final _scrollController = ScrollController();
  final _imagenesSectionKey = GlobalKey();
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _imagenesSubidas = [];
  bool _subiendoImagen = false;
  double? _latitudSeleccionada;
  double? _longitudSeleccionada;

  bool get _esEdicion => widget.apartamento != null;

  @override
  void initState() {
    super.initState();
    if (widget.apartamento != null) {
      _nameController.text = widget.apartamento!.nombre;
      _shortDescriptionController.text = widget.apartamento!.miniDescripcion ?? '';
      _descriptionController.text = widget.apartamento!.descripcion ?? '';
      _priceController.text = (widget.apartamento!.precioPorNoche ?? '').toString();
      _guestsController.text = (widget.apartamento!.maxHuespedes ?? 1).toString();
      _bedroomsController.text = (widget.apartamento!.habitaciones ?? 1).toString();
      _bathroomsController.text = (widget.apartamento!.banos ?? 1).toString();
      _latitudSeleccionada = widget.apartamento!.latitud;
      _longitudSeleccionada = widget.apartamento!.longitud;
      _imagenesSubidas = List<String>.from(widget.apartamento!.imagenes);
      if (_imagenesSubidas.isEmpty &&
          widget.apartamento!.urlImagen != null &&
          widget.apartamento!.urlImagen!.isNotEmpty) {
        _imagenesSubidas = [widget.apartamento!.urlImagen!];
      }
      _serviciosSeleccionados
        ..clear()
        ..addAll(widget.apartamento!.servicios);
    }

    if (widget.enfocarImagenes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final contextoImagenes = _imagenesSectionKey.currentContext;
        if (contextoImagenes != null) {
          Scrollable.ensureVisible(
            contextoImagenes,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
          );
        }
      });
    }
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

  Future<void> _seleccionarYSubirImagen() async {
    final usuario = Supabase.instance.client.auth.currentSession?.user;
    if (usuario == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión')),
        );
      }
      return;
    }

    final archivo = await _seleccionarImagenCompatible();
    if (archivo == null) return;

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

      if (!mounted) return;
      setState(() {
        _imagenesSubidas = [..._imagenesSubidas, urlPublica];
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subiendo imagen: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoImagen = false);
    }
  }

  Future<void> _mostrarAccionesImagen(int index) async {
    if (index < 0 || index >= _imagenesSubidas.length) return;

    final eliminar = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar imagen'),
              onTap: () => Navigator.of(context).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancelar'),
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );

    if (eliminar == true && mounted) {
      setState(() {
        _imagenesSubidas.removeAt(index);
      });
    }
  }

  Future<void> _usarUbicacionActual() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa la ubicación del dispositivo.')),
        );
      }
      return;
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se concedieron permisos de ubicación.')),
        );
      }
      return;
    }

    final posicion = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _latitudSeleccionada = posicion.latitude;
      _longitudSeleccionada = posicion.longitude;
    });
  }

  Future<void> _seleccionarEnMapa() async {
    LatLng? seleccionTemporal = (_latitudSeleccionada != null && _longitudSeleccionada != null)
        ? LatLng(_latitudSeleccionada!, _longitudSeleccionada!)
        : null;

    final centroInicial = seleccionTemporal ?? const LatLng(39.4699, -0.3763);

    final resultado = await showDialog<LatLng>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Seleccionar ubicación en mapa'),
              content: SizedBox(
                width: 360,
                height: 320,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: centroInicial,
                    initialZoom: 13,
                    onTap: (_, latLng) {
                      setDialogState(() {
                        seleccionTemporal = latLng;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flutter_booking',
                    ),
                    MarkerLayer(
                      markers: seleccionTemporal == null
                          ? []
                          : [
                              Marker(
                                point: seleccionTemporal!,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                              ),
                            ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: seleccionTemporal == null
                      ? null
                      : () => Navigator.of(context).pop(seleccionTemporal),
                  child: const Text('Usar ubicación'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado != null) {
      setState(() {
        _latitudSeleccionada = resultado.latitude;
        _longitudSeleccionada = resultado.longitude;
      });
    }
  }

  Future<void> _saveApartment() async {
    if (!_formKey.currentState!.validate()) return;

    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'short_description': _shortDescriptionController.text.trim().isEmpty
            ? null
          : _shortDescriptionController.text.trim(),
        'price_per_night':
            double.parse(_priceController.text.trim().replaceAll(',', '.')),
        'max_guests': int.parse(_guestsController.text.trim()),
        'bedrooms': int.parse(_bedroomsController.text.trim()),
        'bathrooms': int.parse(_bathroomsController.text.trim()),
        'latitude': _latitudSeleccionada,
        'longitude': _longitudSeleccionada,
        'images': _imagenesSubidas,
        'amenities': _serviciosSeleccionados.toList(),
      };

      if (_esEdicion) {
        await Supabase.instance.client
            .from('apartments')
            .update(updates)
            .eq('id', widget.apartamento!.id)
            .eq('owner_id', user.id);
      } else {
        updates['owner_id'] = user.id;
        await Supabase.instance.client.from('apartments').insert(updates);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion
                  ? 'Apartamento actualizado correctamente'
                  : 'Apartamento creado correctamente',
            ),
          ),
        );
        if (_esEdicion) {
          context.go('/apartments?refresh=${DateTime.now().millisecondsSinceEpoch}');
        } else {
          context.pop();
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteApartment() async {
    if (!_esEdicion) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar apartamento?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final user = Supabase.instance.client.auth.currentSession?.user;
      if (user == null) return;

      await Supabase.instance.client
          .from('apartments')
          .delete()
          .eq('id', widget.apartamento!.id)
          .eq('owner_id', user.id);
      if (mounted) {
        context.go('/apartments?refresh=${DateTime.now().millisecondsSinceEpoch}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar apartamento' : 'Nuevo apartamento'),
        actions: _esEdicion
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteApartment,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del apartamento'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Introduce un nombre'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shortDescriptionController,
              decoration: const InputDecoration(labelText: 'Mini descripción'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Precio / noche (€)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final text = value?.trim().replaceAll(',', '.');
                      return (text == null || double.tryParse(text) == null)
                          ? 'Inválido'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _guestsController,
                    decoration: const InputDecoration(labelText: 'Máx. huéspedes'),
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || int.tryParse(value.trim()) == null)
                        ? 'Inválido'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bedroomsController,
                    decoration: const InputDecoration(labelText: 'Habitaciones'),
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || int.tryParse(value.trim()) == null)
                        ? 'Inválido'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _bathroomsController,
                    decoration: const InputDecoration(labelText: 'Baños'),
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || int.tryParse(value.trim()) == null)
                        ? 'Inválido'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              key: _imagenesSectionKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Añadir imágenes'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagenesSubidas.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == _imagenesSubidas.length) {
                          return InkWell(
                            onTap: _subiendoImagen ? null : _seleccionarYSubirImagen,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 120,
                              height: 96,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade400),
                                color: Colors.grey.shade100,
                              ),
                              alignment: Alignment.center,
                              child: _subiendoImagen
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add, size: 30),
                            ),
                          );
                        }

                        final imagen = _imagenesSubidas[index];
                        return GestureDetector(
                          onLongPress: () => _mostrarAccionesImagen(index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imagen,
                              width: 120,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                height: 96,
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Ubicación'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarEnMapa,
                    icon: const Icon(Icons.map),
                    label: const Text('Mapa'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _usarUbicacionActual,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Actual'),
                  ),
                ),
              ],
            ),
            if (_latitudSeleccionada != null && _longitudSeleccionada != null) ...[
              const SizedBox(height: 8),
              Text(
                'Lat: ${_latitudSeleccionada!.toStringAsFixed(6)} · Lng: ${_longitudSeleccionada!.toStringAsFixed(6)}',
              ),
            ],
            const SizedBox(height: 16),
            const Text('Servicios'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _serviciosDisponibles.map((servicio) {
                final seleccionado = _serviciosSeleccionados.contains(servicio);
                return FilterChip(
                  label: Text(servicio),
                  selected: seleccionado,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _serviciosSeleccionados.add(servicio);
                      } else {
                        _serviciosSeleccionados.remove(servicio);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveApartment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_esEdicion ? 'Actualizar apartamento' : 'Guardar apartamento'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _guestsController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
