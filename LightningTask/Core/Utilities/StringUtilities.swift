//
//  StringUtilities.swift
//  LightningTask
//

import Foundation

struct ListNameMatcher {
    let availableListNames: [String]

    func snapToAvailableLists(_ names: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for name in names {
            guard let canonical = match(name) else { continue }
            if seen.insert(canonical).inserted { result.append(canonical) }
        }
        return result
    }

    private func match(_ candidate: String) -> String? {
        if let exact = availableListNames.first(where: { $0 == candidate }) { return exact }
        let lower = candidate.lowercased()
        if let ci = availableListNames.first(where: { $0.lowercased() == lower }) { return ci }
        if let sub = availableListNames.first(where: {
            let a = $0.lowercased(); return a.contains(lower) || lower.contains(a)
        }) { return sub }
        let scored = availableListNames.map { ($0, levenshtein($0.lowercased(), lower)) }
        guard let best = scored.min(by: { $0.1 < $1.1 }) else { return nil }
        return best.1 <= max(2, lower.count / 5) ? best.0 : nil
    }

    private func levenshtein(_ a: String, _ b: String) -> Int {
        let aChars = Array(a), bChars = Array(b)
        if aChars.isEmpty { return bChars.count }
        if bChars.isEmpty { return aChars.count }
        var dp = Array(repeating: Array(repeating: 0, count: bChars.count + 1), count: aChars.count + 1)
        for i in 0...aChars.count { dp[i][0] = i }
        for j in 0...bChars.count { dp[0][j] = j }
        for i in 1...aChars.count {
            for j in 1...bChars.count {
                let cost = aChars[i-1] == bChars[j-1] ? 0 : 1
                dp[i][j] = min(dp[i-1][j] + 1, dp[i][j-1] + 1, dp[i-1][j-1] + cost)
            }
        }
        return dp[aChars.count][bChars.count]
    }
}

struct TokenBasedListMatcher {
    let listTitles: [String]

    func candidateLists(for input: String) -> [String] {
        let inputLower = input.lowercased()
        let separators = CharacterSet(charactersIn: " /-_")
        return listTitles
            .map { title -> (String, Int) in
                let tokens = title.lowercased().components(separatedBy: separators).filter { $0.count > 2 }
                guard !tokens.isEmpty else { return (title, 0) }
                return (title, tokens.filter { inputLower.contains($0) }.count)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.count > $1.0.count }
            .map { $0.0 }
    }
}

struct VerbatimListNameDetector {
    let listTitles: [String]

    func matches(in input: String) -> [String] {
        let lower = input.lowercased()
        return listTitles
            .filter { !$0.isEmpty && lower.contains($0.lowercased()) }
            .sorted { $0.count > $1.count }
    }

    func stripListNames(_ item: String, names: [String]) -> String {
        var result = item
        for name in names {
            for prefix in ["in ", "auf ", "für ", "fuer ", ""] {
                result = result.replacingOccurrences(of: prefix + name, with: "", options: .caseInsensitive)
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
