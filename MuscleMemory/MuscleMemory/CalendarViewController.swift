//
//  CalendarViewController.swift
//

import UIKit

class CalendarViewController: UIViewController {

    // The array of all tasks to display in the calendar.
    var tasks: [Task] = []

    // The tasks who's due dates match the current selected calendar date.
    private var selectedTasks: [Task] = []

    private var calendarView: UICalendarView!

    @IBOutlet private weak var calendarContainerView: UIView!
    @IBOutlet private weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: - Setup the Table View
        // 1. Set table view data source. Needed for standard table view setup:
        //    - tableView(numberOfRowsInSection:) -> How many rows to display
        //    - tableView(cellForRowAt:) -> Create and configure a cell for each row
        // 2. Hide the top cell separator. (Just a UI design choice for this case)
        // 3. Inform the view controller what the main scroll view is, in this case it's the table view.
        //    - The view controller will make sure the table view has the correct content insets to clear navigation and tab bars.
        //    - It will also make the otherwise clear nav and tab bars opaque when content scrolls behind it.
        //    - Typically, it isn't necessary to set this explicitly, but it can be sometimes when the table view is not a top level UI element in the view hierarchy. In this case, it's in a stack view below the calendar view and without this set, the tab bar wasn't adjusting to scrolling content as expected.
        // ------

        // 1.
        tableView.dataSource = self
        // 2.
        tableView.tableHeaderView = UIView()
        // 3.
        setContentScrollView(tableView)

        // MARK: - Create and add Calendar View to view hierarchy
        // For whatever reason, the UICalendarView can't be added via storyboard. so we'll need to create it, add it to the view heirarchy and setup auto layout constraints programmatically.
        // 1. Create a calendar view and assign it to our view controller's associated property.
        // 2. Set `translatesAutoresizingMaskIntoConstraints` false since we'll be using autolayout.
        //    - ⚠️ This is necessary anytime you add programatic autolayout constraints.
        // 3. Add the calendar view to the view hierarchy. In this case, as a subview of the calendar container view.
        // 4. Create and activate auto layout constraints pinning the calendar view to the calendar container view on all sides.
        // ------

        // 1.
        self.calendarView = UICalendarView()
        // 2.
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        // 3.
        calendarContainerView.addSubview(calendarView)
        // 4.
        NSLayoutConstraint.activate([
            calendarView.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor),
            calendarView.topAnchor.constraint(equalTo: calendarContainerView.topAnchor),
            calendarView.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor)
        ])

        // MARK: - Setup the Calendar View
        // 1. Set the delegate for the calendar view
        //    - Needed for the `calendarView(_:decorationFor:)` delegate method to set a decoration for a given calendar date.
        // 2. Set the delegate for the calendar view's single date selection behavior.
        //    - Needed for the `dateSelection(_:didSelectDate:)` delegate method to react to a user selecting a given calendar date.
        // ------

        // 1.
        calendarView.delegate = self
        // 2.
        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = dateSelection

        // MARK: - Set initial calendar selection
        // If there are tasks for today's date, then select today's date on the calendar.
        // 1. Get and update the saved tasks array.
        // 2. Get the date components that represent today's date.
        //    - Calendar View works mostly with DateComponents instead of Date, but we can easily convert back and fourth as needed.
        // 3. Use our filterTasks(for dateComponents:) helper method to filter the tasks array down to only tasks with a due date of today (if any exist).
        // 4. If there are any tasks with today as the due date...
        //    i. Get the calendar's selection property (we need to cast to the specific type of selection, i.e. UICalendarSelectionSingleDate)
        //    ii. Set the calendar's selected date by calling the setSelected(_:animated:) method and passing in the date components for today.
        // ---

        // 1.
        tasks = Task.getTasks()
        // 2.
        let todayComponents = Calendar.current.dateComponents([.year, .month, .weekOfMonth, .day], from: Date())
        // 3.
        let todayTasks = filterTasks(for: todayComponents)
        // 4.
        if !todayTasks.isEmpty {
            // i.
            let selection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate
            // ii.
            selection?.setSelected(todayComponents, animated: false)
        }
    }

    // Refresh tasks anytime the view appears in case updates to any tasks were made on another tab.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshTasks()
    }

    // MARK: - Helper Functions

    // A helper method to filter an array of tasks down to only the tasks which have a due date that matches the given date components.
    // 1. Get the user's current calendar.
    // 2. Use the calendar's `date(from:)` method to convert the given DateComponents to a Date.
    //    - The reason for the conversion is so we can compare with our tasks due dates, which use the Date data type.
    // 3. Filter the main tasks array to only tasks who's due date matches the given date.
    //    i. Use the calendar's isDate(_:equalTo:toGranularity) method to see if a given task's due date matches the date we want to filter on. Setting granularity to `day` matches any date within the same day, regardless of the specific time.
    // 4. return the filtered tasks array
    private func filterTasks(for dateComponents: DateComponents) -> [Task] {
        // 1.
        let calendar = Calendar.current
        // 2.
        guard let date = calendar.date(from: dateComponents) else {
            return []
        }
        // 3.
        let tasksMatchingDate = tasks.filter { task in
            // i.
            return calendar.isDate(task.dueDate, equalTo: date, toGranularity: .day)
        }
        // 4.
        return tasksMatchingDate
    }

    // Refresh the main tasks and update the calendar view and table view.
    // 1. Refresh the main tasks array with the current saved tasks.
    // 2. Apply the same sorting logic used in the TaskListViewController table view.
    // 3. Update the selected tasks array for the current selected calendar date.
    // 4. Create an array of the task due dates by mapping each task to it's due date property.
    // 5. Create an array of DateComponents from the due dates array.
    // 6. Remove any duplicate date components. There will be multiple date components if there are multiple tasks with the same due date.
    //    - ⚠️ We'll use these date components to reload the calendar view and it expects all dates to be unique or else...crash 💥
    // 7. Reload the calendar view's date decorations for all of the task due date components.
    // 8. Reload the table view with animation.
    private func refreshTasks() {
        // 1.
        tasks = Task.getTasks()
        // 2.
        tasks.sort { lhs, rhs in
            if lhs.isComplete && rhs.isComplete {
                return lhs.completedDate! < rhs.completedDate!
            } else if !lhs.isComplete && !rhs.isComplete {
                return lhs.createdDate < rhs.createdDate
            } else {
                return !lhs.isComplete && rhs.isComplete
            }
        }
        // 3.
        if let selection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate,
            let selectedComponents = selection.selectedDate {

            selectedTasks = filterTasks(for: selectedComponents)
        }
        // 4.
        let taskDueDates = tasks.map(\.dueDate)
        // 5.
        var taskDueDateComponents = taskDueDates.map { dueDate in
            Calendar.current.dateComponents([.year, .month, .weekOfMonth, .day], from: dueDate)
        }
        // 6.
        taskDueDateComponents.removeDuplicates()
        // 7.
        calendarView.reloadDecorations(forDateComponents: taskDueDateComponents, animated: false)
        // 8.
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}

