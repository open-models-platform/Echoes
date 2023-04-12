import 'package:Echoes/helper/customRoute.dart';
import 'package:Echoes/helper/enum.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/state/authState.dart';
import 'package:Echoes/state/feedState.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:Echoes/widgets/customWidgets.dart';
import 'package:Echoes/widgets/echoo/echoo.dart';
import 'package:Echoes/widgets/echoo/widgets/echooBottomSheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedPostDetail extends StatefulWidget {
  const FeedPostDetail({Key? key, required this.postId}) : super(key: key);
  final String postId;

  static Route<void> getRoute(String postId) {
    return SlideLeftRoute<void>(
      builder: (BuildContext context) => FeedPostDetail(
        postId: postId,
      ),
    );
  }

  @override
  _FeedPostDetailState createState() => _FeedPostDetailState();
}

class _FeedPostDetailState extends State<FeedPostDetail> {
  late String postId;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    postId = widget.postId;
    // var state = Provider.of<FeedState>(context, listen: false);
    // state.getpostDetailFromDatabase(postId);
    super.initState();
  }

  Widget _floatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        var state = Provider.of<FeedState>(context, listen: false);
        state.setEchooToReply = state.echooDetailModel!.last;
        Navigator.of(context).pushNamed('/ComposeEchooPage/' + postId);
      },
      child: const Icon(Icons.add),
    );
  }

  Widget _commentRow(FeedModel model) {
    return Echoo(
      model: model,
      type: EchooType.Reply,
      trailing: EchooBottomSheet().echooOptionIcon(context,
          scaffoldKey: scaffoldKey, model: model, type: EchooType.Reply),
      scaffoldKey: scaffoldKey,
    );
  }

  Widget _echooDetail(FeedModel model) {
    return Echoo(
      model: model,
      type: EchooType.Detail,
      trailing: EchooBottomSheet().echooOptionIcon(context,
          scaffoldKey: scaffoldKey, model: model, type: EchooType.Detail),
      scaffoldKey: scaffoldKey,
    );
  }

  void addLikeToComment(String commentId) {
    var state = Provider.of<FeedState>(context, listen: false);
    var authState = Provider.of<AuthState>(context, listen: false);
    state.addLikeToEchoo(state.echooDetailModel!.last, authState.userId);
  }

  void openImage() async {
    Navigator.pushNamed(context, '/ImageViewPge');
  }

  void deleteEchoo(EchooType type, String echooId,
      {required String parentkey}) {
    var state = Provider.of<FeedState>(context, listen: false);
    state.deleteEchoo(echooId, type, parentkey: parentkey);
    Navigator.of(context).pop();
    if (type == EchooType.Detail) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<FeedState>(context);
    return WillPopScope(
      onWillPop: () async {
        Provider.of<FeedState>(context, listen: false)
            .removeLastEchooDetail(postId);
        return Future.value(true);
      },
      child: Scaffold(
        key: scaffoldKey,
        floatingActionButton: _floatingActionButton(),
        backgroundColor: Theme.of(context).backgroundColor,
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              title: customTitleText(
                'Thread',
              ),
              iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              bottom: PreferredSize(
                child: Container(
                  color: Colors.grey.shade200,
                  height: 1.0,
                ),
                preferredSize: const Size.fromHeight(0.0),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  state.echooDetailModel == null ||
                          state.echooDetailModel!.isEmpty
                      ? Container()
                      : _echooDetail(state.echooDetailModel!.last),
                  Container(
                    height: 6,
                    width: context.width,
                    color: TwitterColor.mystic,
                  )
                ],
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                state.echooReplyMap == null ||
                        state.echooReplyMap!.isEmpty ||
                        state.echooReplyMap![postId] == null
                    ? [
                        //!Removed container
                        const Center(
                            //  child: Text('No comments'),
                            )
                      ]
                    : state.echooReplyMap![postId]!
                        .map((x) => _commentRow(x))
                        .toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
