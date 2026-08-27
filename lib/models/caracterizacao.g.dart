part of 'caracterizacao.dart';

class CaracterizacaoAdapter extends TypeAdapter<Caracterizacao> {
  @override
  final int typeId = 3;

  @override
  Caracterizacao read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Caracterizacao(
      id: fields[0] as String,
      parcelaId: fields[1] as String,
      usoPrevio: fields[2] as String,
      numeroEstratos: fields[3] as int,
      epifitas: fields[4] as int,
      orquideas: fields[5] as int,
      bromelias: fields[6] as int,
      musgosLiquens: fields[7] as int,
      serapilheira: fields[8] as int,
      trepadeirasLenhosas: fields[9] as int,
      trepadeirasHerbaceas: fields[10] as int,
      densidadeArbustos: fields[11] as int,
      relevo: fields[12] as String,
      antropizacao: fields[13] as String,
      observacoes: fields[14] as String?,
      historicoUso: fields[15] != null ? fields[15] as int : 0,
      coberturaVegetal: fields[16] != null ? fields[16] as int : 0,
      tipoSubstrato: fields[17] != null ? fields[17] as String : '',
      geoambiente: fields[18] != null ? fields[18] as String : '',
      especiesLenhosas: fields[19] != null ? fields[19] as String : '',
      pressaoExterna: fields[20] != null ? fields[20] as int : 0,
      coberturaHerbaceoArbustiva: fields[21] != null ? fields[21] as int : 0,
      soloExposto: fields[22] != null ? fields[22] as int : 0,
      coberturaSerapilheira: fields[23] != null ? fields[23] as int : 0,
      antropizacaoTipo: fields[24] != null ? fields[24] as String : '',
      antropizacaoTipoOutro: fields[25] as String?,
      antropizacaoIntensidade: fields[26] != null ? fields[26] as int : 0,
      fitofisionomia: fields[27] != null ? fields[27] as String : '',
      fitofisionomiaOutro: fields[28] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Caracterizacao obj) {
    writer
      ..writeByte(29)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parcelaId)
      ..writeByte(2)
      ..write(obj.usoPrevio)
      ..writeByte(3)
      ..write(obj.numeroEstratos)
      ..writeByte(4)
      ..write(obj.epifitas)
      ..writeByte(5)
      ..write(obj.orquideas)
      ..writeByte(6)
      ..write(obj.bromelias)
      ..writeByte(7)
      ..write(obj.musgosLiquens)
      ..writeByte(8)
      ..write(obj.serapilheira)
      ..writeByte(9)
      ..write(obj.trepadeirasLenhosas)
      ..writeByte(10)
      ..write(obj.trepadeirasHerbaceas)
      ..writeByte(11)
      ..write(obj.densidadeArbustos)
      ..writeByte(12)
      ..write(obj.relevo)
      ..writeByte(13)
      ..write(obj.antropizacao)
      ..writeByte(14)
      ..write(obj.observacoes)
      ..writeByte(15)
      ..write(obj.historicoUso)
      ..writeByte(16)
      ..write(obj.coberturaVegetal)
      ..writeByte(17)
      ..write(obj.tipoSubstrato)
      ..writeByte(18)
      ..write(obj.geoambiente)
      ..writeByte(19)
      ..write(obj.especiesLenhosas)
      ..writeByte(20)
      ..write(obj.pressaoExterna)
      ..writeByte(21)
      ..write(obj.coberturaHerbaceoArbustiva)
      ..writeByte(22)
      ..write(obj.soloExposto)
      ..writeByte(23)
      ..write(obj.coberturaSerapilheira)
      ..writeByte(24)
      ..write(obj.antropizacaoTipo)
      ..writeByte(25)
      ..write(obj.antropizacaoTipoOutro)
      ..writeByte(26)
      ..write(obj.antropizacaoIntensidade)
      ..writeByte(27)
      ..write(obj.fitofisionomia)
      ..writeByte(28)
      ..write(obj.fitofisionomiaOutro);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaracterizacaoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
