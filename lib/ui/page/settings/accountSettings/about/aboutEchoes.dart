import 'package:Echoes/helper/utility.dart';
import 'package:Echoes/ui/page/settings/widgets/headerWidget.dart';
import 'package:Echoes/ui/page/settings/widgets/settingsRowWidget.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:Echoes/widgets/customAppBar.dart';
import 'package:Echoes/widgets/customWidgets.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoesColor.white,
      appBar: CustomAppBar(
        isBackButton: true,
        title: customTitleText(
          'About Echooes',
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          const HeaderWidget(
            'Help',
            secondHeader: true,
          ),
          SettingRowWidget(
            "Help Centre",
            vPadding: 0,
            showDivider: false,
            onPressed: () {
              Utility.launchURL(
                  "https://github.com/open-models-platform/Echoes/issues");
            },
          ),
          const HeaderWidget('Legal'),
          const SettingRowWidget(
            "Terms of Service",
            showDivider: true,
          ),
          const SettingRowWidget(
            "Privacy policy",
            showDivider: true,
          ),
          const SettingRowWidget(
            "Cookie use",
            showDivider: true,
          ),
          SettingRowWidget(
            "Legal notices",
            showDivider: true,
            onPressed: () async {
              showLicensePage(
                context: context,
                applicationName: 'Echooes',
                applicationVersion: '1.0.0',
                useRootNavigator: true,
              );
            },
          ),
          const HeaderWidget('Developer'),
          SettingRowWidget("Github", showDivider: true, onPressed: () {
            Utility.launchURL("https://github.com/open-models-platform");
          }),
          SettingRowWidget("LinkidIn", showDivider: true, onPressed: () {
            Utility.launchURL("https://www.linkedin.com/in/thealphamerc/");
          }),
          SettingRowWidget("Echoes", showDivider: true, onPressed: () {
            Utility.launchURL("https://echoes.com/TheAlphaMerc");
          }),
          SettingRowWidget("Blog", showDivider: true, onPressed: () {
            Utility.launchURL("https://dev.to/thealphamerc");
          }),
        ],
      ),
    );
  }
}
