import 'package:Echoes/helper/enum.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/state/feedState.dart';
import 'package:Echoes/ui/theme/theme.dart';
import 'package:Echoes/widgets/cache_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EchooImage extends StatelessWidget {
  const EchooImage(
      {Key? key, required this.model, this.type, this.isReechooImage = false})
      : super(key: key);

  final FeedModel model;
  final EchooType? type;
  final bool isReechooImage;
  @override
  Widget build(BuildContext context) {
    if (model.imagePath != null) assert(type != null);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      alignment: Alignment.centerRight,
      child: model.imagePath == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                borderRadius: BorderRadius.all(
                  Radius.circular(isReechooImage ? 0 : 20),
                ),
                onTap: () {
                  if (type == EchooType.ParentEchoo) {
                    return;
                  }
                  var state = Provider.of<FeedState>(context, listen: false);
                  state.getPostDetailFromDatabase(model.key);
                  state.setEchooToReply = model;
                  Navigator.pushNamed(context, '/ImageViewPge');
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.all(
                    Radius.circular(isReechooImage ? 0 : 20),
                  ),
                  child: Container(
                    width:
                        context.width * (type == EchooType.Detail ? .95 : .8) -
                            8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).backgroundColor,
                    ),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: CacheImage(
                        path: model.imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
