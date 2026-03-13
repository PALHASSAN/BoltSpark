//
//  TestView.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

import SwiftUI

struct TestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Button(action: creationTest) {
                Text("إنشاء مستخدم جديد")
                    .fontWeight(.bold)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    func creationTest() {
        do {
            let user = try User.firstOrFail()
            
            if let dbPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                print(dbPath.appendingPathComponent("boltspark.sqlite").path)
            }
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - Models
@Model
struct User: Timestamps {
    var id: Int64?
    
    @Validate(.name(""), .required())
    var name: String = ""
    
    @Validate(.required(), .unique(table: "users", column: "email"))
    var email: String = ""
    
    @Validate(.required())
    var role: String = ""
    
    @HasMany(Project.self)
    var projects: [Project]
}

@Model
struct Project: Timestamps, SoftDeletable {
    var id: Int64?
    var user_id: Int64
    var title: String
    var budget: Double
    
    @BelongsTo(User.self)
    var owner: User?
    
//    @HasMany(Task.self)
//    var tasks: [Task]
}

//@Model
//struct Task: Timestamps, SoftDeletable {
//    var id: Int64?
//    var project_id: Int64
//    var description: String
//    var is_completed: Bool
//    var priority: Int // 1 to 5
//    
//    @BelongsTo(Project.self)
//    var project: Project
//}

// MARK: - Migration
func migrateProjectSystem() {
    do {
        try Schema.create("users") { table in
            table.id()
            table.string("name")
            table.string("email").unique()
            table.string("role")
            table.timestamps()
        }

        try Schema.create("projects") { table in
            table.id()
            table.foreignId("user_id", references: "users")
            table.string("title")
            table.double("budget")
            table.timestamps()
            table.softDelete()
        }

        try Schema.create("tasks") { table in
            table.id()
            table.foreignId("project_id", references: "projects")
            table.string("description")
            table.boolean("is_completed").defaults(to: false)
            table.integer("priority").defaults(to: 3)
            table.timestamps()
            table.softDelete()
        }
    } catch {
        print("Migration Failed: \(error)")
    }
}

// MARK: - Migration
func runComplexDemo() async {
    do {
        var manager = try User.create(name: "Alhassan", email: "al@bolt.com", role: "manager")
        
        var boltProject = try Project.create(
            user_id: manager.id!,
            title: "BoltSpark Framework",
            budget: 50000.0
        )
        
//        try Task.create(project_id: boltProject.id!, description: "Fix Macro Crashes", is_completed: true, priority: 5)
//        try Task.create(project_id: boltProject.id!, description: "Write Documentation", is_completed: false, priority: 3)
//        let docTask = try Task.create(project_id: boltProject.id!, description: "Add MySQL Driver", is_completed: false, priority: 4)
//
//        let urgentTasks = try Task.where("is_completed", false)
//                                 .where("priority", ">=", 4)
//                                 .orderBy("priority", desc: true)
//                                 .get()

//        print("🚀 Urgent Tasks count: \(urgentTasks.count)")

        // Soft Delete Simulation
//        try docTask.delete() // Task is now "hidden" but still in DB
        
        // Relationship: Get a User, then their Projects, then only Active Tasks
        if let user = try User.where("role", "manager").first() {
            let projects = try user.projects // Fetched via @HasMany
            
            for project in projects {
                // Get tasks including those that were soft-deleted
//                let allTasks = try Task.withTrashed()
//                                       .where("project_id", project.id!)
//                                       .get()
                
//                print("Project: \(project.title) has \(allTasks.count) total tasks (including deleted).")
            }
        }

    } catch {
        print("Error in Business Logic: \(error)")
    }
}

//@Model
//struct Post: Timestamps, SoftDeletable {
//    var id: Int64?
//    var user_id: Int64
//    var title: String
//    var content: String
//    var isPublished: Bool
//    
//    @BelongsTo(User.self)
//    var author: User?
//}

#Preview {
    TestView()
}
