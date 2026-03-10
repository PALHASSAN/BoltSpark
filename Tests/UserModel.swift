//
//  UserModel.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

import BoltSpark

@Model
struct UserModel {
    var id: Int64?
    var fullName: String
    var email: String
    var password: String
    
    static let posts = hasMany(PostModel.self, foreignKey: "user_id")
}
