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
    );
  }

  @override
  void write(BinaryWriter writer, Parcela obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.metodo);
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
