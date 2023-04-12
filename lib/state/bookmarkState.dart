import 'dart:async';

import 'package:Echoes/helper/shared_prefrence_helper.dart';
import 'package:Echoes/helper/utility.dart';
import 'package:Echoes/model/bookmarkModel.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/ui/page/common/locator.dart';
import 'package:firebase_database/firebase_database.dart';

import 'appState.dart';

class BookmarkState extends AppState {
  BookmarkState() {
    getDataFromDatabase();
  }
  List<FeedModel>? _echooList;
  List<BookmarkModel>? _bookmarkList;

  addBookmarkEchooToList(BookmarkModel model) {
    _bookmarkList ??= <BookmarkModel>[];

    if (!_bookmarkList!.any((element) => element.key == model.key)) {
      _bookmarkList!.add(model);
    }
  }

  List<FeedModel>? get echooList => _echooList;

  /// get [Notification list] from firebase realtime database
  void getDataFromDatabase() async {
    String userId = await getIt<SharedPreferenceHelper>()
        .getUserProfile()
        .then((value) => value!.userId!);
    try {
      if (_echooList != null) {
        return;
      }
      isBusy = true;
      kDatabase
          .child('bookmark')
          .child(userId)
          .once()
          .then((DatabaseEvent event) async {
        final snapshot = event.snapshot;
        if (snapshot.value != null) {
          var map = snapshot.value as Map<dynamic, dynamic>?;
          if (map != null) {
            map.forEach((bookmarkKey, value) {
              var map = value as Map<dynamic, dynamic>;
              var model = BookmarkModel.fromJson(map);
              model.key = bookmarkKey;
              addBookmarkEchooToList(model);
            });
          }

          if (_bookmarkList != null) {
            for (var bookmark in _bookmarkList!) {
              var echoo = await getEchooDetail(bookmark.echooId);
              if (echoo != null) {
                _echooList ??= <FeedModel>[];
                _echooList!.add(echoo);
              }
            }
          }
        }
        isBusy = false;
      });
    } catch (error) {
      isBusy = false;
      cprint(error, errorIn: 'getDataFromDatabase');
    }
  }

  /// get `Echoo` present in notification
  Future<FeedModel?> getEchooDetail(String echooId) async {
    FeedModel _echooDetail;
    final event = await kDatabase.child('echoo').child(echooId).once();

    final snapshot = event.snapshot;
    if (snapshot.value != null) {
      var map = snapshot.value as Map<dynamic, dynamic>;
      _echooDetail = FeedModel.fromJson(map);
      _echooDetail.key = snapshot.key!;
      return _echooDetail;
    } else {
      return null;
    }
  }
}
