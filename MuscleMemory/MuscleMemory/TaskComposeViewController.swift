//
//  TaskComposeViewController.swift
//

import UIKit

class TaskComposeViewController: UIViewController {

    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var noteField: UITextField!
    @IBOutlet weak var caloriesField: UITextField!
    
    // A UI element that allows users to pick a date.
    @IBOutlet weak var datePicker: UIDatePicker!

    // The optional task to edit.
    // If a task is present we're in "Edit Task" mode
    // Otherwise we're in "New Task" mode
    var taskToEdit: Task?

    // When a new task is created (or an existing task is edited), this closure is called
    // passing in the task as an argument so it can be used by whoever presented the TaskComposeViewController.
    var onComposeTask: ((Task) -> Void)? = nil

    // When the view loads, do initial setup for the view controller.
    // 1. If a task was passed in to edit, set all the fields with the "task to edit" properties.
    // 2. Set the title to "Edit Task" in this case.
    //     - `self.title` refers to the title of the view controller and will appear in the navigation bar title.
    //     - The default navigation bar title for this screen has been set in storyboard (i.e. "New Task")
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1.
        if let task = taskToEdit {
            titleField.text = task.title
            noteField.text = task.note
            caloriesField.text = task.calories
            datePicker.date = task.dueDate

            // 2.
            self.title = "Workout Details"
        }
    }

    // The function called when the "Done" button is tapped.
    // 1. Make sure we have non-nil text and the text isn't empty.
    //    i. If it's nil or empty, present an alert prompting the user to enter a title.
    //    ii. Exit the funtion (i.e. return).
    // 2. Create a variable to hold the created or edited task
    // 3. If a "task to edit" is present, we're editing an existing task...
    //    i. Set the task variable as the "task to edit".
    //    ii. Update the task's properties based on the current values of the text and date fields.
    // 4. If NO "task to edit" is present, we're creating a new task. Set the task variable with a newly created task.
    // 5. Call the "onComposeTask" closure passing in the new or edited task.
    // 6. Dismiss the TaskComposeViewController.
    @IBAction func didTapDoneButton(_ sender: Any) {
        // 1.
        guard let title = titleField.text,
              !title.isEmpty
        else {
            // i.
            presentAlert(title: "Oops...", message: "Make sure to add a title!")
            // ii.
            return
        }
        // 2.
        var task: Task
        // 3.
        if let editTask = taskToEdit {
            // i.
            task = editTask
            // ii.
            task.title = title
            task.note = noteField.text
            task.calories = caloriesField.text
            task.dueDate = datePicker.date
        } else {
            // 4.
            task = Task(title: title,
                        note: noteField.text,
                        calories: caloriesField.text,
                        dueDate: datePicker.date)
        }
        // 5.
        onComposeTask?(task)
        // 6.
        dismiss(animated: true)
    }

    // The cancel button was tapped.
    @IBAction func didTapCancelButton(_ sender: Any) {
        // Dismiss the TaskComposeViewController.
        dismiss(animated: true)
    }

    // A helper method to present an alert given a title and message.
    // 1. Create an Alert Controller instance with, title, message and alert style.
    // 2. Create an Alert Action (i.e. an alert button)
    //    - You could add an action (i.e. closure) to be called when the user taps the associated button.
    // 3. Add the action to the alert controller
    // 4. Present the alert
    private func presentAlert(title: String, message: String) {
        // 1.
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        // 2.
        let okAction = UIAlertAction(title: "OK", style: .default)
        // 3.
        alertController.addAction(okAction)
        // 4.
        present(alertController, animated: true)
    }
}
