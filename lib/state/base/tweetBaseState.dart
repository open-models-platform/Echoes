import 'dart:io';

import 'package:Echoes/helper/enum.dart';
import 'package:Echoes/helper/utility.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/state/appState.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;

class EchooBaseState extends AppState {
  /// get [Echoo Detail] from firebase realtime kDatabase
  /// If model is null then fetch echoo from firebase
  /// [getPostDetailFromDatabase] is used to set prepare Echoo to display Echoo detail
  /// After getting echoo detail fetch echoo comments from firebase
  Future<FeedModel?> getPostDetailFromDatabase(String postID) async {
    try {
      late FeedModel echoo;

      // Fetch echoo data from firebase
      return await kDatabase
          .child('echoo')
          .child(postID)
          .once()
          .then((DatabaseEvent event) {
        final snapshot = event.snapshot;
        if (snapshot.value != null) {
          var map = snapshot.value as Map;
          echoo = FeedModel.fromJson(map);
          echoo.key = snapshot.key!;
        }
        return echoo;
      });
    } catch (error) {
      cprint(error, errorIn: 'getPostDetailFromDatabase');
      return null;
    }
  }

  Future<List<FeedModel>?> getEchoosComments(FeedModel post) async {
    late List<FeedModel> _commentList;
    // Check if parent echoo has reply echoos or not
    if (post.replyEchooKeyList != null && post.replyEchooKeyList!.isNotEmpty) {
      // for (String? x in post.replyEchooKeyList!) {
      //   if (x == null) {
      //     return;
      //   }
      // }
      //FIXME
      _commentList = [];
      for (String? replyEchooId in post.replyEchooKeyList!) {
        if (replyEchooId != null) {
          await kDatabase
              .child('echoo')
              .child(replyEchooId)
              .once()
              .then((DatabaseEvent event) {
            final snapshot = event.snapshot;
            if (snapshot.value != null) {
              var commentModel = FeedModel.fromJson(snapshot.value as Map);
              var key = snapshot.key!;
              commentModel.key = key;

              /// add comment echoo to list if echoo is not present in [comment echoo ]list
              /// To reduce delicacy
              if (!_commentList.any((x) => x.key == key)) {
                _commentList.add(commentModel);
              }
            } else {}
            if (replyEchooId == post.replyEchooKeyList!.last) {
              /// Sort comment by time
              /// It helps to display newest Echoo first.
              _commentList.sort((x, y) => DateTime.parse(y.createdAt)
                  .compareTo(DateTime.parse(x.createdAt)));
            }
          });
        }
      }
    }
    return _commentList;
  }

  /// [Delete echoo] in Firebase kDatabase
  /// Remove Echoo if present in home page Echoo list
  /// Remove Echoo if present in Echoo detail page or in comment
  bool deleteEchoo(
    String echooId,
    EchooType type,
    /*{String parentkey}*/
  ) {
    try {
      /// Delete echoo if it is in nested echoo detail page
      kDatabase.child('echoo').child(echooId).remove();
      return true;
    } catch (error) {
      cprint(error, errorIn: 'deleteEchoo');
      return false;
    }
  }

  /// [update] echoo
  void updateEchoo(FeedModel model) async {
    await kDatabase.child('echoo').child(model.key!).set(model.toJson());
  }

  /// Add/Remove like on a Echoo
  /// [postId] is echoo id, [userId] is user's id who like/unlike Echoo
  void addLikeToEchoo(FeedModel echoo, String userId) {
    try {
      if (echoo.likeList != null &&
          echoo.likeList!.isNotEmpty &&
          echoo.likeList!.any((id) => id == userId)) {
        // If user wants to undo/remove his like on echoo
        echoo.likeList!.removeWhere((id) => id == userId);
        echoo.likeCount = echoo.likeCount! - 1;
      } else {
        // If user like Echoo
        echoo.likeList ??= [];
        echoo.likeList!.add(userId);
        echoo.likeCount = echoo.likeCount! + 1;
      }
      // update likeList of a echoo
      kDatabase
          .child('echoo')
          .child(echoo.key!)
          .child('likeList')
          .set(echoo.likeList);

      // Sends notification to user who created echoo
      // UserModel owner can see notification on notification page
      kDatabase
          .child('notification')
          .child(echoo.userId)
          .child(echoo.key!)
          .set({
        'type':
            echoo.likeList!.isEmpty ? null : NotificationType.Like.toString(),
        'updatedAt':
            echoo.likeList!.isEmpty ? null : DateTime.now().toUtc().toString(),
      });
    } catch (error) {
      cprint(error, errorIn: 'addLikeToEchoo');
    }
  }

  /// Add new [echoo]
  /// Returns new echoo id
  String? createPost(FeedModel echoo) {
    var json = echoo.toJson();
    var reference = kDatabase.child('echoo').push();
    reference.set(json);
    return reference.key;
  }

  /// upload [file] to firebase storage and return its  path url
  Future<String?> uploadFile(File file) async {
    try {
      // isBusy = true;
      notifyListeners();
      var storageReference = FirebaseStorage.instance
          .ref()
          .child("echooImage")
          .child(Path.basename(DateTime.now().toIso8601String() + file.path));
      await storageReference.putFile(file);

      var url = await storageReference.getDownloadURL();
      return url;
    } catch (error) {
      cprint(error, errorIn: 'uploadFile');
      return null;
    }
  }
}
