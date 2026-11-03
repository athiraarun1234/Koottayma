import 'dart:io';

import 'package:Koottaayma/SQFLITEVERSION1/LabelDetails.dart';
import 'package:Koottaayma/SQFLITEVERSION1/LanguageModel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
// Database Helper Class
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;



  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = p.join(await getDatabasesPath(), 'MyCommunitysqlite.db');
    // Updated version to 7 to include new cache tables
    return openDatabase(path, version: 9, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Languages table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Languages(
        nLanguageID INTEGER PRIMARY KEY,
        cLanguageName TEXT NOT NULL
      )
    ''');
    
    // Create LabelDetails table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS LabelDetails(
        nLabelLanguageMasterID INTEGER,
        nLanguageID INTEGER,
        nCommunityID INTEGER,
        nDeviseEnvironmentID INTEGER,
        nPageID INTEGER,
        nLabelID INTEGER,
        cLabelKey TEXT,
        nUserTypeID INTEGER,
        PRIMARY KEY (nPageID, nLabelID, nLanguageID)
      )
    ''');

    // Create SyncMetadata table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS SyncMetadata(
        syncKey TEXT PRIMARY KEY,
        lastSyncTime INTEGER,
        version TEXT,
        languageId INTEGER
      )
    ''');
    
    // Create user preferences table
    await _createUserPreferencesTable(db);
    
    // Create family members table
    await _createFamilyMembersTable(db);
    
    // Create notepad images table
    await _createDrawingsTable(db);
    
    // Create holy mass table
    await createHolyMassTable(db);

    //  NEW: Create cache tables for API response data
    await _createCacheTables(db);
  }

 Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS SyncMetadata(
        syncKey TEXT PRIMARY KEY,
        lastSyncTime INTEGER,
        version TEXT,
        languageId INTEGER
      )
    ''');
  }
  
  if (oldVersion < 3) {
    await db.execute('''
      ALTER TABLE LabelDetails ADD COLUMN nUserTypeID INTEGER
    ''');
  }
  
  if (oldVersion < 4) {
    await _createFamilyMembersTable(db);
  }
  
  if (oldVersion < 5) {
    await _createDrawingsTable(db);
  }
  
  if (oldVersion < 6) {
    await createHolyMassTable(db);
  }

  if (oldVersion < 7) {
    await _createCacheTables(db);
  }

  if (oldVersion < 8) {
    await _createCacheTables(db);
  }

  // NEW: Add this for version 9
  if (oldVersion < 9) {
    print(' Upgrading to version 9 - Creating parish_details_cache');
    
    // Create parish_details_cache explicitly
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parish_details_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        parish_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Verify all cache tables exist
    await _createCacheTables(db);
    
    print(' Version 9 upgrade complete');
  }
}

 

  Future<void> _createCacheTables(Database db) async {
    // Main cache table for complete user data
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_data_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_key TEXT NOT NULL,
        phone_number INTEGER NOT NULL,
        complete_data TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(role_key, phone_number)
      )
    ''');
    
    // Gospel Readings cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS gospel_readings_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        gospel_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Special Programs cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS special_programs_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        programs_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  //   ///////////// parish details  connect churches
  await db.execute('''
      CREATE TABLE IF NOT EXISTS parish_details_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        parish_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Holy Mass Timings cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS holy_mass_timings_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        mass_timings_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Family Details cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS family_details_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        family_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // japamala Details cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS japamala_details_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        japamala_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // padapooja Details cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS padapooja_details_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        padapooja_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

      
      // karunayude kontha Details cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS karunayudekontha_details_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        karunayudekontha_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Kurishintte vazhikal cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS kurishinttevazhi_details_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        kurishinttevazhi_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
      //today verse cache
     await db.execute('''
      CREATE TABLE IF NOT EXISTS today_verse_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        todayverse_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
     ////church details
   await db.execute('''
      CREATE TABLE IF NOT EXISTS church_details_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number INTEGER NOT NULL UNIQUE,
        church_data TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Sync tracking table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_info (
        phone_number INTEGER PRIMARY KEY,
        last_sync TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    print(' All cache tables created successfully');
  }

  

  /// Save complete user data for a role
  Future<void> saveCompleteUserData({
    required String roleKey,
    required int phoneNumber,
    required String completeData,
  }) async {
    final db = await database;
    
    await db.insert(
      'user_data_cache',
      {
        'role_key': roleKey,
        'phone_number': phoneNumber,
        'complete_data': completeData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(' Saved $roleKey data to SQLite for phone: $phoneNumber');
  }

  /// Save Gospel Readings
  Future<void> saveGospelReadings({
    required int phoneNumber,
    required String gospelData,
  }) async {
    final db = await database;
    
    await db.insert(
      'gospel_readings_cache',
      {
        'phone_number': phoneNumber,
        'gospel_data': gospelData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(' Saved Gospel Readings for phone: $phoneNumber');
  }

  /// Save Special Programs
  Future<void> saveSpecialPrograms({
    required int phoneNumber,
    required String programsData,
  }) async {
    final db = await database;
    
    await db.insert(
      'special_programs_cache',
      {
        'phone_number': phoneNumber,
        'programs_data': programsData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print('Saved Special Programs for phone: $phoneNumber');
  }
/// Save  Parish Details
  Future<void> saveParishDetails({
    required int phoneNumber,
    required String parishData,
  }) async {
    final db = await database;
    
    await db.insert(
      'parish_details_cache',
      {
        'phone_number': phoneNumber,
        'parish_data': parishData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(' Saved Parish details for phone: $phoneNumber');
  }
  /// Save Holy Mass Timings
  Future<void> saveHolyMassTimings({
    required int phoneNumber,
    required String massTimingsData,
  }) async {
    final db = await database;
    
    await db.insert(
      'holy_mass_timings_cache',
      {
        'phone_number': phoneNumber,
        'mass_timings_data': massTimingsData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  
    print(' Saved Holy Mass Timings for phone: $phoneNumber');
  }

  /// Save Family Details
  Future<void> saveFamilyDetails({
    required int phoneNumber,
    required String familyData,
  }) async {
    final db = await database;
    
    await db.insert(
      'family_details_cache',
      {
        'phone_number': phoneNumber,
        'family_data': familyData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(' Saved Family Details for phone: $phoneNumber');
  }

  /// Save japamala Details
  Future<void> saveJapamalaDetails({
    required int phoneNumber,
    required String japamalaData,
  }) async {
    final db = await database;
    
    await db.insert(
      'japamala_details_cache',
      {
        'phone_number': phoneNumber,
        'japamala_data': japamalaData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(' Saved japamala Details for phone: $phoneNumber');
  }

  /// Save padapooja Details
  Future<void> savePadapoojaDetails({
    required int phoneNumber,
    required String padapoojaData,
  }) async {
    final db = await database;
    
    await db.insert(
      'padapooja_details_cache',
      {
        'phone_number': phoneNumber,
        'padapooja_data': padapoojaData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(' Saved padapooja Details for phone: $phoneNumber');
  }

   /// Save karunayudekontha Details
  Future<void> saveKarunayuddeKonthaDetails({
    required int phoneNumber,
    required String karunayudekonthaData,
  }) async {
    final db = await database;
    
    await db.insert(
      'karunayudekontha_details_cache',
      {
        'phone_number': phoneNumber,
        'karunayudekontha_data': karunayudekonthaData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(' Saved karunayudekontha Details for phone: $phoneNumber');
  }

   /// Save kurishinttevazhikal Details
  Future<void> saveKurishinttevazhiDetails({
    required int phoneNumber,
    required String kurishinttevazhiData,
  }) async {
    final db = await database;
    
    await db.insert(
      'kurishinttevazhi_details_cache',
      {
        'phone_number': phoneNumber,
        'kurishinttevazhi_data': kurishinttevazhiData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(' Saved Kurishinttte vazhi Details for phone: $phoneNumber');
  }

   //save today verse
 
  Future<void> saveTodayVerse({
    required int phoneNumber,
    required String todayverseData,
  }) async {
    final db = await database;
    
    await db.insert(
      'today_verse_cache',
      {
        'phone_number': phoneNumber,
        'todayverse_data': todayverseData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(' Saved toady verse for phone: $phoneNumber');
  }
  //save church details

 Future<void> saveChurchDetails({
    required int phoneNumber,
    required String churchData,
  }) async {
    final db = await database;
    
    await db.insert(
      'church_details_cache',
      {
        'phone_number': phoneNumber,
        'church_data': churchData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(' Saved church details for phone: $phoneNumber');
  }

  /// Update last sync time
  Future<void> updateLastSyncTime(int phoneNumber) async {
    final db = await database;
    
    await db.insert(
      'sync_info',
      {
        'phone_number': phoneNumber,
        'last_sync': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(' Updated sync time for phone: $phoneNumber');
  }

  

  /// Get complete user data from cache
  Future<Map<String, dynamic>?> getCachedUserData({
    required String roleKey,
    required int phoneNumber,
  }) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'user_data_cache',
      where: 'role_key = ? AND phone_number = ?',
      whereArgs: [roleKey, phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['complete_data'] as String);
    }
    return null;
  }

  /// Get Gospel Readings from cache
  Future<Map<String, dynamic>?> getCachedGospelReadings(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'gospel_readings_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['gospel_data'] as String);
    }
    return null;
  }

  /// Get Special Programs from cache
  Future<List<dynamic>?> getCachedSpecialPrograms(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'special_programs_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['programs_data'] as String);
    }
    return null;
  }
  /// Get Parish DETAILS from cache
  Future<List<dynamic>?> getCachedParishDetails(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'parish_details_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['parish_data'] as String);
    }
    return null;
  }

  /// Get Holy Mass Timings from cache
  Future<List<dynamic>?> getCachedHolyMassTimings(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'holy_mass_timings_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['mass_timings_data'] as String);
    }
    return null;
  }

  /// Get Family Details from cache
  Future<List<dynamic>?> getCachedFamilyDetails(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'family_details_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['family_data'] as String);
    }
    return null;
  }

   /// Get japamala Details from cache
  Future<List<dynamic>?> getCachedJapamalaDetails(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'japamala_details_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['japamala_data'] as String);
    }
    return null;
  }
  /// Get padapooja Details from cache
  Future<List<dynamic>?> getCachedPadapoojaDetails(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'padapooja_details_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['padapooja_data'] as String);
    }
    return null;
  }

     /// Get karunayudekontha Details from cache
  Future<List<dynamic>?> getCachedKarunayudeKonthaDetails(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'karunayudekontha_details_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['karunayudekontha_data'] as String);
    }
    return null;
  }


 /// Get Kurishintttevazhi Details from cache
  Future<List<dynamic>?> getCachedKurishinttevazhiDetails(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'kurishinttevazhi_details_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['kurishinttevazhi_data'] as String);
    }
    return null;
  }

   // get today verse from cache
 
  Future<Map<String, dynamic>?> getCachedTodayVerse(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'today_verse_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['todayverse_data'] as String);
    }
    return null;
  }
/// get church details from cache 
 Future<List<dynamic>?> getCachedChurchDetails(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'church_details_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['church_data'] as String);
    }
    return null;
  }


  /// Get last sync time for a user
  Future<DateTime?> getLastSyncTimeForUser(int phoneNumber) async {
    final db = await database;
    
    final maps = await db.query(
      'sync_info',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isNotEmpty) {
      return DateTime.parse(maps.first['last_sync'] as String);
    }
    return null;
  }

  /// Clear all cache for a user
  Future<void> clearUserCache(int phoneNumber) async {
    final db = await database;
    
    await db.delete('user_data_cache', where: 'phone_number = ?', whereArgs: [phoneNumber]);
    await db.delete('gospel_readings_cache', where: 'phone_number = ?', whereArgs: [phoneNumber]);
    await db.delete('special_programs_cache', where: 'phone_number = ?', whereArgs: [phoneNumber]);
    await db.delete('holy_mass_timings_cache', where: 'phone_number = ?', whereArgs: [phoneNumber]);
     await db.delete('parish_details_cache', where: 'phone_number = ?', whereArgs: [phoneNumber]);
      await db.delete('church_details_cache', where: 'phone_number = ?', whereArgs: [phoneNumber]);
       await db.delete('today_verse_cache', where: 'phone_number = ?', whereArgs: [phoneNumber]);
    await db.delete('family_details_cache', where: 'phone_number = ?', whereArgs: [phoneNumber]);
    await db.delete('sync_info', where: 'phone_number = ?', whereArgs: [phoneNumber]);
    
    print(' Cleared all cache for phone: $phoneNumber');
  }

  /// Check if cached data exists for user
  Future<bool> hasCachedData(int phoneNumber) async {
    final db = await database;
    
    final result = await db.query(
      'user_data_cache',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }



  Future<void> runMigrationForUserPreferences() async {
    try {
      await _ensureUserPreferencesTable();
      print('User preferences table migration completed');
    } catch (e) {
      print('Error running migration: $e');
    }
  }

  Future<void> _ensureUserPreferencesTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // Save the selected language ID
  Future<void> saveSelectedLanguageId(int languageId) async {
    final db = await database;
    await db.insert(
      'user_preferences',
      {
        'key': 'selected_language_id',
        'value': languageId.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Saved language ID: $languageId');
  }

  // Get the saved language ID
  Future<int?> getSavedLanguageId() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'user_preferences',
        where: 'key = ?',
        whereArgs: ['selected_language_id'],
      );
      
      if (result.isNotEmpty) {
        final languageId = int.parse(result.first['value'].toString());
        print('Retrieved saved language ID: $languageId');
        return languageId;
      }
      return null;
    } catch (e) {
      print('Error getting saved language ID: $e');
      return null;
    }
  }

  // Clear saved language (useful for logout or language change)
  Future<void> clearSavedLanguage() async {
    final db = await database;
    await db.delete(
      'user_preferences',
      where: 'key = ?',
      whereArgs: ['selected_language_id'],
    );
    print('Cleared saved language');
  }

  // Create the user_preferences table
  Future<void> _createUserPreferencesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> executeQuery(String query) async {
    final db = await database;
    try {
      print('Executing query: $query');
      await db.execute(query);
      print('Query executed successfully');
    } catch (e) {
      print('Error executing query: $e');
      print('Query was: $query');
      rethrow;
    }
  }

  Future<bool> shouldRefreshData(String dataType, {int? languageId}) async {
    final db = await database;
    final syncKey = languageId != null ? '${dataType}_$languageId' : dataType;
    
    final result = await db.query(
      'SyncMetadata',
      where: 'syncKey = ?',
      whereArgs: [syncKey],
    );

    if (result.isEmpty) {
      return true;
    }

    final lastSync = result.first['lastSyncTime'] as int;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    const refreshInterval = 60 * 60 * 60 * 1000; // 60 hours in milliseconds
    
    return (currentTime - lastSync) > refreshInterval;
  }

  Future<void> updateSyncMetadata(String dataType, {int? languageId, String? version}) async {
    final db = await database;
    final syncKey = languageId != null ? '${dataType}_$languageId' : dataType;
    
    await db.insert(
      'SyncMetadata',
      {
        'syncKey': syncKey,
        'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
        'version': version ?? '1.0',
        'languageId': languageId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearSyncMetadata(String syncKey) async {
    final db = await database;
    await db.delete(
      'SyncMetadata',
      where: 'syncKey = ?',
      whereArgs: [syncKey],
    );
  }

  Future<void> clearAllSyncMetadata() async {
    final db = await database;
    await db.delete('SyncMetadata');
  }

  Future<bool> checkAndUpdateLanguages() async {
    final shouldRefresh = await shouldRefreshData('languages');
    
    if (!shouldRefresh) {
      print('Languages data is up to date');
      return false;
    }

    print('Languages need refresh...');
    return true;
  }

  Future<bool> checkAndUpdateLabels(int languageId) async {
    final shouldRefresh = await shouldRefreshData('labels', languageId: languageId);
    
    if (!shouldRefresh) {
      print('Labels for language $languageId are up to date');
      return false;
    }

    print('Labels for language $languageId need refresh...');
    return true;
  }

  Future<DateTime?> getLastSyncTime(String dataType, {int? languageId}) async {
    final db = await database;
    final syncKey = languageId != null ? '${dataType}_$languageId' : dataType;
    
    final result = await db.query(
      'SyncMetadata',
      where: 'syncKey = ?',
      whereArgs: [syncKey],
    );

    if (result.isEmpty) return null;
    
    final timestamp = result.first['lastSyncTime'] as int;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> insertLanguage(LanguageModel language) async {
    final db = await database;
    await db.insert('Languages', language.toMap(), 
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LanguageModel>> getStoredLanguages() async {
    final db = await database;
    final results = await db.query('Languages', orderBy: 'cLanguageName ASC');
    return results.map((map) => LanguageModel.fromMap(map)).toList();
  }

  Future<bool> hasStoredLanguages() async {
    final db = await database;
    final result = await db.query('Languages', limit: 1);
    return result.isNotEmpty;
  }

  Future<void> clearLanguages() async {
    final db = await database;
    await db.delete('Languages');
    await clearSyncMetadata('languages');
  }

  Future<void> insertLabelDetails(Map<String, dynamic> detail) async {
    final db = await database;
    try {
      print('Inserting label detail: $detail');
      
      final requiredFields = ['nLanguageID', 'nPageID', 'nLabelID', 'cLabelKey'];
      for (String field in requiredFields) {
        if (!detail.containsKey(field) || detail[field] == null) {
          throw Exception('Missing required field: $field');
        }
      }
      
      final cleanedDetail = {
        'nLabelLanguageMasterID': detail['nLabelLanguageMasterID'] != null ? 
            int.tryParse(detail['nLabelLanguageMasterID'].toString()) ?? 0 : 0,
        'nLanguageID': int.parse(detail['nLanguageID'].toString()),
        'nCommunityID': detail['nCommunityID'] != null ? 
            int.tryParse(detail['nCommunityID'].toString()) ?? 0 : 0,
        'nDeviseEnvironmentID': detail['nDeviseEnvironmentID'] != null ? 
            int.tryParse(detail['nDeviseEnvironmentID'].toString()) ?? 0 : 0,
        'nPageID': int.parse(detail['nPageID'].toString()),
        'nLabelID': int.parse(detail['nLabelID'].toString()),
        'nUserTypeID': detail['nUserTypeID'] != null ? 
             int.tryParse(detail['nUserTypeID'].toString()) ?? 0 : 0,
        'cLabelKey': detail['cLabelKey'].toString(),
      };
      
      print('Cleaned detail for insertion: $cleanedDetail');
      
      await db.insert('LabelDetails', cleanedDetail, 
          conflictAlgorithm: ConflictAlgorithm.replace);
      
      print('Successfully inserted label detail');
      
    } catch (e) {
      print('Error inserting label detail: $e');
      print('Detail data: $detail');
      rethrow;
    }
  }

  Future<void> insertLabelDetailsForLanguage(Map<String, dynamic> detail, int targetLanguageId) async {
    if (detail['nLanguageID'] == targetLanguageId) {
      await insertLabelDetails(detail);
    }
  }

  Future<String> getLabelText(int pageId, int labelId, int languageId) async {
    final db = await database;
    final results = await db.query(
      'LabelDetails',
      where: 'nPageID = ? AND nLabelID = ? AND nLanguageID = ?',
      whereArgs: [pageId, labelId, languageId],
    );

    if (results.isNotEmpty) {
      return results.first['cLabelKey'] as String;
    }
    return 'Label not found';
  }
 
  Future<List<LabelDetails>> getLabelsForPage(
    int pageId, 
    int languageId, 
    int userTypeId, 
  ) async {
    final db = await database;
    final results = await db.query(
      'LabelDetails',
      where: 'nPageID = ? AND nLanguageID = ? AND nUserTypeID = ?',
      whereArgs: [pageId, languageId, userTypeId], 
      orderBy: 'nLabelID ASC',
    );
    
    print('Found ${results.length} labels for page $pageId, language $languageId, and userType $userTypeId');
    
    return results.map((map) => LabelDetails(
        nLabelLanguageMasterID: map['nLabelLanguageMasterID'] as int,
        nLanguageID: map['nLanguageID'] as int,
        nCommunityID: map['nCommunityID'] as int,
        nDeviseEnvironmentID: map['nDeviseEnvironmentID'] as int,
        nPageID: map['nPageID'] as int,
        nLabelID: map['nLabelID'] as int,
        nUserTypeID: map['nUserTypeID'] as int,
        cLabelKey: map['cLabelKey'] as String,
    )).toList();
  }

  Future<bool> hasLabelsForLanguage(int languageId) async {
    final db = await database;
    final result = await db.query(
      'LabelDetails',
      where: 'nLanguageID = ?',
      whereArgs: [languageId],
      limit: 1,
    );
    print('Language $languageId has ${result.length} labels');
    return result.isNotEmpty;
  }

  Future<List<int>> getAvailableLanguages() async {
    final db = await database;
    final results = await db.query(
      'LabelDetails',
      columns: ['DISTINCT nLanguageID'],
    );
    return results.map((row) => row['nLanguageID'] as int).toList();
  }

  Future<void> clearLabelDetails() async {
    final db = await database;
    await db.delete('LabelDetails');
    await clearSyncMetadata('labels');
  }

  Future<void> clearLabelsForLanguage(int languageId) async {
    final db = await database;
    await db.delete(
      'LabelDetails',
      where: 'nLanguageID = ?',
      whereArgs: [languageId],
    );
    await clearSyncMetadata('labels_$languageId');
  }

  Future<void> debugPrintLabelDetails() async {
    final db = await database;
    final results = await db.query('LabelDetails');
    print('LabelDetails Table Contents ');
    print('Total records: ${results.length}');
    for (var row in results) {
      print('Row: $row');
    }
    print('End LabelDetails');
  }

  Future<void> debugTableInfo() async {
    final db = await database;
    final results = await db.rawQuery('PRAGMA table_info(LabelDetails)');
    print(' LabelDetails Table Structure ');
    for (var row in results) {
      print('Column: $row');
    }
    print(' End Table Structure ');
  }

  Future<void> debugPrintSyncMetadata() async {
    final db = await database;
    final results = await db.query('SyncMetadata');
    print(' SyncMetadata Table Contents ');
    print('Total sync records: ${results.length}');
    for (var row in results) {
      final timestamp = row['lastSyncTime'] as int;
      final syncTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      print('Sync Key: ${row['syncKey']}, Last Sync: $syncTime, Version: ${row['version']}, Language ID: ${row['languageId']}');
    }
    print(' End SyncMetadata ');
  }

  // Create the family_members table
  Future _createFamilyMembersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS family_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_phone TEXT NOT NULL,
        nDailyNotificationsID INTEGER,
        cFirstName TEXT,
        cLastName TEXT,
        cAddress TEXT,
        dDoB TEXT,
        nGenderID INTEGER,
        nPhoneNo TEXT,
        cImagePath TEXT,
        cDioceseName TEXT,
        cForaneName TEXT,
        cParishName TEXT,
        cDistrictName TEXT,
        cStateName TEXT,
        cEducationName TEXT,
        cInstitutionName TEXT,
        dYearofPassing TEXT,
        nHeight TEXT,
        nWeight TEXT,
        cBloodGroup TEXT,
        cFamilyName TEXT,
        cFamilyNo INTEGER,
        cFamilyUnitName TEXT,
        cMemberCode INTEGER,
        cRelationName TEXT,
        cWardName TEXT,
        cIDNo TEXT,
        nAvgIncome TEXT,
        cRationCardNo TEXT,
        nHouseOwnershipID TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_user_phone 
      ON family_members(user_phone)
    ''');
  }

  // Insert or update family members
  Future<void> insertOrUpdateFamilyMembers(
    String userPhone, 
    List<Map<String, dynamic>> members
  ) async {
    final db = await database;
    final batch = db.batch();

    // Delete existing records for this user
    batch.delete(
      'family_members',
      where: 'user_phone = ?',
      whereArgs: [userPhone],
    );

    // Insert all members
    for (var member in members) {
      batch.insert(
        'family_members',
        {
          'user_phone': userPhone,
          'nDailyNotificationsID': member['nDailyNotificationsID'],
          'cFirstName': member['cFirstName'],
          'cLastName': member['cLastName'],
          'cAddress': member['cAddress'],
          'dDoB': member['dDoB'],
          'nGenderID': member['nGenderID'],
          'nPhoneNo': member['nPhoneNo'],
          'cImagePath': member['cImagePath'],
          'cDioceseName': member['cDioceseName'],
          'cForaneName': member['cForaneName'],
          'cParishName': member['cParishName'],
          'cDistrictName': member['cDistrictName'],
          'cStateName': member['cStateName'],
          'cEducationName': member['cEducationName'],
          'cInstitutionName': member['cInstitutionName'],
          'dYearofPassing': member['dYearofPassing'],
          'nHeight': member['nHeight']?.toString(),
          'nWeight': member['nWeight']?.toString(),
          'cBloodGroup': member['cBloodGroup'],
          'cFamilyName': member['cFamilyName'],
          'cFamilyNo':member['cFamilyNo'],
          'cFamilyUnitName':member['cFamilyUnitName'],
          'cMemberCode':member['cMemberCode'],
          'cRelationName':member['cRelationName'],
          'cWardName':member['cWardName'],
          'cIDNo': member['cIDNo'],
          'nAvgIncome': member['nAvgIncome']?.toString(),
          'cRationCardNo': member['cRationCardNo'],
          'nHouseOwnershipID': member['nHouseOwnershipID']?.toString(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    print(' Inserted ${members.length} family members for user: $userPhone');
  }

  // Get family members for a user
  Future<List<Map<String, dynamic>>> getFamilyMembers(String userPhone) async {
    final db = await database;
    final results = await db.query(
      'family_members',
      where: 'user_phone = ?',
      whereArgs: [userPhone],
      orderBy: 'created_at DESC',
    );
    
    print('Retrieved ${results.length} family members for user: $userPhone');
    return results;
  }

  // Delete family members for a user
  Future<void> deleteFamilyMembers(String userPhone) async {
    final db = await database;
    await db.delete(
      'family_members',
      where: 'user_phone = ?',
      whereArgs: [userPhone],
    );
    print(' Deleted family members for user: $userPhone');
  }

  // Check if family members exist for a user
  Future<bool> hasFamilyMembers(String userPhone) async {
    final db = await database;
    final result = await db.query(
      'family_members',
      where: 'user_phone = ?',
      whereArgs: [userPhone],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Create the drawings table (notepad images)
Future<void> _createDrawingsTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS drawings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_phone TEXT NOT NULL,
      title TEXT,
      image_data TEXT,
      points TEXT,
      timestamp TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_drawings_user_phone 
    ON drawings(user_phone)
  ''');
}


  // Insert a new drawing
  // Future<int> insertDrawing({
  //   required String userPhone,
  //   required String imageData,
  //   String? title,
  // }) async {
  //   final db = await database;
  //   final now = DateTime.now().toIso8601String();
    
  //   final id = await db.insert(
  //     'drawings',
  //     {
  //       'user_phone': userPhone,
  //       'image_data': imageData,
  //       'title': title ?? 'Drawing ${DateTime.now().toString()}',
  //       'created_at': now,
  //       'updated_at': now,
  //     },
  //   );
    
  //   print(' Inserted drawing with ID: $id for user: $userPhone');
  //   return id;
  // }

  // // Get all drawings for a user
  // Future<List<Map<String, dynamic>>> getDrawings(String userPhone) async {
  //   final db = await database;
  //   final results = await db.query(
  //     'drawings',
  //     where: 'user_phone = ?',
  //     whereArgs: [userPhone],
  //     orderBy: 'created_at DESC',
  //   );
    
  //   print('Retrieved ${results.length} drawings for user: $userPhone');
  //   return results;
  // }

  // // Update a drawing
  // Future<void> updateDrawing({
  //   required int id,
  //   required String imageData,
  //   String? title,
  // }) async {
  //   final db = await database;
  //   await db.update(
  //     'drawings',
  //     {
  //       'image_data': imageData,
  //       'title': title,
  //       'updated_at': DateTime.now().toIso8601String(),
  //     },
  //     where: 'id = ?',
  //     whereArgs: [id],
  //   );
    
  //   print(' Updated drawing with ID: $id');
  // }

  // // Delete a drawing
  // Future<void> deleteDrawing(int id) async {
  //   final db = await database;
  //   await db.delete(
  //     'drawings',
  //     where: 'id = ?',
  //     whereArgs: [id],
  //   );
    
  //   print(' Deleted drawing with ID: $id');
  // }

  // // Delete all drawings for a user
  // Future<void> deleteAllDrawings(String userPhone) async {
  //   final db = await database;
  //   await db.delete(
  //     'drawings',
  //     where: 'user_phone = ?',
  //     whereArgs: [userPhone],
  //   );
    
  //   print(' Deleted all drawings for user: $userPhone');
  // }

  // Create the holy_mass table
  Future<void> createHolyMassTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS holy_mass (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_phone TEXT NOT NULL,
        nHolyMassTimeID INTEGER,
        cHolyMassTime TEXT,
        nIsBooking INTEGER DEFAULT 0,
        nIsAttend INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_holy_mass_user_phone 
      ON holy_mass(user_phone)
    ''');
  }

  // Insert or update holy mass data
  Future<void> insertOrUpdateHolyMass({
    required String userPhone,
    required List<Map<String, dynamic>> massData,
  }) async {
    final db = await database;
    final batch = db.batch();

    // Delete existing records for this user
    batch.delete(
      'holy_mass',
      where: 'user_phone = ?',
      whereArgs: [userPhone],
    );

    // Insert all mass timings
    for (var mass in massData) {
      batch.insert(
        'holy_mass',
        {
          'user_phone': userPhone,
          'nHolyMassTimeID': mass['nHolyMassTimeID'],
          'cHolyMassTime': mass['cHolyMassTime'],
          'nIsBooking': mass['nIsBooking'] ?? 0,
          'nIsAttend': mass['nIsAttend'] ?? 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    }

    await batch.commit(noResult: true);
    print(' Inserted ${massData.length} holy mass timings for user: $userPhone');
  }

  // Get holy mass data for a user
  Future<List<Map<String, dynamic>>> getHolyMass(String userPhone) async {
    final db = await database;
    final results = await db.query(
      'holy_mass',
      where: 'user_phone = ?',
      whereArgs: [userPhone],
      orderBy: 'nHolyMassTimeID ASC',
    );
    
    print('Retrieved ${results.length} holy mass timings for user: $userPhone');
    return results;
  }

  // Update booking status
  Future<void> updateHolyMassBooking({
    required String userPhone,
    required int massTimeId,
    required int isBooking,
  }) async {
    final db = await database;
    await db.update(
      'holy_mass',
      {
        'nIsBooking': isBooking,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_phone = ? AND nHolyMassTimeID = ?',
      whereArgs: [userPhone, massTimeId],
    );
    
    print(' Updated booking status for mass ID: $massTimeId');
  }

  // Update attendance status
  Future<void> updateHolyMassAttendance({
    required String userPhone,
    required int massTimeId,
    required int isAttend,
  }) async {
    final db = await database;
    await db.update(
      'holy_mass',
      {
        'nIsAttend': isAttend,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_phone = ? AND nHolyMassTimeID = ?',
      whereArgs: [userPhone, massTimeId],
    );
    
    print(' Updated attendance status for mass ID: $massTimeId');
  }

  // Delete holy mass data for a user
  Future<void> deleteHolyMass(String userPhone) async {
    final db = await database;
    await db.delete(
      'holy_mass',
      where: 'user_phone = ?',
      whereArgs: [userPhone],
    );
    
    print(' Deleted holy mass data for user: $userPhone');
  }

  // Clear all data from database (useful for logout or reset)
  // Future<void> clearAllData() async {
  //   final db = await database;
  //   await db.delete('Languages');
  //   await db.delete('LabelDetails');
  //   await db.delete('SyncMetadata');
  //   await db.delete('user_preferences');
  //   await db.delete('family_members');
  //   await db.delete('drawings');
  //   await db.delete('holy_mass');
  //   // Clear cache tables
  //   await db.delete('user_data_cache');
  //   await db.delete('gospel_readings_cache');
  //   await db.delete('special_programs_cache');
  //   await db.delete('holy_mass_timings_cache');
  //   await db.delete('family_details_cache');
  //   await db.delete('sync_info');
    
  //   print(' Cleared all database data');
  // }

  // Close database connection
  // Future<void> close() async {
  //   final db = await database;
  //   await db.close();
  //   _database = null;
  //   print(' Database connection closed');
  // }

  // Get database size (for debugging)
  Future<int> getDatabaseSize() async {
    try {
      final path = p.join(await getDatabasesPath(), 'MyCommunitysqlite.db');
      final file = await File(path).stat();
      return file.size;
    } catch (e) {
      print('Error getting database size: $e');
      return 0;
    }
  }

  // Debug: Print all table names
  Future<void> debugPrintAllTables() async {
    final db = await database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );
    print(' All tables in database:');
    for (var table in tables) {
      print('  - ${table['name']}');
    }
  }

  // Debug: Get row count for a table
  Future<int> getTableRowCount(String tableName) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}