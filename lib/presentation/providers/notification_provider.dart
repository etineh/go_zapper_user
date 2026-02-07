import 'package:flutter/foundation.dart';
import 'package:gozapper/domain/entities/notification.dart';
import 'package:gozapper/domain/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository notificationRepository;

  NotificationProvider({required this.notificationRepository});

  // State - cache notifications per filter
  final Map<String, List<Notification>> _notificationsByFilter = {
    'all': [],
    'delivery': [],
    'payment': [],
    'account': [],
  };

  // Track which filters have been loaded
  final Map<String, bool> _filterLoaded = {
    'all': false,
    'delivery': false,
    'payment': false,
    'account': false,
  };

  // Track pagination state per filter
  final Map<String, int> _filterOffset = {
    'all': 0,
    'delivery': 0,
    'payment': 0,
    'account': 0,
  };

  final Map<String, bool> _filterHasMore = {
    'all': true,
    'delivery': true,
    'payment': true,
    'account': true,
  };

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _currentFilter = 'all'; // all, delivery, payment, account
  static const int _pageSize = 20;

  // Getters
  List<Notification> get notifications => _notificationsByFilter[_currentFilter] ?? [];
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;
  bool get hasMoreData => _filterHasMore[_currentFilter] ?? false;
  bool get isFilterLoaded => _filterLoaded[_currentFilter] ?? false;

  /// Get grouped notifications by date
  /// Returns Map<String, List<Notification>> with keys: 'Today', 'Yesterday', 'This Week', 'Earlier'
  Map<String, List<Notification>> get groupedNotifications {
    final filtered = notifications;
    final grouped = <String, List<Notification>>{};

    // Initialize groups in order
    const groups = ['Today', 'Yesterday', 'This Week', 'Earlier'];
    for (final group in groups) {
      grouped[group] = [];
    }

    // Group notifications by their date group
    for (final notification in filtered) {
      grouped[notification.dateGroup]?.add(notification);
    }

    // Remove empty groups and return
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  /// Get all notification dates for grouping
  List<String> get groupedDates {
    return groupedNotifications.keys.toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setLoadingMore(bool value) {
    _isLoadingMore = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Fetch notifications (initial load or refresh)
  /// If filter is not loaded yet, fetches from backend
  /// If refresh=true, refreshes the current filter from backend
  Future<void> fetchNotifications({bool refresh = false}) async {
    // Check if this filter is already loaded and we're not forcing refresh
    if (!refresh && (_filterLoaded[_currentFilter] ?? false)) {
      return; // Use cached data
    }

    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    final typeFilter = _currentFilter == 'all' ? null : _currentFilter;
    final offset = refresh ? 0 : (_filterOffset[_currentFilter] ?? 0);

    final result = await notificationRepository.getNotifications(
      type: typeFilter,
      limit: _pageSize,
      offset: offset,
    );

    result.fold(
      (failure) {
        _setError(failure.message);
        _setLoading(false);
      },
      (newNotifications) {
        if (refresh || offset == 0) {
          // Replace data for new load or refresh
          _notificationsByFilter[_currentFilter] = newNotifications;
          _filterOffset[_currentFilter] = _pageSize;
        } else {
          // Append for pagination
          final existingIds =
              _notificationsByFilter[_currentFilter]?.map((n) => n.id).toSet() ?? {};
          final uniqueNotifications = newNotifications
              .where((notification) => !existingIds.contains(notification.id))
              .toList();
          _notificationsByFilter[_currentFilter]?.addAll(uniqueNotifications);
          _filterOffset[_currentFilter] =
              (_filterOffset[_currentFilter] ?? 0) + uniqueNotifications.length;
        }

        // Mark filter as loaded
        _filterLoaded[_currentFilter] = true;

        // Check if there are more results
        _filterHasMore[_currentFilter] = newNotifications.length == _pageSize;

        _clearError();
        _setLoading(false);
      },
    );
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (!(_filterHasMore[_currentFilter] ?? false) || _isLoadingMore) return;

    _setLoadingMore(true);

    final currentOffset = (_filterOffset[_currentFilter] ?? 0);
    final typeFilter = _currentFilter == 'all' ? null : _currentFilter;

    final result = await notificationRepository.getNotifications(
      type: typeFilter,
      limit: _pageSize,
      offset: currentOffset,
    );

    result.fold(
      (failure) {
        _setError(failure.message);
        _setLoadingMore(false);
      },
      (newNotifications) {
        // Get existing IDs to avoid duplicates
        final existingIds =
            _notificationsByFilter[_currentFilter]?.map((n) => n.id).toSet() ?? {};

        // Add only notifications that don't already exist
        final uniqueNotifications = newNotifications
            .where((notification) => !existingIds.contains(notification.id))
            .toList();

        _notificationsByFilter[_currentFilter]?.addAll(uniqueNotifications);

        // Update offset
        _filterOffset[_currentFilter] = currentOffset + uniqueNotifications.length;

        // Check if there are more results
        _filterHasMore[_currentFilter] = newNotifications.length == _pageSize;

        _clearError();
        _setLoadingMore(false);
      },
    );
  }

  /// Set filter and switch to it
  /// Shows cached data immediately if available, otherwise loads from backend
  /// Always performs a background refresh if filter is already loaded
  Future<void> setFilter(String filter) async {
    if (_currentFilter == filter) {
      // Same filter clicked again - do a silent background refresh
      _silentRefresh();
      return;
    }

    _currentFilter = filter;
    notifyListeners();

    // Load this filter's data if not already loaded
    if (!(_filterLoaded[_currentFilter] ?? false)) {
      await fetchNotifications();
    } else {
      // Filter already loaded - do a background refresh without showing spinner
      _silentRefresh();
    }
  }

  /// Fetch notifications in background without showing loading spinner
  /// Only notifies listeners when new data arrives
  void _silentRefresh() {
    final typeFilter = _currentFilter == 'all' ? null : _currentFilter;

    notificationRepository.getNotifications(
      type: typeFilter,
      limit: _pageSize,
      offset: 0,
    ).then((result) {
      result.fold(
        (failure) {
          _setError(failure.message);
        },
        (newNotifications) {
          // Replace data with fresh from backend
          _notificationsByFilter[_currentFilter] = newNotifications;
          _filterOffset[_currentFilter] = _pageSize;
          _filterHasMore[_currentFilter] = newNotifications.length == _pageSize;
          _clearError();
          notifyListeners();
        },
      );
    });
  }

  /// Delete a notification from current filter
  Future<bool> deleteNotification(String id) async {
    final result = await notificationRepository.deleteNotification(id);

    return result.fold(
      (failure) {
        _setError(failure.message);
        return false;
      },
      (_) {
        // Remove from current filter's local list
        _notificationsByFilter[_currentFilter]?.removeWhere((n) => n.id == id);

        // Also remove from 'all' if we're in a specific filter
        if (_currentFilter != 'all') {
          _notificationsByFilter['all']?.removeWhere((n) => n.id == id);
        }

        _clearError();
        notifyListeners();
        return true;
      },
    );
  }

  /// Refresh notifications (pull-to-refresh)
  /// Only refreshes the current filter
  Future<void> refreshNotifications() async {
    await fetchNotifications(refresh: true);
  }
}
