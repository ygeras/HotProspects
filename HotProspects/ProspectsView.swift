//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Yuri Gerasimchuk on 12.07.2022.
//

import CodeScanner
import SwiftUI
import UserNotifications

struct ProspectsView: View {
    enum FilterType {
        case none, contacted, uncontacted
    }
    
    enum SortMethod {
        case name, recent
    }
    
    @EnvironmentObject var prospects: Prospects
    @State private var isShowingScanner = false
    @State private var isShowingConfirmationDialog = false
    @State private var sortMethod = SortMethod.name
    
    let filter: FilterType
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }
    
    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter { $0.isContacted }
        case .uncontacted:
            return prospects.people.filter { !$0.isContacted }
        }
    }
    
    var sortedProspects: [Prospect] {
        switch sortMethod {
        case .name:
            return filteredProspects.sorted { $0.name < $1.name }
        case .recent:
            return filteredProspects.sorted { $0.dateCreated > $1.dateCreated }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedProspects) { prospect in
                    VStack {
                        HStack {
                            if filter == .none {
                                if prospect.isContacted {
                                    Image(systemName: "person.crop.circle.badge.checkmark")
                                        .foregroundColor(Color.green)
                                } else {
                                    Image(systemName: "person.crop.circle.badge.xmark")
                                        .foregroundColor(Color.red)
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                Text(prospect.name)
                                    .font(.headline)
                                Text(prospect.emailAddress)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        // Delete button
                        Button(role: .destructive) {
                            withAnimation {
                                prospects.delete(prospect)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        if prospect.isContacted {
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Uncontacted", systemImage: "person.crop.circle.badge.xmark")
                            }
                            .tint(.blue)
                        } else {
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark")
                            }
                            .tint(.green)

                            Button {
                                addNotification(for: prospect)
                            } label: {
                                Label("Remind Me", systemImage: "bell")
                            }
                            .tint(.orange)
                        }

                    }
                }
//                .onDelete { offsets in
//                    prospects.removeItems(at: offsets)
//                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Sort button
                    Button {
                        isShowingConfirmationDialog = true
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down.square")
                    }
                    .confirmationDialog(
                        "Sort by",
                        isPresented: $isShowingConfirmationDialog,
                        titleVisibility: .visible
                    ) {
                        Button("By name") { sortMethod = .name }
                        Button("By most recent") { sortMethod = .recent }
                    }
                    
                    // Scan button
                    Button {
                        isShowingScanner = true
                    } label: {
                        Label("Scan", systemImage: "qrcode.viewfinder")
                    }
                }

            }
            .sheet(isPresented: $isShowingScanner) {
                let john = "John Johnson\njohnjohnson@gmail.com"
                let bill = "Bill Burns\nbill.burns@gmail.com"
                let paul = "Paul Hudson\npaul@hackingwithswift.com"
                let smith = "Jonh Smith\njsmith@gmail.com"
                
                let simulatedData = [john, bill, paul, smith].randomElement() ?? ""

                CodeScannerView(
                    codeTypes: [.qr],
                    simulatedData: simulatedData,
                    completion: handleScan
                )
            }
        }
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            
            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            prospects.add(person)
        case .failure(let error):
            print("Scanning failed :\(error.localizedDescription)")
        }
    }
    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default
            
            var dateComponents = DateComponents()
            dateComponents.hour = 9
            
            //            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else {
                        print("D'oh")
                    }
                }
            }
        }
    }
    
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
            .environmentObject(Prospects())
    }
}
