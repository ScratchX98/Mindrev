import 'package:flutter/material.dart';

import 'package:mindrev/services/text.dart';
import 'package:mindrev/extra/theme.dart';
import 'package:mindrev/widgets/widgets.dart';

import 'package:hive_flutter/hive_flutter.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  var box = Hive.lazyBox('mindrev');
  //futures that will be awaited by FutureBuilder
  Future futureText = readText('settings');

  //variables for form
  //final _formKey = GlobalKey<FormState>();
  bool uiColors = true;

  //function to get old settings
  void getSettings() async {
    var settings = await box.get('settings');

    //update pre set form vars
    try {
      uiColors = settings!['uiColors'];
    } catch (e) {
      uiColors = true;
    }
  }

  @override
  void initState() {
    super.initState();
    getSettings();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        futureText
      ]),
      builder: (BuildContext ctx, AsyncSnapshot<dynamic> snapshot) {
        //only show page when data is loaded
        if (snapshot.hasData) {
          //data loaded with FutureBuilder
          Map text = snapshot.data![0];

          return Scaffold(
            //appbar
            appBar: AppBar(
              foregroundColor: theme.secondaryText,
              title: Text(text['title']),
              centerTitle: true,
              elevation: 10,
              backgroundColor: theme.secondary,
            ),

            //button to save
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(
                Icons.save,
              ),
              label: Text(
                text['save'],
              ),
              foregroundColor: theme.accentText,
              backgroundColor: theme.accent,
              onPressed: () async {
                await box.put('settings', {
                  'uiColors': uiColors
                });
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),

            //body with everything
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text['ui'],
                            style: TextStyle(color: theme.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Divider(),
                          ListTile(
                            title: Text(text['uiColors'], style: defaultPrimaryTextStyle),
                            leading: Icon(Icons.palette, color: theme.accent),
                            trailing: Switch(
                              value: uiColors,
                              onChanged: (bool value) {
                                setState(() {
                                  uiColors = value;
                                });
                              },
                              activeColor: theme.accent,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            text['theme'],
                            style: TextStyle(color: theme.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Divider(),
                          Row (
                            children: [
                              const SizedBox(width: 15),
                            	Icon (Icons.brush, color: theme.accent),
                            	const SizedBox(width: 25),
                              Material(
                                color: theme.primary,
                                elevation: 8,
                                borderRadius: const BorderRadius.all(Radius.circular(15)),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column (
                                    children: const [
                                      Text('THEMES GO HERE') //to remove
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            //loading screen to be shown until Future is found
            body: loading,
          );
        }
      },
    );
  }
}
