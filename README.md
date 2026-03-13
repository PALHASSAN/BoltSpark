[![Swift Version](https://img.shields.io/badge/swift-5.9-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Build](https://img.shields.io/github/workflow/status/PALHASSAN/BoltSpark/Build)](https://github.com/PALHASSAN/BoltSpark/actions)
[![Stars](https://img.shields.io/github/stars/PALHASSAN/BoltSpark?style=social)](https://github.com/PALHASSAN/BoltSpark/stargazers)

# ⚡ BoltSpark
BoltSpark is an elegant, macro-driven ORM for Swift that brings a Laravel-inspired developer experience to database management. It streamlines schema definition, relationship mapping, and data querying with an expressive, type-safe API that eliminates unnecessary boilerplate.

## ✨ Features
* **Built-in Validation**: Integrated with LiveValidate for declarative model validation.
* **Direct Model Querying**: Execute database operations directly from your models using static methods like `.where()`, `.find()`, and `.get()`.
* **Declarative Validation**: Real-time data validation integrated directly into models via `@Validate`.
* **Macro-Powered Relationships**: Define complex data connections using property wrappers that generate safe accessors automatically.
* **Fluent Schema Builder**: Programmatically define your database structure with a clean, readable Blueprint API.
* **Advanced Querying**: Support for eager loading, relationship existence checks (`has`), and constrained relationship filtering (`whereHas`).
* **Lifecycle Management**: Built-in support for automatic Timestamps and Soft Deletes.

## 🧩 Built-in Validation (LiveValidate)
BoltSpark ships with built-in integration with **LiveValidate**, a powerful validation library that provides declarative, real-time validation for Swift models.

This means you can define validation rules directly on your model properties using the `@Validate` without needing additional setup.

🔗 **LiveValidate Repository**
https://github.com/PALHASSAN/LiveValidate

### 📦 Installation
Add the package to your project via **Swift Package Manager (SPM)**:
In Xcode: `File > Add Package Dependencies...` and enter this URL in the search bar:

```
https://github.com/PALHASSAN/BoltSpark.git
```

## 🚀 Quick Start
Define a model and start querying your data immediately:

```swift
import BoltSpark

@Model
struct User: Timestamps {
    var id: Int64?
    var name: String = ""
    var email: String = ""
}

// Perform queries directly without calling .query()
let users = try User.where("active", 1).orderBy("name").get()

```

## 🔎 Direct Querying
BoltSpark turns your models into powerful gateways for data interaction. You no longer need to manually initialize a query builder; simply call the static methods on the model itself.

* **Retrieval**: `User.all()`, `User.first()`, or `User.find(id)`.
* **Filtering**: `User.where("role", "admin")` or `User.whereIn("id", [1, 2, 3])`.
* **Aggregates**: `User.count()` or `User.exists()`.
* **Ordering & Limits**: `User.orderBy("created_at", desc: true).limit(10)`.

## ✅ Validation
BoltSpark integrates seamlessly with `LiveValidate` to provide real-time, declarative validation for your model properties.

```swift
@Model
struct User: Timestamps {
    var id: Int64?
    
    @Validate(.name("Full Name"), .required(), .min(3))
    var name: String = ""
    
    @Validate(.required(), .email(), .unique(table: "users", column: "email"))
    var email: String = ""
}

```

> [!NOTE]
> LiveValidate is included by default; no extra setup required.

## 🔗 Relationships
BoltSpark supports a comprehensive suite of relationship types to define how your data connects.

### Example: One-to-Many (@HasMany)
Define a relationship where one model owns multiple children.

```swift
@Model
struct User: Timestamps {
    var id: Int64?
    var name: String = ""
    
    @HasMany(Project.self)
    var projects: [Project]
}

@Model
struct Project: Timestamps {
    var id: Int64?
    var user_id: Int64
    var title: String = ""
}

```

Access related records through a simple property call: `try user.projects`. BoltSpark automatically infers the foreign key based on the parent model's name.

## 🛠 Supported Relationship Types
| Relationship | Description | Example |
| --- | --- | --- |
| **@HasOne** | A direct one-to-one connection. | `@HasOne(Profile.self)` |
| **@HasMany** | A one-to-many connection. | `@HasMany(Project.self)` |
| **@BelongsTo** | The inverse of a HasOne/HasMany. | `@BelongsTo(User.self)` |
| **@BelongsToMany** | Many-to-many via a pivot table. | `@BelongsToMany(Role.self, through: "user_roles")` |
| **@HasManyThrough** | Distant relations via an intermediate model. | `@HasManyThrough(Task.self, through: Project.self)` |
| **@HasOneThrough** | One-to-one via an intermediate model. | `@HasOneThrough(Owner.self, through: Project.self)` |
| **@MorphMany** | Polymorphic one-to-many connection. | `@MorphMany(Comment.self, name: "model")` |
| **@MorphOne** | Polymorphic one-to-one connection. | `@MorphOne(Image.self, name: "model")` |
| **@MorphTo** | Inverse polymorphic connection. | `@MorphTo(Target.self, name: "model")` |

## ⚙️ Advanced Relationship Querying
Leverage related data to refine your searches and optimize performance.

* **Eager Loading**: Load related models in a single batch to avoid N+1 query issues using `.with()`.
```swift
let users = try User.with("projects", "roles").get()

```

* **Existence Checks**: Filter parent models that have (or don't have) specific related records.
```swift
let activeUsers = try User.has("projects").get()
let idleUsers = try User.doesntHave("projects").get()

```

* **Constrained Filtering**: Filter parents based on properties of their children.
```swift
let bigSpenders = try User.whereHas("projects") { query in
    query.where("budget", ">", 50000)
}.get()

```

## 🧩 Full Integrated Example

### 1. Schema Migration

```swift
try Schema.create("users") { table in
    table.id()
    table.string("name")
    table.string("email").unique()
    table.timestamps()
}

try Schema.create("projects") { table in
    table.id()
    table.foreignId("user_id", references: "users")
    table.string("title")
    table.double("budget").defaults(to: 0.0)
    table.timestamps()
    table.softDelete()
}

```

### 2. Implementation

```swift
@Model
struct User: Timestamps {
    var id: Int64?
    var name: String = ""
    @Validate(.required(), .email())
    var email: String = ""
    
    @HasMany(Project.self)
    var projects: [Project]
}

@Model
struct Project: Timestamps, SoftDeletable {
    var id: Int64?
    var user_id: Int64
    var title: String = ""
    var budget: Double = 0.0
}

```

### 3. Usage

```swift
func handleData() async throws {
    // Direct Creation
    let user = try User.create(name: "Alhassan", email: "al@bolt.com")
    
    // Direct Querying with Eager Loading & Pagination
    let pagedData = try User.where("name", "Alhassan")
                           .with("projects")
                           .paginate(page: 1, perPage: 15)
    
    // Soft Deletion
    if let project = try Project.find(1) {
        try project.delete()
        let trashed = try Project.onlyTrashed().get()
        try project.restore()
    }
}

```

## 🧠 Best Practices
* **Direct Access**: Favor static model methods (e.g., `User.where()`) over manual builder calls for cleaner, more readable code.
* **Batch Loading**: Always use `.with()` when you know related data will be accessed to maintain high performance.
* **Standardize Naming**: Stick to standard plural table names to allow BoltSpark to automatically infer relationship keys.
* **Protocol Adoption**: Ensure your structs adopt `Timestamps` or `SoftDeletable` to unlock automatic lifecycle management.

## 📝 Notes
> [!NOTE]
> BoltSpark utilizes `DatabasePool` for auto-initialization, ensuring thread-safe, high-performance concurrent reads across your application.

> [!NOTE]
> Relationship properties are generated as throwing accessors. Always wrap relationship access in `try` to handle potential database fetch errors gracefully.

## 🤝 Contributing
Contributions are welcome! Please submit a pull request or open an issue to suggest improvements or report bugs.

## 📄 License
MIT License. Copyright (c) 2026 Alhassan AlMakki.
