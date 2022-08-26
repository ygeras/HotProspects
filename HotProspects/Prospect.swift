//
//  Prospect.swift
//  HotProspects
//
//  Created by Yuri Gerasimchuk on 12.07.2022.
//

import SwiftUI

class Prospect: Identifiable, Codable, Equatable {

    var id = UUID()
    var name = "Anonymus"
    var emailAddress = ""
    var dateCreated = Date.now
    fileprivate(set) var isContacted = false
    
    static func == (lhs: Prospect, rhs: Prospect) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor class Prospects: ObservableObject {
    @Published private(set) var people: [Prospect]
    /*
    // For use with UserDefaults:
    let saveKey = "SavedData"
     */
    
    let savePath = FileManager.documentsDirectory.appendingPathComponent("SavedProspects")
    
    init() {
        /*
        // For use with UserDefaults:
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data) {
                people = decoded
                return
            }
        }
        self.people = []
         */
        
        // Get data from disk
        do {
            let data = try Data(contentsOf: savePath)
            let decoder = JSONDecoder()
            people = try decoder.decode([Prospect].self, from: data)
        } catch {
            people = []
        }
    }
    
    private func save() {
        /*
        // For use with UserDefaults:
        if let encoded = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
         */
        
        // Save data to disk
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(people)
            try data.write(
                to: savePath,
                options: [.atomic, .completeFileProtection])
        } catch {
            print("Unable to save data: \(error.localizedDescription)")
        }
    }
    
    func add(_ prospect: Prospect) {
        people.append(prospect)
        save()
    }
    
    func toggle(_ prospect: Prospect) {
        objectWillChange.send()
        prospect.isContacted.toggle()
        save()
    }
    
    // To be used in swipe action modifier
    func delete(_ prospect: Prospect) {
        if let index = people.firstIndex(of: prospect) {
            people.remove(at: index)
            save()
        }
    }
    
    /* This to be used with onDelete modifier
    func removeItems(at offsets: IndexSet) {
        var objectsToDelete = IndexSet()
        
        for offset in offsets {
            let item = people[offset]
            
            if let index = people.firstIndex(of: item) {
                objectsToDelete.insert(index)
            }
        }
        people.remove(atOffsets: objectsToDelete)
        save()
    }
    */
}
