import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';
import '../models/parcela.dart';
import '../models/individuo.dart';
import '../models/fuste.dart';

class IndividuoFormScreen extends StatefulWidget {
  final Parcela parcela;
  final String estrato;
  final Individuo? individuo;
  final int subParcela;

  const IndividuoFormScreen({
    super.key,
    required this.parcela,
    required this.estrato,
    this.individuo,
    this.subParcela = 1,
  });

  @override
  State<IndividuoFormScreen> createState() => _IndividuoFormScreenState();
}

class _IndividuoFormScreenState extends State<IndividuoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _nomeComumController = TextEditingController();
  final _nomeCientificoController = TextEditingController();
  final _familiaController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _numeroIndividuosController = TextEditingController();
  final _diametroCopa1Controller = TextEditingController();
  final _diametroCopa2Controller = TextEditingController();
  final _numeroGpsController = TextEditingController();
  final _numeroIndividuosEspecieController = TextEditingController();

  List<_FusteEntry> _fustes = [];
  List<String> _nomesComuns = [];
  List<String> _nomesCientificos = [];
  List<String> _familias = [];
  List<String> _fotosBase64 = [];

  DateTime _dataColeta = DateTime.now();
  bool _isEditing = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isHerbaceo => widget.estrato == 'Herbáceo';
  bool get _isFloristica => widget.estrato == 'Florística';
  bool get _requiresDiametroCopa =>
      (widget.parcela.fisionomia == 'Cerrado' && widget.estrato == 'Arbóreo') ||
      (widget.parcela.fisionomia == 'Campo Rupestre' &&
          (widget.estrato == 'Arbóreo' || widget.estrato == 'Arbustivo')) ||
      (widget.parcela.metodo == 'Censo' && (widget.estrato == 'Arbóreo' || widget.estrato == 'Censo') &&
          (widget.parcela.fisionomia == 'Cerrado' || widget.parcela.fisionomia == 'Campo Rupestre' || widget.parcela.fisionomia == 'Árvores isoladas'));

  bool get _capObrigatorio =>
      !(widget.estrato == 'Arbustivo' && widget.parcela.fisionomia == 'Campo Rupestre');

  @override
  void initState() {
    super.initState();
    _nomesComuns = DatabaseHelper.instance.getNomesComuns();
    _nomesCientificos = DatabaseHelper.instance.getNomesCientificos();
    _familias = DatabaseHelper.instance.getFamilias();

    if (widget.individuo != null) {
      _isEditing = true;
      _numeroController.text = widget.individuo!.numero.toString();
      _nomeComumController.text = widget.individuo!.nomeComum;
      _nomeCientificoController.text = widget.individuo!.nomeCientifico;
      _familiaController.text = widget.individuo!.familia;
      _dataColeta = widget.individuo!.dataColeta;
      _observacoesController.text = widget.individuo!.observacoes ?? '';
      _fotosBase64 = List<String>.from(widget.individuo!.fotos);
      _numeroIndividuosController.text =
          widget.individuo!.numeroIndividuos?.toString() ?? '';
      _diametroCopa1Controller.text =
          widget.individuo!.diametroCopa1?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
      _diametroCopa2Controller.text =
          widget.individuo!.diametroCopa2?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
      _numeroGpsController.text = widget.individuo!.numeroGps?.toString() ?? '';
      _numeroIndividuosEspecieController.text = widget.individuo!.numeroIndividuosEspecie?.toString() ?? '';
    if (!_isHerbaceo && !_isFloristica) {
        _loadFustes();
      }
    } else {
      _numeroController.text =
          DatabaseHelper.instance.getNextIndividuoNumero(widget.parcela.id, widget.estrato)
              .toString();
      if (widget.parcela.metodo == 'Censo') {
        _numeroGpsController.text =
            DatabaseHelper.instance.getNextNumeroGps(widget.parcela.id, widget.estrato)
                .toString();
      }
      if (!_isHerbaceo && !_isFloristica) {
        _fustes = [_FusteEntry(altura: 0, cap: 0)];
      }
    }
  }

  void _loadFustes() {
    if (widget.individuo != null) {
      final fustes =
          DatabaseHelper.instance.getFustesByIndividuo(widget.individuo!.id);
      setState(() {
        _fustes = fustes.isEmpty
            ? [_FusteEntry(altura: 0, cap: 0)]
            : fustes
                .map((f) => _FusteEntry(altura: f.altura, cap: f.cap))
                .toList();
      });
    }
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _nomeComumController.dispose();
    _nomeCientificoController.dispose();
    _familiaController.dispose();
    _observacoesController.dispose();
    _numeroIndividuosController.dispose();
    _diametroCopa1Controller.dispose();
    _diametroCopa2Controller.dispose();
    _numeroGpsController.dispose();
    _numeroIndividuosEspecieController.dispose();
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

  void _addFuste() {
    setState(() => _fustes.add(_FusteEntry(altura: 0, cap: 0)));
  }

  void _removeFuste(int index) {
    if (_fustes.length > 1) {
      setState(() => _fustes.removeAt(index));
    }
  }

  Future<void> _tirarFoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() => _fotosBase64.add(base64Str));
    }
  }

  Future<void> _selecionarFoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() => _fotosBase64.add(base64Str));
    }
  }

  void _removerFoto(int index) {
    setState(() => _fotosBase64.removeAt(index));
  }

  Future<void> _saveIndividuo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nomeComumController.text.trim().isEmpty &&
        _nomeCientificoController.text.trim().isEmpty &&
        _familiaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Preencha pelo menos 1 campo: Nome Comum, Nome Científico ou Família'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isHerbaceo) {
      final capObrigatorio = !(widget.estrato == 'Arbustivo' && widget.parcela.fisionomia == 'Campo Rupestre');

      for (var i = 0; i < _fustes.length; i++) {
        if (_fustes[i].altura <= 0 || (capObrigatorio && _fustes[i].cap <= 0)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                capObrigatorio
                    ? 'Fuste ${i + 1}: altura e CAP devem ser maiores que 0'
                    : 'Fuste ${i + 1}: altura deve ser maior que 0',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      for (var i = 0; i < _fustes.length; i++) {
        if (widget.estrato == 'Arbóreo' || (widget.parcela.metodo == 'Censo' && widget.estrato != 'Arbustivo')) {
          if (_fustes[i].cap < 15 || _fustes[i].altura < 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Fuste ${i + 1}: o CAP deve ser ≥ 15 cm e a altura ≥ 2 m',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            return;
          }
        } else if (widget.estrato == 'Arbustivo') {
          if (widget.parcela.fisionomia != 'Campo Rupestre') {
            if (_fustes[i].cap >= 15 || _fustes[i].altura < 1.5) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Fuste ${i + 1}: no estrato Arbustivo o CAP deve ser < 15 cm e a altura ≥ 1,5 m',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
              return;
            }
          }
        }
      }
    }

    if (_requiresDiametroCopa) {
      if (_diametroCopa1Controller.text.trim().isEmpty ||
          _diametroCopa2Controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preencha os campos Diâmetro de Copa 1 e Diâmetro de Copa 2'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final individuo = Individuo(
      id: widget.individuo?.id ?? const Uuid().v4(),
      parcelaId: widget.parcela.id,
      numero: int.parse(_numeroController.text.trim()),
      nomeComum: _nomeComumController.text.trim(),
      nomeCientifico: _nomeCientificoController.text.trim(),
      familia: _familiaController.text.trim(),
      dataColeta: _dataColeta,
      observacoes: _observacoesController.text.trim().isEmpty
          ? null
          : _observacoesController.text.trim(),
      fotos: _fotosBase64,
      estrato: widget.estrato,
      numeroIndividuos:
          _isHerbaceo && _numeroIndividuosController.text.trim().isNotEmpty
              ? int.tryParse(_numeroIndividuosController.text.trim())
              : null,
      diametroCopa1: _requiresDiametroCopa && _diametroCopa1Controller.text.trim().isNotEmpty
          ? double.tryParse(_diametroCopa1Controller.text.trim().replaceAll(',', '.'))
          : null,
      diametroCopa2: _requiresDiametroCopa && _diametroCopa2Controller.text.trim().isNotEmpty
          ? double.tryParse(_diametroCopa2Controller.text.trim().replaceAll(',', '.'))
          : null,
      subParcela: widget.subParcela,
      numeroGps: widget.parcela.metodo == 'Censo' && _numeroGpsController.text.trim().isNotEmpty
          ? int.tryParse(_numeroGpsController.text.trim())
          : null,
      numeroIndividuosEspecie: _isHerbaceo && widget.parcela.fisionomia == 'Campo Rupestre' && _numeroIndividuosEspecieController.text.trim().isNotEmpty
          ? int.tryParse(_numeroIndividuosEspecieController.text.trim())
          : null,
    );

    await DatabaseHelper.instance.insertIndividuo(individuo);

    if (_isEditing && !_isHerbaceo && !_isFloristica) {
      await DatabaseHelper.instance
          .deleteFustesByIndividuo(widget.individuo!.id);
    }

    if (!_isHerbaceo && !_isFloristica) {
      for (var i = 0; i < _fustes.length; i++) {
        await DatabaseHelper.instance.insertFuste(
          Fuste(
            id: const Uuid().v4(),
            individuoId: individuo.id,
            numeroFuste: i + 1,
            altura: _fustes[i].altura,
            cap: _fustes[i].cap,
          ),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Indivíduo atualizado com sucesso!'
                : 'Indivíduo cadastrado com sucesso!',
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
          _isEditing
              ? 'Editar ${_isFloristica ? "Espécie" : "Indivíduo"} Nº ${widget.individuo!.numero}'
              : '${_isFloristica ? "Nova Espécie" : "Novo Indivíduo"} - ${widget.estrato}',
        ),
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
                controller: _numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número do Indivíduo *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Insira o número';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Insira um número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (widget.parcela.metodo == 'Censo') ...[
                TextFormField(
                  controller: _numeroGpsController,
                  decoration: const InputDecoration(
                    labelText: 'Número do GPS *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.gps_fixed),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (widget.parcela.metodo == 'Censo') {
                      if (value == null || value.trim().isEmpty) {
                        return 'Insira o número do GPS';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'Insira um número válido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (_isHerbaceo && widget.parcela.fisionomia == 'Campo Rupestre') ...[
                TextFormField(
                  controller: _numeroIndividuosEspecieController,
                  decoration: const InputDecoration(
                    labelText: 'Número de indivíduos da espécie *',
                    hintText: 'Quantidade total desta espécie',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Insira o número de indivíduos';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Insira um número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (_isHerbaceo) ...[
                TextFormField(
                  controller: _numeroIndividuosController,
                  decoration: InputDecoration(
                    labelText: widget.parcela.fisionomia == 'Campo Rupestre'
                        ? '% Cobertura da espécie *'
                        : 'Nº de Indivíduos *',
                    hintText: widget.parcela.fisionomia == 'Campo Rupestre'
                        ? 'Ex: 25'
                        : 'Quantidade desta espécie',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      widget.parcela.fisionomia == 'Campo Rupestre'
                          ? Icons.pie_chart
                          : Icons.group,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+([,]\d{0,2})?$')),
                  ],
                  validator: (value) {
                    if (_isHerbaceo && (value == null || value.trim().isEmpty)) {
                      return widget.parcela.fisionomia == 'Campo Rupestre'
                          ? 'Insira a porcentagem de cobertura'
                          : 'Insira o número de indivíduos';
                    }
                    if (_isHerbaceo && double.tryParse(value!.trim().replaceAll(',', '.')) == null) {
                      return 'Insira um número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              Autocomplete<String>(
                initialValue: TextEditingValue(text: _nomeComumController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return _nomesComuns;
                  return _nomesComuns.where((nome) => nome
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _nomeComumController.text = selection;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextFormField(
                    controller: controller..text = _nomeComumController.text,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Nome Comum',
                      hintText: 'Ex: Ipê Amarelo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.eco),
                    ),
                    onChanged: (value) {
                      _nomeComumController.text = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              Autocomplete<String>(
                initialValue:
                    TextEditingValue(text: _nomeCientificoController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return _nomesCientificos;
                  return _nomesCientificos.where((nome) => nome
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _nomeCientificoController.text = selection;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextFormField(
                    controller: controller
                      ..text = _nomeCientificoController.text,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Nome Científico',
                      hintText: 'Ex: Handroanthus albus',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.science),
                    ),
                    onChanged: (value) {
                      _nomeCientificoController.text = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              Autocomplete<String>(
                initialValue: TextEditingValue(text: _familiaController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return _familias;
                  return _familias.where((nome) => nome
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _familiaController.text = selection;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextFormField(
                    controller: controller..text = _familiaController.text,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Família',
                      hintText: 'Ex: Bignoniaceae',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    onChanged: (value) {
                      _familiaController.text = value;
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
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!_isHerbaceo && !_isFloristica) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.content_copy,
                                color: Colors.green[800]),
                            const SizedBox(width: 8),
                            Text(
                              'FUSTES (${_fustes.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(_fustes.length, (index) {
                          return _buildFusteCard(index);
                        }),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _addFuste,
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar Fuste'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green[800],
                              side: BorderSide(color: Colors.green[800]!),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_requiresDiametroCopa) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.scatter_plot,
                                color: Colors.green[800]),
                            const SizedBox(width: 8),
                            Text(
                              'DIÂMETRO DE COPA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _diametroCopa1Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Diâmetro de Copa 1 (m)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+([,]\d{0,2})?$')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _diametroCopa2Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Diâmetro de Copa 2 (m)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+([,]\d{0,2})?$')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.camera_alt,
                              color: Colors.green[800]),
                          const SizedBox(width: 8),
                          Text(
                            'FOTOS ${_fotosBase64.isNotEmpty ? "(${_fotosBase64.length})" : ""}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Opcional - fotos para identificação do indivíduo',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      if (_fotosBase64.isNotEmpty) ...[
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _fotosBase64.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(_fotosBase64[index]),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removerFoto(index),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _tirarFoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Tirar Foto'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green[800],
                                side: BorderSide(color: Colors.green[800]!),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selecionarFoto,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galeria'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green[800],
                                side: BorderSide(color: Colors.green[800]!),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _observacoesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _saveIndividuo,
                icon: const Icon(Icons.save),
                label: Text(_isFloristica ? 'Salvar Espécie' : 'Salvar Indivíduo'),
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

  Widget _buildFusteCard(int index) {
    return Card(
      color: Colors.green[50],
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Fuste ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (_fustes.length > 1)
                  IconButton(
                    onPressed: () => _removeFuste(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _fustes[index].altura > 0
                        ? _fustes[index].altura.toStringAsFixed(2).replaceAll('.', ',')
                        : '',
                    decoration: const InputDecoration(
                      labelText: 'Altura (m) *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+([,]\d{0,2})?$')),
                    ],
                    onChanged: (value) {
                      final parsed = double.tryParse(value.replaceAll(',', '.'));
                      if (parsed != null) {
                        _fustes[index].altura = parsed;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _fustes[index].cap > 0
                        ? _fustes[index].cap.toStringAsFixed(2).replaceAll('.', ',')
                        : '',
                    decoration: InputDecoration(
                      labelText: _capObrigatorio ? 'CAP (cm) *' : 'CAP (cm)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+([,]\d{0,2})?$')),
                    ],
                    onChanged: (value) {
                      final parsed = double.tryParse(value.replaceAll(',', '.'));
                      if (parsed != null) {
                        _fustes[index].cap = parsed;
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FusteEntry {
  double altura;
  double cap;

  _FusteEntry({required this.altura, required this.cap});
}
