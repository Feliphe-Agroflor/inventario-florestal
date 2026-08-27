part of 'censo_sub_parcela.dart';

class CensoSubParcelaAdapter extends TypeAdapter<CensoSubParcela> {
  @override
  final int typeId = 4;

  @override
  CensoSubParcela read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CensoSubParcela(
      id: fields[0] as String,
      parcelaId: fields[1] as String,
      estrato: fields[2] as String,
      codigo: fields[3] as String,
      data: fields[4] as DateTime,
      observacoes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CensoSubParcela obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parcelaId)
      ..writeByte(2)
      ..write(obj.estrato)
      ..writeByte(3)
      ..write(obj.codigo)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.observacoes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CensoSubParcelaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
