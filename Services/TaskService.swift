import Foundation
import Supabase

final class TaskService {

    // MARK: - Open taken ophalen (buddy kaart)

    func fetchOpenTasks() async throws -> [DBTask] {
        try await supabase
            .from("tasks")
            .select()
            .eq("status", value: "open")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Taken voor een oudere (geschiedenis + actief)

    func fetchTasksForElderly(elderlyId: UUID) async throws -> [DBTask] {
        try await supabase
            .from("tasks")
            .select()
            .eq("elderly_id", value: elderlyId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Taak aanmaken

    func createTask(
        elderlyId: UUID,
        category: String,
        timingType: String,
        scheduledAt: Date? = nil,
        note: String,
        priceCents: Int
    ) async throws -> DBTask {
        struct Insert: Encodable {
            let elderlyId: UUID
            let category: String
            let timingType: String
            let scheduledAt: Date?
            let note: String
            let priceCents: Int
            enum CodingKeys: String, CodingKey {
                case elderlyId = "elderly_id"
                case category
                case timingType    = "timing_type"
                case scheduledAt   = "scheduled_at"
                case note
                case priceCents    = "price_cents"
            }
        }

        return try await supabase
            .from("tasks")
            .insert(Insert(
                elderlyId: elderlyId,
                category: category,
                timingType: timingType,
                scheduledAt: scheduledAt,
                note: note,
                priceCents: priceCents
            ))
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Taak accepteren (buddy)

    func acceptTask(taskId: UUID, buddyId: UUID, etaMinutes: Int) async throws {
        struct Update: Encodable {
            let status: String
            let assignedBuddyId: UUID
            let acceptedAt: Date
            let buddyEtaMinutes: Int
            enum CodingKeys: String, CodingKey {
                case status
                case assignedBuddyId  = "assigned_buddy_id"
                case acceptedAt       = "accepted_at"
                case buddyEtaMinutes  = "buddy_eta_minutes"
            }
        }

        try await supabase
            .from("tasks")
            .update(Update(
                status: "accepted",
                assignedBuddyId: buddyId,
                acceptedAt: Date(),
                buddyEtaMinutes: etaMinutes
            ))
            .eq("id", value: taskId.uuidString)
            .execute()
    }

    // MARK: - Buddy aankomst

    func markArrived(taskId: UUID) async throws {
        struct Update: Encodable {
            let status: String
            let arrivedAt: Date
            enum CodingKeys: String, CodingKey {
                case status
                case arrivedAt = "arrived_at"
            }
        }

        try await supabase
            .from("tasks")
            .update(Update(status: "arrived", arrivedAt: Date()))
            .eq("id", value: taskId.uuidString)
            .execute()
    }

    // MARK: - Taak afronden

    func completeTask(
        taskId: UUID,
        buddyId: UUID,
        note: String,
        netAmountCents: Int,
        elderlyName: String,
        category: String
    ) async throws {
        struct TaskUpdate: Encodable {
            let status: String
            let completedAt: Date
            let completionNote: String
            enum CodingKeys: String, CodingKey {
                case status
                case completedAt   = "completed_at"
                case completionNote = "completion_note"
            }
        }
        struct EarningInsert: Encodable {
            let buddyId: UUID
            let taskId: UUID
            let elderlyName: String
            let category: String
            let amountCents: Int
            enum CodingKeys: String, CodingKey {
                case buddyId     = "buddy_id"
                case taskId      = "task_id"
                case elderlyName = "elderly_name"
                case category
                case amountCents = "amount_cents"
            }
        }

        // Taak afsluiten
        try await supabase
            .from("tasks")
            .update(TaskUpdate(status: "completed", completedAt: Date(), completionNote: note))
            .eq("id", value: taskId.uuidString)
            .execute()

        // Verdienstrecord aanmaken (netto na platformcommissie)
        try await supabase
            .from("earnings")
            .insert(EarningInsert(
                buddyId: buddyId,
                taskId: taskId,
                elderlyName: elderlyName,
                category: category,
                amountCents: netAmountCents
            ))
            .execute()
    }

    // MARK: - Verdiensten ophalen

    func fetchEarnings(buddyId: UUID) async throws -> [DBEarning] {
        try await supabase
            .from("earnings")
            .select()
            .eq("buddy_id", value: buddyId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Review plaatsen

    func submitReview(
        taskId: UUID,
        reviewerId: UUID,
        revieweeId: UUID,
        stars: Int,
        body: String
    ) async throws {
        struct Insert: Encodable {
            let taskId: UUID
            let reviewerId: UUID
            let revieweeId: UUID
            let stars: Int
            let body: String
            enum CodingKeys: String, CodingKey {
                case taskId     = "task_id"
                case reviewerId = "reviewer_id"
                case revieweeId = "reviewee_id"
                case stars, body
            }
        }

        try await supabase
            .from("reviews")
            .insert(Insert(
                taskId: taskId,
                reviewerId: reviewerId,
                revieweeId: revieweeId,
                stars: stars,
                body: body
            ))
            .execute()
    }

    // MARK: - Familie koppelen via code

    func validateLinkingCode(code: String) async throws -> DBLinkingCode? {
        let results: [DBLinkingCode] = try await supabase
            .from("linking_codes")
            .select()
            .eq("code", value: code)
            .filter("used_at", operator: "is", value: "null")
            .gte("expires_at", value: Date().ISO8601Format())
            .limit(1)
            .execute()
            .value
        return results.first
    }

    func linkFamilyToElderly(familyId: UUID, elderlyId: UUID, code: String) async throws {
        struct LinkInsert: Encodable {
            let familyId: UUID
            let elderlyId: UUID
            enum CodingKeys: String, CodingKey {
                case familyId  = "family_id"
                case elderlyId = "elderly_id"
            }
        }

        // Koppeling aanmaken
        try await supabase
            .from("family_elderly_links")
            .insert(LinkInsert(familyId: familyId, elderlyId: elderlyId))
            .execute()

        // Code markeren als gebruikt
        try await supabase
            .from("linking_codes")
            .update(["used_at": Date().ISO8601Format()])
            .eq("code", value: code)
            .execute()
    }

    // MARK: - Realtime: live taakupdates voor elderly/familie

    func subscribeToTaskUpdates(elderlyId: UUID, onUpdate: @escaping (DBTask) -> Void) async {
        let channel = supabase.realtimeV2.channel("tasks-\(elderlyId.uuidString)")

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "tasks",
            filter: .eq("elderly_id", value: elderlyId.uuidString)
        )

        try? await channel.subscribeWithError()

        Task {
            for await change in changes {
                if case let .update(action) = change,
                   let task = try? action.decodeRecord(as: DBTask.self, decoder: JSONDecoder()) {
                    await MainActor.run { onUpdate(task) }
                }
            }
        }
    }
}
