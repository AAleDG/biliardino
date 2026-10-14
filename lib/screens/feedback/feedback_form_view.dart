import 'package:flutter/material.dart';

import '../../models/app_style.dart';
import '../../presentation/italia90/theme/italia90_tokens.dart';
import '../../theme/app_theme.dart';

class FeedbackFormView extends StatelessWidget {
  const FeedbackFormView({
    super.key,
    required this.style,
    required this.formKey,
    required this.message,
    required this.email,
    required this.onChanged,
    required this.onSubmit,
    this.sending = false,
    this.error,
    this.draftNotice,
    this.readOnly = false,
  });

  final AppStyle style;
  final GlobalKey<FormState> formKey;
  final TextEditingController message;
  final TextEditingController email;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final bool sending;
  final String? error;
  final String? draftNotice;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final italia = style == AppStyle.italia90;
    final body = italia ? Italia90.body : AppType.body;
    final display = italia ? Italia90.heading : AppType.section;
    final primary = italia ? Italia90.primary : AppColors.primary;
    final ink = italia ? Italia90.ink : AppColors.ink;
    final label = body.copyWith(
      fontSize: 18,
      height: 1.1,
      color: ink,
      fontWeight: italia ? FontWeight.w700 : FontWeight.w600,
    );
    final intro = body.copyWith(fontSize: 19, height: 1.3, color: ink);
    final compact =
        MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).height < 650;
    // Anton's capitals sit above the line-box center. Center the visible
    // lettering, retaining the same button bounds and scaling with the text.
    Widget actionLabel(String text) => Transform.translate(
      offset: Offset(
        0,
        italia ? MediaQuery.textScalerOf(context).scale(3.5) : 0,
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
    InputDecoration decoration(String hint, {double? minHeight}) =>
        InputDecoration(
          constraints: minHeight == null
              ? null
              : BoxConstraints(minHeight: minHeight),
          hintText: hint,
          hintStyle: body.copyWith(
            fontSize: 16,
            letterSpacing: 0,
            color: italia ? Italia90.muted : AppColors.textSecondary,
          ),
          fillColor: italia ? Italia90.panel : AppColors.surface,
          contentPadding: const EdgeInsets.all(12),
        );
    Widget fieldLabel(String text) => ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.only(bottom: italia ? 6 : 10),
        child: text == 'Email (facoltativa)'
            ? Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Email '),
                    TextSpan(
                      text: '(facoltativa)',
                      style: label.copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                style: label,
              )
            : Text(text, style: label),
      ),
    );
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hai un’idea o qualcosa non funziona?',
          style: italia
              ? intro
              : AppType.section.copyWith(fontSize: 26, height: 1.2),
        ),
        SizedBox(height: italia ? 0 : 2),
        Text('Raccontacelo qui.', style: intro),
        SizedBox(height: italia ? 18 : 24),
        fieldLabel('Messaggio'),
        Semantics(
          label: 'Messaggio (obbligatorio)',
          child: TextFormField(
            key: const ValueKey('feedback-message'),
            controller: message,
            enabled: !sending && !readOnly,
            style: body.copyWith(
              fontSize: 16,
              height: italia ? 1.35 : 1.3,
              letterSpacing: 0,
            ),
            minLines: compact ? 4 : (italia ? 6 : 7),
            textAlignVertical: TextAlignVertical.top,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: decoration('Scrivi il tuo messaggio…'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Scrivi un messaggio.'
                : null,
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(height: 22),
        fieldLabel('Email (facoltativa)'),
        Semantics(
          label: 'Email (facoltativa)',
          child: TextFormField(
            key: const ValueKey('feedback-email'),
            controller: email,
            enabled: !sending && !readOnly,
            style: body.copyWith(fontSize: 16, height: 1.2, letterSpacing: 0),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            decoration: decoration('Per ricevere una risposta', minHeight: 48),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return null;
              return RegExp(r'^[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+$').hasMatch(text)
                  ? null
                  : 'Inserisci un’email valida.';
            },
            onChanged: (_) => onChanged(),
            onFieldSubmitted: (_) => sending ? null : onSubmit(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Invieremo anche versione dell’app, sistema operativo e stile scelto.',
          style: body.copyWith(
            fontSize: italia ? 13 : 15,
            height: italia ? 1.4 : 1.3,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: body.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: italia ? 7 : 0),
            child: fields,
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey('feedback-send'),
            onPressed: sending || readOnly ? null : onSubmit,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(italia ? 52 : 60),
              backgroundColor: primary,
              foregroundColor: Colors.white,
              textStyle: display.copyWith(fontSize: 24, height: 1),
            ),
            child: sending
                ? Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      actionLabel('INVIO IN CORSO'),
                    ],
                  )
                : actionLabel('INVIA FEEDBACK'),
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: draftNotice != null,
            child: Text(
              draftNotice ?? 'La bozza resta salvata su questo dispositivo.',
              textAlign: TextAlign.center,
              style: body.copyWith(
                fontSize: italia ? 13 : 14,
                height: 1.4,
                color: italia ? Italia90.muted : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
