import 'package:flutter_test/flutter_test.dart';
import 'package:go_stop_app/utils/event_evaluator.dart';
import 'package:go_stop_app/models/card_model.dart';

GoStopCard c(int month, String type, {String name = ''}) =>
    GoStopCard(id: month, month: month, type: type, name: name, imageUrl: '');

void main() {
  test('isChok detects chok event', () {
    final played = c(1, '피');
    final drawn = c(2, '피');
    final field = [c(2, '띠')];
    expect(EventEvaluator.isChok(played, drawn, field), isTrue);
  });

  test('isTtak detects ttak event', () {
    final played = c(3, '피');
    final field = [c(3, '피'), c(3, '띠')];
    expect(EventEvaluator.isTtak(played, field), isTrue);
  });

  test('isBomb detects bomb event', () {
    final hand = [c(4, '피'), c(4, '띠'), c(4, '광')];
    final field = [c(4, '피')];
    expect(EventEvaluator.isBomb(hand, field), isTrue);
  });

  test('isPuk updates history when puk occurs', () {
    final ev = EventEvaluator();
    final played = c(5, '피');
    final field = [c(5, '띠'), c(5, '피')];
    expect(ev.isPuk(played, field), isTrue);
    expect(ev.pukHistory.contains('5'), isTrue);
  });

  test('isTriplePuk returns true after three puks', () {
    final ev = EventEvaluator();
    for (var m in [6, 7, 8]) {
      expect(ev.isPuk(c(m, '피'), [c(m, '피'), c(m, '띠')]), isTrue);
    }
    expect(ev.isTriplePuk(), isTrue);
  });
}
