//
//  String.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

extension String {
    public var singularized: String {
        let lower = self.lowercased()
        
        let irregulars = [
            "children": "child",
            "people": "person",
            "men": "man",
            "women": "woman",
            "teeth": "tooth",
            "feet": "foot"
        ]
        
        if let irregular = irregulars[lower] {
            return irregular
        }
        
        if lower.hasSuffix("ies") {
            return String(self.dropLast(3)) + "y"
        }
        
        if lower.hasSuffix("es") && !lower.hasSuffix("ees") {
            return String(self.dropLast(2))
        }
        
        if lower.hasSuffix("s") {
            return String(self.dropLast())
        }
        
        return self
    }
}

extension String {
    func toSnakeCase() -> String {
        return unicodeScalars.reduce("") {
            if CharacterSet.uppercaseLetters.contains($1) {
                return $0 + ($0.isEmpty ? "" : "_") + String($1).lowercased()
            }
            return $0 + String($1)
        }
    }
}
