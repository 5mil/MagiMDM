import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: Session
    @State private var rows: [DeviceRow] = []
    var body: some View {
        VStack {
            HStack {
                Button("School") { Task { try? await session.api?.bulk(policy: "SchoolDay"); await load() } }
                Button("Free") { Task { try? await session.api?.bulk(policy: "AfterHours"); await load() } }
                Button("Exam") { Task { try? await session.api?.bulk(policy: "ExamLock"); await load() } }
                Button("Lock") { Task { try? await session.api?.lockAll(); await load() } }
            }.buttonStyle(.borderedProminent)
            List(rows) { d in
                VStack(alignment: .leading) {
                    Text("\(d.name) · \(d.platform)").font(.headline)
                    Text("\(d.policy ?? "") · last \(d.last_seen_at ?? "—")")
                        .font(.caption)
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .navigationTitle("Devices")
    }

    func load() async {
        rows = (try? await session.api?.devices()) ?? []
    }
}
