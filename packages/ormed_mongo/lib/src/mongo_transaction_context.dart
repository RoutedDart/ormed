/// Tracks the current Mongo transaction/session metadata.
///
/// `mongo_dart` currently lacks a session/transaction API, so we stub out
/// the lifecycle here while keeping the structure ready for a future real
/// implementation once upstream support exists.
class MongoTransactionContext {
  MongoTransactionContext._();

  static String? currentSessionId;
  static MongoTransactionState sessionState = MongoTransactionState.idle;
  static DateTime? sessionStartedAt;
  static DateTime? sessionEndedAt;

  static void beginSession(String sessionId) {
    currentSessionId = sessionId;
    sessionState = MongoTransactionState.active;
    sessionStartedAt = DateTime.now().toUtc();
    sessionEndedAt = null;
  }

  static void commitSession() {
    sessionState = MongoTransactionState.committed;
    sessionEndedAt = DateTime.now().toUtc();
    currentSessionId = null;
  }

  static void abortSession() {
    sessionState = MongoTransactionState.aborted;
    sessionEndedAt = DateTime.now().toUtc();
    currentSessionId = null;
  }
}

enum MongoTransactionState { idle, active, committed, aborted }
