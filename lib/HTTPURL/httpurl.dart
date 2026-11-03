
String baseUrl = 'https://lv4hfxvb-7000.inc1.devtunnels.ms/';

//String baseUrl = 'https://api.koottaayma.in/';


//if we change the base url also change in the network_security_config.xml file

String GetLanguages='${baseUrl}fetchlanguagedetails/';//get
String GetLanguageLabels='${baseUrl}getlabeldetails/';//post


String GuestRegitrationDetails='${baseUrl}guestdetails/checkdetails/';//post guest details+ church and district
String GuestDropdownSelection='${baseUrl}guestdetails/getchurch/';//get church and district from dropdown

String VerifyUserPhoneNUmber='${baseUrl}verifyusers/';//post
String FamilyMemberDetails='${baseUrl}memberdetails/familydetailsgetphonenumber/';
//FamilyMemberDetails===>(post give the phone number then the response is placed in the ui design of the account page)
String AudioDetails='${baseUrl}notifications/addgospelreading/';//get
String SaveAttendance='${baseUrl}sundayschool/addsundayclassattendance/';//post(memberid=>passing)
String SundaySchoolStudentsList='${baseUrl}sundayschool/getsundayclasslistdetails/';//post(phoneno=>passinf )
String GetAbsentees='${baseUrl}sundayschool/getattendance/';



String NotificationsList='${baseUrl}sacraments/requestbaptismdetailsget/';//post phone no to get datas
String presidentapprovalAPI='${baseUrl}sacraments/presidentapproval/';//Directly to the code because
                                                                   // the baptisumrequestid is passed to the api
String PresidentRejectionAPI='${baseUrl}sacraments/presidentrejection/';
String PriestBaptisumRequestDetails='${baseUrl}sacraments/getbaptismrequest/';//get api
//String PriestBaptisumCertificategenerate='${baseUrl}sacraments/addbaptismcertificate/';//get and post is same
String PriestMeetingRequest='${baseUrl}sacraments/addbaptismmeeting/';
String PriestProfilePage='${baseUrl}churchdetails/allpriestdetails/';
String FamilyWelfareAPI='${baseUrl}familywelfare/familywelfare/';
String FamilyMemberMedicalDetails='${baseUrl}familywelfare/medicaldetails/';
String GetBaptisumRequestData='${baseUrl}sacraments/getrequestbaptismmember/';//myrequest page//postapi
String DailyRequestAPI='${baseUrl}sacramentsdetails/memberrequest/';//(post both eucharist and the confession

//DailyRequestAPI in this api is used same in get and post
String BibleReadingsAPI='${baseUrl}notifications/addedreadings/';//get data
String HolyMassAPI='${baseUrl}holymass/addholymasstiming/';//get data
String SpecialProgramsAPI=  '${baseUrl}notifications/addspecialprograms/'; //GET DATA
String InterestRequestAPI='${baseUrl}holymass/addinterestprograms/';//POST DATA
String ConnectChurchGetAPI='${baseUrl}churchdetails/viewchurchforselection/';//get church name and placing
String ConnectChurchSelectionAPI='${baseUrl}holymass/selectedchurchdetails/';//post  selcet church to pass the church idand phone no
String GroupAPI='${baseUrl}groups/getmemberbasedongroups/';//get groups
String GroupProgrammeAPI='${baseUrl}groups/getprogrammeewithgroup/';//post api to fetch all programs
String CalenderEventsAPI='${baseUrl}notifications/addcalendarevents/';//get calender details
String SaintAPI='${baseUrl}saints/getallsaintmaster/';//get all saint details

// BETSEIDHA
String BetseidhaGuestGet='${baseUrl}churchdetails/guestapproval/';//get betseidha guest details getting
String BetseidhaGuestApproval='${baseUrl}churchdetails/approvalasmember/pik/';//put
String BetseidhaPriestMediaSend='${baseUrl}notifications/priestnotifications/';//post media files
String BetseidhaGuestAccountDetails='${baseUrl}guestdetails/addguestdetails/';//get betseidha guest profile details
String BetseidhaPriestMediaSendGET='${baseUrl}notifications/priestnotifications/';//GET media files
String BetseidhaUserMediaSend='${baseUrl}notifications/membernotifications/';//post media files
String BetseidhaUserMediaSendGET='${baseUrl}notifications/membernotifications/';//GET MEDIA FILES FROM USER
String BetseidhaPriestApprovalUserMessages='${baseUrl}notifications/allmembernotifications/';//get media files

//notification alert for updating the details 
String NotificationALertAPI='${baseUrl}notifications/notificationalert/';//GET API SEND TOKEN**************
String NotificationResetAPI='${baseUrl}notifications/notificationreset/';

