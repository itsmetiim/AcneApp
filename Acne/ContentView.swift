//
//  ContentView.swift
//  Acne
//
//  Created by Tim Riedel on 02.01.25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedDate: Date = Date() // Automatically set to today
    @State private var visibleDates: [Date] = []
    @State private var isUpdatingDates = false // Prevent multiple updates simultaneously
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM"
        initializeDates()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .white.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                ScrollViewReader { proxy in
                    VStack {
                        // Capsules Section
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 8) {
                                ForEach(visibleDates, id: \.self) { date in
                                    Capsule()
                                        .fill(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.gray)
                                        .frame(width: (calendar.isDate(date, inSameDayAs: selectedDate) ? 90 : 60), height: (calendar.isDate(date, inSameDayAs: selectedDate) ? 130 : 90))
                                        .id(date)
                                        .overlay(
                                            Text(dateFormatter.string(from: date))
                                                .foregroundColor(.white)
                                                .font(.caption)
                                                .bold()
                                        )
                                        .onTapGesture {
                                            withAnimation {
                                                updateSelectedDate(to: date, proxy: proxy)
                                            }
                                        }
                                        .padding(4)
                                        .onAppear {
                                            handleDateAppearance(date: date)
                                        }
                                }
                            }
                            .padding()
                        }

                        // Timeline Section with Double-Tap Gesture
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 8) { // Static spacing
                                ForEach(visibleDates, id: \.self) { date in
                                    let isToday = calendar.isDate(date, inSameDayAs: Date()) // Check if it's today's date
                                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate) // Check if it's the selected date
                                    let isMajor = calendar.component(.weekday, from: date) == 1 // Major lines for Sundays

                                    Rectangle()
                                        .fill(isToday ? Color.white : (isSelected ? Color.blue : Color.gray)) // Today's date is white
                                        .frame(width: 2, height: isMajor ? 40 : 20)
                                        .shadow(color: isToday ? Color.white : Color.clear, radius: 10) // Add glowing effect for today
                                        .onTapGesture {
                                            withAnimation {
                                                updateSelectedDate(to: date, proxy: proxy)
                                            }
                                        }
                                }
                            }
                            .padding()
                            .gesture(
                                TapGesture(count: 2)
                                    .onEnded {
                                        withAnimation {
                                            centerTimelineToToday(proxy: proxy)
                                        }
                                    }
                            )
                        }
                    }
                    .onAppear {
                        // Initialize visible dates and scroll to today on app launch
                        initializeDates()
                        DispatchQueue.main.async {
                            withAnimation {
                                selectToday(proxy: proxy) // Automate the "Today" selection
                            }
                        }
                    }

                    Spacer()

                    // Button Section
                    HStack {
                        Button(action: { print("Add Product") }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .frame(width: 170, height: 70)
                                    .foregroundColor(.white)

                                Text("+  Add Product")
                                    .foregroundColor(.black)
                            }
                        }

                        Spacer()
                            .frame(width: 65)

                        Button(action: { print("HelloWorld") }) {
                            ZStack {
                                Circle()
                                    .frame(width: 70)
                                    .foregroundColor(.white)
                                Image(systemName: "book.fill")
                                    .foregroundColor(.black)
                                    .scaleEffect(1.5)
                            }
                        }

                        Spacer()
                            .frame(width: 65)

                        Button(action: {
                            withAnimation {
                                selectToday(proxy: proxy)
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .frame(width: 170, height: 70)
                                    .foregroundColor(.blue)

                                Text("Today")
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Date Management

    /// Initializes visible dates around the current date.
    private func initializeDates() {
        let today = calendar.startOfDay(for: Date()) // Normalize to start of the day
        let pastDays = -7 // Load 1 week into the past
        let futureDays = 35 // Load 5 weeks into the future for better centering
        visibleDates = (pastDays...futureDays).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

    /// Handles the appearance of a date and triggers updates if near the edges.
    private func handleDateAppearance(date: Date) {
        guard !isUpdatingDates else { return } // Prevent overlapping updates

        if let firstDate = visibleDates.first, date == firstDate {
            // Load earlier dates
            isUpdatingDates = true
            let newDates = (-10..<0).compactMap { calendar.date(byAdding: .day, value: $0, to: firstDate) }
            DispatchQueue.main.async {
                visibleDates.insert(contentsOf: newDates, at: 0)
                isUpdatingDates = false
            }
        } else if let lastDate = visibleDates.last, date == lastDate {
            // Load later dates
            isUpdatingDates = true
            let newDates = (1...10).compactMap { calendar.date(byAdding: .day, value: $0, to: lastDate) }
            DispatchQueue.main.async {
                visibleDates.append(contentsOf: newDates)
                isUpdatingDates = false
            }
        }
    }

    /// Updates the selected date and scrolls to it
    private func updateSelectedDate(to date: Date, proxy: ScrollViewProxy) {
        selectedDate = date
        proxy.scrollTo(date, anchor: .center)
    }

    /// Selects today's date and scrolls to it
    private func selectToday(proxy: ScrollViewProxy) {
        let today = calendar.startOfDay(for: Date()) // Normalize to start of the day
        if let matchingDate = visibleDates.first(where: { calendar.isDate($0, inSameDayAs: today) }) {
            updateSelectedDate(to: matchingDate, proxy: proxy)
        }
    }

    /// Centers the timeline's white-highlighted line (today) in the middle of the screen
    private func centerTimelineToToday(proxy: ScrollViewProxy) {
        let today = calendar.startOfDay(for: Date())
        if let matchingDate = visibleDates.first(where: { calendar.isDate($0, inSameDayAs: today) }) {
            proxy.scrollTo(matchingDate, anchor: .center)
        }
    }
}

