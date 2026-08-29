import Foundation

@main
enum ClinicalModelsSmokeTests {
    static func main() {
        testMeasuredEntriesRequirePositiveAmounts()
        testLeakageRequiresAnAmount()
        testEventNormalization()
        testSubmissionGate()
        print("ClinicalModels smoke tests passed")
    }

    private static func testMeasuredEntriesRequirePositiveAmounts() {
        var draft = BladderDiaryDraft(type: .void, amountText: "", measured: true)
        precondition(draft.validationMessage != nil)

        draft.amountText = "250,5"
        precondition(draft.validationMessage == nil)
        precondition(draft.parsedAmount == 250.5)

        draft.measured = false
        draft.amountText = "400"
        precondition(draft.event(sessionId: UUID()).amountMl == nil)
    }

    private static func testLeakageRequiresAnAmount() {
        var draft = BladderDiaryDraft(type: .leakage)
        precondition(draft.validationMessage != nil)
        draft.leakageAmount = "Az"
        precondition(draft.validationMessage == nil)
    }

    private static func testEventNormalization() {
        let sessionId = UUID()
        let recordedAt = Date()
        let fluid = BladderDiaryDraft(
            type: .fluid,
            amountText: "200",
            urgency: 4,
            fluidType: "Su"
        ).event(sessionId: sessionId, recordedAt: recordedAt)

        precondition(fluid.sessionId == sessionId)
        precondition(fluid.amountMl == 200)
        precondition(fluid.urgency == nil)
        precondition(fluid.occurredAt == recordedAt)
    }

    private static func testSubmissionGate() {
        let sessionId = UUID()
        let startedAt = Date(timeIntervalSince1970: 1_000)
        let session = BladderDiarySession(
            id: sessionId,
            status: "active",
            startedAt: startedAt,
            endsAt: startedAt.addingTimeInterval(72 * 60 * 60),
            submittedAt: nil,
            events: nil
        )
        let storedEvent = BladderDiaryEvent(
            sessionId: sessionId,
            type: .void,
            recordedAt: startedAt,
            storageState: .serverStored
        )
        let pendingEvent = BladderDiaryEvent(
            sessionId: sessionId,
            type: .void,
            recordedAt: startedAt,
            storageState: .localOnly
        )

        precondition(!session.canSubmit(events: [storedEvent], now: startedAt))
        precondition(!session.canSubmit(events: [pendingEvent], now: session.resolvedEndsAt))
        precondition(session.canSubmit(events: [storedEvent], now: session.resolvedEndsAt))
    }
}
