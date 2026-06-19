class ChecklistGroup {
  final int? id;
  final String name;

  ChecklistGroup({this.id, required this.name});

  factory ChecklistGroup.fromJson(Map<String, dynamic> json) {
    return ChecklistGroup(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class ChecklistFamilyMapping {
  final int? id;
  final String codeFamille;
  final ChecklistGroup? group;

  ChecklistFamilyMapping({this.id, required this.codeFamille, this.group});

  factory ChecklistFamilyMapping.fromJson(Map<String, dynamic> json) {
    return ChecklistFamilyMapping(
      id: json['id'],
      codeFamille: json['codeFamille'],
      group: json['group'] != null ? ChecklistGroup.fromJson(json['group']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codeFamille': codeFamille,
    };
  }
}

class ChecklistTaskType {
  final int? id;
  final String name;
  final String? information;

  ChecklistTaskType({this.id, required this.name, this.information});

  factory ChecklistTaskType.fromJson(Map<String, dynamic> json) {
    return ChecklistTaskType(
      id: json['id'],
      name: json['name'],
      information: json['information'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'information': information,
    };
  }
}

class ChecklistTask {
  final int? id;
  final String nomTache;
  final ChecklistTaskType? type;
  final ChecklistGroup? group;
  final String? codeFamille;
  final bool active;
  final String? information;

  ChecklistTask({this.id, required this.nomTache, this.type, this.group, this.codeFamille, this.active = true, this.information});

  factory ChecklistTask.fromJson(Map<String, dynamic> json) {
    return ChecklistTask(
      id: json['id'],
      nomTache: json['nomTache'],
      type: json['type'] != null ? ChecklistTaskType.fromJson(json['type']) : null,
      group: json['group'] != null ? ChecklistGroup.fromJson(json['group']) : null,
      codeFamille: json['codeFamille'],
      active: json['active'] ?? true,
      information: json['information'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomTache': nomTache,
      'codeFamille': codeFamille,
      'active': active,
      'information': information,
    };
  }
}

class ChecklistResponse {
  final int? id;
  final String idLigneDocument;
  final ChecklistTask? task;
  final bool isChecked;
  final String? dateChecked;
  final String? note;
  final String? dateNote;
  final String? checkedBy;

  ChecklistResponse({
    this.id,
    required this.idLigneDocument,
    this.task,
    required this.isChecked,
    this.dateChecked,
    this.note,
    this.dateNote,
    this.checkedBy,
  });

  factory ChecklistResponse.fromJson(Map<String, dynamic> json) {
    return ChecklistResponse(
      id: json['id'],
      idLigneDocument: json['idLigneDocument'],
      task: json['task'] != null ? ChecklistTask.fromJson(json['task']) : null,
      isChecked: json['isChecked'] ?? false,
      dateChecked: json['dateChecked'],
      note: json['note'],
      dateNote: json['dateNote'],
      checkedBy: json['checkedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idLigneDocument': idLigneDocument,
      'isChecked': isChecked,
      'note': note,
      'dateNote': dateNote,
      'checkedBy': checkedBy,
    };
  }
}
class ErpFamily {
  final String code;
  final String libelle;

  ErpFamily({required this.code, required this.libelle});

  factory ErpFamily.fromJson(Map<String, dynamic> json) {
    return ErpFamily(
      code: json['code']?.toString() ?? json['id']?.toString() ?? '',
      libelle: json['libelle']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}
