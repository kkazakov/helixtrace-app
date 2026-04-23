import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:helixtrace/data/models/point_model.dart';
import 'package:helixtrace/data/services/api_service.dart';
import 'package:helixtrace/features/auth/providers/providers.dart';

class PointsState {
  final bool isLoading;
  final List<PointModel> points;
  final String? error;

  PointsState({
    this.isLoading = false,
    this.points = const [],
    this.error,
  });

  PointsState.loading() : this(isLoading: true);
  PointsState.error(String message) : this(isLoading: false, error: message);
  PointsState.loaded(List<PointModel> points) : this(points: points);
}

class PointsNotifier extends StateNotifier<PointsState> {
  final ApiService _apiService;

  PointsNotifier(this._apiService) : super(PointsState.loading());

  Future<void> fetchPoints() async {
    state = PointsState.loading();
    try {
      final response = await _apiService.getPoints(
        includePublic: true,
        includeMeshcoreDashboard: true,
      );
      if (kDebugMode) {
        debugPrint('Points API response: ${response.data}');
      }
      final data = response.data as List;
      if (kDebugMode) {
        debugPrint('Points count: ${data.length}');
      }
      final points = data
          .map((json) => PointModel.fromJson(json as Map<String, dynamic>))
          .toList();
      state = PointsState.loaded(points);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Points fetch error: $e\n$st');
      }
      state = PointsState.error(e.toString());
    }
  }
}

final pointsProvider = StateNotifierProvider<PointsNotifier, PointsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PointsNotifier(apiService);
});
