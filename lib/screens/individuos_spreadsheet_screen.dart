import 'dart:async';
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
  bool _isExpanding = false;
  bool _isFilteringActive = false;
  Map<String, Set<String>> _columnFilters = {};

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
              widget.parcela.id, widget.estrato, widget.subParcelaFiltro!);
    } else if (_hasSubParcelas) {
      individuos = DatabaseHelper.instance
          .getIndividuosByParcelaEstratoSubParcela(
              widget.parcela.id, widget.estrato, _currentSubParcela);
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

    setState(() {
      _individuos = lista;
    });
    _rebuildDisplayRows();
  }

  void _rebuildDisplayRows() {
    if (_columnFilters.isNotEmpty) {
      _applyFilters();
    } else {
      List<_DisplayRow> rows = [];
      for (var row in _individuos) {
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
        _displayRows = rows;
      });
    }
  }

  Future<void> _expandPendingIndividuos() async {
    if (!_isHerbaceo || widget.parcela.fisionomia == 'Campo Rupestre') return;
    if (_isExpanding) return;

    final subP = _hasSubParcelas ? _currentSubParcela : 1;

    while (true) {
      final fresh = DatabaseHelper.instance
          .getIndividuosByParcelaEstratoSubParcela(
              widget.parcela.id, widget.estrato, subP);

      Individuo? toExpand;
      for (final ind in fresh) {
        if (ind.numeroIndividuos == null || ind.numeroIndividuos! <= 1) continue;

        final sameSpecies = fresh
            .where((i) =>
                i.nomeComum == ind.nomeComum &&
                i.nomeCientifico == ind.nomeCientifico &&
                i.numero >= ind.numero)
            .toList();

        if (ind.numeroIndividuos! > sameSpecies.length) {
          toExpand = ind;
          break;
        }
      }

      if (toExpand == null) break;

      final needed = toExpand.numeroIndividuos!;
      final sameSpecies = fresh
          .where((i) =>
              i.nomeComum == toExpand!.nomeComum &&
              i.nomeCientifico == toExpand.nomeCientifico &&
              i.numero >= toExpand.numero)
          .toList();
      final currentCount = sameSpecies.length;

      final maxNum = fresh.isNotEmpty
          ? fresh.map((i) => i.numero).reduce((a, b) => a > b ? a : b)
          : 0;
      var nextNum = maxNum + 1;
      for (int j = currentCount; j < needed; j++) {
        await DatabaseHelper.instance.insertIndividuo(Individuo(
          id: const Uuid().v4(),
          parcelaId: widget.parcela.id,
          numero: nextNum++,
          nomeComum: toExpand.nomeComum,
          nomeCientifico: toExpand.nomeCientifico,
          familia: toExpand.familia,
          dataColeta: toExpand.dataColeta,
          estrato: widget.estrato,
          subParcela: toExpand.subParcela,
          observacoes: toExpand.observacoes,
        ));
      }

      toExpand.numeroIndividuos = null;
      await _saveIndividuo(toExpand);
    }
  }

  Future<void> _addNewIndividuo() async {
    await _expandPendingIndividuos();

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

  Future<void> _saveIndividuo(Individuo individuo) async {
    await DatabaseHelper.instance.insertIndividuo(individuo);
  }

  Future<void> _saveFuste(Fuste fuste) async {
    await DatabaseHelper.instance.insertFuste(fuste);
  }

  String? _validateFuste(Individuo ind, Fuste fuste) {
    final estrato = ind.estrato;
    final fisionomia = widget.parcela.fisionomia;
    final metodo = widget.parcela.metodo;

    if (estrato == 'Herbáceo' || estrato == 'Florística') return null;

    if (estrato == 'Arbóreo' ||
        (metodo == 'Censo' && estrato == 'Censo')) {
      if (fuste.altura > 0 && fuste.altura < 2) {
        return 'Arbóreo: altura deve ser ≥ 2 m (atual: ${fuste.altura.toStringAsFixed(2)} m)';
      }
      if (fuste.cap > 0 && fuste.cap < 15) {
        return 'Arbóreo: CAP deve ser ≥ 15 cm (atual: ${fuste.cap.toStringAsFixed(2)} cm)';
      }
    }

    if (estrato == 'Arbustivo' && fisionomia != 'Campo Rupestre') {
      if (fuste.cap >= 15) {
        return 'Arbustivo: CAP deve ser < 15 cm (atual: ${fuste.cap.toStringAsFixed(2)} cm)';
      }
      if (fuste.altura > 0 && fuste.altura < 1.5) {
        return 'Arbustivo: altura deve ser ≥ 1,5 m (atual: ${fuste.altura.toStringAsFixed(2)} m)';
      }
    }

    return null;
  }

  bool _hasAlturaError(Individuo ind, Fuste fuste) {
    final estrato = ind.estrato;
    final fisionomia = widget.parcela.fisionomia;
    final metodo = widget.parcela.metodo;

    if (estrato == 'Herbáceo' || estrato == 'Florística') return false;

    if (estrato == 'Arbóreo' || (metodo == 'Censo' && estrato == 'Censo')) {
      if (fuste.altura > 0 && fuste.altura < 2) return true;
    }

    if (estrato == 'Arbustivo' && fisionomia != 'Campo Rupestre') {
      if (fuste.altura > 0 && fuste.altura < 1.5) return true;
    }

    return false;
  }

  bool _hasCapError(Individuo ind, Fuste fuste) {
    final estrato = ind.estrato;
    final fisionomia = widget.parcela.fisionomia;
    final metodo = widget.parcela.metodo;

    if (estrato == 'Herbáceo' || estrato == 'Florística') return false;

    if (estrato == 'Arbóreo' || (metodo == 'Censo' && estrato == 'Censo')) {
      if (fuste.cap > 0 && fuste.cap < 15) return true;
    }

    if (estrato == 'Arbustivo' && fisionomia != 'Campo Rupestre') {
      if (fuste.cap >= 15) return true;
    }

    return false;
  }

  void _showValidationIfNeeded(Individuo ind, Fuste fuste) {
    final error = _validateFuste(ind, fuste);
    if (error != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('Atenção'),
            ],
          ),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _addFusteToLastIndividuo() async {
    if (_individuos.isEmpty) return;
    final lastRow = _individuos.last;
    final currentFustes =
        DatabaseHelper.instance.getFustesByIndividuo(lastRow.individuo.id);
    final nextNum = currentFustes.length + 1;
    await DatabaseHelper.instance.insertFuste(Fuste(
      id: const Uuid().v4(),
      individuoId: lastRow.individuo.id,
      numeroFuste: nextNum,
      altura: 0,
      cap: 0,
    ));
    _loadData();
  }

  Future<void> _deleteFuste(Individuo individuo, Fuste fuste) async {
    final currentFustes =
        DatabaseHelper.instance.getFustesByIndividuo(individuo.id);
    if (currentFustes.length <= 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não é possível excluir o último fuste!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
            'Deseja excluir o fuste Nº ${fuste.numeroFuste}?'),
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
      await DatabaseHelper.instance.deleteFuste(fuste.id);
      final updatedFustes =
          DatabaseHelper.instance.getFustesByIndividuo(individuo.id);
      for (int i = 0; i < updatedFustes.length; i++) {
        if (updatedFustes[i].numeroFuste != i + 1) {
          updatedFustes[i].numeroFuste = i + 1;
          await DatabaseHelper.instance.insertFuste(updatedFustes[i]);
        }
      }
      _loadData();
    }
  }

  Future<void> _updateNumeroIndividuo(
      Individuo individuo, String value) async {
    final newNum = int.tryParse(value);
    if (newNum == null || newNum < 1) return;
    final existing = _individuos
        .where((r) =>
            r.individuo.numero == newNum &&
            r.individuo.id != individuo.id)
        .toList();
    if (existing.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Número $newNum já existe!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    individuo.numero = newNum;
    await _saveIndividuo(individuo);
    _loadData();
  }

  Future<void> _expandNumeroIndividuos(
      Individuo individuo, int newNum) async {
    if (newNum < 1) return;
    if (_isExpanding) return;
    _isExpanding = true;

    individuo.numeroIndividuos = newNum;
    await _saveIndividuo(individuo);

    final freshIndividuos = DatabaseHelper.instance
        .getIndividuosByParcelaEstratoSubParcela(
            widget.parcela.id, widget.estrato, individuo.subParcela);

    final maxNum = freshIndividuos.isNotEmpty
        ? freshIndividuos.map((i) => i.numero).reduce((a, b) => a > b ? a : b)
        : 0;

    final sameSpecies = freshIndividuos
        .where((i) =>
            i.nomeComum == individuo.nomeComum &&
            i.nomeCientifico == individuo.nomeCientifico &&
            i.numero >= individuo.numero)
        .toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));

    final extras = sameSpecies.where((i) => i.id != individuo.id).toList();
    final currentCount = 1 + extras.length;

    if (newNum > currentCount) {
      var nextNum = maxNum + 1;
      for (int j = currentCount; j < newNum; j++) {
        await DatabaseHelper.instance.insertIndividuo(Individuo(
          id: const Uuid().v4(),
          parcelaId: widget.parcela.id,
          numero: nextNum++,
          nomeComum: individuo.nomeComum,
          nomeCientifico: individuo.nomeCientifico,
          familia: individuo.familia,
          dataColeta: individuo.dataColeta,
          estrato: widget.estrato,
          subParcela: individuo.subParcela,
          observacoes: individuo.observacoes,
        ));
      }
    } else if (newNum < currentCount) {
      final toDelete = extras.sublist(newNum - 1);
      for (final extra in toDelete) {
        await DatabaseHelper.instance.deleteIndividuo(extra.id);
      }
    }

    individuo.numeroIndividuos = null;
    await _saveIndividuo(individuo);

    _loadData();
    _isExpanding = false;
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
      await _saveIndividuo(individuo);
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

  void _toggleFiltering() {
    setState(() {
      _isFilteringActive = !_isFilteringActive;
      if (!_isFilteringActive) {
        _columnFilters.clear();
        _applyFilters();
      }
    });
  }

  void _applyFilters() {
    if (_columnFilters.isEmpty) {
      _displayRows = _individuos.expand((row) {
        if (row.fustes.isEmpty) {
          return [_DisplayRow(individuo: row.individuo, isFirstFuste: true)];
        }
        return row.fustes.asMap().entries.map((e) => _DisplayRow(
              individuo: row.individuo,
              fuste: e.value,
              isFirstFuste: e.key == 0,
            ));
      }).toList();
      return;
    }

    _displayRows = _individuos.expand((row) {
      if (row.fustes.isEmpty) {
        return [_DisplayRow(individuo: row.individuo, isFirstFuste: true)];
      }
      return row.fustes.asMap().entries.map((e) => _DisplayRow(
            individuo: row.individuo,
            fuste: e.value,
            isFirstFuste: e.key == 0,
          ));
    }).toList();

    for (final entry in _columnFilters.entries) {
      if (entry.value.isEmpty) continue;
      _displayRows = _displayRows.where((row) {
        final value = _getColumnValue(row, entry.key);
        return entry.value.contains(value);
      }).toList();
    }
  }

  String _getColumnValue(_DisplayRow row, String column) {
    final ind = row.individuo;
    final fuste = row.fuste;
    switch (column) {
      case 'numero':
        return '${ind.numero}';
      case 'fuste':
        return '${fuste?.numeroFuste ?? ""}';
      case 'nomeComum':
        return ind.nomeComum;
      case 'nomeCientifico':
        return ind.nomeCientifico;
      case 'familia':
        return ind.familia;
      case 'altura':
        return fuste?.altura != null ? '${fuste!.altura}' : '';
      case 'cap':
        return fuste?.cap != null ? '${fuste!.cap}' : '';
      case 'copa1':
        return ind.diametroCopa1 != null ? '${ind.diametroCopa1}' : '';
      case 'copa2':
        return ind.diametroCopa2 != null ? '${ind.diametroCopa2}' : '';
      case 'epifitas':
        return fuste?.epifitas == true ? 'Sim' : 'Não';
      case 'data':
        return '${ind.dataColeta.day}/${ind.dataColeta.month}/${ind.dataColeta.year}';
      default:
        return '';
    }
  }

  Set<String> _getUniqueValuesForColumn(String column) {
    return _displayRows.map((row) => _getColumnValue(row, column)).toSet();
  }

  void _showFilterDialog(String column, String columnName) {
    final uniqueValues = _getUniqueValuesForColumn(column);
    final currentFilters = _columnFilters[column] ?? {};
    final tempFilters = Set<String>.from(currentFilters);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Filtrar: $columnName'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Column(
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          if (tempFilters.length == uniqueValues.length) {
                            tempFilters.clear();
                          } else {
                            tempFilters.addAll(uniqueValues);
                          }
                        });
                      },
                      child: Text(
                        tempFilters.length == uniqueValues.length
                            ? 'Desmarcar Tudo'
                            : 'Marcar Tudo',
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: uniqueValues.length,
                    itemBuilder: (context, index) {
                      final value = uniqueValues.elementAt(index);
                      final isSelected = tempFilters.contains(value);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (selected) {
                          setDialogState(() {
                            if (selected == true) {
                              tempFilters.add(value);
                            } else {
                              tempFilters.remove(value);
                            }
                          });
                        },
                        title: Text(
                          value.isEmpty ? '(vazio)' : value,
                          style: const TextStyle(fontSize: 13),
                        ),
                        dense: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _columnFilters.remove(column);
                  _applyFilters();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Limpar Filtro'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (tempFilters.isEmpty) {
                    _columnFilters.remove(column);
                  } else {
                    _columnFilters[column] = tempFilters;
                  }
                  _applyFilters();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
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
        actions: [
          IconButton(
            icon: Icon(
              _isFilteringActive ? Icons.filter_alt : Icons.filter_alt_off,
              color: _isFilteringActive ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleFiltering,
            tooltip: _isFilteringActive
                ? 'Desativar filtros'
                : 'Ativar filtros',
          ),
        ],
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
      body: _buildSpreadsheet(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewIndividuo,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_isFloristica ? 'Nova Espécie' : 'Novo Indivíduo'),
      ),
    );
  }

  Widget _buildSpreadsheet() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final List<double> flexes = [];
        if (_showFustes) flexes.add(1.5);
        if (_showFustes) flexes.add(1.5);
        if (_isHerbaceo) flexes.add(1.5);
        flexes.add(3);
        flexes.add(3);
        flexes.add(2.5);
        if (_isCenso) flexes.add(2);
        if (_isHerbaceo) flexes.add(2);
        if (_isHerbaceo && widget.parcela.fisionomia == 'Campo Rupestre') {
          flexes.add(2);
        }
        if (_showFustes) flexes.add(2);
        if (_showFustes) flexes.add(2);
        if (_requiresDiametroCopa) flexes.add(2);
        if (_requiresDiametroCopa) flexes.add(2);
        if (_showFustes && widget.estrato == 'Arbóreo') flexes.add(2);
        flexes.add(2);
        flexes.add(1.2);
        final totalFlex = flexes.fold(0.0, (a, b) => a + b);
        final colWidths =
            flexes.map((f) => (f / totalFlex) * totalWidth).toList();

        return Scrollbar(
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            controller: _horizontalScroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Column(
                children: [
                  _buildHeaderRow(colWidths),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._displayRows.asMap().entries.map(
                              (e) => _buildDataRow(e.key, e.value, colWidths)),
                          _buildAddRow(colWidths),
                          const SizedBox(height: 300),
                        ],
                      ),
                    ),
                  ),
                ],
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
          if (_showFustes) _headerCell('Nº', w[i++], columnKey: 'numero'),
          if (_showFustes) _headerCell('Fuste', w[i++], columnKey: 'fuste'),
          if (_isHerbaceo) _headerCell('Nº', w[i++], columnKey: 'numero'),
          _headerCell('Nome Comum', w[i++], columnKey: 'nomeComum'),
          _headerCell('Nome Científico', w[i++], columnKey: 'nomeCientifico'),
          _headerCell('Família', w[i++], columnKey: 'familia'),
          if (_isCenso) _headerCell('Nº GPS', w[i++]),
          if (_isHerbaceo)
            _headerCell(
                widget.parcela.fisionomia == 'Campo Rupestre'
                    ? '% Cobertura'
                    : 'Nº Indiv.',
                w[i++]),
          if (_isHerbaceo && widget.parcela.fisionomia == 'Campo Rupestre')
            _headerCell('Nº Indiv. Esp.', w[i++]),
          if (_showFustes) _headerCell('Altura (m)', w[i++], columnKey: 'altura'),
          if (_showFustes) _headerCell('CAP (cm)', w[i++], columnKey: 'cap'),
          if (_requiresDiametroCopa) _headerCell('Copa 1 (m)', w[i++], columnKey: 'copa1'),
          if (_requiresDiametroCopa) _headerCell('Copa 2 (m)', w[i++], columnKey: 'copa2'),
          if (_showFustes && widget.estrato == 'Arbóreo') _headerCell('Epífitas', w[i++], columnKey: 'epifitas'),
          _headerCell('Data', w[i++], columnKey: 'data'),
          _headerCell('', w[i++]),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width, {String? columnKey}) {
    final hasFilter = columnKey != null && _columnFilters.containsKey(columnKey);
    return GestureDetector(
      onTap: _isFilteringActive && columnKey != null
          ? () => _showFilterDialog(columnKey, text)
          : null,
      child: Container(
        width: width,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green[900]!, width: 0.5),
          color: hasFilter ? Colors.green[600] : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
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
            if (_isFilteringActive && columnKey != null)
              Positioned(
                right: 2,
                top: 2,
                child: Icon(
                  hasFilter ? Icons.filter_list : Icons.tune,
                  size: 14,
                  color: hasFilter ? Colors.yellow : Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(
      int displayIndex, _DisplayRow row, List<double> w) {
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
          if (_showFustes)
            _cellWithSuggestions(
              value: '${ind.numero}',
              width: w[i++],
              options: [],
              keyboardType: TextInputType.number,
              readOnly: false,
              fontStyle: FontStyle.normal,
              textStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
                fontSize: 13,
              ),
              cellKey: 'num_${ind.id}',
              onFieldChanged: (v) {
                final newNum = int.tryParse(v);
                if (newNum != null && newNum >= 1) {
                  ind.numero = newNum;
                  _saveIndividuo(ind);
                }
              },
              onSubmitted: (v) => _updateNumeroIndividuo(ind, v),
            ),
          if (_showFustes)
            _cellWithSuggestions(
              value: '${fuste?.numeroFuste ?? ""}',
              width: w[i++],
              options: [],
              keyboardType: TextInputType.number,
              readOnly: true,
              textStyle: TextStyle(fontSize: 12, color: Colors.grey[700]),
              cellKey: 'fuste_${ind.id}_${fuste?.id ?? "0"}',
            ),
          if (_isHerbaceo)
            _cellWithSuggestions(
              value: '${ind.numero}',
              width: w[i++],
              options: [],
              keyboardType: TextInputType.number,
              readOnly: false,
              fontStyle: FontStyle.normal,
              textStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
                fontSize: 13,
              ),
              cellKey: 'num_${ind.id}',
              onFieldChanged: (v) {
                final newNum = int.tryParse(v);
                if (newNum != null && newNum >= 1) {
                  ind.numero = newNum;
                  _saveIndividuo(ind);
                }
              },
              onSubmitted: (v) => _updateNumeroIndividuo(ind, v),
            ),
          _cellWithSuggestions(
            value: ind.nomeComum,
            width: w[i++],
            options: DatabaseHelper.instance.getNomesComuns(),
            keyboardType: TextInputType.text,
            readOnly: false,
            cellKey: 'nome_${ind.id}',
            onFieldChanged: (v) {
              ind.nomeComum = v;
              _saveIndividuo(ind);
            },
          ),
          _cellWithSuggestions(
            value: ind.nomeCientifico,
            width: w[i++],
            options: DatabaseHelper.instance.getNomesCientificos(),
            keyboardType: TextInputType.text,
            readOnly: false,
            fontStyle: FontStyle.italic,
            cellKey: 'cient_${ind.id}',
            onFieldChanged: (v) {
              ind.nomeCientifico = v;
              _saveIndividuo(ind);
            },
          ),
          _cellWithSuggestions(
            value: ind.familia,
            width: w[i++],
            options: DatabaseHelper.instance.getFamilias(),
            keyboardType: TextInputType.text,
            readOnly: false,
            cellKey: 'fam_${ind.id}',
            onFieldChanged: (v) {
              ind.familia = v;
              _saveIndividuo(ind);
            },
          ),
          if (_isCenso)
            _cellWithSuggestions(
              value: ind.numeroGps?.toString() ?? '',
              width: w[i++],
              options: [],
              keyboardType: TextInputType.number,
              readOnly: false,
              cellKey: 'gps_${ind.id}',
              onFieldChanged: (v) {
                ind.numeroGps = int.tryParse(v);
                _saveIndividuo(ind);
              },
            ),
          if (_isHerbaceo)
            _cellWithSuggestions(
              value: ind.numeroIndividuos?.toString() ?? '',
              width: w[i++],
              options: [],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              readOnly: false,
              cellKey: 'nind_${ind.id}',
              onFieldChanged: (v) {
                ind.numeroIndividuos = int.tryParse(v);
              },
              onFocusLost: () => _saveIndividuo(ind),
              onSubmitted: widget.parcela.fisionomia != 'Campo Rupestre'
                  ? (v) async {
                      final newNum = int.tryParse(v);
                      if (newNum != null && newNum >= 1) {
                        try {
                          await _expandNumeroIndividuos(ind, newNum);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    }
                  : null,
            ),
          if (_isHerbaceo && widget.parcela.fisionomia == 'Campo Rupestre')
            _cellWithSuggestions(
              value: ind.numeroIndividuosEspecie?.toString() ?? '',
              width: w[i++],
              options: [],
              keyboardType: TextInputType.number,
              readOnly: false,
              cellKey: 'nindE_${ind.id}',
              onFieldChanged: (v) {
                ind.numeroIndividuosEspecie = int.tryParse(v);
                _saveIndividuo(ind);
              },
            ),
          if (_showFustes && fuste != null) ...[
            _cellWithSuggestions(
              value: fuste.altura > 0
                  ? fuste.altura.toStringAsFixed(2).replaceAll('.', ',')
                  : '',
              width: w[i++],
              options: [],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              readOnly: false,
              cellKey: 'alt_${fuste.id}',
              hasError: _hasAlturaError(ind, fuste),
              onFieldChanged: (v) {
                fuste.altura =
                    double.tryParse(v.replaceAll(',', '.')) ?? 0;
                _saveFuste(fuste);
              },
              onSubmitted: (v) {
                fuste.altura = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                _saveFuste(fuste);
                setState(() {});
                _showValidationIfNeeded(ind, fuste);
              },
            ),
            _cellWithSuggestions(
              value: fuste.cap > 0
                  ? fuste.cap.toStringAsFixed(2).replaceAll('.', ',')
                  : '',
              width: w[i++],
              options: [],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              readOnly: false,
              cellKey: 'cap_${fuste.id}',
              hasError: _hasCapError(ind, fuste),
              onFieldChanged: (v) {
                fuste.cap =
                    double.tryParse(v.replaceAll(',', '.')) ?? 0;
                _saveFuste(fuste);
              },
              onSubmitted: (v) {
                fuste.cap = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                _saveFuste(fuste);
                setState(() {});
                _showValidationIfNeeded(ind, fuste);
              },
            ),
          ] else if (_showFustes) ...[
            _emptyCell(w[i++]),
            _emptyCell(w[i++]),
          ],
          if (_requiresDiametroCopa && row.isFirstFuste) ...[
            _cellWithSuggestions(
              value: ind.diametroCopa1
                      ?.toStringAsFixed(2)
                      .replaceAll('.', ',') ??
                  '',
              width: w[i++],
              options: [],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              readOnly: false,
              cellKey: 'copa1_${ind.id}',
              onFieldChanged: (v) {
                ind.diametroCopa1 =
                    double.tryParse(v.replaceAll(',', '.'));
                _saveIndividuo(ind);
              },
            ),
            _cellWithSuggestions(
              value: ind.diametroCopa2
                      ?.toStringAsFixed(2)
                      .replaceAll('.', ',') ??
                  '',
              width: w[i++],
              options: [],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              readOnly: false,
              cellKey: 'copa2_${ind.id}',
              onFieldChanged: (v) {
                ind.diametroCopa2 =
                    double.tryParse(v.replaceAll(',', '.'));
                _saveIndividuo(ind);
              },
            ),
          ] else if (_requiresDiametroCopa) ...[
            _emptyCell(w[i++]),
            _emptyCell(w[i++]),
          ],
          if (_showFustes && widget.estrato == 'Arbóreo') _epifitasCell(ind, fuste, w[i++]),
          _dateCell(ind, w[i++]),
          _actionsCell(ind, row, w[i++]),
        ],
      ),
    );
  }

  Widget _buildAddRow(List<double> w) {
    int i = 0;
    return Container(
      color: Colors.grey[100],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showFustes)
            _addCell(w[i++], onTap: _addNewIndividuo),
          if (_showFustes)
            _addCell(w[i++], onTap: _addFusteToLastIndividuo),
          if (_isHerbaceo) _addCell(w[i++], onTap: _addNewIndividuo),
          _emptyCell(w[i++]),
          _emptyCell(w[i++]),
          _emptyCell(w[i++]),
          if (_isCenso) _emptyCell(w[i++]),
          if (_isHerbaceo) _emptyCell(w[i++]),
          if (_isHerbaceo && widget.parcela.fisionomia == 'Campo Rupestre')
            _emptyCell(w[i++]),
          if (_showFustes) _emptyCell(w[i++]),
          if (_showFustes) _emptyCell(w[i++]),
          if (_requiresDiametroCopa) _emptyCell(w[i++]),
          if (_requiresDiametroCopa) _emptyCell(w[i++]),
          if (_showFustes && widget.estrato == 'Arbóreo') _emptyCell(w[i++]),
          _emptyCell(w[i++]),
          _emptyCell(w[i++]),
        ],
      ),
    );
  }

  Widget _addCell(double width, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 0.5),
          color: Colors.grey[50],
        ),
        child: Icon(Icons.add_circle_outline, size: 20, color: Colors.green[700]),
      ),
    );
  }

  Widget _cellWithSuggestions({
    required String value,
    required double width,
    required List<String> options,
    required TextInputType keyboardType,
    required bool readOnly,
    FontStyle fontStyle = FontStyle.normal,
    TextStyle? textStyle,
    ValueChanged<String>? onFieldChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onFocusLost,
    String? cellKey,
    bool hasError = false,
  }) {
    return _AutocompleteCell(
      key: cellKey != null ? ValueKey(cellKey) : null,
      initialValue: value,
      width: width,
      options: options,
      keyboardType: keyboardType,
      readOnly: readOnly,
      fontStyle: fontStyle,
      textStyle: textStyle,
      onFieldChanged: onFieldChanged,
      onSubmitted: onSubmitted,
      onFocusLost: onFocusLost,
      hasError: hasError,
    );
  }

  Widget _epifitasCell(Individuo ind, Fuste? fuste, double width) {
    return _cellWithSuggestions(
      value: ind.epifitasDetalhes ?? '',
      width: width,
      options: [],
      keyboardType: TextInputType.text,
      readOnly: false,
      cellKey: 'epif_${fuste?.id ?? ind.id}',
      onFieldChanged: (v) {
        ind.epifitasDetalhes = v;
        if (v.isNotEmpty) {
          fuste?.epifitas = true;
        } else {
          fuste?.epifitas = null;
        }
        _saveIndividuo(ind);
        _saveFuste(fuste!);
      },
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

  Widget _actionsCell(Individuo ind, _DisplayRow row, double width) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
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
          } else if (value == 'excluir_ind') {
            _deleteIndividuo(ind);
          } else if (value == 'excluir_fuste' && row.fuste != null) {
            _deleteFuste(ind, row.fuste!);
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
          if (row.fuste != null)
            PopupMenuItem(
              value: 'excluir_fuste',
              child: const ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.orange),
                title: Text('Excluir fuste',
                    style: TextStyle(color: Colors.orange)),
                dense: true,
              ),
            ),
          const PopupMenuItem(
            value: 'excluir_ind',
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Excluir indivíduo',
                  style: TextStyle(color: Colors.red)),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutocompleteCell extends StatefulWidget {
  final String initialValue;
  final double width;
  final List<String> options;
  final TextInputType keyboardType;
  final bool readOnly;
  final FontStyle fontStyle;
  final TextStyle? textStyle;
  final ValueChanged<String>? onFieldChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFocusLost;
  final bool hasError;

  const _AutocompleteCell({
    super.key,
    required this.initialValue,
    required this.width,
    required this.options,
    required this.keyboardType,
    required this.readOnly,
    this.fontStyle = FontStyle.normal,
    this.textStyle,
    this.onFieldChanged,
    this.onSubmitted,
    this.onFocusLost,
    this.hasError = false,
  });

  @override
  State<_AutocompleteCell> createState() => _AutocompleteCellState();
}

