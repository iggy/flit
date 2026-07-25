import 'package:flit/domain/models/insights.dart';

/// Intent-level insights operations (ticket P6-03).
abstract interface class InsightsRepository {
  /// `insights.get {days}` → session/message counts over rolling window.
  Future<Insights> get({int days = 30});
}
