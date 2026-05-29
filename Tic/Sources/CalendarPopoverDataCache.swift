import Foundation

struct CalendarPopoverDataCache {
    private struct MonthSlotsKey: Hashable {
        let year: Int
        let month: Int
        let showSolarTerms: Bool

        init(month date: Date, showSolarTerms: Bool, calendar: Calendar) {
            let components = calendar.dateComponents([.year, .month], from: date)
            self.year = components.year ?? 0
            self.month = components.month ?? 0
            self.showSolarTerms = showSolarTerms
        }
    }

    private struct UpcomingEventsKey: Hashable {
        let year: Int
        let month: Int
        let day: Int
        let includeSolarTerms: Bool
        let limit: Int

        init(date: Date, limit: Int, includeSolarTerms: Bool, calendar: Calendar) {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            self.year = components.year ?? 0
            self.month = components.month ?? 0
            self.day = components.day ?? 0
            self.includeSolarTerms = includeSolarTerms
            self.limit = limit
        }
    }

    private var monthSlotsByKey: [MonthSlotsKey: [CalendarMonthSlot]] = [:]
    private var monthSlotsOrder: [MonthSlotsKey] = []
    private var upcomingEventsByKey: [UpcomingEventsKey: [CalendarUpcomingEvent]] = [:]
    private var upcomingEventsOrder: [UpcomingEventsKey] = []

    mutating func monthSlots(
        for month: Date,
        showSolarTerms: Bool,
        calendar: Calendar
    ) -> [CalendarMonthSlot] {
        let key = MonthSlotsKey(month: month, showSolarTerms: showSolarTerms, calendar: calendar)
        if let cached = monthSlotsByKey[key] {
            touch(key, in: &monthSlotsOrder)
            return cached
        }

        let slots = ChineseCalendarSupport.monthSlots(for: month, showSolarTerms: showSolarTerms)
        monthSlotsByKey[key] = slots
        remember(key, in: &monthSlotsOrder, cache: &monthSlotsByKey, limit: 18)
        return slots
    }

    mutating func upcomingEvents(
        from date: Date,
        limit: Int,
        includeSolarTerms: Bool,
        calendar: Calendar
    ) -> [CalendarUpcomingEvent] {
        let key = UpcomingEventsKey(
            date: calendar.startOfDay(for: date),
            limit: limit,
            includeSolarTerms: includeSolarTerms,
            calendar: calendar
        )
        if let cached = upcomingEventsByKey[key] {
            touch(key, in: &upcomingEventsOrder)
            return cached
        }

        let events = ChineseCalendarSupport.upcomingEvents(
            from: date,
            limit: limit,
            includeSolarTerms: includeSolarTerms
        )
        upcomingEventsByKey[key] = events
        remember(key, in: &upcomingEventsOrder, cache: &upcomingEventsByKey, limit: 90)
        return events
    }

    private func touch<Key: Hashable>(_ key: Key, in order: inout [Key]) {
        order.removeAll { $0 == key }
        order.append(key)
    }

    private func remember<Key: Hashable, Value>(
        _ key: Key,
        in order: inout [Key],
        cache: inout [Key: Value],
        limit: Int
    ) {
        touch(key, in: &order)
        while order.count > limit, let staleKey = order.first {
            order.removeFirst()
            cache.removeValue(forKey: staleKey)
        }
    }
}
