import 'package:Echoes/helper/customRoute.dart';
import 'package:Echoes/helper/enum.dart';
import 'package:Echoes/helper/utility.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/state/authState.dart';
import 'package:Echoes/state/feedState.dart';
import 'package:Echoes/ui/page/common/usersListPage.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:Echoes/widgets/customWidgets.dart';
import 'package:Echoes/widgets/echoo/widgets/echooBottomSheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EchooIconsRow extends StatelessWidget {
  final FeedModel model;
  final Color iconColor;
  final Color iconEnableColor;
  final double? size;
  final bool isEchooDetail;
  final EchooType? type;
  final GlobalKey<ScaffoldState> scaffoldKey;
  const EchooIconsRow(
      {Key? key,
      required this.model,
      required this.iconColor,
      required this.iconEnableColor,
      this.size,
      this.isEchooDetail = false,
      this.type,
      required this.scaffoldKey})
      : super(key: key);

  Widget _likeCommentsIcons(BuildContext context, FeedModel model) {
    var authState = Provider.of<AuthState>(context, listen: false);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 0, top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(
            width: 20,
          ),
          _iconWidget(
            context,
            text: isEchooDetail ? '' : model.commentCount.toString(),
            icon: AppIcon.reply,
            iconColor: iconColor,
            size: size ?? 20,
            onPressed: () {
              var state = Provider.of<FeedState>(context, listen: false);
              state.setEchooToReply = model;
              Navigator.of(context).pushNamed('/ComposeEchooPage');
            },
          ),
          _iconWidget(context,
              text: isEchooDetail ? '' : model.reechooCount.toString(),
              icon: AppIcon.reechoo,
              iconColor: iconColor,
              size: size ?? 20, onPressed: () {
            EchooBottomSheet().openReechooBottomSheet(context,
                type: type, model: model, scaffoldKey: scaffoldKey);
          }),
          _iconWidget(
            context,
            text: isEchooDetail ? '' : model.likeCount.toString(),
            icon: model.likeList!.any((userId) => userId == authState.userId)
                ? AppIcon.heartFill
                : AppIcon.heartEmpty,
            onPressed: () {
              addLikeToEchoo(context);
            },
            iconColor:
                model.likeList!.any((userId) => userId == authState.userId)
                    ? iconEnableColor
                    : iconColor,
            size: size ?? 20,
          ),
          _iconWidget(context, text: '', icon: null, sysIcon: Icons.share,
              onPressed: () {
            shareEchoo(context);
          }, iconColor: iconColor, size: size ?? 20),
        ],
      ),
    );
  }

  Widget _iconWidget(BuildContext context,
      {required String text,
      IconData? icon,
      Function? onPressed,
      IconData? sysIcon,
      required Color iconColor,
      double size = 20}) {
    if (sysIcon == null) assert(icon != null);
    if (icon == null) assert(sysIcon != null);

    return Expanded(
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              if (onPressed != null) onPressed();
            },
            icon: sysIcon != null
                ? Icon(sysIcon, color: iconColor, size: size)
                : customIcon(
                    context,
                    size: size,
                    icon: icon!,
                    isEchoesIcon: true,
                    iconColor: iconColor,
                  ),
          ),
          customText(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: iconColor,
              fontSize: size - 5,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _timeWidget(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            const SizedBox(width: 5),
            customText(Utility.getPostTime2(model.createdAt),
                style: TextStyles.textStyle14),
            const SizedBox(width: 10),
            customText('Echooes for Android',
                style: TextStyle(color: Theme.of(context).primaryColor))
          ],
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _likeCommentWidget(BuildContext context) {
    bool isLikeAvailable =
        model.likeCount != null ? model.likeCount! > 0 : false;
    bool isReechooAvailable = model.reechooCount! > 0;
    bool isLikeReechooAvailable = isReechooAvailable || isLikeAvailable;
    return Column(
      children: <Widget>[
        const Divider(
          endIndent: 10,
          height: 0,
        ),
        AnimatedContainer(
          padding:
              EdgeInsets.symmetric(vertical: isLikeReechooAvailable ? 12 : 0),
          duration: const Duration(milliseconds: 500),
          child: !isLikeReechooAvailable
              ? const SizedBox.shrink()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    !isReechooAvailable
                        ? const SizedBox.shrink()
                        : customText(model.reechooCount.toString(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                    !isReechooAvailable
                        ? const SizedBox.shrink()
                        : const SizedBox(width: 5),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: customText('Reechoos',
                          style: TextStyles.subtitleStyle),
                      crossFadeState: !isReechooAvailable
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 800),
                    ),
                    !isReechooAvailable
                        ? const SizedBox.shrink()
                        : const SizedBox(width: 20),
                    InkWell(
                      onTap: () {
                        onLikeTextPressed(context);
                      },
                      child: AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Row(
                          children: <Widget>[
                            customSwitcherWidget(
                              duraton: const Duration(milliseconds: 300),
                              child: customText(model.likeCount.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  key: ValueKey(model.likeCount)),
                            ),
                            const SizedBox(width: 5),
                            customText('Likes', style: TextStyles.subtitleStyle)
                          ],
                        ),
                        crossFadeState: !isLikeAvailable
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      ),
                    )
                  ],
                ),
        ),
        !isLikeReechooAvailable
            ? const SizedBox.shrink()
            : const Divider(
                endIndent: 10,
                height: 0,
              ),
      ],
    );
  }

  Widget customSwitcherWidget(
      {required child, Duration duraton = const Duration(milliseconds: 500)}) {
    return AnimatedSwitcher(
      duration: duraton,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(child: child, scale: animation);
      },
      child: child,
    );
  }

  void addLikeToEchoo(BuildContext context) {
    var state = Provider.of<FeedState>(context, listen: false);
    var authState = Provider.of<AuthState>(context, listen: false);
    state.addLikeToEchoo(model, authState.userId);
  }

  void onLikeTextPressed(BuildContext context) {
    Navigator.of(context).push(
      CustomRoute<bool>(
        builder: (BuildContext context) => UsersListPage(
          pageTitle: "Liked by",
          userIdsList: model.likeList!.map((userId) => userId).toList(),
          emptyScreenText: "This echoo has no like yet",
          emptyScreenSubTileText:
              "Once a user likes this echoo, user list will be shown here",
        ),
      ),
    );
  }

  void shareEchoo(BuildContext context) async {
    EchooBottomSheet().openShareEchooBottomSheet(context, model, type);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        isEchooDetail ? _timeWidget(context) : const SizedBox(),
        isEchooDetail ? _likeCommentWidget(context) : const SizedBox(),
        _likeCommentsIcons(context, model)
      ],
    );
  }
}
