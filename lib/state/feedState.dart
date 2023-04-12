import 'dart:async';
import 'dart:io';

import 'package:Echoes/helper/enum.dart';
import 'package:Echoes/helper/shared_prefrence_helper.dart';
import 'package:Echoes/helper/utility.dart';
import 'package:Echoes/model/feedModel.dart';
import 'package:Echoes/model/user.dart';
import 'package:Echoes/state/appState.dart';
import 'package:Echoes/ui/page/common/locator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart' as database;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:link_preview_generator/link_preview_generator.dart'
    show WebInfo;
import 'package:path/path.dart' as path;
import 'package:translator/translator.dart';
// import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;
// import 'authState.dart';

class FeedState extends AppState {
  bool isBusy = false;
  Map<String, List<FeedModel>?>? echooReplyMap = {};
  FeedModel? _echooToReplyModel;
  FeedModel? get echooToReplyModel => _echooToReplyModel;
  set setEchooToReply(FeedModel model) {
    _echooToReplyModel = model;
  }

  late List<FeedModel> _commentList;

  List<FeedModel>? _feedList;
  database.Query? _feedQuery;
  List<FeedModel>? _echooDetailModelList;

  List<FeedModel>? get echooDetailModel => _echooDetailModelList;

  /// `feedList` always [contain all echoos] fetched from firebase database
  List<FeedModel>? get feedList {
    if (_feedList == null) {
      return null;
    } else {
      return List.from(_feedList!.reversed);
    }
  }

  /// contain echoo list for home page
  List<FeedModel>? getEchooList(UserModel? userModel) {
    if (userModel == null) {
      return null;
    }

    List<FeedModel>? list;

    if (!isBusy && feedList != null && feedList!.isNotEmpty) {
      list = feedList!.where((x) {
        /// If Echoo is a comment then no need to add it in echoo list
        if (x.parentkey != null &&
            x.childRetwetkey == null &&
            x.user!.userId != userModel.userId) {
          return false;
        }

        /// Only include Echoos of logged-in user's and his following user's
        if (x.user!.userId == userModel.userId ||
            (userModel.followingList != null &&
                userModel.followingList!.contains(x.user!.userId))) {
          return true;
        } else {
          return false;
        }
      }).toList();
      if (list.isEmpty) {
        list = null;
      }
    }
    return list;
  }

  Map<String, WebInfo> _linkWebInfos = {};
  Map<String, WebInfo> get linkWebInfos => _linkWebInfos;
  void addWebInfo(String url, WebInfo webInfo) {
    _linkWebInfos.addAll({url: webInfo});
  }

  Map<String, Translation?> _echoosTranslations = {};
  Map<String, Translation?> get echoosTranslations => _echoosTranslations;
  void addEchooTranslation(String echoo, Translation? translation) {
    _echoosTranslations.addAll({echoo: translation});
    notifyListeners();
  }

  /// set echoo for detail echoo page
  /// Setter call when echoo is tapped to view detail
  /// Add Echoo detail is added in _echooDetailModelList
  /// It makes `Echooes` to view nested Echoos
  set setFeedModel(FeedModel model) {
    _echooDetailModelList ??= [];

    /// [Skip if any duplicate echoo already present]

    _echooDetailModelList!.add(model);
    cprint("Detail Echoo added. Total Echoo: ${_echooDetailModelList!.length}");
    notifyListeners();
  }

  /// `remove` last Echoo from echoo detail page stack
  /// Function called when navigating back from a Echoo detail
  /// `_echooDetailModelList` is map which contain lists of comment Echoo list
  /// After removing Echoo from Echoo detail Page stack its comments echoo is also removed from `_echooDetailModelList`
  void removeLastEchooDetail(String echooKey) {
    if (_echooDetailModelList != null && _echooDetailModelList!.isNotEmpty) {
      // var index = _echooDetailModelList.in
      FeedModel removeEchoo =
          _echooDetailModelList!.lastWhere((x) => x.key == echooKey);
      _echooDetailModelList!.remove(removeEchoo);
      echooReplyMap?.removeWhere((key, value) => key == echooKey);
      cprint(
          "Last index Echoo removed from list. Remaining Echoo: ${_echooDetailModelList!.length}");
      notifyListeners();
    }
  }

