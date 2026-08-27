import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/parcela.dart';
import 'parcela_form_screen.dart';
import 'individuos_list_screen.dart';
import 'export_screen.dart';
import 'caracterizacao_screen.dart';
import 'censo_sub_parcelas_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Parcela> _parcelas = [];
  final Set<String> _expandedParcelas = {};

  @override
  void initState() {
    super.initState();
    _loadParcelas();
  }

  void _loadParcelas() {
    setState(() {
      _parcelas = DatabaseHelper.instance.getParcelas();
    });
  }

  Future<void> _deleteParcela(Parcela parcela) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
            'Deseja excluir o registro "${parcela.nomeParcela}"?\nTodos os indivíduos e fustes também serão excluídos.'),
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
      await DatabaseHelper.instance.deleteParcela(parcela.id);
      _loadParcelas();
    }
  }

  String _getFisionomiaEmoji(String fisionomia) {
    switch (fisionomia) {
      case 'Floresta Estacional Semidecidual':
        return '\uD83C\uDF32';
      case 'Cerrado':
        return '\uD83C\uDF3E';
      case 'Capão':
        return '\uD83C\uDF33';
      case 'Campo Rupestre':
        return '\u26F0\uFE0F';
      default:
        return '\uD83C\uDF3F';
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

  int _countIndividuos(String parcelaId, String estrato) {
    final individuos = DatabaseHelper.instance.getIndividuosByParcela(parcelaId);
    return individuos.where((i) => i.estrato == estrato).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventário Florestal'),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exportar dados',
            onPressed: _parcelas.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ExportScreen()),
                    ).then((_) => _loadParcelas());
                  },
          ),
        ],
      ),
      body: _parcelas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forest, size: 80, color: Colors.green[200]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum registro cadastrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque no botão + para criar um novo registro',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _parcelas.length,
              itemBuilder: (context, index) {
                final parcela = _parcelas[index];
                final isExpanded = _expandedParcelas.contains(parcela.id);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Text(
                            _getFisionomiaEmoji(parcela.fisionomia),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        title: Text(
                          parcela.metodo == 'Florística caminhamento'
                              ? 'Florística'
                              : parcela.metodo == 'Censo'
                                  ? 'Censo'
                                  : parcela.nomeParcela,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${parcela.identificadorCampo != null ? "${parcela.identificadorCampo} | " : ""}${_getFisionomiaEmoji(parcela.fisionomia)} ${parcela.fisionomia}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'editar') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ParcelaFormScreen(parcela: parcela),
                                    ),
                                  ).then((_) => _loadParcelas());
                                } else if (value == 'excluir') {
                                  _deleteParcela(parcela);
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
                                    leading:
                                        Icon(Icons.delete, color: Colors.red),
                                    title: Text('Excluir',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedParcelas.remove(parcela.id);
                                  } else {
                                    _expandedParcelas.add(parcela.id);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedParcelas.remove(parcela.id);
                            } else {
                              _expandedParcelas.add(parcela.id);
                            }
                          });
                        },
                      ),
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        if (parcela.metodo != 'Censo')
                          _buildCaracterizacaoTile(parcela),
                        if (parcela.metodo == 'Florística caminhamento')
                          _buildEstratoTile(
                            parcela,
                            'Florística',
                            '\uD83C\uDF3F',
                            Icons.grass,
                          )
                        else if (parcela.metodo == 'Censo') ...[
                          _buildEstratoTile(
                            parcela,
                            'Censo',
                            '\uD83C\uDF33',
                            Icons.forest,
                          ),
                          _buildEstratoTile(
                            parcela,
                            'Arbustivo',
                            '\uD83C\uDF3F',
                            Icons.grass,
                          ),
                          _buildEstratoTile(
                            parcela,
                            'Herbáceo',
                            '\uD83C\uDF31',
                            Icons.eco,
                          ),
                        ]
                        else ...[
                          _buildEstratoTile(
                            parcela,
                            'Arbóreo',
                            '\uD83C\uDF32',
                            Icons.forest,
                          ),
                          _buildEstratoTile(
                            parcela,
                            'Arbustivo',
                            '\uD83C\uDF3F',
                            Icons.grass,
                          ),
                          _buildEstratoTile(
                            parcela,
                            'Herbáceo',
                            '\uD83C\uDF31',
                            Icons.eco,
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ParcelaFormScreen()),
          ).then((_) => _loadParcelas());
        },
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo registro'),
      ),
    );
  }

  Widget _buildCaracterizacaoTile(Parcela parcela) {
    final caracterizacao =
        DatabaseHelper.instance.getCaracterizacaoByParcela(parcela.id);
    final hasData = caracterizacao != null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(Icons.description, color: Colors.blue[700], size: 28),
      title: const Text(
        '\uD83D\uDCCB Caracterização',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        hasData ? 'Preenchida' : 'Não preenchida',
        style: TextStyle(
          color: hasData ? Colors.green[600] : Colors.orange[600],
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CaracterizacaoScreen(parcelaId: parcela.id, fisionomia: parcela.fisionomia),
          ),
        ).then((_) => _loadParcelas());
      },
    );
  }

  Widget _buildEstratoTile(
    Parcela parcela,
    String estrato,
    String emoji,
    IconData icon,
  ) {
    final count = _countIndividuos(parcela.id, estrato);
    final isCensoSubParcela = parcela.metodo == 'Censo' &&
        (estrato == 'Arbustivo' || estrato == 'Herbáceo');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: Colors.green[700], size: 28),
      title: Text(
        '$emoji $estrato',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        isCensoSubParcela
            ? 'Toque para gerenciar sub-parcelas'
            : '$count indivíduo${count != 1 ? 's' : ''}',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (isCensoSubParcela) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CensoSubParcelasListScreen(
                parcela: parcela,
                estrato: estrato,
              ),
            ),
          ).then((_) => _loadParcelas());
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividuosListScreen(
                parcela: parcela,
                estrato: estrato,
              ),
            ),
          ).then((_) => _loadParcelas());
        }
      },
    );
  }
}
