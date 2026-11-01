import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The platform connectivity source, as a provider so tests can fake it.
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// Longest a brief drop (a switch between Wi-Fi and mobile data) can last
/// before it counts as being offline.
const offlineGracePeriod = Duration(milliseconds: 800);

bool _hasNetwork(List<ConnectivityResult> results) =>
    results.any((result) => result != ConnectivityResult.none);

/// Whether the device has a network connection: the current state first, then
/// every change. A drop is re-checked after [offlineGracePeriod] so switching
/// networks does not flash the offline screen.
///
/// This reports a network interface being up, not that the internet is
/// reachable behind it (a Wi-Fi with no data still counts as online).
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = ref.watch(connectivityProvider);

  yield _hasNetwork(await connectivity.checkConnectivity());

  await for (final results in connectivity.onConnectivityChanged) {
    if (_hasNetwork(results)) {
      yield true;
      continue;
    }
    await Future<void>.delayed(offlineGracePeriod);
    yield _hasNetwork(await connectivity.checkConnectivity());
  }
});
