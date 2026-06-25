import 'package:flutter_bloc/flutter_bloc.dart';

/// Guards [emit] against the "Cannot emit new states after calling close"
/// crash.
///
/// Cubits here kick off async work (network fetch, LLM calls) and then emit in
/// the `.fold` / `.then` callback. If the user navigates away before the future
/// resolves, the cubit is already closed and that late `emit` throws. [safeEmit]
/// drops the emit when the cubit is closed. Use it for every emit that runs
/// after an `await`.
mixin SafeEmit<S> on Cubit<S> {
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }
}
