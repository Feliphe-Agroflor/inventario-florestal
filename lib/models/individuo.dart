import 'package:hive/hive.dart';

part 'individuo.g.dart';

@HiveType(typeId: 1)
class Individuo extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String parcelaId;

  @HiveField(2)
  int numero;

  @HiveField(3)
  String nomeComum;

  @HiveField(4)
  String nomeCientifico;

  @HiveField(5)
  String familia;

  @HiveField(6)
  DateTime dataColeta;

  @HiveField(7)
  String? observacoes;

  @HiveField(8)
  List<String> fotos;

  @HiveField(9)
  String estrato;

  @HiveField(10)
  int? numeroIndividuos;

  @HiveField(11)
  double? diametroCopa1;

  @HiveField(12)
  double? diametroCopa2;

  @HiveField(13)
  int subParcela;

  @HiveField(14)
  int? numeroGps;

  Individuo({
    required this.id,
    required this.parcelaId,
    required this.numero,
    this.nomeComum = '',
    this.nomeCientifico = '',
    this.familia = '',
    required this.dataColeta,
    this.observacoes,
    this.fotos = const [],
    this.estrato = 'Arbóreo',
    this.numeroIndividuos,
    this.diametroCopa1,
    this.diametroCopa2,
    this.subParcela = 1,
    this.numeroGps,
  });
}
