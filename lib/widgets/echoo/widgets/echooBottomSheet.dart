import 'package:Echoes/helper/enum.dart';
import 'package:Echoes/helper/utility.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/model/user.dart';
import 'package:Echoes/state/authState.dart';
import 'package:Echoes/state/feedState.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:Echoes/widgets/customWidgets.dart';
import 'package:Echoes/widgets/echoo/echoo.dart';
import 'package:Echoes/widgets/share_widget.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EchooBottomSheet {
  Widget echooOptionIcon(BuildContext context,
      {required FeedModel model,
      required EchooType type,
      required GlobalKey<ScaffoldState> scaffoldKey}) {
    return Container(
      width: 25,
      height: 25,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: customIcon(context,
          icon: AppIcon.arrowDown,
          isEchoesIcon: true,
          iconColor: AppColor.lightGrey),
    ).ripple(
      () {
        _openBottomSheet(context,
            type: type, model: model, scaffoldKey: scaffoldKey);
      },
      borderRadius: BorderRadius.circular(20),
    );
  }

  void _openBottomSheet(BuildContext context,
      {required EchooType type,
      required FeedModel model,
      required GlobalKey<ScaffoldState> scaffoldKey}) async {
    var authState = Provider.of<AuthState>(context, listen: false);
    bool isMyEchoo = authState.userId == model.userId;
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            padding: const EdgeInsets.only(top: 5, bottom: 0),
            height: context.height *
                (type == EchooType.Echoo
                    ? (isMyEchoo ? .25 : .44)
                    : (isMyEchoo ? .38 : .52)),
            width: context.width,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomSheetTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: type == EchooType.Echoo
                ? _echooOptions(context,
                    scaffoldKey: scaffoldKey,
                    isMyEchoo: isMyEchoo,
                    model: model,
                    type: type)
                : _echooDetailOptions(context,
                    scaffoldKey: scaffoldKey,
                    isMyEchoo: isMyEchoo,
                    model: model,
                    type: type));
      },
    );
  }

  Widget _echooDetailOptions(BuildContext context,
      {required bool isMyEchoo,
      required FeedModel model,
      required EchooType type,
      required GlobalKey<ScaffoldState> scaffoldKey}) {
    return Column(
      children: <Widget>[
        Container(
          width: context.width * .1,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        ),
        _widgetBottomSheetRow(context, AppIcon.link,
            text: 'Copy link to echoo', isEnable: true, onPressed: () async {
          Navigator.pop(context);
          var uri = await Utility.createLinkToShare(
            context,
            "echoo/${model.key}",
            socialMetaTagParameters: SocialMetaTagParameters(
                description: model.description ??
                    "${model.user!.displayName} posted a echoo on Echooes.",
                title: "Echoo on Echooes app",
                imageUrl: Uri.parse(
                    "https://play-lh.googleusercontent.com/e66XMuvW5hZ7HnFf8R_lcA3TFgkxm0SuyaMsBs3KENijNHZlogUAjxeu9COqsejV5w=s180-rw")),
          );

          Utility.copyToClipBoard(
              context: context,
              text: uri.toString(),
              message: "Echoo link copy to clipboard");
        }),
        isMyEchoo
            ? _widgetBottomSheetRow(
                context,
                AppIcon.delete,
                text: 'Delete Echoo',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete"),
                      content: const Text('Do you want to delete this Echoo?'),
                      actions: [
                        // ignore: deprecated_member_use
                        TextButton(
                          // textColor: Colors.black,
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        // ignore: deprecated_member_use
                        TextButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              EchoesColor.dodgeBlue,
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              EchoesColor.white,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteEchoo(
                              context,
                              type,
                              model.key!,
                              parentkey: model.parentkey,
                            );
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );
                },
                isEnable: true,
              )
            : Container(),
        isMyEchoo
            ? _widgetBottomSheetRow(
                context,
                AppIcon.unFollow,
                text: 'Pin to profile',
              )
            : _widgetBottomSheetRow(
                context,
                AppIcon.unFollow,
                text: 'Unfollow ${model.user!.userName}',
              ),
        isMyEchoo
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.mute,
                text: 'Mute ${model.user!.userName}',
              ),
        _widgetBottomSheetRow(
          context,
          AppIcon.mute,
          text: 'Mute this conversation',
        ),
        _widgetBottomSheetRow(
          context,
          AppIcon.viewHidden,
          text: 'View hidden replies',
        ),
        isMyEchoo
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.block,
                text: 'Block ${model.user!.userName}',
              ),
        isMyEchoo
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.report,
                text: 'Report Echoo',
              ),
      ],
    );
  }

  Widget _echooOptions(BuildContext context,
      {required bool isMyEchoo,
      required FeedModel model,
      required EchooType type,
      required GlobalKey<ScaffoldState> scaffoldKey}) {
    return Column(
      children: <Widget>[
        Container(
          width: context.width * .1,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        ),
        _widgetBottomSheetRow(context, AppIcon.link,
            text: 'Copy link to echoo', isEnable: true, onPressed: () async {
          var uri = await Utility.createLinkToShare(
            context,
            "echoo/${model.key}",
            socialMetaTagParameters: SocialMetaTagParameters(
                description: model.description ??
                    "${model.user!.displayName} posted a echoo on Echooes.",
                title: "Echoo on Echooes app",
                imageUrl: Uri.parse(
                    "https://play-lh.googleusercontent.com/e66XMuvW5hZ7HnFf8R_lcA3TFgkxm0SuyaMsBs3KENijNHZlogUAjxeu9COqsejV5w=s180-rw")),
          );

          Navigator.pop(context);
          Utility.copyToClipBoard(
              context: context,
              text: uri.toString(),
              message: "Echoo link copy to clipboard");
        }),
        isMyEchoo
            ? _widgetBottomSheetRow(
                context,
                AppIcon.delete,
                text: 'Delete Echoo',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete"),
                      content: const Text('Do you want to delete this Echoo?'),
                      actions: [
                        // ignore: deprecated_member_use
                        TextButton(
                          // textColor: Colors.black,
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        // ignore: deprecated_member_use
                        TextButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              EchoesColor.dodgeBlue,
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              EchoesColor.white,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteEchoo(
                              context,
                              type,
                              model.key!,
                              parentkey: model.parentkey,
                            );
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );
                },
                isEnable: true,
              )
            : Container(),
        isMyEchoo
            ? _widgetBottomSheetRow(
                context,
                AppIcon.thumbpinFill,
                text: 'Pin to profile',
              )
            : _widgetBottomSheetRow(
                context,
                AppIcon.sadFace,
                text: 'Not interested in this',
              ),
        isMyEchoo
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.unFollow,
                text: 'Unfollow ${model.user!.userName}',
              ),
        isMyEchoo
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.mute,
                text: 'Mute ${model.user!.userName}',
              ),
        isMyEchoo
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.block,
                text: 'Block ${model.user!.userName}',
              ),
        isMyEchoo
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.report,
                text: 'Report Echoo',
              ),
      ],
    );
  }

  Widget _widgetBottomSheetRow(BuildContext context, IconData icon,
      {required String text, Function? onPressed, bool isEnable = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            customIcon(
              context,
              icon: icon,
              isEchoesIcon: true,
              size: 25,
              paddingIcon: 8,
              iconColor:
                  onPressed != null ? AppColor.darkGrey : AppColor.lightGrey,
            ),
            const SizedBox(
              width: 15,
            ),
            customText(
              text,
              context: context,
              style: TextStyle(
                color: isEnable ? AppColor.secondary : AppColor.lightGrey,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            )
          ],
        ),
      ).ripple(() {
        if (onPressed != null) {
          onPressed();
        } else {
          Navigator.pop(context);
        }
      }),
    );
  }

  void _deleteEchoo(BuildContext context, EchooType type, String echooId,
      {String? parentkey}) {
    var state = Provider.of<FeedState>(context, listen: false);
    state.deleteEchoo(echooId, type, parentkey: parentkey);
    // CLose bottom sheet
    Navigator.of(context).pop();
    if (type == EchooType.Detail) {
      // Close Echoo detail page
      Navigator.of(context).pop();
      // Remove last echoo from echoo detail stack page
      state.removeLastEchooDetail(echooId);
    }
  }

  void openReechooBottomSheet(BuildContext context,
      {EchooType? type,
      required FeedModel model,
      required GlobalKey<ScaffoldState> scaffoldKey}) async {
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            padding: const EdgeInsets.only(top: 5, bottom: 0),
            height: 130,
            width: context.width,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomSheetTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _reechoo(context, model, type));
      },
    );
  }

  Widget _reechoo(BuildContext context, FeedModel model, EchooType? type) {
    return Column(
      children: <Widget>[
        Container(
          width: context.width * .1,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        ),
        _widgetBottomSheetRow(
          context,
          AppIcon.reechoo,
          isEnable: true,
          text: 'Reechoo',
          onPressed: () async {
            var state = Provider.of<FeedState>(context, listen: false);
            var authState = Provider.of<AuthState>(context, listen: false);
            var myUser = authState.userModel;
            myUser = UserModel(
                displayName: myUser!.displayName ?? myUser.email!.split('@')[0],
                profilePic: myUser.profilePic,
                userId: myUser.userId,
                isVerified: authState.userModel!.isVerified,
                userName: authState.userModel!.userName);
            // Prepare current Echoo model to reply
            FeedModel post = FeedModel(
                childRetwetkey: model.getEchooKeyToReechoo,
                createdAt: DateTime.now().toUtc().toString(),
                user: myUser,
                userId: myUser.userId!);
            state.createEchoo(post);

            Navigator.pop(context);
            var sharedPost = await state.fetchEchoo(post.childRetwetkey!);
            if (sharedPost != null) {
              sharedPost.reechooCount ??= 0;
              sharedPost.reechooCount = sharedPost.reechooCount! + 1;
              state.updateEchoo(sharedPost);
            }
          },
        ),
        _widgetBottomSheetRow(
          context,
          AppIcon.edit,
          text: 'Reechoo with comment',
          isEnable: true,
          onPressed: () {
            var state = Provider.of<FeedState>(context, listen: false);
            // Prepare current Echoo model to reply
            state.setEchooToReply = model;
            Navigator.pop(context);

            /// `/ComposeEchooPage/reechoo` route is used to identify that echoo is going to be reechoo.
            /// To simple reply on any `Echoo` use `ComposeEchooPage` route.
            Navigator.of(context).pushNamed('/ComposeEchooPage/reechoo');
          },
        )
      ],
    );
  }

  void openShareEchooBottomSheet(
      BuildContext context, FeedModel model, EchooType? type) async {
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            padding: const EdgeInsets.only(top: 5, bottom: 0),
            height: 180,
            width: context.width,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomSheetTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _shareEchoo(context, model, type));
      },
    );
  }

  Widget _shareEchoo(BuildContext context, FeedModel model, EchooType? type) {
    var socialMetaTagParameters = SocialMetaTagParameters(
        description: model.description ?? "",
        title: "${model.user!.displayName} posted a echoo on Echooes.",
        imageUrl: Uri.parse(model.user?.profilePic ??
            "https://play-lh.googleusercontent.com/e66XMuvW5hZ7HnFf8R_lcA3TFgkxm0SuyaMsBs3KENijNHZlogUAjxeu9COqsejV5w=s180-rw"));
    return Column(
      children: <Widget>[
        Container(
          width: context.width * .1,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _widgetBottomSheetRow(
          context,
          AppIcon.bookmark,
          isEnable: true,
          text: 'Bookmark',
          onPressed: () async {
            var state = Provider.of<FeedState>(context, listen: false);
            await state.addBookmark(model.key!);
            Navigator.pop(context);
            ScaffoldMessenger.maybeOf(context)!.showSnackBar(
              const SnackBar(content: Text("Bookmark saved!!")),
            );
          },
        ),
        const SizedBox(height: 8),
        _widgetBottomSheetRow(
          context,
          AppIcon.link,
          isEnable: true,
          text: 'Share Link',
          onPressed: () async {
            Navigator.pop(context);
            var url = Utility.createLinkToShare(
              context,
              "echoo/${model.key}",
              socialMetaTagParameters: socialMetaTagParameters,
            );
            var uri = await url;
            Utility.share(uri.toString(), subject: "Echoo");
          },
        ),
        const SizedBox(height: 8),
        _widgetBottomSheetRow(
          context,
          AppIcon.image,
          text: 'Share with Echoo thumbnail',
          isEnable: true,
          onPressed: () {
            socialMetaTagParameters = SocialMetaTagParameters(
                description: model.description ?? "",
                title: "${model.user!.displayName} posted a echoo on Echooes.",
                imageUrl: Uri.parse(model.user?.profilePic ??
                    "https://play-lh.googleusercontent.com/e66XMuvW5hZ7HnFf8R_lcA3TFgkxm0SuyaMsBs3KENijNHZlogUAjxeu9COqsejV5w=s180-rw"));
            Navigator.pop(context);
            Navigator.push(
              context,
              ShareWidget.getRoute(
                  child: type != null
                      ? Echoo(
                          model: model,
                          type: type,
                          scaffoldKey: GlobalKey<ScaffoldState>(),
                        )
                      : Echoo(
                          model: model,
                          scaffoldKey: GlobalKey<ScaffoldState>()),
                  id: "echoo/${model.key}",
                  socialMetaTagParameters: socialMetaTagParameters),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
