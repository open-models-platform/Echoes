import 'package:Echoes/helper/enum.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:flutter/material.dart';

class UnavailableEchoo extends StatelessWidget {
  const UnavailableEchoo({Key? key, required this.snapshot, required this.type})
      : super(key: key);

  final AsyncSnapshot<FeedModel?> snapshot;
  final EchooType type;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: EdgeInsets.only(
          right: 16,
          top: 5,
          left: type == EchooType.Echoo || type == EchooType.ParentEchoo
              ? 70
              : 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColor.extraLightGrey.withOpacity(.3),
        border: Border.all(color: AppColor.extraLightGrey, width: .5),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: snapshot.connectionState == ConnectionState.waiting
          ? SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: AppColor.extraLightGrey,
                valueColor: AlwaysStoppedAnimation(
                  AppColor.darkGrey.withOpacity(.3),
                ),
              ),
            )
          : Text('This Echoo is unavailable', style: TextStyles.userNameStyle),
    );
  }
}
