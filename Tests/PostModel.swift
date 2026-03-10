//
//  PostModel.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

import BoltSpark

@Model
struct PostModel {
    var id: Int64?
    var title: String
    var user_id: Int64
    
    static let author = belongsTo(UserModel.self, foreignKey: "user_id")
}
