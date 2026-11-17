/// Every server-dependent name lives here (paths + JSON keys), so if the live
/// API docs differ from what we assumed, only this file needs to change.
class Endpoints {
  Endpoints._();

  static const register = '/auth/register';
  static const login = '/auth/login';
  static const otpRequest = '/auth/otp/request';
  static const otpVerify = '/auth/otp/verify';
  static const resetRequest = '/auth/password/reset/request';
  static const resetConfirm = '/auth/password/reset/confirm';
  static const refresh = '/auth/token/refresh';
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
  static const password = 'password';
  static const name = 'name';
  static const code = 'code';
  static const newPassword = 'new_password';
  static const refreshToken = 'refresh_token';
  static const trackId = 'track_id';
  static const playlistName = 'name';
  static const playlistDescription = 'description';
}

/// Candidate response keys; the first one that is present is used.
class ResponseKeys {
  ResponseKeys._();

  static const accessToken = ['access_token', 'accessToken', 'token'];
  static const refreshToken = ['refresh_token', 'refreshToken'];
  static const id = ['id', '_id', 'track_id', 'playlist_id'];
  static const title = ['title', 'name', 'track_name'];
  static const artist = ['artist', 'artist_name', 'singer'];
  static const album = ['album', 'album_name'];
  static const cover = [
    'cover_url',
    'coverUrl',
    'cover',
    'cover_image',
    'image',
    'artwork',
    'thumbnail',
  ];
  static const genre = ['genre', 'category'];
  static const streamUrl = ['stream_url', 'streamUrl', 'audio_url', 'url'];
  static const userName = ['name', 'full_name', 'username', 'display_name'];
}
