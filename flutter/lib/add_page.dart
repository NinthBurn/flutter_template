
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ma_exam_t/models/Albatross.dart';

class AddPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AddPageState();
  }

}

class _AddPageState extends State<AddPage> {
  final GlobalKey<FormState> _addFormKey = GlobalKey();
  final TextEditingController _date = TextEditingController();

  DateTime? date;
  String? name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Add a new element',
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
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Center(child: addForm())
      ],
    );
  }

  Widget addButtonSetup() {
    return ElevatedButton(
        onPressed: () {
          if(_addFormKey.currentState?.validate() ?? false) {
            _addFormKey.currentState?.save();
            Albatross addedElement = Albatross(date: date!, name: name!);

            Navigator.pop(context, addedElement);
          }
        },

        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff008bcc)
        ),

        child: const Text("Register",
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

      readOnly: true,
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
            _date.text = DateFormat("yyyy-MM-dd").format(pickedDate);
          });
        }
      },
    );
  }

  StatefulWidget entityNameInputSetup() {
    return TextFormField(
        keyboardType: TextInputType.text,
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

  Widget addForm() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.8,
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Form(
        key: _addFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            entityNameInputSetup(),
            datePickerSetup(),
            addButtonSetup()
          ],
        ),
      ),
    );
  }

  // samples for int & float
  // StatefulWidget priceInputSetup() {
  //   return TextFormField(
  //       keyboardType: const TextInputType.numberWithOptions(decimal: true),
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