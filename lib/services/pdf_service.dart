import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../models/daily_metrics.dart';

/// Servicio para generar informes PDF para profesionales de salud
class PdfService {
  /// Genera un PDF con el historial de entradas de humor
  static Future<Uint8List> generateMoodReport({
    required String patientName,
    required String patientId,
    required List<MoodEntry> entries,
    required DailyMetrics metrics,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    // Filtrar por rango de fechas si se especifica
    final filteredEntries = _filterEntriesByDate(entries, startDate, endDate);

    // Definir estilos
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#004B49'),
    );
    final headerStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#004B49'),
    );
    final normalStyle = pw.TextStyle(fontSize: 10);

    // Construir el PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Encabezado
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Informe de Seguimiento de Humor', style: titleStyle),
              pw.SizedBox(height: 20),
              pw.Divider(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 20),
            ],
          ),

          // Información del paciente
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Información del Paciente', style: headerStyle),
              pw.SizedBox(height: 10),
              pw.Text('Nombre: $patientName', style: normalStyle),
              pw.Text('ID del Paciente: $patientId', style: normalStyle),
              pw.Text('Fecha del Informe: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: normalStyle),
              if (startDate != null && endDate != null)
                pw.Text(
                    'Período: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                    style: normalStyle),
              pw.SizedBox(height: 20),
            ],
          ),

          // Resumen de métricas
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Resumen de Métricas', style: headerStyle),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricBox('Días Registrados', '${metrics.totalDaysTracked}'),
                  _buildMetricBox('Promedio de Humor', '${metrics.averageMood.toStringAsFixed(1)}/10'),
                  _buildMetricBox('Días Estables', '${metrics.stableDays}', color: PdfColors.green),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricBox('Episodios Elevados', '${metrics.elevatedEpisodes}', color: PdfColors.orange),
                  _buildMetricBox('Episodios Depresivos', '${metrics.depressiveEpisodes}', color: PdfColors.redAccent),
                  _buildMetricBox('Horas de Sueño Promedio', '${metrics.averageSleepHours.toStringAsFixed(1)}h'),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          ),

          // Patrones de sueño
          if (metrics.sleepData.isNotEmpty) ...[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Patrones de Sueño', style: headerStyle),
                pw.SizedBox(height: 10),
                pw.Text('Horas de sueño promedio: ${metrics.averageSleepHours.toStringAsFixed(1)} horas',
                    style: normalStyle),
                pw.Text('Días con sueño adecuado (7-9h): ${metrics.adequateSleepDays}',
                    style: normalStyle),
                pw.Text('Días con insomnio (<5h): ${metrics.insomniaDays}',
                    style: normalStyle),
                pw.Text('Días con hipersomnia (>10h): ${metrics.hypersomniaDays}',
                    style: normalStyle),
                pw.SizedBox(height: 20),
              ],
            ),
          ],

          // Nivel de actividad
          if (metrics.activityLevel.isNotEmpty) ...[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Nivel de Actividad', style: headerStyle),
                pw.SizedBox(height: 10),
                pw.Text('Nivel de actividad promedio: ${metrics.averageActivityLevel.toStringAsFixed(1)}/10',
                    style: normalStyle),
                pw.SizedBox(height: 20),
              ],
            ),
          ],

          // Historial de entradas
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Historial de Registros', style: headerStyle),
              pw.SizedBox(height: 10),
              ...filteredEntries.map((entry) => _buildEntryCard(entry, normalStyle)),
            ],
          ),

          // Notas clínicas
          pw.SizedBox(height: 30),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Notas Clínicas', style: headerStyle),
              pw.SizedBox(height: 10),
              pw.Container(
                height: 100,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
            ],
          ),

          // Footer
          pw.SizedBox(height: 30),
          pw.Divider(height: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          pw.Text(
            'Informe generado por Bipolar Clarity App - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
          pw.Text(
            'Este informe es un complemento y no sustituye la evaluación clínica profesional.',
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Filtra las entradas por rango de fechas
  static List<MoodEntry> _filterEntriesByDate(
    List<MoodEntry> entries,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return entries;
    return entries.where((entry) {
      final entryDate = entry.date;
      if (startDate != null && entryDate.isBefore(startDate)) return false;
      if (endDate != null && entryDate.isAfter(endDate)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Construye una tarjeta de métrica
  static pw.Widget _buildMetricBox(
    String label,
    String value, {
    PdfColor? color,
  }) {
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: (color ?? PdfColors.teal).withOpacity(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: (color ?? PdfColors.teal).withOpacity(0.3)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color ?? PdfColors.teal,
              )),
          pw.SizedBox(height: 4),
          pw.Text(label,
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  /// Construye una tarjeta de entrada
  static pw.Widget _buildEntryCard(MoodEntry entry, pw.TextStyle normalStyle) {
    final moodColor = _getMoodColor(entry.moodScore);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Indicador de humor
          pw.Container(
            width: 50,
            height: 50,
            decoration: pw.BoxDecoration(
              color: moodColor.withOpacity(0.2),
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: moodColor, width: 2),
            ),
            child: pw.Center(
              child: pw.Text(
                entry.moodScore.toString(),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: moodColor,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          // Detalles de la entrada
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${dateFormat.format(entry.date)} - ${timeFormat.format(entry.date)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: moodColor.withOpacity(0.1),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        _getMoodLabel(entry.moodScore),
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: moodColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                if (entry.notes.isNotEmpty)
                  pw.Text(entry.notes, style: normalStyle),
                pw.SizedBox(height: 4),
                pw.Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (entry.sleepHours != null)
                      _buildTag('💤 ${entry.sleepHours}h', normalStyle),
                    if (entry.activityLevel != null)
                      _buildTag('🏃 ${entry.activityLevel}/10', normalStyle),
                    if (entry.medicationTaken)
                      _buildTag('💊 Medicación', normalStyle),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una etiqueta
  static pw.Widget _buildTag(String text, pw.TextStyle style) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8)),
    );
  }

  /// Obtiene el color según la puntuación de humor
  static PdfColor _getMoodColor(double score) {
    if (score >= 8) return PdfColors.orange; // Manía/Elevado
    if (score >= 6) return PdfColors.green; // Estable/Bueno
    if (score >= 4) return PdfColors.yellow; // Levemente bajo
    return PdfColors.redAccent; // Depresivo
  }

  /// Obtiene la etiqueta según la puntuación de humor
  static String _getMoodLabel(double score) {
    if (score >= 8) return 'Elevado';
    if (score >= 6) return 'Estable';
    if (score >= 4) return 'Levemente bajo';
    return 'Depresivo';
  }

  /// Imprime el PDF directamente
  static Future<void> printPdf(Uint8List pdfData) async {
    await Printing.layoutPdf(onLayout: (_) => pdfData);
  }

  /// Comparte el PDF
  static Future<void> sharePdf(Uint8List pdfData, String filename) async {
    await Printing.sharePdf(bytes: pdfData, filename: filename);
  }
}
