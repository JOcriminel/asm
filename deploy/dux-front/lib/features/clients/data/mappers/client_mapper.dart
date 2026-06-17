import 'package:intl/intl.dart';
import '../../domain/models/client.dart';
import '../models/client_dto.dart';

class ClientMapper {
  static Client toEntity(ClientDto dto) {
    int? nbDoc;
    if (dto.nbDoc != null) {
      if (dto.nbDoc is int) {
        nbDoc = dto.nbDoc;
      } else if (dto.nbDoc is String) {
        nbDoc = int.tryParse(dto.nbDoc as String);
      }
    }

    DateTime? dateCreation;
    if (dto.dateCreation != null && dto.dateCreation!.isNotEmpty) {
      try {
        final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
        dateCreation = formatter.parse(dto.dateCreation!.split('.').first);
      } catch (_) {}
    }

    return Client(
      id: dto.id ?? '',
      code: dto.code ?? '',
      nomPrenom: dto.nomPrenom ?? '',
      nomPrenomEdit: dto.nomPrenomEdit,
      tel: dto.tel,
      mail: dto.mail,
      adresse: dto.adresse,
      ville: dto.ville,
      pays: dto.pays,
      matriculeFiscal: dto.matriculeFiscal,
      secteur: dto.secteur,
      stationLibelle: dto.stationLibelle,
      devise: dto.devise,
      nbDoc: nbDoc,
      dateCreation: dateCreation,
    );
  }
}