  /// [clear all echoos] if any echoo present in echoo detail page or comment echoo
  void clearAllDetailAndReplyEchooStack() {
    if (_echooDetailModelList != null) {
      _echooDetailModelList!.clear();
    }
    if (echooReplyMap != null) {
      echooReplyMap!.clear();
    }
    cprint('Empty echoos from stack');
  }

  /// [Subscribe Echoos] firebase Database
  Future<bool> databaseInit() {
    try {
      if (_feedQuery == null) {
        _feedQuery = kDatabase.child("echoo");
        _feedQuery!.onChildAdded.listen(_onEchooAdded);
        _feedQuery!.onChildChanged.listen(_onEchooChanged);
        _feedQuery!.onChildRemoved.listen(_onEchooRemoved);
      }

      return Future.value(true);
    } catch (error) {
      cprint(error, errorIn: 'databaseInit');
      return Future.value(false);
    }
  }

  /// get [Echoo list] from firebase realtime database
  void getDataFromDatabase() {
    try {
      isBusy = true;
      _feedList = null;
      notifyListeners();
      kDatabase.child('echoo').once().then((DatabaseEvent event) {
        final snapshot = event.snapshot;
        _feedList = <FeedModel>[];
        if (snapshot.value != null) {
          var map = snapshot.value as Map<dynamic, dynamic>?;
          if (map != null) {
            map.forEach((key, value) {
              var model = FeedModel.fromJson(value);
              model.key = key;
              if (model.isValidEchoo) {
                _feedList!.add(model);
              }
            });

            /// Sort Echoo by time
            /// It helps to display newest Echoo first.
            _feedList!.sort((x, y) => DateTime.parse(x.createdAt)
                .compareTo(DateTime.parse(y.createdAt)));
          }
        } else {
          _feedList = null;
        }
        isBusy = false;
        notifyListeners();
      });
    } catch (error) {
      isBusy = false;
      cprint(error, errorIn: 'getDataFromDatabase');
    }
  }

  /// get [Echoo Detail] from firebase realtime kDatabase
  /// If model is null then fetch echoo from firebase
  /// [getPostDetailFromDatabase] is used to set prepare Echoo to display Echoo detail
  /// After getting echoo detail fetch echoo comments from firebase
  void getPostDetailFromDatabase(String? postID, {FeedModel? model}) async {
    try {
      FeedModel? _echooDetail;
      if (model != null) {
        // set echoo data from echoo list data.
        // No need to fetch echoo from firebase db if data already present in echoo list
        _echooDetail = model;
        setFeedModel = _echooDetail;
        postID = model.key;
      } else {
        assert(postID != null);
        // Fetch echoo data from firebase
        kDatabase
            .child('echoo')
            .child(postID!)
            .once()
            .then((DatabaseEvent event) {
          final snapshot = event.snapshot;
          if (snapshot.value != null) {
            var map = snapshot.value as Map<dynamic, dynamic>;
            _echooDetail = FeedModel.fromJson(map);
            _echooDetail!.key = snapshot.key!;
            setFeedModel = _echooDetail!;
          }
        });
      }

      if (_echooDetail != null) {
        // Fetch comment echoos
        _commentList = <FeedModel>[];
        // Check if parent echoo has reply echoos or not
        if (_echooDetail!.replyEchooKeyList != null &&
            _echooDetail!.replyEchooKeyList!.isNotEmpty) {
          for (String? x in _echooDetail!.replyEchooKeyList!) {
            if (x == null) {
              return;
            }
            kDatabase
                .child('echoo')
                .child(x)
                .once()
                .then((DatabaseEvent event) {
              final snapshot = event.snapshot;
              if (snapshot.value != null) {
                var commentModel = FeedModel.fromJson(snapshot.value as Map);
                String key = snapshot.key!;
                commentModel.key = key;

                /// add comment echoo to list if echoo is not present in [comment echoo ]list
                /// To reduce delicacy
                if (!_commentList.any((x) => x.key == key)) {
                  _commentList.add(commentModel);
                }
              } else {}
              if (x == _echooDetail!.replyEchooKeyList!.last) {
                /// Sort comment by time
                /// It helps to display newest Echoo first.
                _commentList.sort((x, y) => DateTime.parse(y.createdAt)
                    .compareTo(DateTime.parse(x.createdAt)));
                echooReplyMap!.putIfAbsent(postID!, () => _commentList);
                notifyListeners();
              }
            });
          }
        } else {
          echooReplyMap!.putIfAbsent(postID!, () => _commentList);
          notifyListeners();
        }
      }
    } catch (error) {
      cprint(error, errorIn: 'getPostDetailFromDatabase');
    }
  }

