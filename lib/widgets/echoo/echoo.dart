import 'package:Echoes/helper/enum.dart';
import 'package:Echoes/helper/utility.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/state/feedState.dart';
import 'package:Echoes/ui/page/feed/feedPostDetail.dart';
import 'package:Echoes/ui/page/profile/profilePage.dart';
import 'package:Echoes/ui/page/profile/widgets/circular_image.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:Echoes/widgets/echoo/widgets/echooIconsRow.dart';
import 'package:Echoes/widgets/echoo/widgets/parentEchoo.dart';
import 'package:Echoes/widgets/newWidget/title_text.dart';
import 'package:Echoes/widgets/url_text/customUrlText.dart';
import 'package:Echoes/widgets/url_text/custom_link_media_info.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../customWidgets.dart';
import 'widgets/echooImage.dart';
import 'widgets/reechooWidget.dart';

class Echoo extends StatelessWidget {
  final FeedModel model;
  final Widget? trailing;
  final EchooType type;
  final bool isDisplayOnProfile;
  final GlobalKey<ScaffoldState> scaffoldKey;
  const Echoo({
    Key? key,
    required this.model,
    this.trailing,
    this.type = EchooType.Echoo,
    this.isDisplayOnProfile = false,
    required this.scaffoldKey,
  }) : super(key: key);

  void onLongPressedEchoo(BuildContext context) {
    if (type == EchooType.Detail || type == EchooType.ParentEchoo) {
      Utility.copyToClipBoard(
          context: context,
          text: model.description ?? "",
          message: "Echoo copy to clipboard");
    }
  }

  void onTapEchoo(BuildContext context) {
    var feedState = Provider.of<FeedState>(context, listen: false);
    if (type == EchooType.Detail || type == EchooType.ParentEchoo) {
      return;
    }
    if (type == EchooType.Echoo && !isDisplayOnProfile) {
      feedState.clearAllDetailAndReplyEchooStack();
    }
    feedState.getPostDetailFromDatabase(null, model: model);
    Navigator.push(context, FeedPostDetail.getRoute(model.key!));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      children: <Widget>[
        /// Left vertical bar of a echoo
        type != EchooType.ParentEchoo
            ? const SizedBox.shrink()
            : Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 38,
                    top: 75,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(width: 2.0, color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ),
        InkWell(
          onLongPress: () {
            onLongPressedEchoo(context);
          },
          onTap: () {
            onTapEchoo(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                  top: type == EchooType.Echoo || type == EchooType.Reply
                      ? 12
                      : 0,
                ),
                child: type == EchooType.Echoo || type == EchooType.Reply
                    ? _EchooBody(
                        isDisplayOnProfile: isDisplayOnProfile,
                        model: model,
                        trailing: trailing,
                        type: type,
                      )
                    : _EchooDetailBody(
                        // isDisplayOnProfile: isDisplayOnProfile,
                        model: model,
                        trailing: trailing,
                        type: type,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: EchooImage(
                  model: model,
                  type: type,
                ),
              ),
              model.childRetwetkey == null
                  ? const SizedBox.shrink()
                  : ReechooWidget(
                      childRetwetkey: model.childRetwetkey!,
                      type: type,
                      isImageAvailable: model.imagePath != null &&
                          model.imagePath!.isNotEmpty,
                    ),
              Padding(
                padding:
                    EdgeInsets.only(left: type == EchooType.Detail ? 10 : 60),
                child: EchooIconsRow(
                  type: type,
                  model: model,
                  isEchooDetail: type == EchooType.Detail,
                  iconColor: Theme.of(context).textTheme.caption!.color!,
                  iconEnableColor: EchoesColor.ceriseRed,
                  size: 20,
                  scaffoldKey: GlobalKey<ScaffoldState>(),
                ),
              ),
              type == EchooType.ParentEchoo
                  ? const SizedBox.shrink()
                  : const Divider(height: .5, thickness: .5)
            ],
          ),
        ),
      ],
    );
  }
}