class _AutocompleteCellState extends State<_AutocompleteCell> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _filteredOptions = [];
  bool _suppressListener = false;
  bool _isSelectingSuggestion = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      widget.onFocusLost?.call();
    }
  }

  @override
  void didUpdateWidget(covariant _AutocompleteCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      final hasFocus = _focusNode.hasFocus;
      final sel = _controller.selection;
      _suppressListener = true;
      _controller.text = widget.initialValue;
      _suppressListener = false;
      if (hasFocus && sel.isValid) {
        _controller.selection = sel;
      }
    }
  }

  void _onTextChanged() {
    if (_suppressListener || _isSelectingSuggestion) return;
    final value = _controller.text;
    widget.onFieldChanged?.call(value);

    if (widget.options.isNotEmpty) {
      if (value.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options
            .where((o) => o.toLowerCase().contains(value.toLowerCase()))
            .toList();
      }
      if (_filteredOptions.isNotEmpty && _focusNode.hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => _SuggestionOverlay(
        layerLink: _layerLink,
        options: _filteredOptions,
        width: widget.width.clamp(150, 300).toDouble(),
        onSelected: (option) {
          _isSelectingSuggestion = true;
          _suppressListener = true;
          _controller.text = option;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: option.length),
          );
          _suppressListener = false;
          widget.onFieldChanged?.call(option);
          _removeOverlay();
          _isSelectingSuggestion = false;
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: widget.width,
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.hasError ? Colors.red : Colors.grey[300]!,
              width: widget.hasError ? 2.0 : 0.5,
            ),
            color: widget.hasError ? Colors.red[50] : null,
          ),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            readOnly: widget.readOnly,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              border: InputBorder.none,
              isDense: true,
            ),
            style: widget.textStyle ??
                TextStyle(
                  fontSize: 12,
                  fontStyle: widget.fontStyle,
                ),
            keyboardType: widget.keyboardType,
            inputFormatters: widget.keyboardType ==
                    const TextInputType.numberWithOptions(decimal: true)
                ? [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[,\.]?\d{0,2}'))
                  ]
                : widget.keyboardType == TextInputType.number
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
            onFieldSubmitted: widget.onSubmitted,
          ),
        ),
      ),
    );
  }
}

class _SuggestionOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final List<String> options;
  final double width;
  final ValueChanged<String> onSelected;

  const _SuggestionOverlay({
    required this.layerLink,
    required this.options,
    required this.width,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 48),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(2),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                return InkWell(
                  onTap: () => onSelected(option),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(option, style: const TextStyle(fontSize: 12)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
