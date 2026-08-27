import 'package:hive_flutter/hive_flutter.dart';
import '../models/parcela.dart';
import '../models/individuo.dart';
import '../models/fuste.dart';
import '../models/caracterizacao.dart';
import '../models/censo_sub_parcela.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const String _parcelasBox = 'parcelas';
  static const String _individuosBox = 'individuos';
  static const String _fustesBox = 'fustes';
  static const String _caracterizacoesBox = 'caracterizacoes';
  static const String _censoSubParcelasBox = 'censoSubParcelas';

  DatabaseHelper._init();

  Future<void> init() async {
    Hive.registerAdapter(ParcelaAdapter());
    Hive.registerAdapter(IndividuoAdapter());
    Hive.registerAdapter(FusteAdapter());
    Hive.registerAdapter(CaracterizacaoAdapter());
    Hive.registerAdapter(CensoSubParcelaAdapter());
    await Hive.openBox<Parcela>(_parcelasBox);
    await Hive.openBox<Individuo>(_individuosBox);
    await Hive.openBox<Fuste>(_fustesBox);
    await Hive.openBox<Caracterizacao>(_caracterizacoesBox);
    await Hive.openBox<CensoSubParcela>(_censoSubParcelasBox);
  }

  // CRUD Parcelas
  Future<void> insertParcela(Parcela parcela) async {
    final box = Hive.box<Parcela>(_parcelasBox);
    await box.put(parcela.id, parcela);
  }

  List<Parcela> getParcelas() {
    final box = Hive.box<Parcela>(_parcelasBox);
    final list = box.values.toList();
    list.sort((a, b) => b.dataColeta.compareTo(a.dataColeta));
    return list;
  }

  Parcela? getParcela(String id) {
    final box = Hive.box<Parcela>(_parcelasBox);
    return box.get(id);
  }

  Future<void> updateParcela(Parcela parcela) async {
    final box = Hive.box<Parcela>(_parcelasBox);
    await box.put(parcela.id, parcela);
  }

  Future<void> deleteParcela(String id) async {
    final box = Hive.box<Parcela>(_parcelasBox);
    final individuos = getIndividuosByParcela(id);
    for (var ind in individuos) {
      await deleteIndividuo(ind.id);
    }
    await deleteCaracterizacaoByParcela(id);
    await box.delete(id);
  }

  // CRUD Indivíduos
  Future<void> insertIndividuo(Individuo individuo) async {
    final box = Hive.box<Individuo>(_individuosBox);
    await box.put(individuo.id, individuo);
  }

  List<Individuo> getIndividuosByParcela(String parcelaId) {
    final box = Hive.box<Individuo>(_individuosBox);
    final list = box.values.where((i) => i.parcelaId == parcelaId).toList();
    list.sort((a, b) => a.numero.compareTo(b.numero));
    return list;
  }

  List<Individuo> getIndividuosByParcelaEstratoSubParcela(
      String parcelaId, String estrato, int subParcela) {
    final box = Hive.box<Individuo>(_individuosBox);
    final list = box.values
        .where((i) =>
            i.parcelaId == parcelaId &&
            i.estrato == estrato &&
            i.subParcela == subParcela)
        .toList();
    list.sort((a, b) => a.numero.compareTo(b.numero));
    return list;
  }

  Individuo? getIndividuo(String id) {
    final box = Hive.box<Individuo>(_individuosBox);
    return box.get(id);
  }

  Future<void> updateIndividuo(Individuo individuo) async {
    final box = Hive.box<Individuo>(_individuosBox);
    await box.put(individuo.id, individuo);
  }

  Future<void> deleteIndividuo(String id) async {
    final fustes = getFustesByIndividuo(id);
    for (var f in fustes) {
      await deleteFuste(f.id);
    }
    final box = Hive.box<Individuo>(_individuosBox);
    await box.delete(id);
  }

  int getNextIndividuoNumero(String parcelaId, String estrato) {
    final individuos = getIndividuosByParcela(parcelaId)
        .where((i) => i.estrato == estrato)
        .toList();
    if (individuos.isEmpty) return 1;
    return individuos.map((i) => i.numero).reduce((a, b) => a > b ? a : b) + 1;
  }

  // CRUD Fustes
  Future<void> insertFuste(Fuste fuste) async {
    final box = Hive.box<Fuste>(_fustesBox);
    await box.put(fuste.id, fuste);
  }

  List<Fuste> getFustesByIndividuo(String individuoId) {
    final box = Hive.box<Fuste>(_fustesBox);
    final list = box.values.where((f) => f.individuoId == individuoId).toList();
    list.sort((a, b) => a.numeroFuste.compareTo(b.numeroFuste));
    return list;
  }

  Future<void> deleteFuste(String id) async {
    final box = Hive.box<Fuste>(_fustesBox);
    await box.delete(id);
  }

  Future<void> deleteFustesByIndividuo(String individuoId) async {
    final box = Hive.box<Fuste>(_fustesBox);
    final keys = box.values
        .where((f) => f.individuoId == individuoId)
        .map((f) => f.id)
        .toList();
    for (var key in keys) {
      await box.delete(key);
    }
  }

  // CRUD Caracterização
  Future<void> insertCaracterizacao(Caracterizacao caracterizacao) async {
    final box = Hive.box<Caracterizacao>(_caracterizacoesBox);
    await box.put(caracterizacao.id, caracterizacao);
  }

  Caracterizacao? getCaracterizacaoByParcela(String parcelaId) {
    final box = Hive.box<Caracterizacao>(_caracterizacoesBox);
    try {
      return box.values.firstWhere((c) => c.parcelaId == parcelaId);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCaracterizacaoByParcela(String parcelaId) async {
    final box = Hive.box<Caracterizacao>(_caracterizacoesBox);
    final keys = box.values
        .where((c) => c.parcelaId == parcelaId)
        .map((c) => c.id)
        .toList();
    for (var key in keys) {
      await box.delete(key);
    }
  }

  // Buscar nomes únicos para autocomplete
  List<String> getNomesComuns() {
    final box = Hive.box<Individuo>(_individuosBox);
    final nomes = box.values.map((i) => i.nomeComum).toSet().toList();
    nomes.sort();
    return nomes;
  }

  List<String> getNomesCientificos() {
    final box = Hive.box<Individuo>(_individuosBox);
    final nomes = box.values.map((i) => i.nomeCientifico).toSet().toList();
    nomes.sort();
    return nomes;
  }

  List<String> getFamilias() {
    final box = Hive.box<Individuo>(_individuosBox);
    final nomes = box.values.map((i) => i.familia).toSet().toList();
    nomes.sort();
    return nomes;
  }

  List<String> getResponsaveis() {
    final box = Hive.box<Parcela>(_parcelasBox);
    final nomes = box.values
        .where((p) => p.responsavel != null && p.responsavel!.isNotEmpty)
        .map((p) => p.responsavel!)
        .toSet()
        .toList();
    nomes.sort();
    return nomes;
  }

  List<String> getIdentificadores() {
    final box = Hive.box<Parcela>(_parcelasBox);
    final nomes = box.values
        .where((p) => p.identificadorCampo != null && p.identificadorCampo!.isNotEmpty)
        .map((p) => p.identificadorCampo!)
        .toSet()
        .toList();
    nomes.sort();
    return nomes;
  }

  // CRUD CensoSubParcelas
  Future<void> insertCensoSubParcela(CensoSubParcela subParcela) async {
    final box = Hive.box<CensoSubParcela>(_censoSubParcelasBox);
    await box.put(subParcela.id, subParcela);
  }

  List<CensoSubParcela> getCensoSubParcelas(String parcelaId, String estrato) {
    final box = Hive.box<CensoSubParcela>(_censoSubParcelasBox);
    final list = box.values
        .where((sp) => sp.parcelaId == parcelaId && sp.estrato == estrato)
        .toList();
    list.sort((a, b) => a.codigo.compareTo(b.codigo));
    return list;
  }

  Future<void> deleteCensoSubParcela(String id) async {
    final box = Hive.box<CensoSubParcela>(_censoSubParcelasBox);
    await box.delete(id);
  }

  Future<void> updateCensoSubParcela(CensoSubParcela subParcela) async {
    final box = Hive.box<CensoSubParcela>(_censoSubParcelasBox);
    await box.put(subParcela.id, subParcela);
  }
}
