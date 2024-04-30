//
//  Task.swift
//

import UIKit

// The Task model
struct Task: Codable {

    // The task's title
    var title: String

    // An optional note
    var note: String?
    
    var calories: String?

    // The due date by which the task should be completed
    var dueDate: Date

    // Initialize a new task
    // `note` and `dueDate` properties have default values provided if none are passed into the init by the caller.
    init(title: String, note: String? = nil, calories: String? = nil, dueDate: Date = Date()) {
        self.title = title
        self.note = note
        self.calories = calories
        self.dueDate = dueDate
    }

    // A boolean to determine if the task has been completed. Defaults to `false`
    var isComplete: Bool = false {

        // Any time a task is completed, update the completedDate accordingly.
        didSet {
            if isComplete {
                // The task has just been marked complete, set the completed date to "right now".
                completedDate = Date()
            } else {
                completedDate = nil
            }
        }
    }

    // The date the task was completed
    // private(set) means this property can only be set from within this struct, but read from anywhere (i.e. public)
    private(set) var completedDate: Date?

    // The date the task was created
    // This property is set as the current date whenever the task is initially created.
    var createdDate: Date = Date()

    // An id (Universal Unique Identifier) used to identify a task.
    var id: String = UUID().uuidString
}

// MARK: - Task + UserDefaults
extension Task {
    
    static let tasksKey = "tasks"


    // Given an array of tasks, encodes them to data and saves to UserDefaults.
    static func save(_ tasks: [Task]) {
            let defaults = UserDefaults.standard
            let encodedData = try! JSONEncoder().encode(tasks)
            defaults.set(encodedData, forKey: Task.tasksKey)
           
        }


    // Retrieve an array of saved tasks from UserDefaults.
    static func getTasks() -> [Task] {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Task.tasksKey){
            let tasks = try! JSONDecoder().decode([Task].self, from: data)
            return tasks
        }
        else
        {
            return []
        }
    }

    // Add a new task or update an existing task with the current task.
    func save() {
        var tasks = Task.getTasks()

        // Check if the current task already exists in the tasks array
        if let existingIndex = tasks.firstIndex(where: { $0.id == self.id }) {
            // Remove the existing task from the array
            tasks.remove(at: existingIndex)
            // Insert the updated task in place of the task you removed
            tasks.insert(self, at: existingIndex)
        } else {
            // If no matching task already exists, add the new task to the end of the array
            tasks.append(self)
        }

        // Save the updated tasks array to UserDefaults
        Task.save(tasks)
    }

 }
