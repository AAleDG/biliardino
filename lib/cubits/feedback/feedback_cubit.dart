import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/app_style.dart';
import '../../models/feedback_draft.dart';
import '../../repositories/feedback_repository.dart';

enum FeedbackStatus { loading, recovery, editing, sending, sent }

class FeedbackState {
  const FeedbackState({
    this.status = FeedbackStatus.loading,
    this.draft = const FeedbackDraft(),
    this.error,
    this.draftNotice,
  });

  final FeedbackStatus status;
  final FeedbackDraft draft;
  final String? error;
  final String? draftNotice;
}

class FeedbackCubit extends Cubit<FeedbackState> {
  FeedbackCubit(this._repository) : super(const FeedbackState());

  final FeedbackRepository _repository;
  int _revision = 0;

  Future<void> load() async {
    emit(const FeedbackState());
    try {
      final draft = await _repository.loadDraft().timeout(
        const Duration(seconds: 5),
      );
      if (!isClosed) {
        emit(FeedbackState(status: FeedbackStatus.editing, draft: draft));
      }
    } on FeedbackRecoveryRequired catch (recovery) {
      if (!isClosed) {
        emit(
          FeedbackState(status: FeedbackStatus.recovery, draft: recovery.draft),
        );
      }
    } on Object {
      if (!isClosed) {
        emit(
          const FeedbackState(
            error: 'Non siamo riusciti a recuperare la bozza. Riprova.',
          ),
        );
      }
    }
  }

  Future<void> restoreDraft() async {
    if (state.status != FeedbackStatus.recovery) return;
    final draft = state.draft;
    emit(FeedbackState(status: FeedbackStatus.loading, draft: draft));
    try {
      await _repository.restoreDraft(draft).timeout(const Duration(seconds: 5));
      if (!isClosed) {
        emit(FeedbackState(status: FeedbackStatus.editing, draft: draft));
      }
    } on Object {
      if (!isClosed) {
        emit(
          FeedbackState(
            status: FeedbackStatus.recovery,
            draft: draft,
            error: 'Non siamo riusciti a ripristinare la bozza. Riprova.',
          ),
        );
      }
    }
  }

  Future<void> edit(FeedbackDraft draft) async {
    if (state.status != FeedbackStatus.editing) return;
    final revision = ++_revision;
    emit(
      FeedbackState(
        status: FeedbackStatus.editing,
        draft: draft,
        draftNotice: 'Salvataggio della bozza…',
      ),
    );
    String? notice;
    try {
      await _repository.saveDraft(draft).timeout(const Duration(seconds: 5));
    } on Object {
      notice = 'Non siamo riusciti a salvare la bozza su questo dispositivo.';
    }
    if (!isClosed &&
        revision == _revision &&
        (state.status == FeedbackStatus.editing ||
            state.status == FeedbackStatus.sending)) {
      emit(
        FeedbackState(
          status: state.status,
          draft: draft,
          error: state.error,
          draftNotice: notice,
        ),
      );
    }
  }

  Future<bool> flushDraft() async {
    if (state.status != FeedbackStatus.editing) return true;
    try {
      await _repository
          .saveDraft(state.draft)
          .timeout(const Duration(seconds: 5));
      return true;
    } on Object {
      if (!isClosed) {
        emit(
          FeedbackState(
            status: FeedbackStatus.editing,
            draft: state.draft,
            error: state.error,
            draftNotice:
                'Non siamo riusciti a salvare la bozza su questo dispositivo.',
          ),
        );
      }
      return false;
    }
  }

  Future<void> send(AppStyle style) async {
    if (state.status != FeedbackStatus.editing) return;
    final draft = state.draft;
    if (draft.message.trim().isEmpty) return;
    emit(
      FeedbackState(
        status: FeedbackStatus.sending,
        draft: draft,
        draftNotice: state.draftNotice,
      ),
    );
    try {
      await _repository.send(draft, style);
    } on Object {
      if (!isClosed) {
        emit(
          FeedbackState(
            status: FeedbackStatus.editing,
            draft: draft,
            error: 'Non siamo riusciti a inviare. Riprova.',
            draftNotice: state.draftNotice,
          ),
        );
      }
      return;
    }
    String? notice;
    try {
      await _repository.clearDraft().timeout(const Duration(seconds: 5));
    } on Object {
      notice =
          'Feedback ricevuto. Non siamo riusciti a cancellare la bozza su questo dispositivo.';
    }
    // A local cleanup failure never changes an acknowledged send into a retry.
    if (!isClosed) {
      emit(FeedbackState(status: FeedbackStatus.sent, draftNotice: notice));
    }
  }
}
