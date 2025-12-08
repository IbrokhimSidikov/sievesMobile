import 'test.dart';
import 'test_session.dart';

class TestWithSessions {
  final Test test;
  final List<TestSession>? sessions;

  TestWithSessions({
    required this.test,
    this.sessions,
  });
}
