import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

class NotificationsState {
  final List<dynamic> list;
  final bool isLoading;

  NotificationsState({required this.list, required this.isLoading});

  factory NotificationsState.initial() => NotificationsState(list: [], isLoading: false);

  NotificationsState copyWith({List<dynamic>? list, bool? isLoading}) {
    return NotificationsState(
      list: list ?? this.list,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(NotificationsState.initial());

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await DioClient().get('/cliente/notificaciones');
      state = state.copyWith(
        list: res.data as List<dynamic>,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
