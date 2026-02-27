import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../MODELS/apartament_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Apartamento>> _apartamentosFuture;

  @override
  void initState() {
    super.initState();
    _apartamentosFuture = _cargarApartamentos();
  }

  Future<List<Apartamento>> _cargarApartamentos() {
    final usuario = Supabase.instance.client.auth.currentSession?.user;

    var query = Supabase.instance.client.from('apartments').select();
    if (usuario != null) {
      query = query.neq('owner_id', usuario.id);
    }

    return query.withConverter((data) => data.map((json) => Apartamento.fromJson(json)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/inicio');
            }
          },
        ),
        title: const Text('Encuentra tu apartamento'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('IMG/body_trans.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<Apartamento>>(
          future: _apartamentosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: \\${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay apartamentos disponibles.'));
            }
            final apartamentos = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: apartamentos.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: Image.asset(
                          'IMG/header_inicio.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }
                final apartamento = apartamentos[index - 1];
                final imagen = apartamento.imagenes.isNotEmpty
                    ? apartamento.imagenes.first
                    : apartamento.urlImagen;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push(
                    '/apartment-detail',
                    extra: {
                      'apartamento': apartamento,
                      'modoCliente': true,
                    },
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 170,
                            width: double.infinity,
                            child: imagen != null && imagen.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Image.network(
                                      imagen,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.apartment, size: 38),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  apartamento.nombre,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  apartamento.miniDescripcion ?? apartamento.descripcion ?? 'Sin descripción',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text('${apartamento.precioPorNoche ?? '-'} €/noche'),
                                    const SizedBox(width: 12),
                                    Text('Máx. ${apartamento.maxHuespedes ?? '-'} huéspedes'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment),
            label: 'Tus apartamentos',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            context.go('/apartments');
          }
        },
      ),
    );
  }
}
