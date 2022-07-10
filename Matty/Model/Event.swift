import CoreLocation
import FirebaseFirestore

struct Event: Hashable, Identifiable {
    let id: String
    let name: String
    let description: String
    let details: String
    let interest: Interest
    let location: Location
    let startDate: Date
    let endDate: Date
    let isPublic: Bool
    let withApproval: Bool
    let creator: User
    var userStatus: UserStatus
    var participants: [User]
}

extension Event {
    
    struct Location: Hashable {
        let name: String
        let address: String
        let coordinates: CLLocationCoordinate2D?
    }
    
    var past: Bool {
        return endDate < .now
    }
    
    var started: Bool {
        return startDate < .now
    }
    
    enum UserStatus {
        case owner, participant, none
    }
}

extension CLLocationCoordinate2D: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
