import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/parcela.dart';

class ParcelaFormScreen extends StatefulWidget {
  final Parcela? parcela;

  const ParcelaFormScreen({super.key, this.parcela});

  @override
  State<ParcelaFormScreen> createState() => _ParcelaFormScreenState();
}

class _ParcelaFormScreenState extends State<ParcelaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _identificadorController = TextEditingController();
  final _responsavelController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _tamanhoArboreoController = TextEditingController();
  final _tamanhoArbustivoController = TextEditingController();
  final _tamanhoHerbaceoController = TextEditingController();
  final _localidadeController = TextEditingController();

  String? _fisionomia;
  String _metodo = 'Parcela';
  String? _estagioSucessional;
  DateTime _dataColeta = DateTime.now();
  List<String> _responsaveisSugestoes = [];
  List<String> _identificadoresSugestoes = [];

  final List<String> _metodos = ['Parcela', 'Censo', 'Florística caminhamento'];
  final List<String> _fisionomias = [
    'Floresta Estacional Semidecidual',
    'Cerrado',
    'Campo Rupestre',
    'Árvores isoladas',
  ];

  final List<String> _estagiosSucessionais = [
    'Inicial',
    'Médio',
    'Avançado',
  ];

  @override
  void initState() {
    super.initState();
    _responsaveisSugestoes = DatabaseHelper.instance.getResponsaveis();
    _identificadoresSugestoes = DatabaseHelper.instance.getIdentificadores();
    if (widget.parcela != null) {
      _nomeController.text = widget.parcela!.nomeParcela;
      _fisionomia = widget.parcela!.fisionomia;
      _metodo = widget.parcela!.metodo;
      _estagioSucessional = widget.parcela!.estagioSucessional;
      _dataColeta = widget.parcela!.dataColeta;
      _responsavelController.text = widget.parcela!.responsavel ?? '';
      _observacoesController.text = widget.parcela!.observacoes ?? '';
      _identificadorController.text = widget.parcela!.identificadorCampo ?? '';
      _tamanhoArboreoController.text = widget.parcela!.tamanhoParcelaArboreo?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
      _tamanhoArbustivoController.text = widget.parcela!.tamanhoParcelaArbustivo?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
      _tamanhoHerbaceoController.text = widget.parcela!.tamanhoParcelaHerbaceo?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
      _localidadeController.text = widget.parcela!.localidade ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _identificadorController.dispose();
    _responsavelController.dispose();
    _observacoesController.dispose();
    _tamanhoArboreoController.dispose();
    _tamanhoArbustivoController.dispose();
    _tamanhoHerbaceoController.dispose();
    _localidadeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataColeta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _dataColeta = picked);
    }
  }

  void _setToday() {
    setState(() => _dataColeta = DateTime.now());
  }

  Future<void> _saveParcela() async {
    if (!_formKey.currentState!.validate()) return;

    final parcela = Parcela(
      id: widget.parcela?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nomeParcela: _nomeController.text.trim(),
      fisionomia: _fisionomia!,
      dataColeta: _dataColeta,
      responsavel: _responsavelController.text.trim().isEmpty
          ? null
          : _responsavelController.text.trim(),
      observacoes: _observacoesController.text.trim().isEmpty
          ? null
          : _observacoesController.text.trim(),
      identificadorCampo: _identificadorController.text.trim().isEmpty
          ? null
          : _identificadorController.text.trim(),
      metodo: _metodo,
      tamanhoParcelaArboreo: _metodo == 'Parcela' && _tamanhoArboreoController.text.trim().isNotEmpty
          ? double.tryParse(_tamanhoArboreoController.text.trim().replaceAll(',', '.'))
          : null,
      tamanhoParcelaArbustivo: _metodo == 'Parcela' && _tamanhoArbustivoController.text.trim().isNotEmpty
          ? double.tryParse(_tamanhoArbustivoController.text.trim().replaceAll(',', '.'))
          : null,
      tamanhoParcelaHerbaceo: _metodo == 'Parcela' && _tamanhoHerbaceoController.text.trim().isNotEmpty
          ? double.tryParse(_tamanhoHerbaceoController.text.trim().replaceAll(',', '.'))
          : null,
      localidade: _localidadeController.text.trim().isEmpty
          ? null
          : _localidadeController.text.trim(),
      estagioSucessional: _fisionomia == 'Floresta Estacional Semidecidual' ? _estagioSucessional : null,
    );

    await DatabaseHelper.instance.insertParcela(parcela);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.parcela == null
                ? 'Registro criado com sucesso!'
                : 'Registro atualizado com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.parcela == null ? 'Novo registro' : 'Editar registro'),
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
              DropdownButtonFormField<String>(
                initialValue: _metodo,
                decoration: const InputDecoration(
                  labelText: 'Método *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assignment),
                ),
                items: _metodos.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _metodo = value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione o método';
                  }
                  return null;
                },
              ),
              if (_metodo == 'Parcela') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Código da Parcela *',
                    hintText: 'Ex: PC-01',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira o código da parcela';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tamanhoArboreoController,
                  decoration: const InputDecoration(
                    labelText: 'Tamanho da Parcela - Arbóreo (m²)',
                    hintText: 'Ex: 400',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.forest),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tamanhoArbustivoController,
                  decoration: const InputDecoration(
                    labelText: 'Tamanho da Parcela - Arbustivo (m²)',
                    hintText: 'Ex: 100',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.grass),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tamanhoHerbaceoController,
                  decoration: const InputDecoration(
                    labelText: 'Tamanho da Parcela - Herbáceo (m²)',
                    hintText: 'Ex: 25',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.eco),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _fisionomia,
                decoration: const InputDecoration(
                  labelText: 'Fisionomia *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.landscape),
                ),
                items: _fisionomias.map((f) {
                  return DropdownMenuItem(value: f, child: Text(f));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _fisionomia = value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione a fisionomia';
                  }
                  return null;
                },
              ),
              if (_fisionomia == 'Floresta Estacional Semidecidual') ...[
                const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _estagioSucessional,
                decoration: const InputDecoration(
                  labelText: 'Estágio Sucessional',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.eco),
                ),
                items: _estagiosSucessionais.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (value) {
                  setState(() => _estagioSucessional = value);
                },
              ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _localidadeController,
                decoration: const InputDecoration(
                  labelText: 'Localidade',
                  hintText: 'Ex: Cachoeira, Trilha, etc.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _identificadorController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return _identificadoresSugestoes;
                  return _identificadoresSugestoes.where((nome) => nome
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _identificadorController.text = selection;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextFormField(
                    controller: controller..text = _identificadorController.text,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Identificador de Campo',
                      hintText: 'Ex: Márcio Edinei, Josimar, Maria, etc.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    onChanged: (value) {
                      _identificadorController.text = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _responsavelController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return _responsaveisSugestoes;
                  return _responsaveisSugestoes.where((nome) => nome
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _responsavelController.text = selection;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextFormField(
                    controller: controller..text = _responsavelController.text,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Responsável',
                      hintText: 'Nome de quem coletou',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (value) {
                      _responsavelController.text = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data da Coleta *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_dataColeta),
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
                onPressed: _saveParcela,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Registro'),
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
