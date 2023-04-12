import 'dart:io';

import 'package:Echoes/helper/constant.dart';
import 'package:Echoes/helper/utility.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/model/user.dart';
import 'package:Echoes/state/authState.dart';
import 'package:Echoes/state/feedState.dart';
import 'package:Echoes/state/searchState.dart';
import 'package:Echoes/ui/page/feed/composeEchoo/state/composeEchooState.dart';
import 'package:Echoes/ui/page/feed/composeEchoo/widget/composeBottomIconWidget.dart';
import 'package:Echoes/ui/page/feed/composeEchoo/widget/composeEchooImage.dart';
import 'package:Echoes/ui/page/feed/composeEchoo/widget/widgetView.dart';
import 'package:Echoes/ui/page/profile/widgets/circular_image.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:Echoes/widgets/customAppBar.dart';
import 'package:Echoes/widgets/customWidgets.dart';
import 'package:Echoes/widgets/newWidget/title_text.dart';
import 'package:Echoes/widgets/url_text/customUrlText.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';

class ComposeEchooPage extends StatefulWidget {
  const ComposeEchooPage(
      {Key? key, required this.isReechoo, this.isEchoo = true})
      : super(key: key);

  final bool isReechoo;
  final bool isEchoo;
  @override
  _ComposeEchooReplyPageState createState() => _ComposeEchooReplyPageState();
}

class _ComposeEchooReplyPageState extends State<ComposeEchooPage> {
  bool isScrollingDown = false;
  late FeedModel? model;
  late ScrollController scrollController;

  File? _image;
  late TextEditingController _textEditingController;

  @override
  void dispose() {
    scrollController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    var feedState = Provider.of<FeedState>(context, listen: false);
    model = feedState.echooToReplyModel;
    scrollController = ScrollController();
    _textEditingController = TextEditingController();
    scrollController.addListener(_scrollListener);
    super.initState();
  }