  /// Fetch `Reechoo` model from firebase realtime kDatabase.
  /// Reechoo itself  is a type of `Echoo`
  Future<FeedModel?> fetchEchoo(String postID) async {
    FeedModel? _echooDetail;

    /// If echoo is available in feedList then no need to fetch it from firebase
    if (feedList!.any((x) => x.key == postID)) {
      _echooDetail = feedList!.firstWhere((x) => x.key == postID);
    }

    /// If echoo is not available in feedList then need to fetch it from firebase
    else {
      cprint("Fetched from DB: " + postID);
      var model = await kDatabase.child('echoo').child(postID).once().then(
        (DatabaseEvent event) {
          final snapshot = event.snapshot;
          if (snapshot.value != null) {
            var map = snapshot.value as Map<dynamic, dynamic>;
            _echooDetail = FeedModel.fromJson(map);
            _echooDetail!.key = snapshot.key!;
            print(_echooDetail!.description);
          }
        },
      );
      if (model != null) {
        _echooDetail = model;
      } else {
        cprint("Fetched null value from  DB");
      }
    }
    return _echooDetail;
  }

  /// create [New Echoo]
  /// returns Echoo key
  Future<String?> createEchoo(FeedModel model) async {
    ///  Create echoo in [Firebase kDatabase]
    isBusy = true;
    notifyListeners();
    String? echooKey;
    try {
      DatabaseReference dbReference = kDatabase.child('echoo').push();

      await dbReference.set(model.toJson());

      echooKey = dbReference.key;
    } catch (error) {
      cprint(error, errorIn: 'createEchoo');
    }
    isBusy = false;
    notifyListeners();
    return echooKey;
  }

  ///  It will create echoo in [Firebase kDatabase] just like other normal echoo.
  ///  update reechoo count for reechoo model
  Future<String?> createReEchoo(FeedModel model) async {
    String? echooKey;
    try {
      echooKey = await createEchoo(model);
      if (_echooToReplyModel != null) {
        if (_echooToReplyModel!.reechooCount == null) {
          _echooToReplyModel!.reechooCount = 0;
        }
        _echooToReplyModel!.reechooCount =
            _echooToReplyModel!.reechooCount! + 1;
        updateEchoo(_echooToReplyModel!);
      }
    } catch (error) {
      cprint(error, errorIn: 'createReEchoo');
    }
    return echooKey;
  }

  /// [Delete echoo] in Firebase kDatabase
  /// Remove Echoo if present in home page Echoo list
  /// Remove Echoo if present in Echoo detail page or in comment
  deleteEchoo(String echooId, EchooType type, {String? parentkey} //FIXME
      ) {
    try {
      /// Delete echoo if it is in nested echoo detail page
      kDatabase.child('echoo').child(echooId).remove().then((_) {
        if (type == EchooType.Detail &&
            _echooDetailModelList != null &&
            _echooDetailModelList!.isNotEmpty) {
          // var deletedEchoo =
          //     _echooDetailModelList.firstWhere((x) => x.key == echooId);
          _echooDetailModelList!.remove(_echooDetailModelList!);
          if (_echooDetailModelList!.isEmpty) {
            _echooDetailModelList = null;
          }

          cprint('Echoo deleted from nested echoo detail page echoo');
        }
      });
    } catch (error) {
      cprint(error, errorIn: 'deleteEchoo');
    }
  }

  /// upload [file] to firebase storage and return its  path url
  Future<String?> uploadFile(File file) async {
    try {
      isBusy = true;
      notifyListeners();
      var storageReference = FirebaseStorage.instance
          .ref()
          .child("echooImage")
          .child(path.basename(DateTime.now().toIso8601String() + file.path));
      await storageReference.putFile(file);

      var url = await storageReference.getDownloadURL();
      // ignore: unnecessary_null_comparison
      if (url != null) {
        return url;
      }
      return null;
    } catch (error) {
      cprint(error, errorIn: 'uploadFile');
      return null;
    }
  }

  /// [Delete file] from firebase storage
  Future<void> deleteFile(String url, String baseUrl) async {
    try {
      var filePath = url.split(".com/o/")[1];
      filePath = filePath.replaceAll(RegExp(r'%2F'), '/');
      filePath = filePath.replaceAll(RegExp(r'(\?alt).*'), '');
      //  filePath = filePath.replaceAll('echooImage/', '');
      cprint('[Path]' + filePath);
      var storageReference = FirebaseStorage.instance.ref();
      await storageReference.child(filePath).delete().catchError((val) {
        cprint('[Error]' + val);
      }).then((_) {
        cprint('[Success] Image deleted');
      });
    } catch (error) {
      cprint(error, errorIn: 'deleteFile');
    }
  }

