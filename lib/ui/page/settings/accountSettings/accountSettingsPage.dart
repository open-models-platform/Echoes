import 'package:Echoes/model/user.dart';
import 'package:Echoes/state/authState.dart';
import 'package:Echoes/ui/page/settings/widgets/headerWidget.dart';
import 'package:Echoes/ui/page/settings/widgets/settingsAppbar.dart';
import 'package:Echoes/ui/page/settings/widgets/settingsRowWidget.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<AuthState>(context).userModel ?? UserModel();
    return Scaffold(
      backgroundColor: EchoesColor.white,
      appBar: SettingsAppBar(
        title: 'Account',
        subtitle: user.userName,
      ),
      body: ListView(
        children: <Widget>[
          const HeaderWidget('Login and security'),
          SettingRowWidget(
            "Username",
            subtitle: user.userName,
            // navigateTo: 'AccountSettingsPage',
          ),
          const Divider(height: 0),
          SettingRowWidget(
            "Phone",
            subtitle: user.contact,
          ),
          SettingRowWidget(
            "Email address",
            subtitle: user.email,
            navigateTo: 'VerifyEmailPage',
          ),
          const SettingRowWidget("Password"),
          const SettingRowWidget("Security"),
          const HeaderWidget(
            'Data and Permission',
            secondHeader: true,
          ),
          const SettingRowWidget("Country"),
          const SettingRowWidget("Your Echooes data"),
          const SettingRowWidget("Apps and sessions"),
          SettingRowWidget(
            "Log out",
            textColor: EchoesColor.ceriseRed,
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
              final state = Provider.of<AuthState>(context);
              state.logoutCallback();
            },
          ),
        ],
      ),
    );
  }
}
