import 'package:Echoes/helper/enum.dart';
import 'package:Echoes/helper/utility.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/state/feedState.dart';
import 'package:Echoes/ui/page/feed/feedPostDetail.dart';
import 'package:Echoes/ui/page/profile/widgets/circular_image.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:Echoes/widgets/customWidgets.dart';
import 'package:Echoes/widgets/echoo/widgets/echooImage.dart';
import 'package:Echoes/widgets/echoo/widgets/unavailableEchoo.dart';
import 'package:Echoes/widgets/newWidget/rippleButton.dart';
import 'package:Echoes/widgets/newWidget/title_text.dart';
import 'package:Echoes/widgets/url_text/customUrlText.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReechooWidget extends StatelessWidget {
  const ReechooWidget(
      {Key? key,
      required this.childRetwetkey,
      required this.type,
      this.isImageAvailable = false})
      : super(key: key);

  final String childRetwetkey;
  final bool isImageAvailable;
  final EchooType type;

  Widget _echoo(BuildContext context, FeedModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          width: context.width - 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              SizedBox(
                width: 20,
                height: 20,
                child: CircularImage(path: model.user!.profilePic),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints:
                    BoxConstraints(minWidth: 0, maxWidth: context.width * .5),
                child: TitleText(
                  model.user!.displayName!,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 3),
              model.user!.isVerified!
                  ? customIcon(
                      context,
                      icon: AppIcon.blueTick,
                      isTwitterIcon: true,
                      iconColor: AppColor.primary,
                      size: 13,
                      paddingIcon: 3,
                    )
                  : const SizedBox(width: 0),
              SizedBox(
                width: model.user!.isVerified! ? 5 : 0,
              ),
              Flexible(
                child: customText(
                  '${model.user!.userName}',
                  style: TextStyles.userNameStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              customText(
                '· ${Utility.getChatTime(model.createdAt)}',
                style: TextStyles.userNameStyle.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        model.description == null
            ? const SizedBox()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: UrlText(
                  text: model.description!.takeOnly(150),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  urlStyle: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w400),
                ),
              ),
        SizedBox(height: model.imagePath == null ? 8 : 0),
        EchooImage(model: model, type: type, isReechooImage: true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var feedstate = Provider.of<FeedState>(context, listen: false);
    return FutureBuilder(
      future: feedstate.fetchEchoo(childRetwetkey),
      builder: (context, AsyncSnapshot<FeedModel?> snapshot) {
        if (snapshot.hasData) {
          return Container(
            margin: EdgeInsets.only(
                left: type == EchooType.Echoo || type == EchooType.ParentEchoo
                    ? 70
                    : 12,
                right: 16,
                top: isImageAvailable ? 8 : 5),
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.extraLightGrey, width: .5),
              borderRadius: const BorderRadius.all(Radius.circular(15)),
            ),
            child: RippleButton(
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              onPressed: () {
                feedstate.getPostDetailFromDatabase(null,
                    model: snapshot.data!);
                Navigator.push(
                    context, FeedPostDetail.getRoute(snapshot.data!.key!));
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                child: _echoo(context, snapshot.data!),
              ),
            ),
          );
        }
        if ((snapshot.connectionState == ConnectionState.done ||
                snapshot.connectionState == ConnectionState.waiting) &&
            !snapshot.hasData) {
          return UnavailableEchoo(
            snapshot: snapshot,
            type: type,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
