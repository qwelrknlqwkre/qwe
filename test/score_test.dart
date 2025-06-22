import 'package:flutter_test/flutter_test.dart';
import 'package:gostop/utils/matgo_engine.dart';
import 'package:gostop/utils/deck_manager.dart';
import 'package:gostop/models/card_model.dart';

GoStopCard c(int month, String type, {String name = ''}) =>
    GoStopCard(id: month, month: month, type: type, name: name, imageUrl: '');

void main() {
  test('기본 점수 계산 테스트', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    engine.captured['player1'] = [c(1, '광'), c(2, '광'), c(3, '광')];
    expect(engine.calculateScore('player1'), 3);
  });

  test('pi over 10 scores correctly', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    engine.captured['player1'] = [for (var i = 0; i < 11; i++) c(i, '피')];
    expect(engine.calculateScore('player1'), 2);
  });

  test('고도리 점수 테스트', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    engine.captured['player1'] = [c(1, '동물'), c(3, '동물'), c(8, '동물')];
    expect(engine.calculateScore('player1'), 5);
  });

  test('animal count seven doubles score', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    engine.captured['player1'] = [for (var i = 0; i < 7; i++) c(i, '동물')];
    expect(engine.calculateScore('player1'), 6);
  });

  test('멍따 점수 테스트', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    // ... existing code ...
  });

  test('승수 적용 테스트', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    // ... existing code ...
  });
}
