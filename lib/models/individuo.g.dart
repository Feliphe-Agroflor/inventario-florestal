part of 'individuo.dart';

class IndividuoAdapter extends TypeAdapter<Individuo> {
  @override
  final int typeId = 1;

  @override
  Individuo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Compatibilidade: campo 9 antigo era nomeEspecie (String?), agora é estrato (String)
    String estrato;
    if (fields.containsKey(9) && fields[9] != null) {
      final val = fields[9];
      if (val is String && ['Arbóreo', 'Arbustivo', 'Herbáceo'].contains(val)) {
        estrato = val;
      } else {
        estrato = 'Arbóreo';
      }
    } else {
      estrato = 'Arbóreo';
    }

    return Individuo(
      id: fields[0] as String,
      parcelaId: fields[1] as String,
      numero: fields[2] as int,
      nomeComum: fields[3] as String,
      nomeCientifico: fields[4] as String,
      familia: fields[5] as String,
      dataColeta: fields[6] as DateTime,
      observacoes: fields[7] as String?,
      fotos: fields[8] != null ? List<String>.from(fields[8] as List) : [],
      estrato: estrato,
      numeroIndividuos: fields[10] as int?,
      diametroCopa1: fields[11] as double?,
      diametroCopa2: fields[12] as double?,
      subParcela: fields[13] != null ? fields[13] as int : 1,
      numeroGps: fields[14] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Individuo obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parcelaId)
      ..writeByte(2)
      ..write(obj.numero)
      ..writeByte(3)
      ..write(obj.nomeComum)
      ..writeByte(4)
      ..write(obj.nomeCientifico)
      ..writeByte(5)
      ..write(obj.familia)
      ..writeByte(6)
      ..write(obj.dataColeta)
      ..writeByte(7)
      ..write(obj.observacoes)
      ..writeByte(8)
      ..write(obj.fotos)
      ..writeByte(9)
      ..write(obj.estrato)
      ..writeByte(10)
      ..write(obj.numeroIndividuos)
      ..writeByte(11)
      ..write(obj.diametroCopa1)
      ..writeByte(12)
      ..write(obj.diametroCopa2)
      ..writeByte(13)
      ..write(obj.subParcela)
      ..writeByte(14)
      ..write(obj.numeroGps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndividuoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
