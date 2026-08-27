import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/caracterizacao.dart';
import '../models/parcela.dart';

class CaracterizacaoScreen extends StatefulWidget {
  final String parcelaId;
  final String fisionomia;

  const CaracterizacaoScreen({
    super.key,
    required this.parcelaId,
    required this.fisionomia,
  });

  @override
  State<CaracterizacaoScreen> createState() => _CaracterizacaoScreenState();
}

class _CaracterizacaoScreenState extends State<CaracterizacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacoesController = TextEditingController();

  bool get _isCampoRupestre => widget.fisionomia == 'Campo Rupestre';
  bool get _isCerrado => widget.fisionomia == 'Cerrado';

  // Campos gerais
  int _historicoUso = 0;
  int _coberturaVegetal = 0;
  String _tipoSubstrato = '';
  String _geoambiente = '';
  String _especiesLenhosas = '';

  // Campos其他fisionomias
  final _usoPrevioController = TextEditingController();
  final _relevoController = TextEditingController();
  final _antropizacaoController = TextEditingController();
  int _numeroEstratos = 0;
  int _epifitas = 0;
  int _orquideas = 0;
  int _bromelias = 0;
  int _musgosLiquens = 0;
  int _serapilheira = 0;
  int _trepadeirasLenhosas = 0;
  int _trepadeirasHerbaceas = 0;
  int _densidadeArbustos = 0;

  // Campos Cerrado
  int _pressaoExterna = 0;
  int _coberturaHerbaceoArbustiva = 0;
  int _soloExposto = 0;
  int _coberturaSerapilheira = 0;
  String _antropizacaoTipo = '';
  String? _antropizacaoTipoOutro;
  int _antropizacaoIntensidade = 0;
  String _fitofisionomia = '';
  String? _fitofisionomiaOutro;

  Caracterizacao? _existing;

  @override
  void initState() {
    super.initState();
    _existing =
        DatabaseHelper.instance.getCaracterizacaoByParcela(widget.parcelaId);
    if (_existing != null) {
      _observacoesController.text = _existing!.observacoes ?? '';

      if (_isCampoRupestre) {
        _historicoUso = _existing!.historicoUso;
        _coberturaVegetal = _existing!.coberturaVegetal;
        _tipoSubstrato = _existing!.tipoSubstrato;
        _geoambiente = _existing!.geoambiente;
        _especiesLenhosas = _existing!.especiesLenhosas;
      } else if (_isCerrado) {
        _pressaoExterna = _existing!.pressaoExterna;
        _coberturaHerbaceoArbustiva = _existing!.coberturaHerbaceoArbustiva;
        _soloExposto = _existing!.soloExposto;
        _coberturaSerapilheira = _existing!.coberturaSerapilheira;
        _antropizacaoTipo = _existing!.antropizacaoTipo;
        _antropizacaoTipoOutro = _existing!.antropizacaoTipoOutro;
        _antropizacaoIntensidade = _existing!.antropizacaoIntensidade;
        _fitofisionomia = _existing!.fitofisionomia;
        _fitofisionomiaOutro = _existing!.fitofisionomiaOutro;
      } else {
        _usoPrevioController.text = _existing!.usoPrevio;
        _numeroEstratos = _existing!.numeroEstratos;
        _epifitas = _existing!.epifitas;
        _orquideas = _existing!.orquideas;
        _bromelias = _existing!.bromelias;
        _musgosLiquens = _existing!.musgosLiquens;
        _serapilheira = _existing!.serapilheira;
        _trepadeirasLenhosas = _existing!.trepadeirasLenhosas;
        _trepadeirasHerbaceas = _existing!.trepadeirasHerbaceas;
        _densidadeArbustos = _existing!.densidadeArbustos;
        _relevoController.text = _existing!.relevo;
        _antropizacaoController.text = _existing!.antropizacao;
      }
    }
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    _usoPrevioController.dispose();
    _relevoController.dispose();
    _antropizacaoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final caracterizacao = Caracterizacao(
      id: _existing?.id ?? const Uuid().v4(),
      parcelaId: widget.parcelaId,
      observacoes: _observacoesController.text.trim().isEmpty
          ? null
          : _observacoesController.text.trim(),
      historicoUso: _historicoUso,
      coberturaVegetal: _coberturaVegetal,
      tipoSubstrato: _tipoSubstrato,
      geoambiente: _geoambiente,
      especiesLenhosas: _especiesLenhosas,
      usoPrevio: _usoPrevioController.text.trim(),
      numeroEstratos: _numeroEstratos,
      epifitas: _epifitas,
      orquideas: _orquideas,
      bromelias: _bromelias,
      musgosLiquens: _musgosLiquens,
      serapilheira: _serapilheira,
      trepadeirasLenhosas: _trepadeirasLenhosas,
      trepadeirasHerbaceas: _trepadeirasHerbaceas,
      densidadeArbustos: _densidadeArbustos,
      relevo: _relevoController.text.trim(),
      antropizacao: _antropizacaoController.text.trim(),
      pressaoExterna: _pressaoExterna,
      coberturaHerbaceoArbustiva: _coberturaHerbaceoArbustiva,
      soloExposto: _soloExposto,
      coberturaSerapilheira: _coberturaSerapilheira,
      antropizacaoTipo: _antropizacaoTipo,
      antropizacaoTipoOutro: _antropizacaoTipoOutro,
      antropizacaoIntensidade: _antropizacaoIntensidade,
      fitofisionomia: _fitofisionomia,
      fitofisionomiaOutro: _fitofisionomiaOutro,
    );

    await DatabaseHelper.instance.insertCaracterizacao(caracterizacao);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caracterização salva com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildScaleField(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text(label, style: const TextStyle(fontSize: 14)),
          if (label.isNotEmpty) const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _buildToggleButton('Ausente', value == 1, () => onChanged(1)),
              _buildToggleButton('Poucas', value == 2, () => onChanged(2)),
              _buildToggleButton('Moderada', value == 3, () => onChanged(3)),
              _buildToggleButton('Abundante', value == 4, () => onChanged(4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomScaleField(String label, List<String> labels, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text(label, style: const TextStyle(fontSize: 14)),
          if (label.isNotEmpty) const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(labels.length, (index) {
              return _buildToggleButton(labels[index], value == index, () => onChanged(index));
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onPressed) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.green[800],
      onSelected: (_) => onPressed(),
    );
  }

  Widget _buildCampoRupestreForm() {
    final historicoLabels = [
      '<50%',
      '>50% a 65%',
      '>65% a 80%',
      '>80%',
    ];
    final coberturaLabels = [
      '<50%',
      '>50% a 65%',
      '>65% a 80%',
      '>80%',
    ];
    final substratoLabels = ['Quartzítico', 'Canga nodular', 'Canga couraçada'];
    final geoambienteLabels = ['Aberto', 'Arbustivo', 'Capão', 'Candeal'];
    final especiesLabels = ['Nenhuma', 'Poucas', 'Muitas'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Parâmetros - Campo Rupestre',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        const SizedBox(height: 12),

        // Histórico de Uso
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Histórico de Uso',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Escolha uma opção:',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ...List.generate(4, (index) {
                  final descriptions = [
                    'Remanescentes de vegetação campestre com porção subterrânea incipiente ou ausente',
                    'Áreas que sofreram ação antrópica com pouco ou nenhum comprometimento da parte subterrânea, ou em processo de regeneração',
                    'Áreas com ação antrópica moderada sem comprometimento da estrutura e fisionomia, ou que tenham evoluído a partir de estágios médios de regeneração',
                    'Vegetação de máxima expressão local, sendo os efeitos das ações antrópicas mínimos',
                  ];
                  return RadioListTile<int>(
                    value: index + 1,
                    groupValue: _historicoUso,
                    onChanged: (v) => setState(() => _historicoUso = v!),
                    title: Text(historicoLabels[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text(descriptions[index], style: const TextStyle(fontSize: 11)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cobertura vegetal
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cobertura vegetal viva do solo (herbácea)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                _buildCustomScaleField(
                  '',
                  coberturaLabels,
                  _coberturaVegetal,
                  (v) => setState(() => _coberturaVegetal = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tipo de substrato
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de Substrato',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: substratoLabels.map((label) {
                    final isSelected = _tipoSubstrato == label;
                    return ChoiceChip(
                      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                      selected: isSelected,
                      selectedColor: Colors.green[800],
                      onSelected: (_) => setState(() => _tipoSubstrato = label),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Geoambiente
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geoambiente',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: geoambienteLabels.map((label) {
                    final isSelected = _geoambiente == label;
                    return ChoiceChip(
                      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                      selected: isSelected,
                      selectedColor: Colors.green[800],
                      onSelected: (_) => setState(() => _geoambiente = label),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Espécies lenhosas
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Espécies Lenhosas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: especiesLabels.map((label) {
                    final isSelected = _especiesLenhosas == label;
                    return ChoiceChip(
                      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                      selected: isSelected,
                      selectedColor: Colors.green[800],
                      onSelected: (_) => setState(() => _especiesLenhosas = label),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Observações
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
      ],
    );
  }

  Widget _buildCerradoForm() {
    final pressaoLabels = ['Explícita', 'Considerável', 'Alguna', 'Não constatada'];
    final coberturaHerbaceaLabels = ['< 50%', '> 50%'];
    final percentLabels = ['< 10%', '10 a 30%', '31 a 50%', '> 50%'];
    final antropizacaoTipoLabels = ['Incêndio', 'Supressão', 'Gado', 'Mineração', 'Estrada/trilhas', 'Outro'];
    final antropizacaoIntensidadeLabels = ['< 10%', '10 e 30%', '30 e 50%', '> 50%'];
    final fitofisionomiaLabels = ['Capão', 'Brejo', 'Lajedo', 'Campo sujo', 'Campo limpo, etc...', 'Outro'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Parâmetros - Cerrado',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        const SizedBox(height: 12),

        // Análise da paisagem - pressão externa
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Análise da paisagem - pressão externa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: pressaoLabels.map((label) {
                    final isSelected = _pressaoExterna == pressaoLabels.indexOf(label) + 1;
                    return ChoiceChip(
                      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                      selected: isSelected,
                      selectedColor: Colors.green[800],
                      onSelected: (_) => setState(() => _pressaoExterna = pressaoLabels.indexOf(label) + 1),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // % cobertura vegetal herbáceo-arbustiva
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '% Cobertura vegetal herbáceo-arbustiva',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                _buildCustomScaleField('', coberturaHerbaceaLabels, _coberturaHerbaceoArbustiva,
                    (v) => setState(() => _coberturaHerbaceoArbustiva = v)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // % Solo exposto
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '% Solo exposto',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                _buildCustomScaleField('', percentLabels, _soloExposto,
                    (v) => setState(() => _soloExposto = v)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // % Cobertura do solo (serapilheira)
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '% Cobertura do solo (serapilheira)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                _buildCustomScaleField('', percentLabels, _coberturaSerapilheira,
                    (v) => setState(() => _coberturaSerapilheira = v)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Antropização na área (tipo)
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antropização na área (tipo)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: antropizacaoTipoLabels.map((label) {
                    final isSelected = _antropizacaoTipo == label;
                    return ChoiceChip(
                      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                      selected: isSelected,
                      selectedColor: Colors.green[800],
                      onSelected: (_) => setState(() {
                        _antropizacaoTipo = label;
                        if (label != 'Outro') _antropizacaoTipoOutro = null;
                      }),
                    );
                  }).toList(),
                ),
                if (_antropizacaoTipo == 'Outro') ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _antropizacaoTipoOutro ?? '',
                    decoration: const InputDecoration(
                      hintText: 'Descreva outro tipo de antropização',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => _antropizacaoTipoOutro = v,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Antropização na área (intensidade)
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antropização na área (intensidade)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                _buildCustomScaleField('', antropizacaoIntensidadeLabels, _antropizacaoIntensidade,
                    (v) => setState(() => _antropizacaoIntensidade = v)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Analise da paisagem - Fitofisionomia
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Análise da paisagem - Fitofisionomia',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: fitofisionomiaLabels.map((label) {
                    final isSelected = _fitofisionomia == label;
                    return ChoiceChip(
                      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                      selected: isSelected,
                      selectedColor: Colors.green[800],
                      onSelected: (_) => setState(() {
                        _fitofisionomia = label;
                        if (label != 'Outro') _fitofisionomiaOutro = null;
                      }),
                    );
                  }).toList(),
                ),
                if (_fitofisionomia == 'Outro') ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _fitofisionomiaOutro ?? '',
                    decoration: const InputDecoration(
                      hintText: 'Descreva outra fitofisionomia',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => _fitofisionomiaOutro = v,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Observações
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
      ],
    );
  }

  Widget _buildDefaultForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _usoPrevioController,
          decoration: const InputDecoration(
            labelText: 'Uso prévio',
            hintText: 'Ex: pastagem, cultivo, etc.',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.history),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Parâmetros',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        const SizedBox(height: 8),
        _buildCustomScaleField(
          'Nº estratos',
          ['Ausente', 'Dossel e\nsub-bosque', 'Dossel,\nsub-dossel\ne sub-bosque'],
          _numeroEstratos,
          (v) => setState(() => _numeroEstratos = v),
        ),
        _buildScaleField(
            'Epífitas', _epifitas, (v) => setState(() => _epifitas = v)),
        _buildScaleField('Orquídeas', _orquideas,
            (v) => setState(() => _orquideas = v)),
        _buildScaleField('Bromélias', _bromelias,
            (v) => setState(() => _bromelias = v)),
        _buildScaleField('Musgos / líquens', _musgosLiquens,
            (v) => setState(() => _musgosLiquens = v)),
        _buildScaleField('Serapilheira', _serapilheira,
            (v) => setState(() => _serapilheira = v)),
        _buildScaleField('Trepadeiras lenhosas', _trepadeirasLenhosas,
            (v) => setState(() => _trepadeirasLenhosas = v)),
        _buildScaleField('Trepadeiras herbáceas', _trepadeirasHerbaceas,
            (v) => setState(() => _trepadeirasHerbaceas = v)),
        _buildScaleField('Densidade de arbustos', _densidadeArbustos,
            (v) => setState(() => _densidadeArbustos = v)),
        const SizedBox(height: 20),
        TextFormField(
          controller: _relevoController,
          decoration: const InputDecoration(
            labelText: 'Relevo',
            hintText: 'Ex: Topo de morro, Encosta, Fundo de vale, Aluvial',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.terrain),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _antropizacaoController,
          decoration: const InputDecoration(
            labelText: 'Antropização',
            hintText:
                'Ex: incêndio, efeito de borda, presença de exóticas, vestígios de animais domésticos',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.warning),
          ),
          maxLines: 3,
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caracterização da Parcela'),
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
              _isCampoRupestre
                  ? _buildCampoRupestreForm()
                  : _isCerrado
                      ? _buildCerradoForm()
                      : _buildDefaultForm(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Caracterização'),
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