class _EchooBody extends StatelessWidget {
  final FeedModel model;
  final Widget? trailing;
  final EchooType type;
  final bool isDisplayOnProfile;
  const _EchooBody(
      {Key? key,
      required this.model,
      this.trailing,
      required this.type,
      required this.isDisplayOnProfile})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double descriptionFontSize = type == EchooType.Echoo
        ? 15
        : type == EchooType.Detail || type == EchooType.ParentEchoo
            ? 18
            : 14;
    FontWeight descriptionFontWeight =
        type == EchooType.Echoo || type == EchooType.Echoo
            ? FontWeight.w400
            : FontWeight.w400;
    TextStyle textStyle = TextStyle(
        color: Colors.black,
        fontSize: descriptionFontSize,
        fontWeight: descriptionFontWeight);
    TextStyle urlStyle = TextStyle(
        color: Colors.blue,
        fontSize: descriptionFontSize,
        fontWeight: descriptionFontWeight);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              // If echoo is displaying on someone's profile then no need to navigate to same user's profile again.
              if (isDisplayOnProfile) {
                return;
              }
              Navigator.push(
                  context, ProfilePage.getRoute(profileId: model.userId));
            },
            child: CircularImage(path: model.user!.profilePic),
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: context.width - 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: 0, maxWidth: context.width * .5),
                          child: TitleText(model.user!.displayName!,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 3),
                        model.user!.isVerified!
                            ? customIcon(
                                context,
                                icon: AppIcon.blueTick,
                                isEchoesIcon: true,
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
                          style:
                              TextStyles.userNameStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(child: trailing ?? const SizedBox()),
                ],
              ),
              model.description == null
                  ? const SizedBox()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UrlText(
                          text: model.description!.removeSpaces,
                          onHashTagPressed: (tag) {
                            cprint(tag);
                          },
                          style: textStyle,
                          urlStyle: urlStyle,
                        ),
                        // EchooTranslation(
                        //   languageCode: model.lanCode,
                        //   echooKey: model.key!,
                        //   description: model.description!,
                        //   textStyle: textStyle,
                        //   urlStyle: urlStyle,
                        // ),
                      ],
                    ),
              if (model.imagePath == null && model.description != null)
                CustomLinkMediaInfo(text: model.description!),
            ],
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}

class _EchooDetailBody extends StatelessWidget {
  final FeedModel model;
  final Widget? trailing;
  final EchooType type;
  // final bool isDisplayOnProfile;
  const _EchooDetailBody({
    Key? key,
    required this.model,
    this.trailing,
    required this.type,
    /*this.isDisplayOnProfile*/
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double descriptionFontSize = type == EchooType.Echoo
        ? context.getDimension(context, 15)
        : type == EchooType.Detail
            ? context.getDimension(context, 18)
            : type == EchooType.ParentEchoo
                ? context.getDimension(context, 14)
                : 10;

    FontWeight descriptionFontWeight =
        type == EchooType.Echoo || type == EchooType.Echoo
            ? FontWeight.w300
            : FontWeight.w400;
    TextStyle textStyle = TextStyle(
        color: Colors.black,
        fontSize: descriptionFontSize,
        fontWeight: descriptionFontWeight);
    TextStyle urlStyle = TextStyle(
        color: Colors.blue,
        fontSize: descriptionFontSize,
        fontWeight: descriptionFontWeight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        model.parentkey != null &&
                model.childRetwetkey == null &&
                type != EchooType.ParentEchoo
            ? ParentEchooWidget(
                childRetwetkey: model.parentkey!,
                // isImageAvailable: false,
                trailing: trailing,
                type: type,
              )
            : const SizedBox.shrink(),
        SizedBox(
          width: context.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context, ProfilePage.getRoute(profileId: model.userId));
                  },
                  child: CircularImage(path: model.user!.profilePic),
                ),
                title: Row(
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth: 0, maxWidth: context.width * .5),
                      child: TitleText(model.user!.displayName!,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 3),
                    model.user!.isVerified!
                        ? customIcon(
                            context,
                            icon: AppIcon.blueTick,
                            isEchoesIcon: true,
                            iconColor: AppColor.primary,
                            size: 13,
                            paddingIcon: 3,
                          )
                        : const SizedBox(width: 0),
                    SizedBox(
                      width: model.user!.isVerified! ? 5 : 0,
                    ),
                  ],
                ),
                subtitle: customText('${model.user!.userName}',
                    style: TextStyles.userNameStyle),
                trailing: trailing,
              ),
              model.description == null
                  ? const SizedBox()
                  : Padding(
                      padding: type == EchooType.ParentEchoo
                          ? const EdgeInsets.only(left: 80, right: 16)
                          : const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UrlText(
                              text: model.description!.removeSpaces,
                              onHashTagPressed: (tag) {
                                cprint(tag);
                              },
                              style: textStyle,
                              urlStyle: urlStyle),
                          // EchooTranslation(
                          //   languageCode: model.lanCode,
                          //   echooKey: model.key!,
                          //   description: model.description!,
                          //   textStyle: textStyle,
                          //   urlStyle: urlStyle,
                          // ),
                        ],
                      ),
                    ),
              if (model.imagePath == null && model.description != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomLinkMediaInfo(text: model.description!),
                )
            ],
          ),
        ),
      ],
    );
  }
}
