import 'package:flutter/material.dart';
import '../models/parcela.dart';
import 'individuos_spreadsheet_screen.dart';

class IndividuosListScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return IndividuosSpreadsheetScreen(
      parcela: parcela,
      estrato: estrato,
      subParcelaFiltro: subParcelaFiltro,
    );
  }
}
