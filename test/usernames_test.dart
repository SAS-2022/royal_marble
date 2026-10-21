import 'package:flutter_test/flutter_test.dart';
import 'package:royal_marble/core/usernames.dart';

void main() {
  test('suggests first.last from the first and last words', () {
    expect(suggestUsername('Ravi Shankar', 'Kumar'), 'ravi.kumar');
    expect(suggestUsername(' Imran ', "O'Neil Khan"), 'imran.khan');
    expect(suggestUsername('Sam', ''), 'sam');
    expect(suggestUsername('محمد', 'علي'), '');
  });

  test('valid usernames', () {
    for (final u in ['ravi.kumar', 'ravi.kumar2', 'rm0042', 'a.b.c']) {
      expect(validUsername(u), isTrue, reason: u);
    }
    for (final u in ['ab', 'Ravi.Kumar', 'ravi..kumar', '.ravi', 'ravi.', 'ravi kumar', 'ravi@x']) {
      expect(validUsername(u), isFalse, reason: u);
    }
  });

  test('the sign-in field takes an email or a username', () {
    expect(signInEmail(' Ravi.Kumar '), 'ravi.kumar@$usernameDomain');
    expect(signInEmail('someone@gmail.com'), 'someone@gmail.com');
    expect(isUsernameEmail('ravi.kumar@$usernameDomain'), isTrue);
    expect(isUsernameEmail('quiet.tester@royalmarble.test'), isFalse);
  });
}
