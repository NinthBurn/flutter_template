import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:ma_exam_t/models/Albatross.dart';
import 'package:ma_exam_t/services/database_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

var logger = Logger();

class ApiService {
  static final ApiService _instance = ApiService._constructor();
  static const String baseUrl = 'http://192.168.1.6:2528';
  static const String socketUrl = 'ws://192.168.1.6:2528';

  static const String getUrl = '$baseUrl/transactions';
  static const String entityUrl = '$baseUrl/transaction';

  static const Duration socketTimeout = Duration(seconds: 2);
  WebSocketChannel? _channel;

  bool _isConnected = false;
  bool _changesSynced = false;
  final StreamController<Map<String, dynamic>> _socketController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get socketStream => _socketController.stream;

  ApiService._constructor();

  factory ApiService() => _instance;

  Future<bool> checkWebSocketConnection() async {
    return _isConnected;
  }

  void tryReconnect() async {
    Future.delayed(socketTimeout).then((value) => {
      if(!_isConnected) {
        _socketController.add({
          'type': 'reset',
          'data': ''
        })
      }
    });
  }

  Future<bool> connectWebSocket() async {
    Completer<bool> completer = Completer<bool>();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(socketUrl));

      await Future.any([
        _channel!.ready.then((onValue) {
          if(!_changesSynced) {
            _isConnected = true;
            completer.complete(true);

          }
          logger.i("WebSocket connection established.");
        }).catchError((error) {
          _isConnected = false;
          _changesSynced = false;
          tryReconnect();
          logger.w("WebSocket connection failed: $error");
          completer.complete(false);
        }),

        Future.delayed(socketTimeout, () {
          if (!completer.isCompleted) {
            logger.w("WebSocket connection timed out.");
            tryReconnect();
            completer.complete(false);
          }
        }),
      ]);

      _channel!.stream.listen((message) {
        final data = json.decode(message);
        _socketController.add({
          'type': 'add',
          'data': data,
        });

        logger.i("Data has changed on the server, updating local data.");
        _addEntityLocally(data);

      }, onDone: () {
        _isConnected = false;
        _changesSynced = false;
        logger.w("WebSocket connection closed.");
        tryReconnect();


        if (!completer.isCompleted) {
          completer.complete(false);
        }

      }, onError: (error) {
        _isConnected = false;
        _changesSynced = false;
        tryReconnect();

        logger.w("WebSocket connection error: $error");
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      return completer.future;
    } catch (e) {
      logger.w("WebSocket connection error: $e");
      _isConnected = false;
      _changesSynced = false;
      tryReconnect();

      return Future.value(false);
    }
  }

  Future<void> _addEntityLocally(Map<String, dynamic> entityData) async {
    try {
      Albatross entity = Albatross.fromJson(entityData);
      await DatabaseService.instance.addEntity(entity);
      logger.i("Entity added locally: ${entity.toString()}");
    } catch (e) {
      logger.i("Error adding entity locally: $e");
      rethrow;
    }
  }

  Future<int> addEntity(Albatross entity) async {
    bool connected = await checkWebSocketConnection();

    if (connected) {
      final response = await http.post(
        Uri.parse(entityUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(entity.toJsonWithoutId()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = json.decode(response.body);
        return 1;
      } else {
        throw Exception('Failed to add component to server.');
      }
    } else {
      logger.w('Failed to connect to the server, saving the changes locally');
      entity.id = await DatabaseService.instance.addEntityOffline(entity);
      return -1;
    }
  }

  Future<List<Albatross>> getAllEntities() async {
    if (await checkWebSocketConnection()) {
      if(!_changesSynced) {
        _changesSynced = true;
        await syncOfflineChanges();
      }

      final response = await http.get(Uri.parse(getUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        await DatabaseService.instance.clearAllEntities();

        List<Albatross> entities = [];

        for (var entityData in jsonResponse) {
          Albatross entity = Albatross.fromJson(entityData);
          entities.add(entity);
          await DatabaseService.instance.addEntity(entity);
        }

        logger.i("Fetched data from server");
        return entities;

      } else {
        throw Exception('Failed to fetch entities from server.');
      }

    } else {
      logger.w("Not connected to server");
      return DatabaseService.instance.getAllEntities();
    }
  }

  Future<Albatross?> getEntity(int id) async {
    if (await checkWebSocketConnection()) {
      final response = await http.get(Uri.parse('$entityUrl/$id'));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = json.decode(response.body);

        Albatross entity = Albatross.fromJson(jsonResponse);
        logger.i("Fetched $entity from server");
        DatabaseService.instance.updateEntity(entity);
        return entity;

      } else {
        throw Exception('Failed to fetch components from server.');
      }

    } else {
      logger.w("Not connected to server");
      return DatabaseService.instance.getEntityById(id);
    }
  }

  Future<Albatross?> getEntityFromDB(int id) async {
      return DatabaseService.instance.getEntityById(id);
  }

  Future<int> updateEntity(Albatross entity) async {
    bool connected = await checkWebSocketConnection();

    if (connected) {
      final response = await http.put(
        Uri.parse('$entityUrl/${entity.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(entity.toJsonWithoutId()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        DatabaseService.instance.updateEntity(entity);
        return 1;
      } else {
        throw Exception('Failed to update component on server.');
      }

    } else {
      logger.w("Not connected to server");
      return -1;
    }
  }

  Future<int> updateLocally(Albatross entity) async {
    DatabaseService.instance.updateEntity(entity);
    return 1;
  }

  Future<int> deleteEntity(int id) async {
    bool connected = await checkWebSocketConnection();

    if (connected) {
      final response = await http.delete(Uri.parse('$entityUrl/$id'));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        DatabaseService.instance.deleteEntity(id);
        return 1;
      } else {
        throw Exception('Failed to delete entity from server.');
      }
    } else {
      logger.w("Not connected to server");
      return -1;
    }
  }

  Future<void> syncOfflineChanges() async {
    List<Map<String, dynamic>> offlineChanges = await DatabaseService.instance.getOfflineChanges();

    for (var change in offlineChanges) {
      String changeType = change['change_type'];
      int id = change['id'];
      String data = change['data'];

      try {
        if (changeType == 'add') {
          var entityData = json.decode(data);
          final response = await http.post(
            Uri.parse(entityUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(entityData),
          );
          if (response.statusCode >= 200 && response.statusCode < 300) {
            await DatabaseService.instance.markChangeAsSynced(change['id']);
          }

        }

      } catch (e) {
        logger.e("Failed to sync offline change: $e");
      }
    }

    await DatabaseService.instance.clearOfflineChanges();
  }
}
