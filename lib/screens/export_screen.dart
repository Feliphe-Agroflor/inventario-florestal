import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/parcela.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  List<Parcela> _parcelas = [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _parcelas = DatabaseHelper.instance.getParcelas();
  }

  String _escapeCsv(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _formatDecimal(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  Future<void> _exportToCsv() async {
    setState(() => _isExporting = true);

    try {
      final List<String> rows = [];

      rows.add(
        'Registro;Método;Identificador Campo;Estrato;Fisionomia;Data Coleta;Responsável;'
        'Nº Indivíduo;Nome Comum;Nome Científico;Família;'
        'Nº Fuste;Altura (m);CAP (cm);DAP (cm);Nº Indivíduos / % Cobertura;'
        'Diâm. Copa 1 (m);Diâm. Copa 2 (m);Observações',
      );

      for (var parcela in _parcelas) {
        final individuos =
            DatabaseHelper.instance.getIndividuosByParcela(parcela.id);

        for (var individuo in individuos) {
          if (individuo.estrato == 'Herbáceo') {
            rows.add([
              _escapeCsv(parcela.nomeParcela),
              _escapeCsv(parcela.metodo),
              _escapeCsv(parcela.identificadorCampo ?? ''),
              _escapeCsv(individuo.estrato),
              _escapeCsv(parcela.fisionomia),
              DateFormat('dd/MM/yyyy').format(parcela.dataColeta),
              _escapeCsv(parcela.responsavel ?? ''),
              '${individuo.numero}',
              _escapeCsv(individuo.nomeComum),
              _escapeCsv(individuo.nomeCientifico),
              _escapeCsv(individuo.familia),
              '',
              '',
              '',
              '',
              '${individuo.numeroIndividuos ?? ''}',
              '',
              '',
              _escapeCsv(individuo.observacoes ?? ''),
            ].join(';'));
          } else {
            final fustes =
                DatabaseHelper.instance.getFustesByIndividuo(individuo.id);

            if (fustes.isEmpty) {
              rows.add([
                _escapeCsv(parcela.nomeParcela),
                _escapeCsv(parcela.metodo),
                _escapeCsv(parcela.identificadorCampo ?? ''),
                _escapeCsv(individuo.estrato),
                _escapeCsv(parcela.fisionomia),
                DateFormat('dd/MM/yyyy').format(parcela.dataColeta),
                _escapeCsv(parcela.responsavel ?? ''),
                '${individuo.numero}',
                _escapeCsv(individuo.nomeComum),
                _escapeCsv(individuo.nomeCientifico),
                _escapeCsv(individuo.familia),
                '',
                '',
                '',
                '',
                '',
                individuo.diametroCopa1 != null ? _formatDecimal(individuo.diametroCopa1!) : '',
                individuo.diametroCopa2 != null ? _formatDecimal(individuo.diametroCopa2!) : '',
                _escapeCsv(individuo.observacoes ?? ''),
              ].join(';'));
            } else {
              for (var fuste in fustes) {
                rows.add([
                  _escapeCsv(parcela.nomeParcela),
                  _escapeCsv(parcela.metodo),
                  _escapeCsv(parcela.identificadorCampo ?? ''),
                  _escapeCsv(individuo.estrato),
                  _escapeCsv(parcela.fisionomia),
                  DateFormat('dd/MM/yyyy').format(parcela.dataColeta),
                  _escapeCsv(parcela.responsavel ?? ''),
                  '${individuo.numero}',
                  _escapeCsv(individuo.nomeComum),
                  _escapeCsv(individuo.nomeCientifico),
                  _escapeCsv(individuo.familia),
                  '${fuste.numeroFuste}',
                  _formatDecimal(fuste.altura),
                  _formatDecimal(fuste.cap),
                  _formatDecimal(fuste.dap),
                  '',
                  individuo.diametroCopa1 != null ? _formatDecimal(individuo.diametroCopa1!) : '',
                  individuo.diametroCopa2 != null ? _formatDecimal(individuo.diametroCopa2!) : '',
                  _escapeCsv(individuo.observacoes ?? ''),
                ].join(';'));
              }
            }
          }
        }
      }

      final csvContent = rows.join('\n');
      final bytes = utf8.encode('\uFEFF$csvContent');
      final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'text/csv'));
      final url = web.URL.createObjectURL(blob);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      web.HTMLAnchorElement()
        ..href = url
        ..setAttribute('download', 'inventario_florestal_$timestamp.csv')
        ..click();

      web.URL.revokeObjectURL(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exportado! ${rows.length - 1} registros'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isExporting = false);
  }

  int get _totalIndividuos {
    int total = 0;
    for (var p in _parcelas) {
      total += DatabaseHelper.instance.getIndividuosByParcela(p.id).length;
    }
    return total;
  }

  int get _totalFustes {
    int total = 0;
    for (var p in _parcelas) {
      final individuos =
          DatabaseHelper.instance.getIndividuosByParcela(p.id);
      for (var ind in individuos) {
        if (ind.estrato != 'Herbáceo') {
          total +=
              DatabaseHelper.instance.getFustesByIndividuo(ind.id).length;
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Dados'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESUMO DOS DADOS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                        Icons.forest, 'Registros', '${_parcelas.length}'),
                    const Divider(),
                    _buildSummaryRow(
                        Icons.eco, 'Indivíduos', '$_totalIndividuos'),
                    const Divider(),
                    _buildSummaryRow(
                        Icons.content_copy, 'Fustes', '$_totalFustes'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportToCsv,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.file_download),
              label: Text(_isExporting ? 'Exportando...' : 'Exportar CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.green[800], size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
