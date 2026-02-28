
// Calendario para reservar, bloquea días ocupados y avisa cuando seleccionas
import 'package:flutter/material.dart';

// Widget calendario para elegir fechas, bloquea días ocupados
class ReservaCalendar extends StatelessWidget {
  final List<DateTimeRange> reservasNoDisponibles;
  final void Function(DateTimeRange) onReservaSeleccionada;

  const ReservaCalendar({
    super.key,
    required this.reservasNoDisponibles,
    required this.onReservaSeleccionada,
  });

  // Función que mira si el día está pillado, devuelve true si ocupado
  bool _isDateDisabled(DateTime date) {
    for (final range in reservasNoDisponibles) {
      if (!date.isBefore(range.start) && !date.isAfter(range.end)) {
        return true;
      }
    }
    return false;
  }

  // Construye el calendario, bloquea días ocupados y lanza callback cuando eliges
  @override
  Widget build(BuildContext context) {
    return CalendarDatePicker(
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (date) => !_isDateDisabled(date),
      onDateChanged: (date) async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: date,
          lastDate: DateTime.now().add(const Duration(days: 365)),
          selectableDayPredicate: (d, _, __) => !_isDateDisabled(d),
        );
        if (range != null) {
          onReservaSeleccionada(range);
        }
      },
    );
  }
}
