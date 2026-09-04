import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/censo_sub_parcela.dart';
import '../models/parcela.dart';
import 'censo_sub_parcela_form_screen.dart';
import 'individuos_list_screen.dart';

class CensoSubParcelasListScreen extends StatefulWidget {
  final Parcela parcela;
  final String estrato;

  const CensoSubParcelasListScreen({
    super.key,
    required this.parcela,
    required this.estrato,
  });

  @override
  State<CensoSubParcelasListScreen> createState() =>
      _CensoSubParcelasListScreenState();
}

class _CensoSubParcelasListScreenState
    extends State<CensoSubParcelasListScreen> {
  List<CensoSubParcela> _subParcelas = [];

  @override
  void initState() {
    super.initState();
    _loadSubParcelas();
  }

  void _loadSubParcelas() {
    setState(() {
      _subParcelas = DatabaseHelper.instance
          .getCensoSubParcelas(widget.parcela.id, widget.estrato);
    });
  }

  Future<void> _deleteSubParcela(CensoSubParcela subParcela) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
            'Deseja excluir a sub-parcela "${subParcela.codigo}"?\nTodos os indivíduos desta sub-parcela também serão excluídos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteCensoSubParcela(subParcela.id);
      _loadSubParcelas();
    }
  }

  int _countIndividuos(int subParcelaIndex) {
    final allIndividuos =
        DatabaseHelper.instance.getIndividuosByParcela(widget.parcela.id);
    return allIndividuos
        .where((i) => i.estrato == widget.estrato && i.subParcela == subParcelaIndex)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final isArbustivo = widget.estrato == 'Arbustivo';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.parcela.nomeParcela),
            Text(
              '${isArbustivo ? '\uD83C\uDF3F' : '\uD83C\uDF31'} ${widget.estrato}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: _subParcelas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.landscape, size: 80, color: Colors.green[200]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma sub-parcela cadastrada',
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
              itemCount: _subParcelas.length,
              itemBuilder: (context, index) {
                final sub = _subParcelas[index];
                final count = _countIndividuos(index + 1);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      sub.codigo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy').format(sub.data)}${sub.tamanhoParcela != null ? ' · ${sub.tamanhoParcela}' : ''} · $count indivíduo${count != 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                                      CensoSubParcelaFormScreen(
                                    parcela: widget.parcela,
                                    estrato: widget.estrato,
                                    subParcela: sub,
                                  ),
                                ),
                              ).then((_) => _loadSubParcelas());
                            } else if (value == 'excluir') {
                              _deleteSubParcela(sub);
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
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IndividuosListScreen(
                            parcela: widget.parcela,
                            estrato: widget.estrato,
                            subParcelaFiltro: index + 1,
                          ),
                        ),
                      ).then((_) => _loadSubParcelas());
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
              builder: (context) => CensoSubParcelaFormScreen(
                parcela: widget.parcela,
                estrato: widget.estrato,
              ),
            ),
          ).then((_) => _loadSubParcelas());
        },
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Sub-parcela'),
      ),
    );
  }
}
