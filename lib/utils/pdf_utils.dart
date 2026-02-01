import 'package:flutter/material.dart';

/// Botones para acciones de exportación PDF
class PdfExportButtons extends StatelessWidget {
  final VoidCallback onExportPdf;
  final VoidCallback onSharePdf;
  final bool isLoading;

  const PdfExportButtons({
    super.key,
    required this.onExportPdf,
    required this.onSharePdf,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: isLoading ? null : onExportPdf,
          icon: const Icon(Icons.print, size: 18),
          label: const Text('Imprimir PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF004B49),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onSharePdf,
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Compartir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF20C997),
            foregroundColor: Colors.white,
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

/// Diálogo de configuración para exportación PDF
class PdfExportDialog extends StatefulWidget {
  final String patientName;
  final String patientId;

  const PdfExportDialog({
    super.key,
    required this.patientName,
    required this.patientId,
  });

  @override
  State<PdfExportDialog> createState() => _PdfExportDialogState();
}

class _PdfExportDialogState extends State<PdfExportDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _includeSleepData = true;
  bool _includeActivityData = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportar Informe PDF'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rango de fechas
            const Text('Período del informe', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _startDate = date);
                    },
                    child: Text(
                      _startDate != null
                          ? 'Desde: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'Seleccionar fecha inicio',
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _endDate = date);
                    },
                    child: Text(
                      _endDate != null
                          ? 'Hasta: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'Seleccionar fecha fin',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Opciones de datos
            const Text('Incluir en el informe', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Datos de sueño'),
              value: _includeSleepData,
              onChanged: (value) => setState(() => _includeSleepData = value ?? true),
            ),
            CheckboxListTile(
              title: const Text('Datos de actividad'),
              value: _includeActivityData,
              onChanged: (value) => setState(() => _includeActivityData = value ?? true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_startDate == null || _endDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Por favor selecciona ambas fechas')),
              );
              return;
            }
            Navigator.pop(context, {
              'startDate': _startDate,
              'endDate': _endDate,
              'includeSleepData': _includeSleepData,
              'includeActivityData': _includeActivityData,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF004B49),
            foregroundColor: Colors.white,
          ),
          child: const Text('Generar PDF'),
        ),
      ],
    );
  }
}
