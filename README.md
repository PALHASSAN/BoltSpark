# BoltSpark

BoltSpark is an elegant, macro-driven ORM for Swift that brings a Laravel-inspired developer experience to database management. It streamlines schema definition, relationship mapping, and data querying with an expressive, type-safe API.

---

## Table of Contents

* [Features](https://www.google.com/search?q=%23features)
* [Installation](https://www.google.com/search?q=%23installation)
* [Quick Start](https://www.google.com/search?q=%23quick-start)
* [Direct Querying](https://www.google.com/search?q=%23direct-querying)
* [Relationships](https://www.google.com/search?q=%23relationships)
* [Example: @HasMany](https://www.google.com/search?q=%23example-hasmany)


* [Querying Relationships](https://www.google.com/search?q=%23querying-relationships)
* [Supported Relationships](https://www.google.com/search?q=%23supported-relationships)
* [Usage Examples](https://www.google.com/search?q=%23usage-examples)
* [Pagination](https://www.google.com/search?q=%23pagination)
* [Soft Deletes & Timestamps](https://www.google.com/search?q=%23soft-deletes--timestamps)
* [Best Practices](https://www.google.com/search?q=%23best-practices)
* [Notes](https://www.google.com/search?q=%23notes)
* [Contributing](https://www.google.com/search?q=%23contributing)
* [License](https://www.google.com/search?q=%23license)

---

## Features

* **Direct Model Querying**: Initiate queries directly from your model classes using static methods like `.where()`, `.find()`, and `.all()`.
* **Macro-Powered Models**: Use the `@Model` macro to inject database logic and relationship accessors with minimal boilerplate.
* **Advanced Relationship Filtering**: Filter records based on the existence or properties of related data using `has` and `whereHas`.
* **Fluent Query Builder**: Construct complex SQL queries through a human-readable, chainable interface.
* **Integrated Pagination**: Easily split large datasets into manageable pages with the built-in `Paginator`.
* **Real-time Validation**: Seamlessly connects with `LiveValidate` for automatic, declarative data validation.

---

## Installation

Add BoltSpark to your project via Swift Package Manager:

```bash
swift-package add BoltSpark

```

---

## Quick Start

Define a model and interact with your database using natural syntax:

```swift
import BoltSpark

@Model
struct User: Timestamps {
    var id: Int64?
    var name: String = ""
    var email: String = ""
}

// Perform queries directly
let users = try User.where("name", "Alhassan").get()

```

---

## Direct Querying

BoltSpark eliminates the need for manual builder initialization. Every model acts as a gateway to the `QueryBuilder`.

* **Filtering**: `User.where("active", 1)`
* **Ordering**: `User.orderBy("created_at", desc: true)`
* **Retrieving**: `User.all()` or `User.get()`
* **Finding**: `User.find(5)`

---

## Relationships

BoltSpark supports robust model relationships to define connections between data entities effortlessly.

### Example: @HasMany

The `@HasMany` macro defines a one-to-many relationship.

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

BoltSpark automatically manages the foreign key mapping (e.g., `user_id`) based on model names.

---

## Querying Relationships

Optimize performance and filter results based on related data:

* **Eager Loading**: Load relationships upfront to avoid N+1 issues using `.with()`.
```swift
let users = try User.with("projects").get()

```


* **Relationship Existence**: Filter records that have at least one related entry.
```swift
let usersWithProjects = try User.has("projects").get()

```


* **Constrained Filtering**: Filter records based on specific conditions in the relationship.
```swift
let busyUsers = try User.whereHas("projects") { query in
    query.where("budget", ">", 10000)
}.get()

```



---

## Supported Relationships

| Relationship | Description | Example |
| --- | --- | --- |
| **@HasOne** | One-to-one connection. | `@HasOne(Profile.self)` |
| **@HasMany** | One-to-many connection. | `@HasMany(Post.self)` |
| **@BelongsTo** | Inverse of a relationship. | `@BelongsTo(User.self)` |
| **@BelongsToMany** | Many-to-many via a pivot table. | `@BelongsToMany(Role.self, through: "pivot")` |
| **@MorphMany** | Polymorphic one-to-many. | `@MorphMany(Comment.self, name: "model")` |

---

## Usage Examples

### CRUD Operations

**Creating Records**

```swift
// Standard Call
User.create(name: "Alhassan", email: "al@bolt.com")

// Safe / Throwable Call
try User.create(name: "Alhassan AlMakki", email: "alhassan@example.com")

```

**Updating Records**

```swift
if var user = try User.find(1) {
    user.name = "Updated Name"
    try user.update()
}

```

---

## Pagination

Retrieve data in chunks to improve application performance:

```swift
let paginatedUsers = try User.where("active", 1).paginate(page: 1, perPage: 15)

print(paginatedUsers.total)        // Total records in DB
print(paginatedUsers.hasMorePages) // Boolean check

```

---

## Soft Deletes & Timestamps

BoltSpark includes built-in support for tracking record lifecycles.

* **Timestamps**: Automatically manages `created_at` and `updated_at`.
* **Soft Deletes**: Records are flagged with `deleted_at` rather than removed from the database.
```swift
// Include deleted items in query
let allUsers = try User.withTrashed().get()

// Restore a deleted item
try user.restore()

```



---

## Best Practices

* **Favor Direct Access**: Use static methods like `User.where()` for cleaner code; avoid manual `query()` calls unless necessary.
* **Eager Load Aggressively**: Always use `.with()` for related properties you plan to display in UI to optimize database roundtrips.
* **Adopt Timestamps**: Use the `Timestamps` protocol for all primary models to maintain a reliable audit trail.
* **Type-Safe Inlines**: Use `.self` in relationship definitions to enable compile-time type checking.

---

## Notes

> **Note**
> BoltSpark automatically handles database initialization and connection pooling. It uses `DatabasePool` to ensure high-performance concurrent reads.

> **Note**
> Relationship accessors are generated as `throwing` properties. Always use `try` when accessing properties like `user.projects`.

---

## Contributing

We welcome contributions! Please submit a pull request or open an issue to suggest improvements or report bugs.

---

## License

MIT License. Copyright (c) 2026 Alhassan AlMakki.
