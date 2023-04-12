enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

enum EchooType {
  Echoo,
  Detail,
  Reply,
  ParentEchoo,
}

enum SortUser {
  Verified,
  Alphabetically,
  Newest,
  Oldest,
  MaxFollower,
}

enum NotificationType {
  NOT_DETERMINED,
  Message,
  Echoo,
  Reply,
  Reechoo,
  Follow,
  Mention,
  Like
}
