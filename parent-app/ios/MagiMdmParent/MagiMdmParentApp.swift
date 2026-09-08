import SwiftUI

@main
struct MagiMdmParentApp: App {
    @StateObject var session = Session()
    var body: some Scene {
        WindowGroup {
            if session.api != nil {
                HomeView().environmentObject(session)
            } else {
                LoginView().environmentObject(session)
            }
        }
    }
}

final class Session: ObservableObject {
    @Published var api: API?
}
