import Foundation

class UserInterestsSelection: ObservableObject {
    
    @Published var interests = [SelectableInterest]()
    
    var noInterests: Bool {
        return interests.isEmpty
    }
    
    init(dataStore: AnyDataStore = FirebaseStore.shared) {
        dataStore.fetchAllInterests { entities in
            self.interests = entities.map { SelectableInterest(value: $0.interest) }
        }
    }
}