  _scrollListener() {
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (!isScrollingDown) {
        Provider.of<ComposeEchooState>(context, listen: false)
            .setIsScrollingDown = true;
      }
    }
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      Provider.of<ComposeEchooState>(context, listen: false)
          .setIsScrollingDown = false;
    }
  }

  void _onCrossIconPressed() {
    setState(() {
      _image = null;
    });
  }

  void _onImageIconSelected(File file) {
    setState(() {
      _image = file;
    });
  }

  /// Submit echoo to save in firebase database
  void _submitButton() async {
    if (_textEditingController.text.isEmpty ||
        _textEditingController.text.length > 280) {
      return;
    }
    var state = Provider.of<FeedState>(context, listen: false);
    kScreenLoader.showLoader(context);

    FeedModel echooModel = await createEchooModel();
    String? echooId;

    /// If echoo contain image
    /// First image is uploaded on firebase storage
    /// After successful image upload to firebase storage it returns image path
    /// Add this image path to echoo model and save to firebase database
    if (_image != null) {
      await state.uploadFile(_image!).then((imagePath) async {
        if (imagePath != null) {
          echooModel.imagePath = imagePath;

          /// If type of echoo is new echoo
          if (widget.isEchoo) {
            echooId = await state.createEchoo(echooModel);
          }

          /// If type of echoo is  reechoo
          else if (widget.isReechoo) {
            echooId = await state.createReEchoo(echooModel);
          }

          /// If type of echoo is new comment echoo
          else {
            echooId = await state.addCommentToPost(echooModel);
          }
        }
      });
    }

    /// If echoo did not contain image
    else {
      /// If type of echoo is new echoo
      if (widget.isEchoo) {
        echooId = await state.createEchoo(echooModel);
      }

      /// If type of echoo is  reechoo
      else if (widget.isReechoo) {
        echooId = await state.createReEchoo(echooModel);
      }

      /// If type of echoo is new comment echoo
      else {
        echooId = await state.addCommentToPost(echooModel);
      }
    }
    echooModel.key = echooId;

    /// Checks for username in echoo description
    /// If username found, sends notification to all tagged user
    /// If no user found, compose echoo screen is closed and redirect back to home page.
    await Provider.of<ComposeEchooState>(context, listen: false)
        .sendNotification(
            echooModel, Provider.of<SearchState>(context, listen: false))
        .then((_) {
      /// Hide running loader on screen
      kScreenLoader.hideLoader();

      /// Navigate back to home page
      Navigator.pop(context);
    });
  }

  /// Return Echoo model which is either a new Echoo , reechoo model or comment model
  /// If echoo is new echoo then `parentkey` and `childRetwetkey` should be null
  /// IF echoo is a comment then it should have `parentkey`
  /// IF echoo is a reechoo then it should have `childRetwetkey`
  Future<FeedModel> createEchooModel() async {
    var state = Provider.of<FeedState>(context, listen: false);
    var authState = Provider.of<AuthState>(context, listen: false);
    var myUser = authState.userModel;
    var profilePic = myUser!.profilePic ?? Constants.dummyProfilePic;

    /// User who are creating reply echoo
    var commentedUser = UserModel(
        displayName: myUser.displayName ?? myUser.email!.split('@')[0],
        profilePic: profilePic,
        userId: myUser.userId,
        isVerified: authState.userModel!.isVerified,
        userName: authState.userModel!.userName);
    var tags = Utility.getHashTags(_textEditingController.text);
    FeedModel reply = FeedModel(
        description: _textEditingController.text,
        lanCode:
            (await GoogleTranslator().translate(_textEditingController.text))
                .sourceLanguage
                .code,
        user: commentedUser,
        createdAt: DateTime.now().toUtc().toString(),
        tags: tags,
        parentkey: widget.isEchoo
            ? null
            : widget.isReechoo
                ? null
                : state.echooToReplyModel!.key,
        childRetwetkey: widget.isEchoo
            ? null
            : widget.isReechoo
                ? model!.key
                : null,
        userId: myUser.userId!);
    return reply;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: customTitleText(''),
        onActionPressed: _submitButton,
        isCrossButton: true,
        submitButtonText: widget.isEchoo
            ? 'Echoo'
            : widget.isReechoo
                ? 'Reechoo'
                : 'Reply',
        isSubmitDisable:
            !Provider.of<ComposeEchooState>(context).enableSubmitButton ||
                Provider.of<FeedState>(context).isBusy,
        isBottomLine: Provider.of<ComposeEchooState>(context).isScrollingDown,
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Stack(
        //!Removed container
        children: <Widget>[
          SingleChildScrollView(
            controller: scrollController,
            child:
                widget.isReechoo ? _ComposeReechoo(this) : _ComposeEchoo(this),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ComposeBottomIconWidget(
              textEditingController: _textEditingController,
              onImageIconSelected: _onImageIconSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposeReechoo
    extends WidgetView<ComposeEchooPage, _ComposeEchooReplyPageState> {
  const _ComposeReechoo(this.viewState) : super(viewState);

  final _ComposeEchooReplyPageState viewState;
  Widget _echoo(BuildContext context, FeedModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // SizedBox(width: 10),

        const SizedBox(width: 20),
        SizedBox(
          width: context.width - 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularImage(path: model.user!.profilePic),
                  ),
                  const SizedBox(width: 10),
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
                  SizedBox(width: model.user!.isVerified! ? 5 : 0),
                  Flexible(
                    child: customText(
                      '${model.user!.userName}',
                      style: TextStyles.userNameStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  customText('· ${Utility.getChatTime(model.createdAt)}',
                      style: TextStyles.userNameStyle),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ),
        if (model.description != null)
          UrlText(
            text: model.description!,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            urlStyle: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.w400),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var authState = Provider.of<AuthState>(context);
    return SizedBox(
      height: context.height,
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child:
                    CircularImage(path: authState.user?.photoURL, height: 40),
              ),
              Expanded(
                child: _TextField(
                  isEchoo: false,
                  isReechoo: true,
                  textEditingController: viewState._textEditingController,
                ),
              ),
              const SizedBox(
                width: 16,
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 80, bottom: 8),
            child: ComposeEchooImage(
              image: viewState._image,
              onCrossIconPressed: viewState._onCrossIconPressed,
            ),
          ),
          Flexible(
            child: Stack(
              children: <Widget>[
                Wrap(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(
                          left: 75, right: 16, bottom: 16),
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.topCenter,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColor.extraLightGrey, width: .5),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(15))),
                      child: _echoo(context, viewState.model!),
                    ),
                  ],
                ),
                _UserList(
                  list: Provider.of<SearchState>(context).userlist,
                  textEditingController: viewState._textEditingController,
                )
              ],
            ),
          ),
          const SizedBox(height: 50)
        ],
      ),
    );
  }
}

