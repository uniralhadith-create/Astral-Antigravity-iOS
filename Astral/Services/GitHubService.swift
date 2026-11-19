import Foundation

struct GitHubRepo: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let full_name: String
    let default_branch: String
    let html_url: String
}

final class GitHubService {
    func fetchRepositories(token: String) async throws -> [GitHubRepo] {
        guard !token.isEmpty, let url = URL(string: "https://api.github.com/user/repos?sort=updated&per_page=30") else {
            return []
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([GitHubRepo].self, from: data)
    }

    func createPullRequest(token: String, repoFullName: String, title: String, head: String, base: String, body: String) async throws -> String {
        guard let url = URL(string: "https://api.github.com/repos/\(repoFullName)/pulls") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "title": title,
            "head": head,
            "base": base,
            "body": body
        ])

        let (data, _) = try await URLSession.shared.data(for: request)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let htmlUrl = json["html_url"] as? String {
            return htmlUrl
        }
        throw NSError(domain: "GitHubService", code: -1, userInfo: [NSLocalizedDescriptionKey: "تعذر إنشاء Pull Request"])
    }
}
