import 'package:Echoes/ui/page/settings/widgets/settingsRowWidget.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:Echoes/widgets/customAppBar.dart';
import 'package:Echoes/widgets/customWidgets.dart';
import 'package:flutter/material.dart';

class ProxyPage extends StatelessWidget {
  const ProxyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoesColor.white,
      appBar: CustomAppBar(
        isBackButton: true,
        title: customTitleText(
          'Proxy',
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: const <Widget>[
          SettingRowWidget(
            "Enable HTTP Proxy",
            showCheckBox: false,
            vPadding: 15,
            showDivider: true,
            subtitle:
                'Configure HTTP proxy for network request (note: this does not apply to browser).',
          ),
          SettingRowWidget(
            "Proxy Host",
            subtitle: 'Configure your proxy\'s hostname.',
            showDivider: true,
          ),
          SettingRowWidget(
            "Proxy Port",
            subtitle: 'Configure your proxy\'s port number.',
          ),
        ],
      ),
    );
  }
}
