import 'package:rinne_graph/src/graph/events.dart';
import 'package:rinne_graph/src/util/debug_logger.dart';

/// Graph event callback function type
typedef GraphEventCallback<T extends GraphEvent> = void Function(T event);

/// Graph event management system (user-facing interface)
///
/// Manages registration and removal of event listeners.
abstract class GraphEventManager {
  /// Register event listener
  void addEventListener<T extends GraphEvent>(GraphEventCallback<T> callback);

  /// Remove event listener
  void removeEventListener<T extends GraphEvent>(
      GraphEventCallback<T> callback);

  /// Remove all listeners of a specific type
  void removeAllListeners<T extends GraphEvent>();

  /// Clear all listeners
  void clearAllListeners();

  /// Get the number of registered listeners
  int getListenerCount<T extends GraphEvent>();

  /// Get list of registered event types
  List<Type> getRegisteredEventTypes();
}

/// Graph event management system (internal implementation)
///
/// Manages registration, removal, and firing of event listeners.
/// Safely handles errors in callbacks without affecting transactions.
class GraphEventManagerImpl implements GraphEventManager {
  final Map<Type, List<Function>> _callbacks = {};

  @override
  void addEventListener<T extends GraphEvent>(
    GraphEventCallback<T> callback,
  ) {
    _callbacks.putIfAbsent(T, () => []).add(callback);
  }

  @override
  void removeEventListener<T extends GraphEvent>(
    GraphEventCallback<T> callback,
  ) {
    _callbacks[T]?.remove(callback);

    // Remove empty list
    if (_callbacks[T]?.isEmpty ?? false) {
      _callbacks.remove(T);
    }
  }

  void _executeCallbacks<T extends GraphEvent>(
      List<Function> callbacks, T event) {
    for (final callback in callbacks) {
      try {
        // Allow dynamic calls as Function type is verified at runtime
        // ignore: avoid_dynamic_calls
        callback(event);
      } on Exception catch (e, stackTrace) {
        // Only log errors, don't stop transaction
        debugLogger.logWithCategory('EVENT_ERROR', 'Event callback error: $e');
        debugLogger.logWithCategory('EVENT_ERROR', 'Stack trace: $stackTrace');
      }
    }
  }

  @override
  void removeAllListeners<T extends GraphEvent>() {
    _callbacks.remove(T);
  }

  @override
  void clearAllListeners() {
    _callbacks.clear();
  }

  @override
  int getListenerCount<T extends GraphEvent>() {
    if (T == GraphEvent) {
      // Total count
      return _callbacks.values.fold(0, (sum, list) => sum + list.length);
    } else {
      // Count for specific type
      return _callbacks[T]?.length ?? 0;
    }
  }

  @override
  List<Type> getRegisteredEventTypes() {
    return _callbacks.keys.toList();
  }

  /// Fire event (internal use only)
  ///
  /// [event] Event to fire
  ///
  /// This method is used only in internal implementation and is not exposed to users.
  void fireEvent<T extends GraphEvent>(T event) {
    // Look for callbacks with specific type
    final callbacks = _callbacks[event.runtimeType];

    if (callbacks == null || callbacks.isEmpty) {
      // Also look for base type
      final baseCallbacks = _callbacks[T];
      if (baseCallbacks == null || baseCallbacks.isEmpty) {
        return;
      }
      _executeCallbacks(baseCallbacks, event);
      return;
    }

    _executeCallbacks(callbacks, event);
  }

  /// Get debug information (internal use only)
  Map<String, dynamic> getDebugInfo() {
    final info = <String, dynamic>{};

    _callbacks.forEach((type, callbacks) {
      info[type.toString()] = callbacks.length;
    });

    return {
      'totalListeners': getListenerCount<GraphEvent>(),
      'eventTypes': info,
    };
  }
}
