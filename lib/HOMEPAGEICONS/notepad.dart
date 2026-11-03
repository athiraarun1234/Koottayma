import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DrawingStorage {
  static final dbHelper = DatabaseHelper();
  
  // Save drawing to SQLite database
  static Future<void> saveDrawing(List<DrawingPoint?> points, String title, {String? userPhone}) async {
    final db = await dbHelper.database;
    
    // Convert points to JSON string
    String pointsJson = jsonEncode(
      points.map((p) {
        if (p == null) return null;
        return {
          'x': p.offset.dx,
          'y': p.offset.dy,
          'color': p.color.value,
          'strokeWidth': p.strokeWidth,
        };
      }).toList(),
    );
    
    // Insert into database
    await db.insert(
      'drawings',
      {
        'user_phone': userPhone,
        'title': title,
        'points': pointsJson,
        'timestamp': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
    
    print('Saved drawing: $title for user: $userPhone');
  }
  
  // Get all saved drawings from database
  static Future<List<SavedDrawing>> getSavedDrawings({String? userPhone}) async {
    final db = await dbHelper.database;
    
    List<Map<String, dynamic>> maps;
    if (userPhone != null) {
      // Get drawings for specific user
      maps = await db.query(
        'drawings',
        where: 'user_phone = ?',
        whereArgs: [userPhone],
        orderBy: 'timestamp DESC',
      );
    } else {
      // Get all drawings
      maps = await db.query(
        'drawings',
        orderBy: 'timestamp DESC',
      );
    }
    
    return List.generate(maps.length, (i) {
      return SavedDrawing.fromMap(maps[i]);
    });
  }
  
  // Delete a drawing by ID
  static Future<void> deleteDrawing(int id) async {
    final db = await dbHelper.database;
    await db.delete(
      'drawings',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Deleted drawing with id: $id');
  }
  
  // Update drawing title
  static Future<void> updateDrawingTitle(int id, String newTitle) async {
    final db = await dbHelper.database;
    await db.update(
      'drawings',
      {
        'title': newTitle,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Updated drawing $id with new title: $newTitle');
  }
  
  // Check if user has drawings
  static Future<bool> hasDrawings(String userPhone) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'drawings',
      where: 'user_phone = ?',
      whereArgs: [userPhone],
      limit: 1,
    );
    return result.isNotEmpty;
  }
  
  // Delete all drawings for a user (useful on logout)
  static Future<void> deleteUserDrawings(String userPhone) async {
    final db = await dbHelper.database;
    await db.delete(
      'drawings',
      where: 'user_phone = ?',
      whereArgs: [userPhone],
    );
    print('Deleted all drawings for user: $userPhone');
  }
}

class SavedDrawing {
  final int? id;
  final String? userPhone;
  final List<DrawingPoint?> points;
  final String title;
  final DateTime timestamp;
  
  SavedDrawing({
    this.id,
    this.userPhone,
    required this.points,
    required this.title,
    required this.timestamp,
  });
  
  // Create from database map
  factory SavedDrawing.fromMap(Map<String, dynamic> map) {
    List<dynamic> pointsData = jsonDecode(map['points']);
    
    List<DrawingPoint?> points = pointsData.map((p) {
      if (p == null) return null;
      return DrawingPoint(
        Offset(p['x'], p['y']),
        Color(p['color']),
        p['strokeWidth'],
      );
    }).toList();
    
    return SavedDrawing(
      id: map['id'],
      userPhone: map['user_phone'],
      points: points,
      title: map['title'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class WritingNotes extends StatefulWidget {
  final String? userPhone; // Optional: Pass from login screen
  
  const WritingNotes({Key? key, this.userPhone}) : super(key: key);

  @override
  State<WritingNotes> createState() => _WritingNotesState();
}

class _WritingNotesState extends State<WritingNotes> {
  List<DrawingPoint?> points = [];
  Color selectedColor = Colors.black;
  double strokeWidth = 3.0;
  String? _currentUserPhone; // Store the current user's phone
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  // Load user phone from SharedPreferences
  Future<void> _loadUserPhone() async {
    if (widget.userPhone != null) {
      // If passed as parameter, use it
      setState(() {
        _currentUserPhone = widget.userPhone;
        _isLoading = false;
      });
    } else {
      // Otherwise, load from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? phoneNumber = prefs.getString('userPhone');
      
      setState(() {
        _currentUserPhone = phoneNumber;
        _isLoading = false;
      });
      
      if (phoneNumber == null) {
        // Show error if no user is logged in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No user logged in. Please login first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveDrawing() async {
    if (_currentUserPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to save drawings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to save!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String title = '';
        return AlertDialog(
          title: const Text('Save Drawing'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Enter title'),
            onChanged: (value) => title = value,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (title.isEmpty) {
                  List<SavedDrawing> existing = await DrawingStorage.getSavedDrawings(
                    userPhone: _currentUserPhone,
                  );
                  title = 'Drawing ${existing.length + 1}';
                }
                await DrawingStorage.saveDrawing(
                  points, 
                  title,
                  userPhone: _currentUserPhone,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Drawing saved successfully!')),
                  );
                  
                  // Clear canvas after save
                  setState(() {
                    points.clear();
                  });
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavedDrawingsList(
                        userPhone: _currentUserPhone,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Write Notes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedDrawingsList(
                    userPhone: _currentUserPhone,
                  ),
                ),
              );
            },
            tooltip: 'View Saved',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDrawing,
            tooltip: 'Save',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                points.clear();
              });
            },
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: strokeWidth,
                    min: 1.0,
                    max: 10.0,
                    onChanged: (value) {
                      setState(() {
                        strokeWidth = value;
                      });
                    },
                  ),
                ),
                Text('${strokeWidth.toStringAsFixed(1)}'),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  points.add(
                    DrawingPoint(
                      details.localPosition,
                      selectedColor,
                      strokeWidth,
                    ),
                  );
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  points.add(
                    DrawingPoint(
                      details.localPosition,
                      selectedColor,
                      strokeWidth,
                    ),
                  );
                });
              },
              onPanEnd: (details) {
                setState(() {
                  points.add(null);
                });
              },
              child: Container(
                color: Colors.white,
                child: CustomPaint(
                  painter: DrawingPainter(points),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Page to show list of saved drawings
class SavedDrawingsList extends StatefulWidget {
  final String? userPhone;
  
  const SavedDrawingsList({Key? key, this.userPhone}) : super(key: key);

  @override
  State<SavedDrawingsList> createState() => _SavedDrawingsListState();
}

class _SavedDrawingsListState extends State<SavedDrawingsList> {
  List<SavedDrawing> _drawings = [];
  bool _isLoading = true;
  String? _currentUserPhone;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    // Get user phone
    if (widget.userPhone != null) {
      _currentUserPhone = widget.userPhone;
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _currentUserPhone = prefs.getString('userPhone');
    }
    
    await _loadDrawings();
  }

  Future<void> _loadDrawings() async {
    setState(() {
      _isLoading = true;
    });
    
    List<SavedDrawing> drawings = await DrawingStorage.getSavedDrawings(
      userPhone: _currentUserPhone,
    );
    
    setState(() {
      _drawings = drawings;
      _isLoading = false;
    });
  }

  void _showEditDialog(SavedDrawing drawing) {
    String newTitle = drawing.title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Title'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Enter new title'),
          controller: TextEditingController(text: drawing.title),
          onChanged: (value) => newTitle = value,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newTitle.isNotEmpty && drawing.id != null) {
                await DrawingStorage.updateDrawingTitle(drawing.id!, newTitle);
                Navigator.pop(context);
                _loadDrawings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title updated!')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(SavedDrawing drawing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Drawing'),
        content: Text('Are you sure you want to delete "${drawing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (drawing.id != null) {
                await DrawingStorage.deleteDrawing(drawing.id!);
                Navigator.pop(context);
                _loadDrawings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Drawing deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Drawings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrawings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drawings.isEmpty
              ? const Center(
                  child: Text('No saved drawings yet'),
                )
              : ListView.builder(
                  itemCount: _drawings.length,
                  itemBuilder: (context, index) {
                    final drawing = _drawings[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(drawing.title),
                        subtitle: Text(
                          '${drawing.timestamp.day}/${drawing.timestamp.month}/${drawing.timestamp.year} '
                          '${drawing.timestamp.hour}:${drawing.timestamp.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(drawing),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(drawing),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DisplayDrawing(
                                points: drawing.points,
                                title: drawing.title,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

// Page to display individual drawing
class DisplayDrawing extends StatelessWidget {
  final List<DrawingPoint?> points;
  final String title;

  const DisplayDrawing({
    Key? key,
    required this.points,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Container(
        color: Colors.white,
        child: CustomPaint(
          painter: DrawingPainter(points),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class DrawingPoint {
  Offset offset;
  Color color;
  double strokeWidth;

  DrawingPoint(this.offset, this.color, this.strokeWidth);
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          Paint()
            ..color = points[i]!.color
            ..strokeWidth = points[i]!.strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}