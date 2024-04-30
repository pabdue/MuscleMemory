//
//  TaskCell.swift
//

import UIKit

// A cell to display a task
class TaskCell: UITableViewCell {

    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    
    
    // The closure called, passing in the associated task, when the "Complete" button is tapped.
    var onCompleteButtonTapped: ((Task) -> Void)?

    // The task associated with the cell
    var task: Task!

    // The function called when the "Complete" button is tapped.
    // 1. Toggle the isComplete boolean state of the task
    // 2. Update the cell's UI with the current task state
    // 3. Call the `onCompleteButtonTapped` closure, passing in the current task so other view controllers can react to the change in task completed status.
    @IBAction func didTapCompleteButton(_ sender: UIButton) {
        // 1.
        task.isComplete = !task.isComplete
        // 2.
        update(with: task)
        // 3.
        onCompleteButtonTapped?(task)
    }

    // Initial configuration of the task cell
    // 1. Set the main task property
    // 2. Set the onCompleteButtonTapped closure
    // 3. Update the UI for the given task
    func configure(with task: Task, onCompleteButtonTapped: ((Task) -> Void)?) {
        // 1.
        self.task = task
        // 2.
        self.onCompleteButtonTapped = onCompleteButtonTapped
        // 3.
        update(with: task)
    }

    // Update the UI for the given task
    // The complete button's image has already been configured in the storyboard for default and selected states.
    // 1. Set the title and note labels
    // 2. Hide the note label if task.note property is empty. (This just helps the title label align with the completed button when there's no note)
    // 3. Set the text color based on the task completed state
    // 4. Set the "Completed" button's selected state based on the task's completed state.
    // 5. Set the button's tint color based on the task's completed state. (blue if complete, system gray if not)
    private func update(with task: Task) {
        // 1.
        titleLabel.text = task.title
        noteLabel.text = task.note
        // 2.
        noteLabel.isHidden = task.note == "" || task.note == nil
        // 3.
        titleLabel.textColor = task.isComplete ? .secondaryLabel : .label
        // 4.
        completeButton.isSelected = task.isComplete
        // 5.
        completeButton.tintColor = task.isComplete ? .systemBlue : .tertiaryLabel
    }

    // This overrides the table view cell's default selected and highlighted behavior to do nothing, otherwise, the row would darken when tapped
    // This is just a design / UI polish for this particular use case. Since we also have the "Completed" button in the row, it looks kinda weird if the whole cell darkens during selection.
    override func setSelected(_ selected: Bool, animated: Bool) { }
    override func setHighlighted(_ highlighted: Bool, animated: Bool) { }
}
