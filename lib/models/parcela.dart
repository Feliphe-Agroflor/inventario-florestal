import 'package:hive/hive.dart';

part 'parcela.g.dart';

@HiveType(typeId: 0)
class Parcela extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nomeParcela;

  @HiveField(3)
  String fisionomia;

  @HiveField(4)
  DateTime dataColeta;

  @HiveField(5)
  String? responsavel;

  @HiveField(6)
  String? observacoes;

  @HiveField(7)
  String? identificadorCampo;

  @HiveField(8)
  String metodo;

  @HiveField(9)
  double? tamanhoParcelaArboreo;

  @HiveField(10)
  double? tamanhoParcelaArbustivo;

  @HiveField(11)
  double? tamanhoParcelaHerbaceo;

  @HiveField(12)
  String? localidade;

  Parcela({
    required this.id,
    required this.nomeParcela,
    required this.fisionomia,
    required this.dataColeta,
    this.responsavel,
    this.observacoes,
    this.identificadorCampo,
    this.metodo = 'Parcela',
    this.tamanhoParcelaArboreo,
    this.tamanhoParcelaArbustivo,
    this.tamanhoParcelaHerbaceo,
    this.localidade,
  });
}
