part of 'fuste.dart';

class FusteAdapter extends TypeAdapter<Fuste> {
  @override
  final int typeId = 2;

  @override
  Fuste read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Fuste(
      id: fields[0] as String,
      individuoId: fields[1] as String,
      numeroFuste: fields[2] as int,
      altura: fields[3] as double,
      cap: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Fuste obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.individuoId)
      ..writeByte(2)
      ..write(obj.numeroFuste)
      ..writeByte(3)
      ..write(obj.altura)
      ..writeByte(4)
      ..write(obj.cap);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FusteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
