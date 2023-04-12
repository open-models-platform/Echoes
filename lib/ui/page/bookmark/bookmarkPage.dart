import 'package:Echoes/helper/enum.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/state/bookmarkState.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:Echoes/widgets/customAppBar.dart';
import 'package:Echoes/widgets/echoo/echoo.dart';
import 'package:Echoes/widgets/newWidget/emptyList.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage({Key? key}) : super(key: key);

  static Route<T> getRoute<T>() {
    return MaterialPageRoute(
      builder: (_) {
        return Provider(
          create: (_) => BookmarkState(),
          child: ChangeNotifierProvider(
            create: (BuildContext context) => BookmarkState(),
            builder: (_, child) => const BookmarkPage(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoesColor.mystic,
      appBar: CustomAppBar(
        title: Text("Bookmark", style: TextStyles.titleStyle),
        isBackButton: true,
      ),
      body: const BookmarkPageBody(),
    );
  }
}

class BookmarkPageBody extends StatelessWidget {
  const BookmarkPageBody({Key? key}) : super(key: key);

  Widget _echoo(BuildContext context, FeedModel model) {
    return Container(
      color: Colors.white,
      child: Echoo(
        model: model,
        type: EchooType.Echoo,
        scaffoldKey: GlobalKey<ScaffoldState>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<BookmarkState>(context);
    var list = state.echooList;
    if (state.isbusy) {
      return const SizedBox(
        height: 3,
        child: LinearProgressIndicator(),
      );
    } else if (list == null || list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: EmptyList(
          'No Bookmark available yet',
          subTitle: 'When new bookmark found, they\'ll show up here.',
        ),
      );
    }
    return ListView.builder(
      addAutomaticKeepAlives: true,
      itemBuilder: (context, index) => _echoo(context, list[index]),
      itemCount: list.length,
    );
  }
}
