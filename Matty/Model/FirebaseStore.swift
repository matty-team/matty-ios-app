import Foundation
import FirebaseFirestore
import CoreLocation

protocol AnyDataStore {
    func fetchUserInterests(completionHandler: @escaping ([AnyInterestEntity]) -> ())
    func fetchAllInterests(completionHandler: @escaping ([AnyInterestEntity]) -> ())
    func fetchUserEvents(completionHandler: @escaping ([AnyEventEntity]) -> ())
    func add(_ event: Event)
}

class FirebaseStore: AnyDataStore {
    
    static let shared = FirebaseStore()
    
    private let firestore = Firestore.firestore()
    private var allInterests = [InterestEntity]()
    
    private init() { }
    
    func fetchUserInterests(completionHandler: @escaping ([AnyInterestEntity]) -> ()) {
        StubDataStore().fetchUserInterests(completionHandler: completionHandler)
    }
    
    func fetchAllInterests(completionHandler: @escaping ([AnyInterestEntity]) -> ()) {
        firestore.collection(.interests).getDocuments { querySnapshot, error in
            self.allInterests = []
            if let error = error {
                print(error.localizedDescription)
            } else {
                if let querySnapshot = querySnapshot {
                    for document in querySnapshot.documents {
                        if let interest = InterestEntity.from(document) {
                            self.allInterests.append(interest)
                        }
                    }
                }
            }
            completionHandler(self.allInterests)
        }
    }
    
    func fetchUserEvents(completionHandler: @escaping ([AnyEventEntity]) -> ()) {
        StubDataStore().fetchUserEvents(completionHandler: completionHandler)
    }
    
    func add(_ event: Event) {
        firestore.collection(.events).addDocument(data: [
            "name": event.name,
            "description": event.description,
            "details": event.details,
            "interest": ref(event.interest)!,
            "location": event.location?.toGeoPoint() ?? NSNull(),
            "date": event.date ?? NSNull(),
            "public": event.isPublic,
            "withApproval": event.withApproval
        ])
    }
    
    private func ref(_ interest: Interest) -> DocumentReference? {
        allInterests.first { $0.interest == interest }?.ref
    }
}

extension CLLocationCoordinate2D {
    
    func toGeoPoint() -> GeoPoint {
        return GeoPoint(latitude: latitude, longitude: longitude)
    }
}

class StubDataStore: AnyDataStore {
    
    let interests = ["CS:GO", "Hiking", "Adventure", "Swimming", "Cycling", "Documentary", "Coding"].toStubInterestEntities()
    let events = [
        eventEntity(name: "Afternoon Cycling", interest: "Cycling", descLength: 40),
        eventEntity(name: "CS:GO game", interest: "CS:GO", descLength: 80),
        eventEntity(name: "Soccer session", interest: "Soccer", descLength: 160)
    ]
    
    func fetchUserInterests(completionHandler: @escaping ([AnyInterestEntity]) -> ()) {
        completionHandler(Array(interests.prefix(5)))
    }
    
    func fetchAllInterests(completionHandler: @escaping ([AnyInterestEntity]) -> ()) {
        completionHandler(interests)
    }
    
    func fetchUserEvents(completionHandler: @escaping ([AnyEventEntity]) -> ()) {
        completionHandler(events)
    }
    
    func add(_ event: Event) { }
    
    static private func eventEntity(name: String, interest: String, descLength: Int) -> StubEventEntity {
        return StubEventEntity(event: Event(
            name: name,
            description: String.randomText(length: descLength),
            details: "",
            interest: Interest(name: interest),
            location: nil,
            date: .now,
            isPublic: true,
            withApproval: false
        ))
    }
}

extension Array where Element == String {
    
    fileprivate func toStubInterestEntities() -> [StubInterestEntity] {
        var entities = [StubInterestEntity]()
        forEach { name in
            let interest = Interest(name: name)
            entities.append(StubInterestEntity(interest: interest))
        }
        return entities
    }
}

extension InterestEntity {
    
    static func from(_ document: QueryDocumentSnapshot) -> InterestEntity? {
        if let name = document.get("name") as? String {
            let interest = Interest(name: name)
            return InterestEntity(interest: interest, ref: document.reference)
        } else {
            return nil
        }
    }
}

extension FirebaseStore {
    
    enum Collection: String {
        case interests
        case events
    }
}

extension Firestore {
    
    func collection(_ collection: FirebaseStore.Collection) -> CollectionReference {
        self.collection(collection.rawValue)
    }
}

extension String {

    static func randomText(length: Int) -> String {
        var text = ""
        while text.count < length {
            text += "\(randomWord()) "
        }
        return String(text.prefix(length))
    }
    
    static func randomWord() -> String {
        var word = ""
        for _ in 1...Int.random(in: 1...6) {
            if let scalar = UnicodeScalar(Int.random(in: 97...122)) {
                word.append(Character(scalar))
            }
        }
        return word
    }
}
