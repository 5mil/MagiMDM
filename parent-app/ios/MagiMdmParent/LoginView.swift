import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: Session
    @State private var url = "https://mdm.home"
    @State private var user = ""
    @State private var pass = ""
    @State private var err = ""
    var body: some View {
        VStack(spacing: 12) {
            Text("MagiMDM Parent").font(.title2)
            TextField("Server URL", text: $url).textInputAutocapitalization(.never)
            TextField("Username", text: $user).textInputAutocapitalization(.never)
            SecureField("Password", text: $pass)
            Button("Sign in") {
                Task {
                    do {
                        let api = API(base: url)
                        try await api.login(user: user, password: pass)
                        session.api = api
                    } catch {
                        err = "Login failed"
                    }
                }
            }
            Text(err).foregroundStyle(.red)
        }.padding()
    }
}
