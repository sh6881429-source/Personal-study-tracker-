import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ── Abstract AI Provider Interface ──
/// Future-proof contract decoupling PrepTracker from any specific AI provider or SDK.
abstract class AIProvider {
  /// Generates a response string for the given prompt payload.
  Future<String> generateContent(String promptPayload);

  /// Streams a response for the given prompt payload.
  Stream<String> streamContent(String promptPayload);
}

/// Riverpod provider for active AIProvider instance.
final aiProvider = Provider<AIProvider>((ref) {
  throw UnimplementedError('aiProvider must be overridden or initialized.');
});
