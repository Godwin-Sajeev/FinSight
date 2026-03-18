import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/ml_service.dart';

// Provides the current user's profile info (name and picture path).
class UserProfileState {
  final String userName;
  final String? profilePicPath;

  const UserProfileState({
    required this.userName,
    this.profilePicPath,
  });

  UserProfileState copyWith({
    String? userName,
    String? profilePicPath,
  }) {
    return UserProfileState(
      userName: userName ?? this.userName,
      profilePicPath: profilePicPath ?? this.profilePicPath,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  UserProfileNotifier() : super(const UserProfileState(userName: 'Alex')) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final name = await MLService.getUserName();
    final pic = await MLService.getProfilePic();
    state = state.copyWith(
      userName: name ?? 'Alex',
      profilePicPath: pic,
    );
  }

  Future<void> updateName(String newName) async {
    await MLService.setUserName(newName);
    state = state.copyWith(userName: newName);
  }

  Future<void> updateProfilePic(String newPicPath) async {
    await MLService.setProfilePic(newPicPath);
    state = state.copyWith(profilePicPath: newPicPath);
  }
}

final userProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  return UserProfileNotifier();
});
