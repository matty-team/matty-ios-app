import Foundation

@MainActor
class EventFeedViewModel: ObservableObject {
    
    @Published var userEvents = [Event]()
    @Published var relevantEvents = [Event]()
    @Published var selectedEvent: Event?
    @Published var showNewEventScreen = false
    @Published var showEventDetailsScreen = false
    @Published var showEditEventScreen = false
    @Published var showSuggestedInterests = false
    @Published var suggestedInterests = [Interest]()
    @Published var foundEvents = [Event]()
    @Published var searchText = "" {
        didSet {
            searchInterests()
            showSuggestedInterests = searchText.isEmpty ? false : true
        }
    }
    @Published var searchEventsInProgress = false
    
    private let dataStore: AnyDataStore
    private var allInterests = [Interest]()
    
    init(dataStore: AnyDataStore = FirebaseStore.shared) {
        self.dataStore = dataStore
        loadAllInterests()
        loadUserEvents()
        loadRelevantEvents()
    }
    
    var showRelevantEvents: Bool {
        return searchText.isEmpty
    }
    
    var showFoundEvents: Bool {
        return !showRelevantEvents
    }
    
    var noSuggestedInterests: Bool {
        return suggestedInterests.isEmpty
    }
    
    var noFoundEvents: Bool {
        return foundEvents.isEmpty
    }
    
    func addEvent() {
        showNewEventScreen = true
    }
    
    func showEventDetails(for event: Event) {
        selectedEvent = event
        showEventDetailsScreen = true
    }
    
    func closeNewEventScreen() {
        showNewEventScreen = false
    }
    
    func closeEditEventScreen() {
        showEditEventScreen = false
    }
    
    func closeEventDetails() {
        showEventDetailsScreen = false
    }
    
    func onEventDetailsDisappear() {
        selectedEvent = nil
    }
    
    func editEvent() {
        showEditEventScreen = true
    }
    
    func joinEvent() {
        if let selectedEvent = selectedEvent {
            dataStore.join(selectedEvent)
            self.selectedEvent?.userStatus = .participant
            userEvents.append(self.selectedEvent!)
            relevantEvents = relevantEvents.filter { $0 != selectedEvent }
        }
    }
    
    func leaveEvent() {
        if let selectedEvent = selectedEvent {
            dataStore.leave(selectedEvent)
            self.selectedEvent?.userStatus = .none
            userEvents = userEvents.filter { $0 != selectedEvent }
        }
    }
    
    func loadAllInterests() {
        Task {
            allInterests = await dataStore.fetchAllInterests()
        }
    }
    
    func loadUserEvents() {
        Task {
            let events = await dataStore.fetchUserEvents()
            userEvents = events.sorted { $0.date ?? .now < $1.date ?? .now }
            while userEvents.first?.past ?? false {
                let pastEvent = userEvents.removeFirst()
                userEvents.append(pastEvent)
            }
        }
    }
    
    func loadRelevantEvents() {
        Task {
            relevantEvents = await dataStore.fetchRelevantEvents()
        }
    }
    
    func searchEvents(by interest: Interest) {
        searchText = interest.name
        foundEvents = []
        searchEventsInProgress = true
        showSuggestedInterests = false
        Task {
            foundEvents = await dataStore.fetchEvents(by: interest)
            searchEventsInProgress = false
        }
    }
    
    func onNewEventSubmit() {
        loadUserEvents()
        closeNewEventScreen()
    }
    
    func onExistingEventSave(updatedEvent: Event) {
        selectedEvent = updatedEvent
        loadUserEvents()
        closeEditEventScreen()
    }
    
    func onExistingEventDelete() {
        loadUserEvents()
        closeEditEventScreen()
        Task {
            closeEventDetails()
        }
    }
    
    private func searchInterests() {
        suggestedInterests = allInterests.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
}
