import Fluent
import Vapor

struct TodoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("todos")
        todos.get(use: index)
        todos.post(use: create)
        todos.group(":todoID") { todo in
            todo.get(use: show)
            todo.put(use: update)
            todo.delete(use: delete)
        }
    }

    func index(req: Request) async throws -> [Todo] {
        try await Todo.query(on: req.db).all()
    }

    func show(req: Request) async throws -> Todo {
        return try await Todo.find(req.parameters.get("todoID"), on: req.db)
            .unwrap(or: Abort(.notFound)).get()
    }

    func create(req: Request) async throws -> Todo {
        let todo = try req.content.decode(Todo.self)
        try await todo.save(on: req.db)
        return todo
    }

    func update(req: Request) async throws -> Todo {
        guard let id = try await req.parameters.get("todoID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let updateTodo = try req.content.decode(Todo.self)
        let todo = try await Todo.find(req.parameters.get("todoID"), on: req.db)
            .unwrap(or: Abort(.notFound)).get()
        todo.id = id
        todo.title = updateTodo.title
        todo.completed = updateTodo.completed
        try await todo.save(on: req.db)
        return todo
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let todo = try await Todo.find(req.parameters.get("todoID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await todo.delete(on: req.db)
        return .noContent
    }
}
