import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/app_style/app_style_cubit.dart';
import '../../cubits/feedback/feedback_cubit.dart';
import '../../models/app_style.dart';
import '../../models/feedback_draft.dart';
import '../../repositories/feedback_repository.dart';
import '../../widgets/feedback/feedback_page_frame.dart';
import 'feedback_confirmation_view.dart';
import 'feedback_form_view.dart';
import 'feedback_recovery_view.dart';

/// Stable route owner: controllers and request survive presentation rebuilds.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _email = TextEditingController();
  late final FeedbackCubit _cubit;
  bool _closing = false;
  bool _canLeave = false;

  @override
  void initState() {
    super.initState();
    _cubit = FeedbackCubit(context.read<FeedbackRepository>());
    unawaited(_cubit.load());
  }

  @override
  void dispose() {
    _message.dispose();
    _email.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  void _changed() => unawaited(
    _cubit.edit(FeedbackDraft(message: _message.text, email: _email.text)),
  );

  void _submit(AppStyle style) {
    if (_closing || _cubit.state.status != FeedbackStatus.editing) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(_cubit.send(style));
  }

  Future<void> _back() async {
    if (_closing || _cubit.state.status == FeedbackStatus.sending) return;
    setState(() => _closing = true);
    final saved = await _cubit.flushDraft();
    if (!mounted) return;
    if (!saved) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bozza non salvata'),
          content: const Text(
            'Non siamo riusciti a salvare la bozza. Chiudendo potresti perdere le ultime modifiche.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Resta'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Chiudi comunque'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (leave != true) {
        setState(() => _closing = false);
        return;
      }
    }
    setState(() => _canLeave = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AppStyleCubit, AppStyle>(
    builder: (context, style) => BlocConsumer<FeedbackCubit, FeedbackState>(
      bloc: _cubit,
      listener: (context, state) {
        if (_message.text != state.draft.message) {
          _message.text = state.draft.message;
        }
        if (_email.text != state.draft.email) {
          _email.text = state.draft.email;
        }
      },
      builder: (context, state) => PopScope<void>(
        canPop: _canLeave,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            unawaited(_back());
          }
        },
        child: FeedbackPageFrame(
          style: style,
          onBack: state.status == FeedbackStatus.sending || _closing
              ? null
              : _back,
          child: state.status == FeedbackStatus.loading
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.error == null)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      Semantics(liveRegion: true, child: Text(state.error!)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _cubit.load,
                        child: const Text('Riprova'),
                      ),
                    ],
                  ],
                )
              : state.status == FeedbackStatus.recovery
              ? FeedbackRecoveryView(
                  style: style,
                  onRestore: _cubit.restoreDraft,
                  error: state.error,
                )
              : state.status == FeedbackStatus.sent
              ? FeedbackConfirmationView(
                  style: style,
                  onReturn: _back,
                  notice: state.draftNotice,
                )
              : FeedbackFormView(
                  style: style,
                  formKey: _formKey,
                  message: _message,
                  email: _email,
                  onChanged: _changed,
                  onSubmit: () => _submit(style),
                  sending: state.status == FeedbackStatus.sending,
                  readOnly: _closing,
                  error: state.error,
                  draftNotice: state.draftNotice,
                ),
        ),
      ),
    ),
  );
}
