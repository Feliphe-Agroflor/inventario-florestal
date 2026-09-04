import 'package:hive/hive.dart';

part 'censo_sub_parcela.g.dart';

@HiveType(typeId: 4)
class CensoSubParcela extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String parcelaId;

  @HiveField(2)
  String estrato;

  @HiveField(3)
  String codigo;

  @HiveField(4)
  DateTime data;

  @HiveField(5)
  String? observacoes;

  @HiveField(6)
  String? tamanhoParcela;

  CensoSubParcela({
    required this.id,
    required this.parcelaId,
    required this.estrato,
    required this.codigo,
    required this.data,
    this.observacoes,
    this.tamanhoParcela,
  });
}
