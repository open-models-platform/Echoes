import 'package:Echoes/helper/enum.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/state/feedState.dart';
import 'package:Echoes/ui/page/feed/feedPostDetail.dart';
import 'package:Echoes/widgets/echoo/echoo.dart';
import 'package:Echoes/widgets/echoo/widgets/unavailableEchoo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ParentEchooWidget extends StatelessWidget {
  const ParentEchooWidget(
      {Key? key,
      required this.childRetwetkey,
      required this.type,
      // this.isImageAvailable,
      this.trailing})
      : super(key: key);

  final String childRetwetkey;
  final EchooType type;
  final Widget? trailing;
  // final bool isImageAvailable;

  void onEchooPressed(BuildContext context, FeedModel model) {
    var feedstate = Provider.of<FeedState>(context, listen: false);
    feedstate.getPostDetailFromDatabase(null, model: model);
    Navigator.push(context, FeedPostDetail.getRoute(model.key!));
  }

  @override
  Widget build(BuildContext context) {
    var feedstate = Provider.of<FeedState>(context, listen: false);
    return FutureBuilder(
      future: feedstate.fetchEchoo(childRetwetkey),
      builder: (context, AsyncSnapshot<FeedModel?> snapshot) {
        if (snapshot.hasData) {
          return Echoo(
            model: snapshot.data!,
            type: EchooType.ParentEchoo,
            trailing: trailing,
            scaffoldKey: GlobalKey<ScaffoldState>(),
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
