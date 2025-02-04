import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:ma_exam_t/inspect_page.dart';
import 'package:ma_exam_t/add_page.dart';
import 'package:ma_exam_t/edit_page.dart';
import 'package:ma_exam_t/models/Albatross.dart';
import 'package:ma_exam_t/section_1.dart';
import 'package:ma_exam_t/section_2.dart';
import 'package:ma_exam_t/services/api_service.dart';

var logger = Logger();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const appTitle = 'Albatross';

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xff008bcc),
      systemNavigationBarColor: Color(0xff008bcc),
      systemNavigationBarDividerColor: Color(0xff008bcc),
      statusBarBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        useMaterial3: true,
      ),
      routes: {
        "/add": (context) => AddPage(),
        "/": (context) => const HomeWidget(),
      },
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomeWidgetState();
  }
}

class _HomeWidgetState extends State<HomeWidget> {
  ApiService apiService = ApiService();
  late List<Albatross> entities;
  bool isLoading = true;
  bool isOffline = false;
  static const String appTitle = 'Albatross';

  @override
  void initState() {
    super.initState();
    _getDataFromAPI();

    apiService.socketStream.listen((event) {
      final changeType = event['type'];
      final entityData = event['data'];
      setState(() {
        if (changeType == 'add') {
          final entity = Albatross.fromJson(entityData);
          entities.add(entity);

        } else if(changeType == 'disconnect') {
          isOffline = true;
          _showReconnectSnackBar();
        }
      });
    });
  }

  void _getDataFromAPI() async {
    try {
      List<Albatross> list;
      apiService.connectWebSocket().then((value) async => {
        list = await apiService.getAllEntities(),
        setState(() {
          isOffline = false;
          entities = list;
          isLoading = false;
        })
      });

    } catch (error) {
        logger.e("Error while fetching all the entities: $error");
        _showErrorToast("An error occurred while fetching the data");
    }
  }

  void _navigateToAddScreen() async {
    final addedEntity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPage(),
      ),
    );

    if (addedEntity != null) {
      try {
        int addedId;
        setState(() {
          isLoading = true;
        });

        apiService.addEntity(addedEntity).then((value) => {
          addedId = value,
          setState(() {
            isLoading = false;
          }),

          if(addedId <= 0) {
              setState(() {
            entities.add(addedEntity);
          }),

          _showErrorToast("No connection to server; operation was performed locally")
          }
        });

      } catch (error) {
        logger.e("Error while adding the entity: $error");
        _showErrorToast("An error occurred while adding the entity");
      }
    }
  }

  Widget entityListWidget() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if(entities.isEmpty) {
      return Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            const Padding(
                padding: EdgeInsets.all(16.0),
                child:Text("Could not fetch data from the server or there is nothing locally",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 18,
                )
              )
            ),
            Center(child:
              ElevatedButton(
                  onPressed: () {
                    _getDataFromAPI();
                  },

                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff008bcc)
                  ),

                  child: const Text("Try again",
                    style: TextStyle(
                        color: Colors.white
                    ),
                  )
              )
            )
          ],
        ),
      );

    } else {
      return ListView.builder(
        itemCount: entities.length,
        itemBuilder: (context, index) {
          final entity = entities[index];

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: const Color(0xfff4fff4),
              child: ListTile(
                key: ValueKey(entity.id),
                onTap: () {
                  debugPrint("Tapped on item with index $index");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InspectPage(entity: entities[index]),
                    ),
                  ).then((value) => {
                    apiService.getEntityFromDB(entities[index].id).then((onValue) => {
                      if(onValue != null)
                        setState(() {
                          entities[index] = onValue;
                        })
                    })
                  });

                },
                title: entityCardWidget(context, entity),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _editButtonWidget(context, index),
                    const SizedBox(width: 10),
                    _deleteButtonWidget(context, index, entity.id),
                    // const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Widget entityCardWidget(BuildContext context, Albatross entity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          entity.name,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _deleteButtonWidget(BuildContext context, int index, int entityId) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff008bcc),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.delete, color: Colors.white),
        onPressed: () {
          _showConfirmDialog(context, "Do you want to delete this item?").then((onValue) => {
            if (onValue == true)
              {
                setState(() {
                  isLoading = true;
                }),
                apiService
                    .deleteEntity(entityId)
                    .then((value) => {
                      setState(() {
                        isLoading = false;
                      }),
                      if(value <= 0) {
                        _showErrorToast("No connection to server; operation was discarded"),
                      } else {
                        setState(() {
                          entities.removeAt(index);
                        }),
                      }
                }).catchError((error) => {
                  logger.e("An error occurred while deleting the entity: $error"),
                  _showErrorToast("An error occurred while deleting the entity"),
                }),
              }
          });
        },
      ),
    );
  }

  Widget _editButtonWidget(BuildContext context, int index) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff008bcc),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.edit, color: Colors.white),
        onPressed: () async {
          Albatross? entity = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPage(entity: entities[index]),
            ),
          );

          if (entity != null) {
            try {
              setState(() {
                isLoading = true;
              });
              apiService.updateEntity(entity).then((value) => {
                setState(() {
                  isLoading = false;
                }),
                if(value <= 0) {
                  _showErrorToast("No connection to server; operation was discarded"),
                } else {
                  setState(() {
                    entities[index] = entity;
                  }),
                }
              });

            } catch (error) {
                logger.e("Error while updating the entity: $error");
                _showErrorToast("An error occurred while updating the entity");
            }
          }
        },
      ),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context, String message) async {
    Widget cancelButton = ElevatedButton(
      child: const Text("No"),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    );

    Widget continueButton = ElevatedButton(
      child: const Text("Yes"),
      onPressed: () {
        Navigator.of(context).pop(true);
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Delete item"),
      content: Text(message),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    final result = await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

    return result ?? false;
  }

  void _showErrorToast(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  Widget _firstSectionButton() {
    return IconButton(
      icon: const Icon(Icons.document_scanner),
      color: Colors.white,
      tooltip: 'Section 1',
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Section1Page(),
          ),
        ).then((value) => {
          _showReconnectSnackBar()
        });
      },
    );
  }

  Widget _secondSectionButton() {
    return IconButton(
      icon: const Icon(Icons.content_paste_search),
      color: Colors.white,
      tooltip: 'Section 2',
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Section2Page(),
          ),
        ).then((value) => {
          _showReconnectSnackBar()
        });
      },
    );
  }

  void _showReconnectSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if(isOffline) {
      final snackBar = SnackBar(
        content: const Text('Running in offline mode'),
        duration: const Duration(days: 365),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            _getDataFromAPI();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffc4e1f3),
      appBar: AppBar(
        title: const Text(
          appTitle,
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff008bcc),
        actions: [
          _firstSectionButton(),
          _secondSectionButton()
        ],
      ),
      body: entityListWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        backgroundColor: const Color(0xff008bcc),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

