import 'dart:io';

import 'package:Echoes/ui/theme/theme.dart';
import 'package:Echoes/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ComposeBottomIconWidget extends StatefulWidget {
  final TextEditingController textEditingController;
  final Function(File) onImageIconSelected;
  const ComposeBottomIconWidget(
      {Key? key,
      required this.textEditingController,
      required this.onImageIconSelected})
      : super(key: key);

  @override
  _ComposeBottomIconWidgetState createState() =>
      _ComposeBottomIconWidgetState();
}

class _ComposeBottomIconWidgetState extends State<ComposeBottomIconWidget> {
  bool reachToWarning = false;
  bool reachToOver = false;
  late Color wordCountColor;
  String echoo = '';

  @override
  void initState() {
    wordCountColor = Colors.blue;
    widget.textEditingController.addListener(updateUI);
    super.initState();
  }

  void updateUI() {
    setState(() {
      echoo = widget.textEditingController.text;
      if (widget.textEditingController.text.isNotEmpty) {
        if (widget.textEditingController.text.length > 259 &&
            widget.textEditingController.text.length < 280) {
          wordCountColor = Colors.orange;
        } else if (widget.textEditingController.text.length >= 280) {
          wordCountColor = Theme.of(context).errorColor;
        } else {
          wordCountColor = Colors.blue;
        }
      }
    });
  }

  Widget _bottomIconWidget() {
    return Container(
      width: context.width,
      height: 50,
      decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          color: Theme.of(context).backgroundColor),
      child: Row(
        children: <Widget>[
          IconButton(
              onPressed: () {
                setImage(ImageSource.gallery);
              },
              icon: customIcon(context,
                  icon: AppIcon.image,
                  isEchoesIcon: true,
                  iconColor: AppColor.primary)),
          IconButton(
              onPressed: () {
                setImage(ImageSource.camera);
              },
              icon: customIcon(context,
                  icon: AppIcon.camera,
                  isEchoesIcon: true,
                  iconColor: AppColor.primary)),
          Expanded(
              child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                child: /*echoo != null &&*/ echoo.length > 289
                    ? Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: customText('${280 - echoo.length}',
                            style:
                                TextStyle(color: Theme.of(context).errorColor)),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          CircularProgressIndicator(
                            value: getEchooLimit(),
                            backgroundColor: Colors.grey,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(wordCountColor),
                          ),
                          echoo.length > 259
                              ? customText('${280 - echoo.length}',
                                  style: TextStyle(color: wordCountColor))
                              : customText('',
                                  style: TextStyle(color: wordCountColor))
                        ],
                      )),
          ))
        ],
      ),
    );
  }

  void setImage(ImageSource source) {
    ImagePicker()
        .pickImage(source: source, imageQuality: 20)
        .then((XFile? file) {
      setState(() {
        // _image = file;
        widget.onImageIconSelected(File(file!.path));
      });
    });
  }

  double getEchooLimit() {
    if (/*echoo == null || */ echoo.isEmpty) {
      return 0.0;
    }
    if (echoo.length > 280) {
      return 1.0;
    }
    var length = echoo.length;
    var val = length * 100 / 28000.0;
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _bottomIconWidget(),
    );
  }
}