//Baptisum urls
String UserDocumentSending='${baseUrl}sacraments/adddocumentbymember/';//baptisum document sending
//String UserDownloadBaptisumApproveLetter='${baseUrl}sacraments/addbaptismcertificate/';
String BaptisumReferenceCode='${baseUrl}sacraments/getrequestbaptismmember/';
String GodNameSearching='${baseUrl}sacraments/requestmemberbycode/';
//GodNameSearching===>god father and mother checking with member code
String GetAllIDs='${baseUrl}sacraments/getbasicdetails/';//post phone to get response=>ids
String BaptismAllPost='${baseUrl}sacraments/requestbaptism/';//all post request 
String ApproveLetter='${baseUrl}sacraments/addbaptismcertificate/';//in this api used to post baptisum letter and get baptisum letter
String BaptisumAllRequestGetPriest='${baseUrl}sacraments/baptismrequestpriest/';//get all baptisum request to generate the certificate


//OBITUARY
String GetFamilyMembersOnly='${baseUrl}notifications/getdeathfamilymember/';//post api to get family members names
String UploadObituaryImage='${baseUrl}notifications/adddailyNotifications/';//post api to upload image
String PriestApprovingObituaryMessages='${baseUrl}notifications/deathpriestnotifications/';// get api to priest fetch obituarymessages


//priest profile page
String PriestProfilePageAPI='${baseUrl}churchdetails/allpriestdetails/';//get api to fetch priest details for profile page
String PriestSendingMessagesAPI='${baseUrl}sacraments/priestdocumentapproval/';
String PriestNamesAPI='${baseUrl}notifications/GetPriestNamesOnPhone/';
String PriestMessageShows='${baseUrl}notifications/priestapprovalnotifications/';//get api to showing priest message in user page*********.


// '${baseUrl}guestdetails/rejectingguestbetseidha/'
// '${baseUrl}churchdetails/approvalasmember/$nGuestID/'
// '${baseUrl}notifications/priestnotifications/'
// '${baseUrl}notifications/approvingmembernotifications/$nMemberNotificationsID/'
// '${baseUrl}notifications/rejectmembernotifications/$nMemberNotificationsID/'
// '${baseUrl}notifications/membernotifications/'
// '${baseUrl}churchdetails/guestapproval/'
// '${baseUrl}notifications/approvingmembernotifications/$nMemberNotificationsID/'
// '${baseUrl}notifications/priestapprovalnotifications/'
// '${baseUrl}holymass/selectedchurchdetails/'
// '${baseUrl}notifications/adddailyNotifications/'
// '${baseUrl}notifications/getdeathnotificationid/'
// '${baseUrl}sacraments/priestactivating/$nBaptismRequestID/'
// '${baseUrl}sacraments/getbaptismrequest/'
// '${baseUrl}holymass/selectedchurchdetails/'
// '${baseUrl}notifications/approvingmembernotifications/$nDeathNotificationID/'
// '${baseUrl}sacraments/presidentapproval/$nBaptismRequestID/'



// /// Maps DateTime.weekday (Mon=1…Sun=7) → app dayID (Sun=1…Sat=7)
//   int get _todayDayID => DateTime.now().weekday % 7 + 1;
//   /// Day 0 always shows; only today's weekday section shows for days 1–7
// List<int> get _visibleDayIDs =>
//     _dayIDs.where((id) => id == 0 || id == _todayDayID).toList();


//   itemCount: _visibleDayIDs.length,
//           itemBuilder: (context, i) => _buildDaySection(_visibleDayIDs[i]), page no 408



//local database
// I/flutter (26339): {"ChurchDetails":
// [{"nChurchID":5,"nForaneID":2,"nParishID":23,"nDioceseID":1,"cChurchName":"Old Portugese Church"},
// {"nChurchID":1,"nForaneID":2,"nParishID":23,"nDioceseID":1,"cChurchName":"സിന്ധുയാത്ര മാതാ പള്ളി"},
// {"nChurchID":2,"nForaneID":2,"nParishID":96,"nDioceseID":1,"cChurchName":"ബെത്സയ്‌ദ ധ്യാന കേന്ദ്രം"},
// {"nChurchID":3,"nForaneID":8,"nParishID":94,"nDioceseID":1,"cChurchName":"MADRE DE DEUS CHURCH VETTUCAUD"},
// {"nChurchID":4,"nForaneID":8,"nParishID":94,"nDioceseID":1,"cChurchName":"Mater Dei Chapel"}],
// "Districts":[{"nDistrictID":1,"cName":"Trivandrum"},
// {"nDistrictID":2,"cName":"Kollam"}]}


//cloud
// I/flutter ( 8719): {"ChurchDetails":
// [{"nChurchID":5,"nForaneID":2,"nParishID":23,"nDioceseID":1,"cChurchName":"Old Portugese Church"},
// {"nChurchID":1,"nForaneID":2,"nParishID":23,"nDioceseID":1,"cChurchName":"Our Lady of Good Voyage"},
// {"nChurchID":2,"nForaneID":2,"nParishID":96,"nDioceseID":1,"cChurchName":"Bethsaida Retreat Centre"},
// {"nChurchID":3,"nForaneID":8,"nParishID":94,"nDioceseID":1,"cChurchName":"MADRE DE DEUS CHURCH VETTUCAUD"},
// {"nChurchID":4,"nForaneID":2,"nParishID":24,"nDioceseID":1,"cChurchName":"Christ the King Church,"}],
// "Districts":[{"nDistrictID":1,"cName":"Trivandrum"},{"nDistrictID":2,"cName":"Kollam"}]}

