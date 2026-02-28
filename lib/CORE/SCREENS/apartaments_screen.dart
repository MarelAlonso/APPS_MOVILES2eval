import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../MODELS/apartament_model.dart';

class ApartmentsListScreen extends StatefulWidget {
	const ApartmentsListScreen({super.key});

	@override
	State<ApartmentsListScreen> createState() => _ApartmentsListScreenState();
}

class _ApartmentsListScreenState extends State<ApartmentsListScreen> {
		late Future<List<Apartamento>> _apartamentosFuture;

		@override
		void initState() {
			super.initState();
			_apartamentosFuture = _cargarApartamentos();
		}

		Future<List<Apartamento>> _cargarApartamentos() {
			final usuario = Supabase.instance.client.auth.currentSession?.user;
			if (usuario == null) {
				return Future.value([]);
			}
			return Supabase.instance.client
					.from('apartments')
					.select()
					.eq('owner_id', usuario.id)
					.withConverter(
						(data) => data.map((json) => Apartamento.fromJson(json)).toList(),
					);
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
				title: const Text('Tus apartamentos'),
				actions: [
					IconButton(
						tooltip: 'Añadir apartamento',
						icon: const Icon(Icons.add),
						onPressed: () async {
							await context.push('/add-apartment');
							if (mounted) {
								setState(() {
									_apartamentosFuture = _cargarApartamentos();
								});
							}
						},
					),
				],
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
							return Center(child: Text('Error: ${snapshot.error}'));
						}
						if (!snapshot.hasData || snapshot.data!.isEmpty) {
							return const Center(child: Text('No hay apartamentos disponibles.'));
						}
						final apartamentos = snapshot.data!;
						return ListView.builder(
							itemCount: apartamentos.length + 1,
							itemBuilder: (context, index) {
								if (index == 0) {
									return Padding(
										padding: const EdgeInsets.only(bottom: 12),
										child: SizedBox(
											height: 220,
											width: double.infinity,
											child: Image.asset(
												'IMG/header_inicio.jpg',
												fit: BoxFit.cover,
												errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
											),
										),
									);
								}
								final apartamento = apartamentos[index - 1];
								return Card(
									margin: const EdgeInsets.all(8.0),
									child: ListTile(
										leading: const Icon(Icons.apartment),
										title: Text(apartamento.nombre),
										subtitle: Text(
											'${apartamento.miniDescripcion ?? apartamento.descripcion ?? 'Sin descripción'} · ${apartamento.maxHuespedes ?? '-'} huéspedes',
										),
										trailing: Text('${apartamento.precioPorNoche} €/noche'),
										onTap: () {
											context.push('/apartment-detail', extra: apartamento);
										},
									),
								);
							},
						);
					},
				),
			),
			bottomNavigationBar: BottomNavigationBar(
				currentIndex: 1,
				items: const [
					BottomNavigationBarItem(
						icon: Icon(Icons.search),
						label: 'Buscar',
					),
					BottomNavigationBarItem(
						icon: Icon(Icons.apartment),
						label: 'Tus apartamentos',
					),
					BottomNavigationBarItem(
						icon: Icon(Icons.calendar_month),
						label: 'Reservas',
					),
				],
				onTap: (index) {
					if (index == 0) {
						context.go('/buscar');
					} else if (index == 2) {
						context.go('/reservas');
					}
				},
			),
		);
	}
	// ...existing code...
}