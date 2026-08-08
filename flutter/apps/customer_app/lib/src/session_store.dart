import 'dart:convert';
import 'dart:io';

import 'domain.dart';

class SavedSession {
  const SavedSession({this.profile, this.storeId});

  final CustomerProfile? profile;
  final int? storeId;
}

abstract interface class SessionStore {
  Future<SavedSession> read();

  Future<void> write({required CustomerProfile profile, int? storeId});

  Future<void> clear();
}

class FileSessionStore implements SessionStore {
  FileSessionStore({File? file})
    : _file =
          file ??
          File(
            '${Directory.systemTemp.path}${Platform.pathSeparator}kirana_customer_session.json',
          );

  final File _file;

  @override
  Future<SavedSession> read() async {
    try {
      if (!await _file.exists()) return const SavedSession();
      final Object? decoded = jsonDecode(await _file.readAsString());
      if (decoded is! Map<String, dynamic>) return const SavedSession();
      final Object? profileJson = decoded['profile'];
      return SavedSession(
        profile: profileJson is Map<String, dynamic>
            ? CustomerProfile.fromJson(profileJson)
            : null,
        storeId: (decoded['storeId'] as num?)?.toInt(),
      );
    } on FormatException {
      return const SavedSession();
    } on FileSystemException {
      return const SavedSession();
    }
  }

  @override
  Future<void> write({required CustomerProfile profile, int? storeId}) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      jsonEncode(<String, Object?>{
        'profile': profile.toJson(),
        'storeId': storeId,
      }),
      flush: true,
    );
  }

  @override
  Future<void> clear() async {
    if (await _file.exists()) await _file.delete();
  }
}
