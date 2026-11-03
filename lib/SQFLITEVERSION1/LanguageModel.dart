// Language Model
class LanguageModel {
  final int nLanguageID;
  final String cLanguageName;
  

  LanguageModel({
    required this.nLanguageID,
    required this.cLanguageName,
  
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      nLanguageID: json['nLanguageID'],
      cLanguageName: json['cLanguageName'],
      
    );
  }

  factory LanguageModel.fromMap(Map<String, dynamic> map) {
    return LanguageModel(
      nLanguageID: map['nLanguageID'],
      cLanguageName: map['cLanguageName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nLanguageID': nLanguageID,
      'cLanguageName': cLanguageName,
    };
  }
}