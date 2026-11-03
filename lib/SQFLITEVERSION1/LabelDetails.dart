// Label Details Model
class LabelDetails {
  final int nDeviseEnvironmentID;
  final int nLabelLanguageMasterID;
  final int nCommunityID;
  final int nPageID;
  final int nLabelID;
  final int nLanguageID;
  final String cLabelKey;
  final int nUserTypeID;
 

  LabelDetails({
    required this.nCommunityID,
    required this.nPageID,
    required this.nLabelID,
    required this.nLanguageID,
    required this.cLabelKey,
    required this.nLabelLanguageMasterID, 
    required this.nDeviseEnvironmentID,
    required this.nUserTypeID,
    
  });

  Map<String, dynamic> toMap() {
    return {
      'nLabelLanguageMasterID': nLabelLanguageMasterID,
      'nLanguageID': nLanguageID,
      'nCommunityID': nCommunityID,
      'nDeviseEnvironmentID': nDeviseEnvironmentID,
      'nPageID': nPageID,
      'nLabelID': nLabelID,
      'cLabelKey': cLabelKey,
      'nUserType':nUserTypeID,
     
    };
  }
}