part of 'parcela.dart';

class ParcelaAdapter extends TypeAdapter<Parcela> {
  @override
  final int typeId = 0;

  @override
  Parcela read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Parcela(
      id: fields[0] as String,
      nomeParcela: fields[1] as String,
      fisionomia: fields[3] as String,
      dataColeta: fields[4] as DateTime,
      responsavel: fields[5] as String?,
      observacoes: fields[6] as String?,
      identificadorCampo: fields[7] as String?,
      metodo: fields[8] != null ? fields[8] as String : 'Parcela',
      tamanhoParcelaArboreo: fields[9] as double?,
      tamanhoParcelaArbustivo: fields[10] as double?,
      tamanhoParcelaHerbaceo: fields[11] as double?,
      localidade: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Parcela obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nomeParcela)
      ..writeByte(3)
      ..write(obj.fisionomia)
      ..writeByte(4)
      ..write(obj.dataColeta)
      ..writeByte(5)
      ..write(obj.responsavel)
      ..writeByte(6)
      ..write(obj.observacoes)
      ..writeByte(7)
      ..write(obj.identificadorCampo)
      ..writeByte(8)
      ..write(obj.metodo)
      ..writeByte(9)
      ..write(obj.tamanhoParcelaArboreo)
      ..writeByte(10)
      ..write(obj.tamanhoParcelaArbustivo)
      ..writeByte(11)
      ..write(obj.tamanhoParcelaHerbaceo)
      ..writeByte(12)
      ..write(obj.localidade);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParcelaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
