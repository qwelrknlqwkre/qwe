import 'package:flutter_test/flutter_test.dart';
import 'package:go_stop_app/utils/matgo_engine.dart';
import 'package:go_stop_app/models/card_model.dart';

GoStopCard c(int month, String type, {String name = ''}) =>
    GoStopCard(id: month, month: month, type: type, name: name, imageUrl: '');

void main() {
  test('three gwang gives 3 points', () {
    final engine = MatgoEngine();
    engine.captured['player1'] = [c(1, '광'), c(2, '광'), c(3, '광')];
    expect(engine.calculateScore('player1'), 3);
  });

  test('pi over 10 scores correctly', () {
    final engine = MatgoEngine();
    engine.captured['player1'] = [for (var i = 0; i < 11; i++) c(i, '피')];
    expect(engine.calculateScore('player1'), 2);
  });

  test('godori adds 5 points', () {
    final engine = MatgoEngine();
    engine.captured['player1'] = [c(1, '동물'), c(3, '동물'), c(8, '동물')];
    expect(engine.calculateScore('player1'), 5);
  });

  test('animal count seven doubles score', () {
    final engine = MatgoEngine();
    engine.captured['player1'] = [for (var i = 0; i < 7; i++) c(i, '동물')];
    expect(engine.calculateScore('player1'), 6);
  });
}
