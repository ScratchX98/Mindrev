import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:mindrev/pages/notes/markdown_text_input/markdown_text_input.dart';
import 'package:mindrev/pages/notes/markdown_text_input/format_markdown.dart';
import 'package:mindrev/services/db.dart';
import 'package:mindrev/services/text.dart';
import 'package:mindrev/models/mindrev_notes.dart';
import 'package:mindrev/models/mindrev_settings.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mindrev/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:scroll_app_bar/scroll_app_bar.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({Key? key}) : super(key: key);

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  MindrevNotes? notes;
  Map? routeData;
  String imgDirectory = '';
  bool edit = false;
  MindrevSettings? settings;
  Box? box;

  //controller for hiding/showing appBar
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    //we basically only need this to determine whether to show formatting bar
    local.getSettings().then(
        (MindrevSettings settings) => setState(() => this.settings = settings),);
  }

  @override
  void didChangeDependencies() {
    routeData = ModalRoute.of(context)?.settings.arguments as Map;
    local.getMaterialData(routeData!['material']).then(
      (value) async {
        await Hive.openBox(
          '${routeData!['material'].id}-images',
        ).then((value) async {
          return box = value;
        });
        setState(() {
          notes = value;
          box;
        });
      },
    );
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();

    if (settings != null && notes != null && box != null) {
      var theme = routeData?['theme'];

      if (notes!.content == '') edit = true;
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.primary,
        appBar: ScrollAppBar(
          automaticallyImplyLeading: true,
          controller: scrollController,
          foregroundColor: theme.secondaryText,
          title: Text(notes!.name),
          elevation: 4,
          centerTitle: true,
          backgroundColor: theme.secondary,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () async {
                routeData?['text'] = await readText('materialExtra');
                Navigator.pushNamed(context, '/materialExtra',
                    arguments: routeData,);
              },
            ),
            IconButton(
              icon: Icon(
                edit == true ? Icons.check : Icons.edit,
                color: theme.secondaryText,
              ),
              onPressed: () async {
                setState(() {
                  edit = !edit;
                });
              },
            )
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: edit
                ? MarkdownTextInput(
                    (String value) => setState(() {
                      //update notes when modified
                      notes!.content = value;
                      local.updateMaterialData(
                        routeData?['material'],
                        notes,
                      );
                    }),
                    notes!.content,
                    maxLines: null,
                    actions: MarkdownType.values,
                    controller: controller,
                    theme: theme,
                    scrollController: scrollController,
                    formatBar: settings!.markdownEdit!,
                    materialDetails: {
                      'material': routeData?['material'],
                      'notes': notes,
                    },
                  )
                : Snap(
                    controller: scrollController.appBar,
                    child: Markdown(
                      builders: <String, MarkdownElementBuilder>{
                        'math': MathBuilder(),
                      },
                      //extend markdown spec to add MathTex
                      extensionSet: md.ExtensionSet(
                        <md.BlockSyntax>[],
                        <md.InlineSyntax>[MathSyntax()],
                      ),
                      controller: scrollController,
                      styleSheet: MarkdownStyleSheet(
                        h1: TextStyle(color: theme.primaryText, fontSize: 25),
                        h1Align: WrapAlignment.center,
                        h2: TextStyle(color: theme.primaryText, fontSize: 23),
                        h3: TextStyle(color: theme.primaryText, fontSize: 21),
                        h4: TextStyle(color: theme.primaryText, fontSize: 19),
                        h5: TextStyle(color: theme.primaryText, fontSize: 17),
                        h6: TextStyle(color: theme.primaryText, fontSize: 15.5),
                        listBullet: TextStyle(color: theme.primaryText),
                        p: TextStyle(color: theme.primaryText, fontSize: 14.5),
                        a: TextStyle(
                            color: theme.accent,
                            decoration: TextDecoration.underline,),
                        tableBody: TextStyle(color: theme.primaryText),
                        tableHead: TextStyle(color: theme.primaryText),
                        codeblockDecoration: const BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        code: TextStyle(
                          color: theme.primaryText,
                          backgroundColor: Colors.transparent,
                          fontFamily: 'SourceCodePro',
                        ),
                        blockquoteAlign: WrapAlignment.center,
                        blockquoteDecoration: const BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      onTapLink: (String text, String? href, String title) {
                        launchUrlString(href!);
                      },
                      data: notes!.content,
                      shrinkWrap: true,
                      //display a custom image from hive
                      imageBuilder: (uri, first, second) {
                        return displayImageWeb(uri, box!, context);
                      },
                    ),
                  ),
          ),
        ),
      );
    } else {
      return loading();
    }
  }
}

//frankly I have no idea how half of this works, see flutter_markdown documentation, GL
class MathBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.textContent.substring(0, 2) == '\$\$') {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 30),
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            children: [
              Math.tex(
                element.textContent
                    .substring(0, element.textContent.length - 2)
                    .substring(2, element.textContent.length - 2),
                mathStyle: MathStyle.text,
                textStyle: largePrimaryTextStyle(),
              ),
            ],
          ),
        ),
      );
    } else {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 15),
        child: ListView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          children: [
            Math.tex(
              element.textContent
                  .substring(0, element.textContent.length - 1)
                  .substring(1, element.textContent.length - 1),
              mathStyle: MathStyle.text,
              textStyle: defaultPrimaryTextStyle(),
            ),
          ],
        ),
      );
    }
  }
}

class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(_pattern);
  static const String _pattern = r'\$+(.+?)\$+'; //I hate regex

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[0]!));
    return true;
  }
}

///TODO add zoom in/out
//get image bytes from hive and return a full image widget
Widget displayImageWeb(Uri uri, Box box, context) {
  return GestureDetector(
    onTap: () {
      showImageViewer(
        context,
        Image.memory(
          Uint8List.fromList(base64Decode(box.get(uri.toString()))),
        ).image,
      );
    },
    child: Image.memory(
      Uint8List.fromList(base64Decode(box.get(uri.toString()))),
    ),
  );
}
