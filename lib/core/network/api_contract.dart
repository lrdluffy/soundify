/// Paths and JSON keys, taken from the official Soundify OpenAPI 3.0 spec
/// (v1.1.0). Base URL (with /api/v1) is in AppConfig. Paths have NO trailing
/// slash. If the backend changes, this is the only file to touch.
class Endpoints {
  Endpoints._();

  static const register = '/auth/register';
  static const login = '/auth/login';
  static const otpRequest = '/auth/otp/request';
  static const otpVerify = '/auth/otp/verify';
  static const resetRequest = '/auth/password/reset/request';
  static const resetConfirm = '/auth/password/reset/confirm';
  static const refresh = '/auth/token/refresh';
  static const logout = '/auth/logout';
  static const me = '/users/me';

  static const tracks = '/tracks';
  static const featured = '/tracks/featured';
  static String stream(String id) => '/tracks/$id/stream';

  static const playlists = '/playlists';
  static String playlist(String id) => '/playlists/$id';
  static String playlistTracks(String id) => '/playlists/$id/tracks';
  static String playlistTrack(String id, String trackId) =>
      '/playlists/$id/tracks/$trackId';

  static const favorites = '/favorites';
  static String favorite(String trackId) => '/favorites/$trackId';
}

/// Request body keys.
class Keys {
  Keys._();

  static const email = 'email';
  static const username = 'username';
  static const displayName = 'display_name';
  static const password = 'password';
  static const code = 'code';
  static const newPassword = 'new_password';
  static const refreshToken = 'refresh';
  static const trackId = 'track_id';
  static const playlistName = 'name';
  static const playlistDescription = 'description';
}

/// Response keys; the first one present wins (first entry = what the spec says,
/// the others are harmless fallbacks).
class ResponseKeys {
  ResponseKeys._();

  static const accessToken = ['access', 'access_token', 'accessToken', 'token'];
  static const refreshToken = ['refresh', 'refresh_token', 'refreshToken'];
  static const id = ['id', '_id', 'track_id', 'playlist_id'];
  static const title = ['title', 'name', 'track_name'];
  static const artist = ['artist', 'artist_name', 'singer'];
  static const album = ['album', 'album_name'];
  static const cover = ['cover_url', 'coverUrl', 'cover', 'image', 'thumbnail'];
  static const genre = ['genre', 'category'];
  static const streamUrl = ['stream_url', 'streamUrl', 'audio_url', 'url'];
  static const userName = ['display_name', 'name', 'full_name', 'username'];
}
