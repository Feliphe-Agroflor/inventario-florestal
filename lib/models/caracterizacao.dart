import 'package:hive/hive.dart';

part 'caracterizacao.g.dart';

@HiveType(typeId: 3)
class Caracterizacao extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String parcelaId;

  @HiveField(2)
  String usoPrevio;

  @HiveField(3)
  int numeroEstratos;

  @HiveField(4)
  int epifitas;

  @HiveField(5)
  int orquideas;

  @HiveField(6)
  int bromelias;

  @HiveField(7)
  int musgosLiquens;

  @HiveField(8)
  int serapilheira;

  @HiveField(9)
  int trepadeirasLenhosas;

  @HiveField(10)
  int trepadeirasHerbaceas;

  @HiveField(11)
  int densidadeArbustos;

  @HiveField(12)
  String relevo;

  @HiveField(13)
  String antropizacao;

  @HiveField(14)
  String? observacoes;

  @HiveField(15)
  int historicoUso;

  @HiveField(16)
  int coberturaVegetal;

  @HiveField(17)
  String tipoSubstrato;

  @HiveField(18)
  String geoambiente;

  @HiveField(19)
  String especiesLenhosas;

  @HiveField(20)
  int pressaoExterna;

  @HiveField(21)
  int coberturaHerbaceoArbustiva;

  @HiveField(22)
  int soloExposto;

  @HiveField(23)
  int coberturaSerapilheira;

  @HiveField(24)
  String antropizacaoTipo;

  @HiveField(25)
  String? antropizacaoTipoOutro;

  @HiveField(26)
  int antropizacaoIntensidade;

  @HiveField(27)
  String fitofisionomia;

  @HiveField(28)
  String? fitofisionomiaOutro;

  Caracterizacao({
    required this.id,
    required this.parcelaId,
    this.usoPrevio = '',
    this.numeroEstratos = 0,
    this.epifitas = 0,
    this.orquideas = 0,
    this.bromelias = 0,
    this.musgosLiquens = 0,
    this.serapilheira = 0,
    this.trepadeirasLenhosas = 0,
    this.trepadeirasHerbaceas = 0,
    this.densidadeArbustos = 0,
    this.relevo = '',
    this.antropizacao = '',
    this.observacoes,
    this.historicoUso = 0,
    this.coberturaVegetal = 0,
    this.tipoSubstrato = '',
    this.geoambiente = '',
    this.especiesLenhosas = '',
    this.pressaoExterna = 0,
    this.coberturaHerbaceoArbustiva = 0,
    this.soloExposto = 0,
    this.coberturaSerapilheira = 0,
    this.antropizacaoTipo = '',
    this.antropizacaoTipoOutro,
    this.antropizacaoIntensidade = 0,
    this.fitofisionomia = '',
    this.fitofisionomiaOutro,
  });

  static String getLabel(int value) {
    switch (value) {
      case 1:
        return 'Ausente';
      case 2:
        return 'Poucas';
      case 3:
        return 'Moderada';
      case 4:
        return 'Abundante';
      default:
        return '-';
    }
  }

  static String getEstratosLabel(int value) {
    switch (value) {
      case 0:
        return 'Ausente';
      case 1:
        return 'Dossel e sub-bosque';
      case 2:
        return 'Dossel, sub-dossel e sub-bosque';
      default:
        return '-';
    }
  }
}
