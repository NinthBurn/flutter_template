import 'package:flutter/material.dart';
import 'package:ma_exam_t/services/api_service.dart';

class Section2Page extends StatefulWidget {
  const Section2Page({super.key});

  @override
  State<StatefulWidget> createState() {
    return _Section2PageState();
  }
}

class _Section2PageState extends State<Section2Page> {
  ApiService apiService = ApiService();
  late List<Map<String, dynamic>> entities;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    try {
      List<Map<String, dynamic>> list;
      apiService.getSection2Data().then((value) => {
        list = value,
        setState(() {
          entities = list;
          _isLoading = false;
        })
      }).catchError((error) => {
        logger.e("Error while fetching section 2 entities: $error")
      });

    } catch (error) {
      logger.e("Error while fetching section 2 entities: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Section 2',
          style: TextStyle(color: Colors.white),),

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        backgroundColor: const Color(0xff008bcc),
      ),
      body: buildUI(),
    );
  }

  Widget buildUI() {
    if(_isLoading){
      return const Center(child: CircularProgressIndicator());
    }

    return entityListWidget();
  }

  Widget entityListWidget() {
    if(entities.isEmpty) {
      return
        const Text("There is no data available",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 18,
            )
        );

    } else {
      return ListView.builder(
        itemCount: entities.length,
        itemBuilder: (context, index) {
          final entity = entities[index];

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: const Color(0xffecfdff),
              child: ListTile(
                // key: ValueKey(entity.id),
                onTap: () {
                  debugPrint("Tapped on item with index $index");
                },
                title: entityCardWidget(context, entity),
              ),
            ),
          );
        },
      );
    }
  }

  Widget entityCardWidget(BuildContext context, Map<String, dynamic> entity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          entity['name'],
          style: const TextStyle(fontSize: 18, color: Colors.lightBlue),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}