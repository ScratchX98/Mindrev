import 'package:flutter/material.dart';

import 'package:mindrev/services/db.dart';
import 'package:mindrev/widgets/widgets.dart';

import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class ClassExtra extends StatefulWidget {
  const ClassExtra({Key? key}) : super(key: key);

  @override
  State<ClassExtra> createState() => _ClassExtraState();
}

class _ClassExtraState extends State<ClassExtra> {
  final TextEditingController _newNameController = TextEditingController();

  @override
  dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map routeData = ModalRoute.of(context)?.settings.arguments as Map;
    Map text = routeData['text'];
    var theme = routeData['theme'];
    var mClass = routeData['class'];
    _newNameController.text = mClass.name;

    //how we format our date
    DateFormat dateFormat = DateFormat('H:m\nE d/M/y');

    return Scaffold(
      backgroundColor: theme.primary,
      appBar: AppBar(
        foregroundColor: theme.secondaryText,
        title: Text(mClass.name),
        elevation: 4,
        centerTitle: true,
        backgroundColor: theme.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //date created
                ListTile(
                  textColor: theme.primaryText,
                  leading: Icon(Icons.calendar_today, color: theme.accent),
                  title: Text(text['creationDate'], style: defaultPrimaryTextStyle()),
                  trailing: Text(
                    dateFormat.format(DateTime.parse(mClass!.date)),
                    style: defaultPrimaryTextStyle(),
                  ),
                ),
                const SizedBox(height: 30),
                //rename class
                Text(
                  text['rename'],
                  style: TextStyle(
                    color: theme.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _newNameController,
                        cursorColor: theme.accent,
                        style: defaultPrimaryTextStyle(),
                        decoration: defaultPrimaryInputDecoration(
                          text['newName'],
                        ),
                      ),
                    ),
                    //note to self maybe remove old flip cards from list
                    IconButton(
                      onPressed: () async {
                        if (_newNameController.text.isNotEmpty) {
                          //move back to home page
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (Route<dynamic> route) => false,
                          );
                          await local.updateClass(
                            mClass,
                            routeData['structure'],
                            _newNameController.text,
                          );
                          //update again
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(defaultSnackbar(text['errorNoText']));
                        }
                      },
                      icon: Icon(Icons.check, color: theme.primaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                //delete class
                Row(
                  children: [
                    Text(
                      text['delete'],
                      style: TextStyle(
                        color: theme.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.warning, color: theme.primaryText),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                coloredButton(
                  text['delete'],
                  () {
                    Alert(
                      context: context,
                      style: defaultAlertStyle(),
                      title: text['sure'] + ' ' + mClass.name + '?',
                      buttons: [
                        coloredDialogButton(
                          text['confirm'],
                          context,
                          () async {
                            //go back to home page
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/home',
                              (Route<dynamic> route) => false,
                            );
                            await local.deleteClass(mClass, routeData['structure']);
                            //update again
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          theme.accent,
                          theme.accentText,
                        ),
                        coloredDialogButton(
                          text['cancel'],
                          context,
                          () => Navigator.pop(context),
                          theme.accent,
                          theme.accentText,
                        )
                      ],
                    ).show();
                  },
                  theme.accent,
                  theme.accentText,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