// MARK: - Calendar Delegate Methods
extension CalendarViewController: UICalendarViewDelegate {

    // Configure the decorations for each calendar date.
    // Similar to how the table view's cellForRowAt datasource method allows us to create, configure and return a cell for each row of the table view, the `calendarView(_:decorationFor:)` delegate method of the calendar view allows for creating, configuring and returning a "decoration" to be shown (or not shown) for all dates displayed by the calendar.
    // In our case, we'll add a decoration for any date that matches one or more tasks due dates
    // If all of the tasks for that date are completed, we'll show a filled in circle to indicate all tasks are complete.
    // If there are incomplete tasks for a given date, we'll show an empty circle to indicate NOT all tasks are complete.
    // If there are no tasks for a date, we won't add any decoration.

    // 1. Filter tasks down to only tasks matching the date we're currently configuring decorations for.
    //    - (i.e. the dateComponents provided by the delegate method).
    // 2. Check if any of the tasks are incomplete.
    // 3. If there are one or more tasks for the given date....
    //    i. Create an image based on the task's completion status.
    //    ii. Use the image created above to create and return a `Decoration` of type, `.image`
    //    iii. If there are no tasks due on the given date, return nil so there is no decoration shown for the date.
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        // 1.
        let tasksMatchingDate = filterTasks(for: dateComponents)
        // 2.
        let hasUncompletedTask = tasksMatchingDate.contains { task in
            return !task.isComplete
        }
        // 3.
        if !tasksMatchingDate.isEmpty {
            // i.
            let image = UIImage(systemName: hasUncompletedTask ? "circle" : "circle.inset.filled")
            // ii.
            return .image(image, color: .systemBlue, size: .large)
        } else {
            // iii.
            return nil
        }
    }
}

// MARK: - Calendar Selection Delegate Methods
extension CalendarViewController: UICalendarSelectionSingleDateDelegate {

    // Similar to the `tableView(_:didSelectRowAt:)` delegate method, the Calendar View's `dateSelection(_:didSelectDate:)` delegate method is called whenever a user selects a date on the calendar.
    // 1. Unwrap the optional date components for the selected date.
    // 2. Update selectedTasks by filtering all tasks for the selected date.
    // 3. If there are no tasks associated with the selected date, deselect the date by setting the selection to nil
    // 4. Otherwise, if there are associated tasks for the date, reload the table view of selected tasks.
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        // 1.
        guard let components = dateComponents else { return }
        // 2.
        selectedTasks = filterTasks(for: components)
        // 3.
        if selectedTasks.isEmpty {
            selection.setSelected(nil, animated: true)
        }
        // 4.
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}

// MARK: - Table View Datasource Methods
extension CalendarViewController: UITableViewDataSource {

    // The number of rows to show based on the number of selected tasks (i.e. tasks associated with the current selected date)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedTasks.count
    }

    // Create and configure a cell for each row of the table view (i.e. each task in the selectedTasks array)
    // 1. Dequeue a Task cell.
    // 2. Get the selected task associated with the current row.
    // 3. Configure the cell with the selected task and add the code to be run when the complete button is tapped...
    //    i. Save the task passed back in the closure.
    //    ii. Refresh the tasks list to reflect the updates with the saved task.
    // 4. Return the configured cell.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 1.
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        // 2.
        let task = selectedTasks[indexPath.row]
        // 3.
        cell.configure(with: task) { [weak self] task in
            // 1.
            task.save()
            // ii.
            self?.refreshTasks()
        }
        // 4.
        return cell
    }
}

extension Array where Element: Equatable, Element: Hashable {

    // A helper method to remove any duplicate values from an array.
    // 1. Initialize a set with the given array
    //    - Sets guarantee that all values are unique, so any duplicates are removed.
    //    - This method is an array instance method so `self` references the array instance on which the method is being called.
    // 2. Initialize an array from the set to arrive at an array with no duplicate values.
    mutating func removeDuplicates() {
        // 1.
        let set = Set(self)
        // 2.
        self = Array(set)
    }
}
