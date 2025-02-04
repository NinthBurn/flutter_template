
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ma_exam_t/models/Albatross.dart';

class EditPage extends StatefulWidget {
  final Albatross entity;

  const EditPage({super.key, required this.entity});

  @override
  State<StatefulWidget> createState() {
    return _EditPageState();
  }

}

class _EditPageState extends State<EditPage> {
  final GlobalKey<FormState> _editFormKey = GlobalKey();
  final TextEditingController _date = TextEditingController();

  String? name;
  DateTime? date = DateTime.now();

  @override
  void initState() {
    super.initState();

    name = widget.entity.name;
    date = widget.entity.date;
    _date.text = DateFormat("yyyy-MM-dd").format(date!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Editing ${name!}',
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
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Center(child: editForm())
      ],
    );
  }

  Widget editButtonSetup() {
    return ElevatedButton(
        onPressed: () {
          if(_editFormKey.currentState?.validate() ?? false) {
            _editFormKey.currentState?.save();
            Albatross selectedEntity = Albatross(date: date!, name: name!);
            selectedEntity.id = widget.entity.id;

            Navigator.pop(context, selectedEntity);
          }
        },

        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff008bcc)
        ),

        child: const Text("Modify",
          style: TextStyle(
              color: Colors.white
          ),
        )
    );
  }

  StatefulWidget datePickerSetup() {
    return TextFormField(
      validator: (value) {
        if(value == null || value.isEmpty) {
          return "Invalid date";
        }
        return null;
      },

      onSaved: (value) {
        setState(() {
          date = DateTime.parse(value!);
        });
      },

      controller: _date,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Date',
      ),

      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101)
        );

        if(pickedDate != null) {
          setState(() {
            // fuck you
            // _date.text = "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
            _date.text = DateFormat("yyyy-MM-dd").format(pickedDate);
          });
        }
      },
    );
  }

  StatefulWidget entityNameInputSetup() {
    return TextFormField(
        keyboardType: TextInputType.text,
        initialValue: name,
        validator: (value) {
          if(value == null || value.isEmpty) {
            return "Invalid entity name";
          }
          return null;
        },

        onSaved: (value) {
          setState(() {
            name = value;
          });
        },

        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Entity name',
        )
    );
  }

  Widget editForm() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.8,
      height: MediaQuery.sizeOf(context).height * 0.85,

      child: Form(
        key: _editFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            entityNameInputSetup(),
            datePickerSetup(),
            editButtonSetup()
          ],
        ),
      ),
    );
  }

  // templates for int & float

  // StatefulWidget priceInputSetup() {
  //   return TextFormField(
  //       keyboardType: const TextInputType.numberWithOptions(decimal: true),
  //       initialValue: price.toString(),
  //       validator: (value) {
  //         if(value == null || value.isEmpty) {
  //           return "Invalid price; only positive numbers are accepted";
  //         }
  //         return null;
  //       },
  //       inputFormatters: <TextInputFormatter>[
  //         FilteringTextInputFormatter.allow(RegExp(r'[0-9]+\.?[0-9]*')),
  //       ],
  //
  //       onSaved: (value) {
  //         setState(() {
  //           price = double.parse(value!);
  //         });
  //       },
  //
  //       decoration: const InputDecoration(
  //         border: OutlineInputBorder(),
  //         labelText: 'Price',
  //       )
  //   );
  // }
  //
  // StatefulWidget quantityInputSetup() {
  //   return TextFormField(
  //       keyboardType: TextInputType.number,
  //       initialValue: quantity.toString(),
  //       validator: (value) {
  //         if(value == null || value.isEmpty) {
  //           return "Invalid quantity; only positive integers are accepted";
  //         }
  //         return null;
  //       },
  //       inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
  //
  //       onSaved: (value) {
  //         setState(() {
  //           quantity = int.parse(value!);
  //         });
  //       },
  //
  //       decoration: const InputDecoration(
  //         border: OutlineInputBorder(),
  //         labelText: 'Quantity',
  //       )
  //   );
  // }
}