  /// [update] echoo
  Future<void> updateEchoo(FeedModel model) async {
    await kDatabase.child('echoo').child(model.key!).set(model.toJson());
  }

  /// Add/Remove like on a Echoo
  /// [postId] is echoo id, [userId] is user's id who like/unlike Echoo
  addLikeToEchoo(FeedModel echoo, String userId) {
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

  /// Add [new comment echoo] to any echoo
  /// Comment is a Echoo itself
  Future<String?> addCommentToPost(FeedModel replyEchoo) async {
    try {
      isBusy = true;
      notifyListeners();
      // String echooKey;
      if (_echooToReplyModel != null) {
        FeedModel echoo =
            _feedList!.firstWhere((x) => x.key == _echooToReplyModel!.key);
        var json = replyEchoo.toJson();
        DatabaseReference ref = kDatabase.child('echoo').push();
        await ref.set(json);
        echoo.replyEchooKeyList!.add(ref.key);
        await updateEchoo(echoo);
        return ref.key;
      } else {
        return null;
      }
    } catch (error) {
      cprint(error, errorIn: 'addCommentToPost');
      return null;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// Add Echoo in bookmark
  Future addBookmark(String echooId) async {
    final pref = getIt<SharedPreferenceHelper>();
    var userId = await pref.getUserProfile().then((value) => value!.userId);
    DatabaseReference dbReference =
        kDatabase.child('bookmark').child(userId!).child(echooId);
    await dbReference.set(
        {"echooId": echooId, "created_at": DateTime.now().toUtc().toString()});
  }

  /// Trigger when any echoo changes or update
  /// When any echoo changes it update it in UI
  /// No matter if Echoo is in home page or in detail page or in comment section.
  _onEchooChanged(DatabaseEvent event) {
    var model =
        FeedModel.fromJson(event.snapshot.value as Map<dynamic, dynamic>);
    model.key = event.snapshot.key!;
    if (_feedList!.any((x) => x.key == model.key)) {
      var oldEntry = _feedList!.lastWhere((entry) {
        return entry.key == event.snapshot.key;
      });
      _feedList![_feedList!.indexOf(oldEntry)] = model;
    }

    if (_echooDetailModelList != null && _echooDetailModelList!.isNotEmpty) {
      if (_echooDetailModelList!.any((x) => x.key == model.key)) {
        var oldEntry = _echooDetailModelList!.lastWhere((entry) {
          return entry.key == event.snapshot.key;
        });
        _echooDetailModelList![_echooDetailModelList!.indexOf(oldEntry)] =
            model;
      }
      if (echooReplyMap != null && echooReplyMap!.isNotEmpty) {
        if (true) {
          var list = echooReplyMap![model.parentkey];
          //  var list = echooReplyMap.values.firstWhere((x) => x.any((y) => y.key == model.key));
          if (list != null && list.isNotEmpty) {
            var index =
                list.indexOf(list.firstWhere((x) => x.key == model.key));
            list[index] = model;
          } else {
            list = [];
            list.add(model);
          }
        }
      }
    }
    // if (event.snapshot != null) {
    cprint('Echoo updated');
    isBusy = false;
    notifyListeners();
    // }
  }

  /// Trigger when new echoo added
  /// It will add new Echoo in home page list.
  /// IF Echoo is comment it will be added in comment section too.
  _onEchooAdded(DatabaseEvent event) {
    FeedModel echoo = FeedModel.fromJson(event.snapshot.value as Map);
    echoo.key = event.snapshot.key!;

    /// Check if Echoo is a comment
    _onCommentAdded(echoo);
    echoo.key = event.snapshot.key!;
    _feedList ??= <FeedModel>[];
    if ((_feedList!.isEmpty || _feedList!.any((x) => x.key != echoo.key)) &&
        echoo.isValidEchoo) {
      _feedList!.add(echoo);
      cprint('Echoo Added');
    }
    isBusy = false;
    notifyListeners();
  }

  /// Trigger when comment echoo added
  /// Check if Echoo is a comment
  /// If Yes it will add echoo in comment list.
  /// add [new echoo] comment to comment list
  _onCommentAdded(FeedModel echoo) {
    if (echoo.childRetwetkey != null) {
      /// if Echoo is a type of reechoo then it can not be a comment.
      return;
    }
    if (echooReplyMap != null && echooReplyMap!.isNotEmpty) {
      if (echooReplyMap![echoo.parentkey] != null) {
        /// Insert new comment at the top of all available comment
        echooReplyMap![echoo.parentkey]!.insert(0, echoo);
      } else {
        echooReplyMap![echoo.parentkey!] = [echoo];
      }
      cprint('Comment Added');
    }
    isBusy = false;
    notifyListeners();
  }

  /// Trigger when Echoo `Deleted`
  /// It removed Echoo from home page list, Echoo detail page list and from comment section if present
  _onEchooRemoved(DatabaseEvent event) async {
    FeedModel echoo = FeedModel.fromJson(event.snapshot.value as Map);
    echoo.key = event.snapshot.key!;
    var echooId = echoo.key;
    var parentkey = echoo.parentkey;

    ///  Delete echoo in [Home Page]
    try {
      late FeedModel deletedEchoo;
      if (_feedList!.any((x) => x.key == echooId)) {
        /// Delete echoo if it is in home page echoo.
        deletedEchoo = _feedList!.firstWhere((x) => x.key == echooId);
        _feedList!.remove(deletedEchoo);

        if (deletedEchoo.parentkey != null &&
            _feedList!.isNotEmpty &&
            _feedList!.any((x) => x.key == deletedEchoo.parentkey)) {
          // Decrease parent Echoo comment count and update
          var parentModel =
              _feedList!.firstWhere((x) => x.key == deletedEchoo.parentkey);
          parentModel.replyEchooKeyList!.remove(deletedEchoo.key);
          parentModel.commentCount = parentModel.replyEchooKeyList!.length;
          updateEchoo(parentModel);
        }
        if (_feedList!.isEmpty) {
          _feedList = null;
        }
        cprint('Echoo deleted from home page echoo list');
      }

      /// [Delete echoo] if it is in nested echoo detail comment section page
      if (parentkey != null &&
          parentkey.isNotEmpty &&
          echooReplyMap != null &&
          echooReplyMap!.isNotEmpty &&
          echooReplyMap!.keys.any((x) => x == parentkey)) {
        // (type == EchooType.Reply || echooReplyMap.length > 1) &&
        deletedEchoo =
            echooReplyMap![parentkey]!.firstWhere((x) => x.key == echooId);
        echooReplyMap![parentkey]!.remove(deletedEchoo);
        if (echooReplyMap![parentkey]!.isEmpty) {
          echooReplyMap![parentkey] = null;
        }

        if (_echooDetailModelList != null &&
            _echooDetailModelList!.isNotEmpty &&
            _echooDetailModelList!.any((x) => x.key == parentkey)) {
          var parentModel =
              _echooDetailModelList!.firstWhere((x) => x.key == parentkey);
          parentModel.replyEchooKeyList!.remove(deletedEchoo.key);
          parentModel.commentCount = parentModel.replyEchooKeyList!.length;
          cprint('Parent echoo comment count updated on child echoo removal');
          updateEchoo(parentModel);
        }

        cprint('Echoo deleted from nested echoo detail comment section');
      }

      /// Delete echoo image from firebase storage if exist.
      if (deletedEchoo.imagePath != null &&
          deletedEchoo.imagePath!.isNotEmpty) {
        deleteFile(deletedEchoo.imagePath!, 'echooImage');
      }

      /// If a reechoo is deleted then reechooCount of original echoo should be decrease by 1.
      if (deletedEchoo.childRetwetkey != null) {
        await fetchEchoo(deletedEchoo.childRetwetkey!)
            .then((FeedModel? reechooModel) {
          if (reechooModel == null) {
            return;
          }
          if (reechooModel.reechooCount! > 0) {
            reechooModel.reechooCount = reechooModel.reechooCount! - 1;
          }
          updateEchoo(reechooModel);
        });
      }

      /// Delete notification related to deleted Echoo.
      if (deletedEchoo.likeCount! > 0) {
        kDatabase
            .child('notification')
            .child(echoo.userId)
            .child(echoo.key!)
            .remove();
      }
      notifyListeners();
    } catch (error) {
      cprint(error, errorIn: '_onEchooRemoved');
    }
  }
}
