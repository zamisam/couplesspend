
//
//  MainTabView.swift
//  Spending
//
//  Created by George Gausden on 2025-07-30.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ExpenseEntryView()
                .tabItem {
                    Label("Add Expense", systemImage: "plus.circle.fill")
                }
            
            SummaryView()
                .tabItem {
                    Label("Summary", systemImage: "chart.pie.fill")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(ExpenseStore())
        .environmentObject(SupabaseService.shared)
}
