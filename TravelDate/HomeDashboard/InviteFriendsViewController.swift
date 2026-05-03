


import SwiftUI

struct InviteFriendsView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {

                // Header
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Invite Friends")
                            .foregroundColor(.white)
                            .font(.system(size: 22, weight: .bold))

                        Text("Build your travel crew")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }

                    Spacer()
                }
                .padding(.horizontal)

                // Search Field
                HStack {
                    TextField("Search friends...", text: .constant(""))
                        .foregroundColor(.white)

                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(14)
                .padding(.horizontal)

                // Invite Link Card
                VStack(alignment: .leading, spacing: 14) {

                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.orange)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Share Invite Link")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))

                            Text("Anyone with this link can join your group")
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                        }
                    }

                    HStack {
                        Text("https://travelapp.com/join/bali-crew-...")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                            .lineLimit(1)

                        Spacer()

                        Button {
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color.orange)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .cornerRadius(18)
                .padding(.horizontal)

                // Suggested Friends Header
                HStack {
                    Text("Suggested Friends")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))

                    Spacer()

                    Text("6 friends")
                        .foregroundColor(.gray)
                        .font(.system(size: 13))
                }
                .padding(.horizontal)

                // Friends List
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(0..<6) { _ in
                            HStack {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 45, height: 45)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Sarah Johnson")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .semibold))

                                    Text("@sarahj")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 13))
                                }

                                Spacer()

                                Button {
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "paperplane")
                                        Text("Invite")
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.orange, lineWidth: 1)
                                    )
                                    .foregroundColor(.orange)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(18)
                        }
                    }
                    .padding(.horizontal)
                }

                // Skip Button
                Button {
                } label: {
                    Text("Skip")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(22)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
    }
}

#Preview {
    InviteFriendsView()
}
