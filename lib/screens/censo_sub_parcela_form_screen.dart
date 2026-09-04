import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/censo_sub_parcela.dart';
import '../models/parcela.dart';

class CensoSubParcelaFormScreen extends StatefulWidget {
  final Parcela parcela;
  final String estrato;
  final CensoSubParcela? subParcela;

  const CensoSubParcelaFormScreen({
    super.key,
    required this.parcela,
    required this.estrato,
    this.subParcela,
  });

  @override
  State<CensoSubParcelaFormScreen> createState() =>
      _CensoSubParcelaFormScreenState();
}

class _CensoSubParcelaFormScreenState extends State<CensoSubParcelaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _tamanhoParcelaController = TextEditingController();
  final _observacoesController = TextEditingController();
  DateTime _data = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.subParcela != null) {
      _codigoController.text = widget.subParcela!.codigo;
      _tamanhoParcelaController.text = widget.subParcela!.tamanhoParcela ?? '';
      _data = widget.subParcela!.data;
      _observacoesController.text = widget.subParcela!.observacoes ?? '';
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _tamanhoParcelaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _data = picked);
    }
  }

  void _setToday() {
    setState(() => _data = DateTime.now());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final subParcela = CensoSubParcela(
      id: widget.subParcela?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      parcelaId: widget.parcela.id,
      estrato: widget.estrato,
      codigo: _codigoController.text.trim(),
      data: _data,
      observacoes: _observacoesController.text.trim().isEmpty
          ? null
          : _observacoesController.text.trim(),
      tamanhoParcela: _tamanhoParcelaController.text.trim().isEmpty
          ? null
          : _tamanhoParcelaController.text.trim(),
    );

    await DatabaseHelper.instance.insertCensoSubParcela(subParcela);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.subParcela == null
                ? 'Sub-parcela criada com sucesso!'
                : 'Sub-parcela atualizada com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArbustivo = widget.estrato == 'Arbustivo';
    final isHerbaceo = widget.estrato == 'Herbáceo';
    final showTamanhoParcela = isArbustivo || isHerbaceo;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.subParcela == null ? 'Nova Sub-parcela' : 'Editar Sub-parcela'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código da Parcela *',
                  hintText: 'Ex: SUB-01',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira o código da sub-parcela';
                  }
                  return null;
                },
              ),
              if (showTamanhoParcela) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tamanhoParcelaController,
                  decoration: const InputDecoration(
                    labelText: 'Tamanho da parcela',
                    hintText: 'Ex: 1x1m, 2x2m',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.square_foot),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_data),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _setToday,
                    icon: const Icon(Icons.today),
                    label: const Text('Hoje'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.edit_calendar),
                    tooltip: 'Selecionar data',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacoesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Notas adicionais',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Sub-parcela'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
