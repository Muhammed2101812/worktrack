import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/dimens.dart';

void main() {
  group('Radii', () {
    test('scale values are exact', () {
      expect(Radii.xs, 8);
      expect(Radii.sm, 12);
      expect(Radii.md, 16);
      expect(Radii.lg, 20);
      expect(Radii.xl, 24);
      expect(Radii.full, 999);
    });

    test('BorderRadius helpers return correct values', () {
      expect(Radii.xsBr, const BorderRadius.all(Radius.circular(8)));
      expect(Radii.mdBr, const BorderRadius.all(Radius.circular(16)));
    });
  });

  group('innerRadius', () {
    test('card 16 minus padding 8 returns 8 (exact scale hit)', () {
      expect(innerRadius(16, 8), 8);
    });

    test('card 16 minus padding 12 snaps UP to nearest sensible (8)', () {
      // 16 - 12 = 4, which is below xs(8); snap up to 8 so children are not
      // sharper than badges.
      expect(innerRadius(16, 12), 8);
    });

    test('card 16 minus padding 4 returns 12', () {
      expect(innerRadius(16, 4), 12);
    });

    test('never returns below 0', () {
      expect(innerRadius(8, 100), 0);
    });
  });

  group('Spacing', () {
    test('scale values', () {
      expect(Spacing.s4, 4);
      expect(Spacing.s32, 32);
    });
  });
}
