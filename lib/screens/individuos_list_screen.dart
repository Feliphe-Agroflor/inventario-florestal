import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/parcela.dart';
import '../models/individuo.dart';
import '../models/fuste.dart';
import 'individuo_form_screen.dart';

class IndividuosListScreen extends StatefulWidget {
  final Parcela parcela;
  final String estrato;
  final int? subParcelaFiltro;

  const IndividuosListScreen({
    super.key,
    required this.parcela,
    required this.estrato,
    this.subParcelaFiltro,
  });

  @override
  State<IndividuosListScreen> createState() => _IndividuosListScreenState();
}

class _IndividuosListScreenState extends State<IndividuosListScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _individuosComFustes = [];
  late TabController _tabController;

  bool get _isHerbaceo => widget.estrato == 'Herbáceo';
  bool get _isFloristica => widget.estrato == 'Florística';
  bool get _hasSubParcelas =>
      widget.subParcelaFiltro == null &&
      ((_isHerbaceo && widget.parcela.fisionomia == 'Campo Rupestre') ||
      (widget.parcela.metodo == 'Censo' && (widget.estrato == 'Arbustivo' || widget.estrato == 'Herbáceo')));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _hasSubParcelas ? 4 : 1, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadIndividuos();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadIndividuos();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  int get _currentSubParcela => _tabController.index + 1;

  void _loadIndividuos() {
    List<Individuo> individuos;

    if (widget.subParcelaFiltro != null) {
      individuos = DatabaseHelper.instance.getIndividuosByParcelaEstratoSubParcela(
        widget.parcela.id,
        widget.estrato,
        widget.subParcelaFiltro!,
      );
    } else if (_hasSubParcelas) {
      individuos = DatabaseHelper.instance.getIndividuosByParcelaEstratoSubParcela(
        widget.parcela.id,
        widget.estrato,
        _currentSubParcela,
      );
    } else {
      final allIndividuos =
          DatabaseHelper.instance.getIndividuosByParcela(widget.parcela.id);
      individuos = allIndividuos.where((i) => i.estrato == widget.estrato).toList();
    }

    List<Map<String, dynamic>> lista = [];
    for (var ind in individuos) {
      final fustes = DatabaseHelper.instance.getFustesByIndividuo(ind.id);
      lista.add({'individuo': ind, 'fustes': fustes});
    }

    setState(() => _individuosComFustes = lista);
  }

  Future<void> _deleteIndividuo(Individuo individuo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
            'Deseja excluir o indivíduo Nº ${individuo.numero} - ${individuo.nomeComum}?'),
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
      _loadIndividuos();
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
      body: _individuosComFustes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, size: 80, color: Colors.green[200]),
                  const SizedBox(height: 16),
                  Text(
                    _isFloristica
                        ? 'Nenhuma espécie cadastrada'
                        : 'Nenhum indivíduo cadastrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque no botão + para adicionar',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _individuosComFustes.length,
              itemBuilder: (context, index) {
                final item = _individuosComFustes[index];
                final Individuo individuo = item['individuo'];
                final List<Fuste> fustes = item['fustes'];

                final totalAltura =
                    fustes.fold(0.0, (sum, f) => sum + f.altura);
                final mediaAltura =
                    fustes.isEmpty ? 0.0 : totalAltura / fustes.length;
                final mediaCap = fustes.isEmpty
                    ? 0.0
                    : fustes.fold(0.0, (sum, f) => sum + f.cap) /
                        fustes.length;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(
                          '${individuo.numero}',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            individuo.nomeComum.isNotEmpty
                                ? individuo.nomeComum
                                : 'Sem nome',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (individuo.fotos.isNotEmpty)
                          Icon(Icons.camera_alt,
                              size: 16, color: Colors.grey[500]),
                      ],
                    ),
                    subtitle: _isFloristica
                        ? _buildFloristicaSubtitle(individuo)
                        : _isHerbaceo
                            ? _buildHerbaceoSubtitle(individuo)
                            : _buildArboreoSubtitle(individuo, fustes,
                                mediaAltura, mediaCap),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'editar') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IndividuoFormScreen(
                                parcela: widget.parcela,
                                estrato: widget.estrato,
                                individuo: individuo,
                              ),
                            ),
                          ).then((_) => _loadIndividuos());
                        } else if (value == 'excluir') {
                          _deleteIndividuo(individuo);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Editar'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'excluir',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Excluir',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IndividuoFormScreen(
                            parcela: widget.parcela,
                            estrato: widget.estrato,
                            individuo: individuo,
                            subParcela: _hasSubParcelas ? _currentSubParcela : 1,
                          ),
                        ),
                      ).then((_) => _loadIndividuos());
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividuoFormScreen(
                parcela: widget.parcela,
                estrato: widget.estrato,
                subParcela: _hasSubParcelas ? _currentSubParcela : 1,
              ),
            ),
          ).then((_) => _loadIndividuos());
        },
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_isFloristica ? 'Nova Espécie' : 'Novo Indivíduo'),
      ),
    );
  }

  Widget _buildFloristicaSubtitle(Individuo individuo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (individuo.nomeCientifico.isNotEmpty)
          Text(
            individuo.nomeCientifico,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        if (individuo.familia.isNotEmpty)
          Text(
            'Família: ${individuo.familia}',
            style: const TextStyle(fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildHerbaceoSubtitle(Individuo individuo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (individuo.numeroIndividuos != null)
          Text(
            widget.parcela.fisionomia == 'Campo Rupestre'
                ? '% Cobertura: ${individuo.numeroIndividuos}%'
                : 'Nº Indivíduos: ${individuo.numeroIndividuos}',
            style: const TextStyle(fontSize: 12),
          ),
        if (individuo.nomeCientifico.isNotEmpty)
          Text(
            individuo.nomeCientifico,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        if (individuo.familia.isNotEmpty)
          Text(
            'Família: ${individuo.familia}',
            style: const TextStyle(fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildArboreoSubtitle(Individuo individuo, List<Fuste> fustes,
      double mediaAltura, double mediaCap) {
    final requiresDiametroCopa =
        (widget.parcela.fisionomia == 'Cerrado' && widget.estrato == 'Arbóreo') ||
        (widget.parcela.fisionomia == 'Campo Rupestre' &&
            (widget.estrato == 'Arbóreo' || widget.estrato == 'Arbustivo')) ||
        (widget.parcela.metodo == 'Censo' && (widget.estrato == 'Arbóreo' || widget.estrato == 'Censo') &&
            (widget.parcela.fisionomia == 'Cerrado' || widget.parcela.fisionomia == 'Campo Rupestre' || widget.parcela.fisionomia == 'Árvores isoladas'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (individuo.nomeCientifico.isNotEmpty)
          Text(
            individuo.nomeCientifico,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        if (individuo.familia.isNotEmpty)
          Text(
            'Família: ${individuo.familia}',
            style: const TextStyle(fontSize: 12),
          ),
        Text(
          'Fustes: ${fustes.length} | '
          'Altura méd: ${mediaAltura.toStringAsFixed(1)}m | '
          'CAP méd: ${mediaCap.toStringAsFixed(1)}cm',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        if (requiresDiametroCopa &&
            (individuo.diametroCopa1 != null || individuo.diametroCopa2 != null))
          Text(
            'Copa: ${individuo.diametroCopa1?.toStringAsFixed(1) ?? "-"}m × '
            '${individuo.diametroCopa2?.toStringAsFixed(1) ?? "-"}m',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
      ],
    );
  }
}
