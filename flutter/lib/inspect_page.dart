
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ma_exam_t/models/Albatross.dart';
import 'package:ma_exam_t/services/api_service.dart';

class InspectPage extends StatefulWidget {
  final Albatross entity;

  const InspectPage({super.key, required this.entity});

  @override
  State<StatefulWidget> createState() {
    return _InspectPageState();
  }
}

class _InspectPageState extends State<InspectPage> {
  ApiService apiService = ApiService();
  String? name;
  DateTime? date;
  int? id;
  bool _isLoading = true;

  TextEditingController nameController = new TextEditingController(text : "name");
  TextEditingController dateController = new TextEditingController(text : "date");


  @override
  void initState() {
    super.initState();

    name = widget.entity.name;
    date = widget.entity.date;
    id = widget.entity.id;

    fetchData();
  }

  void fetchData() {
    //Future.delayed(Duration(seconds: 1)).then((value) => {
    apiService.getEntity(widget.entity.id).then((value) => {
      setState(() {
        if(value != null) {
          id = value.id;
          dateController.text = DateFormat("yyyy-MM-dd").format(value.date);
          nameController.text = value.name;
          name = value.name;
          apiService.updateLocally(value);
          _isLoading = false;
          }
        })
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inspecting ${name!}',
          style: const TextStyle(color: Colors.white),),

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

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Center(child: inspectForm())
      ],
    );
  }

  StatefulWidget datePickerSetup() {
    return TextFormField(
      readOnly: true,

      controller: dateController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Date',
      ),
    );
  }

  Widget inspectForm() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.8,
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Form(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextFormField(
                controller: nameController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Entity name',
                )
            ),

            datePickerSetup(),

            Text("Entity ID: $id",
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 18,
              )
            )
          ],
        ),
      ),
    );
  }
}