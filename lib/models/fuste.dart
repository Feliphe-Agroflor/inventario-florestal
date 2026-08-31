import 'package:hive/hive.dart';

part 'fuste.g.dart';

@HiveType(typeId: 2)
class Fuste extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String individuoId;

  @HiveField(2)
  int numeroFuste;

  @HiveField(3)
  double altura;

  @HiveField(4)
  double cap;

  @HiveField(5)
  bool? epifitas;

  @HiveField(6)
  String? epifitasDetalhes;

  Fuste({
    required this.id,
    required this.individuoId,
    required this.numeroFuste,
    required this.altura,
    required this.cap,
    this.epifitas,
    this.epifitasDetalhes,
  });

  double get dap => cap / 3.14159265359;
}
