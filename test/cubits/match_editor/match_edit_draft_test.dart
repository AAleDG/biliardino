import 'package:biliardino/cubits/match_editor/match_edit_draft.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:flutter_test/flutter_test.dart';

GameMatch sample({List<String>? scorers}) => GameMatch(
  id: 'm',
  playedAt: DateTime(2026, 1, 7, 13, 30, 14, 7),
  mode: MatchMode.twoVsTwo,
  t1p1: 'a',
  t1p2: 'b',
  t2p1: 'c',
  t2p2: 'd',
  t1Score: 4,
  t2Score: 5,
  winningTeam: 2,
  scorerIds: scorers ?? ['a', 'c', 'a', 'd', 'b', 'c', 'a', 'd', 'c'],
);

void main() {
  test('no-op preserves every field and exact interleaved scorer order', () {
    final match = sample();
    final draft = MatchEditDraft.fromMatch(match);
    expect(draft.isDirty, false);
    expect(draft.toMatch().toMap(), match.toMap());
    expect(() => draft.team1.add('x'), throwsUnsupportedError);
    expect(() => draft.goals.clear(), throwsUnsupportedError);
  });
  test('date and time edits preserve the other component and attribution', () {
    final draft = MatchEditDraft.fromMatch(sample());
    final date = draft.withDate(DateTime(2025, 6, 2));
    expect(date.playedAt, DateTime(2025, 6, 2, 13, 30, 14, 7));
    expect(date.withTime(9, 45).playedAt, DateTime(2025, 6, 2, 9, 45, 14, 7));
    expect(date.toMatch().scorerIds, sample().scorerIds);
  });
  test('score shrink leaves allocations intact for explicit repair', () {
    final draft = MatchEditDraft.fromMatch(sample()).withScore(1, 2);
    expect(draft.assigned(1), 4);
    expect(draft.missing(1), -2);
    expect(draft.validationError, contains('eccesso'));
    expect(() => draft.toMatch(), throwsStateError);
    final fixed = draft.changeGoals(1, 'a', -1).changeGoals(1, 'a', -1);
    expect(fixed.toMatch().scorerIds, ['a', 'c', 'd', 'b', 'c', 'd', 'c']);
    expect(fixed.score1, 2);
    expect(fixed.goalsFor('b'), 1);
  });
  test('counts cannot steal goals or alter the final score', () {
    final draft = MatchEditDraft.fromMatch(sample());
    expect(draft.changeGoals(1, 'b', 1), draft);
    expect(draft.changeGoals(1, 'c', -1), draft);
    final changed = draft.changeGoals(1, 'a', -1).changeGoals(1, 'b', 1);
    expect(changed.goalsFor('a'), 2);
    expect(changed.goalsFor('b'), 2);
    expect(changed.score1, 4);
    expect(changed.validationError, isNull);
  });
  test(
    'replacement invalidates only removed player, excludes occupied IDs',
    () {
      final draft = MatchEditDraft.fromMatch(sample());
      expect(draft.replacePlayer(1, 0, 'c'), draft);
      final changed = draft.replacePlayer(1, 0, 'e');
      expect(changed.team1, ['e', 'b']);
      expect(changed.missing(1), 3);
      expect(changed.goalsFor('e'), 0);
      expect(changed.goalsFor('b'), 1);
      expect(changed.goalsFor('c'), 3);
      expect(changed.validationError, contains('Assegna'));
    },
  );
  test(
    'mode reduction retains first players and known goals without inference',
    () {
      final draft = MatchEditDraft.fromMatch(
        sample(),
      ).withMode(MatchMode.oneVsOne);
      expect(draft.team1, ['a']);
      expect(draft.team2, ['c']);
      expect(draft.missing(1), 1);
      expect(draft.missing(2), 2);
      final fixed = draft.confirmSingleScorer(1).confirmSingleScorer(2);
      expect(fixed.validationError, isNull);
      expect(fixed.toMatch().scorerIds, [
        'a',
        'c',
        'a',
        'c',
        'a',
        'c',
        'a',
        'c',
        'c',
      ]);
      expect(
        fixed.withMode(MatchMode.twoVsTwo).validationError,
        contains('Completa'),
      );
    },
  );
  test('legacy and partial 1v1 data require explicit single confirmation', () {
    for (final goals in [
      <String>[],
      ['a'],
    ]) {
      final draft = MatchEditDraft.fromMatch(
        sample(scorers: goals).copyWith(
          mode: MatchMode.oneVsOne,
          t1p2: '',
          t2p2: '',
          t1Score: 2,
          t2Score: 0,
        ),
      );
      expect(draft.validationError, contains('Assegna'));
      expect(draft.confirmSingleScorer(1).toMatch().scorerIds, ['a', 'a']);
    }
  });
  test('large draft scores and explicit single assignment stay compact', () {
    final draft = MatchEditDraft.fromMatch(
      sample(scorers: []).copyWith(
        mode: MatchMode.oneVsOne,
        t1p2: '',
        t2p2: '',
        t1Score: 1000000000000,
        t2Score: 0,
      ),
    );
    expect(draft.goals, isEmpty);
    final assigned = draft.confirmSingleScorer(1);
    expect(assigned.goals.length, 1);
    expect(assigned.assigned(1), 1000000000000);
  });
  test('negative/tied/incomplete drafts cannot save', () {
    final draft = MatchEditDraft.fromMatch(sample());
    expect(draft.withScore(1, -1).validationError, contains('validi'));
    expect(draft.withScore(1, 5).validationError, contains('vincitore'));
    expect(
      draft
          .withMode(MatchMode.oneVsOne)
          .withMode(MatchMode.twoVsTwo)
          .validationError,
      contains('Completa'),
    );
  });
  test(
    'existing 2v2 rivalry survives and can clear, new 2v2 flag rejected',
    () {
      final normal = MatchEditDraft.fromMatch(sample());
      expect(normal.withRivalry(true).isRivalry, false);
      final legacy = MatchEditDraft.fromMatch(
        sample().copyWith(isRivalry: true),
      );
      expect(legacy.toMatch().isRivalry, true);
      expect(legacy.withRivalry(false).toMatch().isRivalry, false);
      expect(
        normal
            .withMode(MatchMode.oneVsOne)
            .withRivalry(true)
            .withMode(MatchMode.twoVsTwo)
            .isRivalry,
        true,
      );
    },
  );
}