class _ComposeEchoo
    extends WidgetView<ComposeEchooPage, _ComposeEchooReplyPageState> {
  const _ComposeEchoo(this.viewState) : super(viewState);

  final _ComposeEchooReplyPageState viewState;

  Widget _echooCard(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(left: 30),
              margin: const EdgeInsets.only(left: 20, top: 20, bottom: 3),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    width: 2.0,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: context.width - 72,
                    child: UrlText(
                      text: viewState.model!.description ?? '',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      urlStyle: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  UrlText(
                    text:
                        'Replying to ${viewState.model!.user!.userName ?? viewState.model!.user!.displayName}',
                    style: TextStyle(
                      color: EchoesColor.paleSky,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircularImage(
                    path: viewState.model!.user!.profilePic, height: 40),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints:
                      BoxConstraints(minWidth: 0, maxWidth: context.width * .5),
                  child: TitleText(viewState.model!.user!.displayName!,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 3),
                viewState.model!.user!.isVerified!
                    ? customIcon(
                        context,
                        icon: AppIcon.blueTick,
                        isEchoesIcon: true,
                        iconColor: AppColor.primary,
                        size: 13,
                        paddingIcon: 3,
                      )
                    : const SizedBox(width: 0),
                SizedBox(width: viewState.model!.user!.isVerified! ? 5 : 0),
                customText('${viewState.model!.user!.userName}',
                    style: TextStyles.userNameStyle.copyWith(fontSize: 15)),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: customText(
                      '- ${Utility.getChatTime(viewState.model!.createdAt)}',
                      style: TextStyles.userNameStyle.copyWith(fontSize: 12)),
                )
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var authState = Provider.of<AuthState>(context, listen: false);
    return Container(
      height: context.height,
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          viewState.widget.isEchoo
              ? const SizedBox.shrink()
              : _echooCard(context),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircularImage(path: authState.user?.photoURL, height: 40),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: _TextField(
                  isEchoo: widget.isEchoo,
                  textEditingController: viewState._textEditingController,
                ),
              )
            ],
          ),
          Flexible(
            child: Stack(
              children: <Widget>[
                ComposeEchooImage(
                  image: viewState._image,
                  onCrossIconPressed: viewState._onCrossIconPressed,
                ),
                _UserList(
                  list: Provider.of<SearchState>(context).userlist,
                  textEditingController: viewState._textEditingController,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField(
      {Key? key,
      required this.textEditingController,
      this.isEchoo = false,
      this.isReechoo = false})
      : super(key: key);
  final TextEditingController textEditingController;
  final bool isEchoo;
  final bool isReechoo;

  @override
  Widget build(BuildContext context) {
    final searchState = Provider.of<SearchState>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: textEditingController,
          onChanged: (text) {
            Provider.of<ComposeEchooState>(context, listen: false)
                .onDescriptionChanged(text, searchState);
          },
          maxLines: null,
          decoration: InputDecoration(
              border: InputBorder.none,
              hintText: isEchoo
                  ? 'What\'s happening?'
                  : isReechoo
                      ? 'Add a comment'
                      : 'Echoo your reply',
              hintStyle: const TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({Key? key, this.list, required this.textEditingController})
      : super(key: key);
  final List<UserModel>? list;
  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    return !Provider.of<ComposeEchooState>(context).displayUserList ||
            list == null ||
            list!.length < 0 ||
            list!.isEmpty
        ? const SizedBox.shrink()
        : Container(
            padding: const EdgeInsetsDirectional.only(bottom: 50),
            color: EchoesColor.white,
            constraints:
                const BoxConstraints(minHeight: 30, maxHeight: double.infinity),
            child: ListView.builder(
              itemCount: list!.length,
              physics: ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                return _UserTile(
                  user: list![index],
                  onUserSelected: (user) {
                    textEditingController.text =
                        Provider.of<ComposeEchooState>(context, listen: false)
                                .getDescription(user.userName!) +
                            " ";
                    textEditingController.selection = TextSelection.collapsed(
                        offset: textEditingController.text.length);
                    Provider.of<ComposeEchooState>(context, listen: false)
                        .onUserSelected();
                  },
                );
              },
            ),
          );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({Key? key, required this.user, required this.onUserSelected})
      : super(key: key);
  final UserModel user;
  final ValueChanged<UserModel> onUserSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        onUserSelected(user);
      },
      leading: CircularImage(path: user.profilePic, height: 35),
      title: Row(
        children: <Widget>[
          ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: 0, maxWidth: context.width * .5),
            child: TitleText(user.displayName!,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 3),
          user.isVerified!
              ? customIcon(
                  context,
                  icon: AppIcon.blueTick,
                  isEchoesIcon: true,
                  iconColor: AppColor.primary,
                  size: 13,
                  paddingIcon: 3,
                )
              : const SizedBox(width: 0),
        ],
      ),
      subtitle: Text(user.userName!),
    );
  }
}
