//
//  ContentView.swift
//  MSJobMonitor
//
//  Created by Dan Chernopolskii on 9/28/25.
//


import SwiftUI
import Foundation
import Combine
import UserNotifications
import AppKit

struct ContentView: View {
    @EnvironmentObject var jobManager: JobManager
    @State private var sidebarVisible = true
    @State private var windowSize: CGSize = .zero
    
    private var isWindowMinimized: Bool {
        windowSize.width < 800
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar
                if sidebarVisible {
                    SidebarView(sidebarVisible: $sidebarVisible, isWindowMinimized: isWindowMinimized)
                        .frame(width: 200)
                        .transition(.move(edge: .leading))
                }
                
                // Main Content Area
                HStack(spacing: 0) {
                    // Show toggle when sidebar is hidden
                    if !sidebarVisible {
                        VStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    sidebarVisible = true
                                }
                            }) {
                                Image(systemName: "sidebar.left")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .help("Show Sidebar")
                            
                            Spacer()
                        }
                        .padding(.top, 8)
                        .padding(.leading, 8)
                    }
                    
                    // Content based on selected tab
                    VStack(spacing: 0) {
                        if jobManager.selectedTab == "jobs" {
                            JobListView(
                                sidebarVisible: $sidebarVisible,
                                isWindowMinimized: isWindowMinimized
                            )
                        } else {
                            SettingsView()
                        }
                    }
                    
                    // Job Detail Pane (if job selected)
                    if let selectedJob = jobManager.selectedJob {
                        JobDetailPane(job: selectedJob)
                            .frame(width: min(450, geometry.size.width * 0.5))
                            .transition(.move(edge: .trailing))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: jobManager.selectedJob)
            }
            .animation(.easeInOut(duration: 0.3), value: sidebarVisible)
            .onAppear {
                windowSize = geometry.size
                if isWindowMinimized {
                    sidebarVisible = false
                }
            }
            .onChange(of: geometry.size) { newSize in
                let wasMinimized = isWindowMinimized
                windowSize = newSize
                
                // Auto-hide/show sidebar based on window size
                if !wasMinimized && isWindowMinimized && sidebarVisible {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        sidebarVisible = false
                    }
                }
                else if wasMinimized && !isWindowMinimized && !sidebarVisible {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        sidebarVisible = true
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}
