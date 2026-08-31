import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/parcela.dart';
import '../models/individuo.dart';
import '../models/fuste.dart';
import 'individuo_form_screen.dart';

class _IndividuoRow {
  final Individuo individuo;
  final List<Fuste> fustes;

  _IndividuoRow({required this.individuo, required this.fustes});
}

class _DisplayRow {
  final Individuo individuo;
  final Fuste? fuste;
  final bool isFirstFuste;

  _DisplayRow({
    required this.individuo,
    this.fuste,
    required this.isFirstFuste,
  });
}

class IndividuosSpreadsheetScreen extends StatefulWidget {
  final Parcela parcela;
  final String estrato;
  final int? subParcelaFiltro;

  const IndividuosSpreadsheetScreen({
    super.key,
    required this.parcela,
    required this.estrato,
    this.subParcelaFiltro,
  });

  @override
  State<IndividuosSpreadsheetScreen> createState() =>
      _IndividuosSpreadsheetScreenState();
}

class _IndividuosSpreadsheetScreenState
    extends State<IndividuosSpreadsheetScreen>
    with SingleTickerProviderStateMixin {
  List<_IndividuoRow> _individuos = [];
  List<_DisplayRow> _displayRows = [];
  late TabController _tabController;
  final ScrollController _horizontalScroll = ScrollController();

  bool get _isHerbaceo => widget.estrato == 'Herbáceo';
  bool get _isFloristica => widget.estrato == 'Florística';
  bool get _isCenso =>
      widget.parcela.metodo == 'Censo' && widget.estrato == 'Censo';
  bool get _hasSubParcelas =>
      widget.subParcelaFiltro == null &&
      ((_isHerbaceo && widget.parcela.fisionomia == 'Campo Rupestre') ||
          (widget.parcela.metodo == 'Censo' &&
              (widget.estrato == 'Arbustivo' ||
                  widget.estrato == 'Herbáceo')));
  bool get _requiresDiametroCopa =>
      (widget.parcela.fisionomia == 'Cerrado' &&
          widget.estrato == 'Arbóreo') ||
      (widget.parcela.fisionomia == 'Campo Rupestre' &&
          (widget.estrato == 'Arbóreo' || widget.estrato == 'Arbustivo')) ||
      (_isCenso &&
          (widget.estrato == 'Arbóreo' || widget.estrato == 'Censo') &&
          (widget.parcela.fisionomia == 'Cerrado' ||
              widget.parcela.fisionomia == 'Campo Rupestre' ||
              widget.parcela.fisionomia == 'Árvores isoladas'));
  bool get _showFustes => !_isHerbaceo && !_isFloristica;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _hasSubParcelas ? 4 : 1, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  int get _currentSubParcela => _tabController.index + 1;

  void _loadData() {
    List<Individuo> individuos;

    if (widget.subParcelaFiltro != null) {
      individuos = DatabaseHelper.instance
          .getIndividuosByParcelaEstratoSubParcela(
        widget.parcela.id,
        widget.estrato,
        widget.subParcelaFiltro!,
      );
    } else if (_hasSubParcelas) {
      individuos = DatabaseHelper.instance
          .getIndividuosByParcelaEstratoSubParcela(
        widget.parcela.id,
        widget.estrato,
        _currentSubParcela,
      );
    } else {
      final all =
          DatabaseHelper.instance.getIndividuosByParcela(widget.parcela.id);
      individuos =
          all.where((i) => i.estrato == widget.estrato).toList();
    }

    List<_IndividuoRow> lista = [];
    for (var ind in individuos) {
      final fustes =
          DatabaseHelper.instance.getFustesByIndividuo(ind.id);
      lista.add(_IndividuoRow(individuo: ind, fustes: fustes));
    }

    List<_DisplayRow> rows = [];
    for (var row in lista) {
      if (_showFustes && row.fustes.isNotEmpty) {
        for (int f = 0; f < row.fustes.length; f++) {
          rows.add(_DisplayRow(
            individuo: row.individuo,
            fuste: row.fustes[f],
            isFirstFuste: f == 0,
          ));
        }
      } else {
        rows.add(_DisplayRow(
          individuo: row.individuo,
          fuste: null,
          isFirstFuste: true,
        ));
      }
    }

    setState(() {
      _individuos = lista;
      _displayRows = rows;
    });
  }

  Future<void> _addNewIndividuo() async {
    final nextNum = DatabaseHelper.instance
        .getNextIndividuoNumero(widget.parcela.id, widget.estrato);
    final subP = _hasSubParcelas ? _currentSubParcela : 1;

    final individuo = Individuo(
      id: const Uuid().v4(),
      parcelaId: widget.parcela.id,
      numero: nextNum,
      dataColeta: DateTime.now(),
      estrato: widget.estrato,
      subParcela: subP,
      numeroGps: _isCenso
          ? DatabaseHelper.instance
              .getNextNumeroGps(widget.parcela.id, widget.estrato)
          : null,
    );

    await DatabaseHelper.instance.insertIndividuo(individuo);

    if (_showFustes) {
      await DatabaseHelper.instance.insertFuste(Fuste(
        id: const Uuid().v4(),
        individuoId: individuo.id,
        numeroFuste: 1,
        altura: 0,
        cap: 0,
      ));
    }

    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontalScroll.hasClients) {
        _horizontalScroll.jumpTo(0);
      }
    });
  }

  Future<void> _deleteIndividuo(Individuo individuo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
            'Deseja excluir o indivíduo Nº ${individuo.numero} - ${individuo.nomeComum.isNotEmpty ? individuo.nomeComum : "Sem nome"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteIndividuo(individuo.id);
      _loadData();
    }
  }

  Future<void> _updateField(
      Individuo individuo, String field, String value) async {
    switch (field) {
      case 'nomeComum':
        individuo.nomeComum = value;
        break;
      case 'nomeCientifico':
        individuo.nomeCientifico = value;
        break;
      case 'familia':
        individuo.familia = value;
        break;
      case 'observacoes':
        individuo.observacoes = value.isEmpty ? null : value;
        break;
      case 'numeroGps':
        individuo.numeroGps = int.tryParse(value);
        break;
      case 'numeroIndividuos':
        individuo.numeroIndividuos = int.tryParse(value);
        break;
      case 'numeroIndividuosEspecie':
        individuo.numeroIndividuosEspecie = int.tryParse(value);
        break;
      case 'diametroCopa1':
        individuo.diametroCopa1 =
            double.tryParse(value.replaceAll(',', '.'));
        break;
      case 'diametroCopa2':
        individuo.diametroCopa2 =
            double.tryParse(value.replaceAll(',', '.'));
        break;
      case 'epifitas':
        individuo.epifitas = value == 'Sim';
        break;
    }
    await DatabaseHelper.instance.insertIndividuo(individuo);
    setState(() {});
  }

  Future<void> _updateFuste(
      Fuste fuste, String field, String value) async {
    switch (field) {
      case 'altura':
        fuste.altura = double.tryParse(value.replaceAll(',', '.')) ?? 0;
        break;
      case 'cap':
        fuste.cap = double.tryParse(value.replaceAll(',', '.')) ?? 0;
        break;
    }
    await DatabaseHelper.instance.insertFuste(fuste);
  }

  Future<void> _updateFusteCount(
      Individuo individuo, int newCount) async {
    if (newCount < 1) return;

    final currentFustes =
        DatabaseHelper.instance.getFustesByIndividuo(individuo.id);
    final currentCount = currentFustes.length;

    if (newCount > currentCount) {
      for (int i = currentCount; i < newCount; i++) {
        await DatabaseHelper.instance.insertFuste(Fuste(
          id: const Uuid().v4(),
          individuoId: individuo.id,
          numeroFuste: i + 1,
          altura: 0,
          cap: 0,
        ));
      }
    } else if (newCount < currentCount) {
      for (int i = currentCount - 1; i >= newCount; i--) {
        await DatabaseHelper.instance.deleteFuste(currentFustes[i].id);
      }
    }

    _loadData();
  }

  Future<void> _selectDate(Individuo individuo) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: individuo.dataColeta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      individuo.dataColeta = picked;
      await DatabaseHelper.instance.insertIndividuo(individuo);
      _loadData();
    }
  }

  String _getEstratoEmoji(String estrato) {
    switch (estrato) {
      case 'Arbóreo':
        return '\uD83C\uDF32';
      case 'Arbustivo':
        return '\uD83C\uDF3F';
      case 'Herbáceo':
        return '\uD83C\uDF31';
      default:
        return '\uD83C\uDF3F';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.parcela.nomeParcela),
            Text(
              '${_getEstratoEmoji(widget.estrato)} ${widget.estrato}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        bottom: _hasSubParcelas
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Sub 1'),
                  Tab(text: 'Sub 2'),
                  Tab(text: 'Sub 3'),
                  Tab(text: 'Sub 4'),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
              )
            : null,
      ),
      body: _individuos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_chart,
                      size: 80, color: Colors.green[200]),
                  const SizedBox(height: 16),
                  Text(
                    _isFloristica
                        ? 'Nenhuma espécie cadastrada'
                        : 'Nenhum indivíduo cadastrado',
                    style:
                        TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque no botão + para adicionar',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          : _buildSpreadsheet(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewIndividuo,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label:
            Text(_isFloristica ? 'Nova Espécie' : 'Novo Indivíduo'),
      ),
    );
  }

  Widget _buildSpreadsheet() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        // Define column flex weights
        final List<double> flexes = [];

        if (_showFustes) flexes.add(1.5); // Nº
        if (_showFustes) flexes.add(1.5); // Fuste
        flexes.add(3);   // Nome Comum
        flexes.add(3);   // Nome Científico
        flexes.add(2.5); // Família
        if (_isCenso) flexes.add(2); // Nº GPS
        if (_isHerbaceo) flexes.add(2); // Nº Indiv / % Cobertura
        if (_isHerbaceo && widget.parcela.fisionomia == 'Campo Rupestre') {
          flexes.add(2); // Nº Indiv Espécie
        }
        if (_showFustes) flexes.add(2); // Altura
        if (_showFustes) flexes.add(2); // CAP
        if (_requiresDiametroCopa) flexes.add(2); // Copa 1
        if (_requiresDiametroCopa) flexes.add(2); // Copa 2
        if (_showFustes) flexes.add(2); // Epífitas
        flexes.add(2);   // Data (last)
        flexes.add(1.2); // Ações

        final totalFlex = flexes.fold(0.0, (a, b) => a + b);
        final colWidths = flexes.map((f) => (f / totalFlex) * totalWidth).toList();

        return Scrollbar(
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            controller: _horizontalScroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderRow(colWidths),
                    ..._displayRows
                        .asMap()
                        .entries
                        .map((e) => _buildDataRow(e.key, e.value, colWidths)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(List<double> w) {
    int i = 0;
    return Container(
      color: Colors.green[800],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showFustes) _headerCell('Nº', w[i++]),
          if (_showFustes) _headerCell('Fuste', w[i++]),
          _headerCell('Nome Comum', w[i++]),
          _headerCell('Nome Científico', w[i++]),
          _headerCell('Família', w[i++]),
          if (_isCenso) _headerCell('Nº GPS', w[i++]),
          if (_isHerbaceo)
            _headerCell(
                widget.parcela.fisionomia == 'Campo Rupestre'
                    ? '% Cobertura'
                    : 'Nº Indiv.',
                w[i++]),
          if (_isHerbaceo && widget.parcela.fisionomia == 'Campo Rupestre')
            _headerCell('Nº Indiv. Esp.', w[i++]),
          if (_showFustes) _headerCell('Altura (m)', w[i++]),
          if (_showFustes) _headerCell('CAP (cm)', w[i++]),
          if (_requiresDiametroCopa) _headerCell('Copa 1 (m)', w[i++]),
          if (_requiresDiametroCopa) _headerCell('Copa 2 (m)', w[i++]),
          if (_showFustes) _headerCell('Epífitas', w[i++]),
          _headerCell('Data', w[i++]),
          _headerCell('', w[i++]),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green[900]!, width: 0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDataRow(int displayIndex, _DisplayRow row, List<double> w) {
    final ind = row.individuo;
    final fuste = row.fuste;

    final indIndex = _individuos.indexOf(
        _individuos.firstWhere((r) => r.individuo.id == ind.id));
    final bgColor = indIndex.isEven ? Colors.white : Colors.grey[50];

    int i = 0;

    return Container(
      color: bgColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nº (repete em todas as linhas)
          if (_showFustes)
            _numberCell(ind.numero, w[i++]),
          // Fuste
          if (_showFustes)
            _fusteCountCell(ind, fuste, w[i++]),
          // Nome Comum (repete em todas as linhas)
          _autocompleteCell(
            value: ind.nomeComum,
            options: DatabaseHelper.instance.getNomesComuns(),
            width: w[i++],
            onChanged: (v) => _updateField(ind, 'nomeComum', v),
          ),
          // Nome Científico (repete em todas as linhas)
          _autocompleteCell(
            value: ind.nomeCientifico,
            options: DatabaseHelper.instance.getNomesCientificos(),
            width: w[i++],
            italic: true,
            onChanged: (v) => _updateField(ind, 'nomeCientifico', v),
          ),
          // Família (repete em todas as linhas)
          _autocompleteCell(
            value: ind.familia,
            options: DatabaseHelper.instance.getFamilias(),
            width: w[i++],
            onChanged: (v) => _updateField(ind, 'familia', v),
          ),
          // Nº GPS (Censo)
          if (_isCenso)
            _editableCell(
              value: ind.numeroGps?.toString() ?? '',
              width: w[i++],
              inputType: TextInputType.number,
              onChanged: (v) => _updateField(ind, 'numeroGps', v),
            ),
          // Herbáceo fields
          if (_isHerbaceo)
            _editableCell(
              value: ind.numeroIndividuos?.toString() ?? '',
              width: w[i++],
              inputType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) =>
                  _updateField(ind, 'numeroIndividuos', v),
            ),
          if (_isHerbaceo && widget.parcela.fisionomia == 'Campo Rupestre')
            _editableCell(
              value: ind.numeroIndividuosEspecie?.toString() ?? '',
              width: w[i++],
              inputType: TextInputType.number,
              onChanged: (v) =>
                  _updateField(ind, 'numeroIndividuosEspecie', v),
            ),
          // Altura & CAP (per fuste)
          if (_showFustes && fuste != null) ...[
            _editableCell(
              value: fuste.altura > 0
                  ? fuste.altura.toStringAsFixed(2).replaceAll('.', ',')
                  : '',
              width: w[i++],
              inputType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _updateFuste(fuste, 'altura', v),
            ),
            _editableCell(
              value: fuste.cap > 0
                  ? fuste.cap.toStringAsFixed(2).replaceAll('.', ',')
                  : '',
              width: w[i++],
              inputType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _updateFuste(fuste, 'cap', v),
            ),
          ] else if (_showFustes) ...[
            _emptyCell(w[i++]),
            _emptyCell(w[i++]),
          ],
          // Diâmetro Copa
          if (_requiresDiametroCopa) ...[
            _editableCell(
              value: ind.diametroCopa1
                      ?.toStringAsFixed(2)
                      .replaceAll('.', ',') ??
                  '',
              width: w[i++],
              inputType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) =>
                  _updateField(ind, 'diametroCopa1', v),
            ),
            _editableCell(
              value: ind.diametroCopa2
                      ?.toStringAsFixed(2)
                      .replaceAll('.', ',') ??
                  '',
              width: w[i++],
              inputType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) =>
                  _updateField(ind, 'diametroCopa2', v),
            ),
          ],
          // Epífitas
          if (_showFustes)
            _epifitasCell(ind, w[i++]),
          // Data (last column before actions)
          _dateCell(ind, w[i++]),
          // Actions
          _actionsCell(ind, displayIndex, w[i++]),
        ],
      ),
    );
  }

  Widget _numberCell(int numero, double width) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Text(
        '$numero',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green[800],
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _fusteCountCell(
      Individuo ind, Fuste? currentFuste, double width) {
    return Container(
      width: width,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: TextFormField(
        initialValue: currentFuste != null
            ? '${currentFuste.numeroFuste}'
            : '1',
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          border: InputBorder.none,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 12),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          final newCount = int.tryParse(value);
          if (newCount != null && newCount >= 1) {
            _updateFusteCount(ind, newCount);
          }
        },
      ),
    );
  }

  Widget _editableCell({
    required String value,
    required double width,
    TextInputType? inputType,
    required ValueChanged<String> onChanged,
  }) {
    final controller = TextEditingController(text: value);
    return Container(
      width: width,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          border: InputBorder.none,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 12),
        keyboardType: inputType,
        inputFormatters: inputType ==
                const TextInputType.numberWithOptions(decimal: true)
            ? [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[,\.]?\d{0,2}'))
              ]
            : inputType == TextInputType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _autocompleteCell({
    required String value,
    required List<String> options,
    required double width,
    bool italic = false,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      width: width,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: value),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) return options;
          return options.where((o) => o
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: (selection) => onChanged(selection),
        fieldViewBuilder:
            (context, controller, focusNode, onSubmitted) {
          return TextFormField(
            controller: controller..text = value,
            focusNode: focusNode,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 8),
              border: InputBorder.none,
              isDense: true,
            ),
            style: TextStyle(
              fontSize: 12,
              fontStyle:
                  italic ? FontStyle.italic : FontStyle.normal,
            ),
            onChanged: onChanged,
          );
        },
      ),
    );
  }

  Widget _dateCell(Individuo ind, double width) {
    return GestureDetector(
      onTap: () => _selectDate(ind),
      child: Container(
        width: width,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 0.5),
        ),
        child: Text(
          DateFormat('dd/MM/yy').format(ind.dataColeta),
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _epifitasCell(Individuo ind, double width) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: DropdownButton<bool?>(
        value: ind.epifitas,
        isDense: true,
        underline: const SizedBox(),
        style:
            const TextStyle(fontSize: 11, color: Colors.black87),
        items: const [
          DropdownMenuItem(value: null, child: Text('-')),
          DropdownMenuItem(value: true, child: Text('Sim')),
          DropdownMenuItem(value: false, child: Text('Não')),
        ],
        onChanged: (v) {
          _updateField(ind, 'epifitas',
              v == null ? '' : (v ? 'Sim' : 'Não'));
        },
      ),
    );
  }

  Widget _emptyCell(double width) {
    return Container(
      width: width,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
        color: Colors.grey[100],
      ),
    );
  }

  Widget _actionsCell(Individuo ind, int displayIndex, double width) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert,
            size: 18, color: Colors.grey[600]),
        onSelected: (value) {
          if (value == 'editar') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IndividuoFormScreen(
                  parcela: widget.parcela,
                  estrato: widget.estrato,
                  individuo: ind,
                  subParcela:
                      _hasSubParcelas ? _currentSubParcela : 1,
                ),
              ),
            ).then((_) => _loadData());
          } else if (value == 'excluir') {
            _deleteIndividuo(ind);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'editar',
            child: ListTile(
              leading: Icon(Icons.edit),
              title: Text('Editar detalhes'),
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'excluir',
            child: ListTile(
              leading:
                  Icon(Icons.delete, color: Colors.red),
              title: Text('Excluir',
                  style: TextStyle(color: Colors.red)),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }
}
