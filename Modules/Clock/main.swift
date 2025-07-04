//
//  main.swift
//  Clock
//
//  Created by Serhiy Mytrovtsiy on 23/03/2023
//  Using Swift 5.0
//  Running on macOS 13.2
//
//  Copyright © 2023 Serhiy Mytrovtsiy. All rights reserved.
//

import Foundation
import Kit

public struct Clock_t: Codable {
    public var id: String = UUID().uuidString
    public var enabled: Bool = true
    
    public var name: String
    public var format: String
    public var tz: String
    
    public var value: Date? = nil
    
    var popupIndex: Int {
        get {
            Store.shared.int(key: "clock_\(self.id)_popupIndex", defaultValue: -1)
        }
        set {
            Store.shared.set(key: "clock_\(self.id)_popupIndex", value: newValue)
        }
    }
    var popupState: Bool {
        get {
            Store.shared.bool(key: "clock_\(self.id)_popupState", defaultValue: true)
        }
        set {
            Store.shared.set(key: "clock_\(self.id)_popupState", value: newValue)
        }
    }
    
    public func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = self.format
        formatter.timeZone = TimeZone(from: self.tz)
        return formatter.string(from: self.value ?? Date())
    }
}

internal class ClockReader: Reader<Date> {
    public override func read() {
        self.callback(Date())
    }
}

public class Clock: Module {
    private let popupView: Popup = Popup(.clock)
    private let portalView: Portal
    private let settingsView: Settings = Settings(.clock)
    
    private var reader: ClockReader?
    
    static var list: [Clock_t] {
        if let objects = Store.shared.data(key: "\(ModuleType.clock.stringValue)_list") {
            let decoder = JSONDecoder()
            if let objectsDecoded = try? decoder.decode(Array.self, from: objects) as [Clock_t] {
                return objectsDecoded
            }
        }
        return [Clock.local]
    }
    
    public init() {
        self.portalView = Portal(.clock, list: Clock.list)
        
        super.init(
            moduleType: .clock,
            popup: self.popupView,
            settings: self.settingsView,
            portal: self.portalView
        )
        guard self.available else { return }
        
        self.reader = ClockReader(.clock) { [weak self] value in
            self?.callback(value)
        }
        
        self.setReaders([self.reader])
    }
    
    private func callback(_ value: Date?) {
        guard let value else { return }
        
        var clocks: [Clock_t] = Clock.list
        var widgetList: [Stack_t] = []
        
        for (i, c) in clocks.enumerated() {
            clocks[i].value = value
            if c.enabled {
                widgetList.append(Stack_t(key: c.name, value: clocks[i].formatted()))
            }
        }
        
        DispatchQueue.main.async(execute: {
            self.popupView.callback(clocks)
            self.portalView.callback(clocks)
        })
        
        self.menuBar.widgets.filter{ $0.isActive }.forEach { (w: SWidget) in
            switch w.item {
            case let widget as StackWidget: widget.setValues(widgetList)
            default: break
            }
        }
    }
}

extension Clock {
    static let localID: String = UUID().uuidString
    static var local: Clock_t {
        Clock_t(id: Clock.localID, name: localizedString("Local time"), format: "yyyy-MM-dd HH:mm:ss", tz: "local")
    }
    static var zones: [KeyValue_t] {
        [
            KeyValue_t(key: "local", value: "Local"),
            KeyValue_t(key: "separator", value: "separator"),
            KeyValue_t(key: "-12", value: "UTC-12:00"),
            KeyValue_t(key: "-11", value: "UTC-11:00"),
            KeyValue_t(key: "-10", value: "UTC-10:00"),
            KeyValue_t(key: "-9", value: "UTC-9:00"),
            KeyValue_t(key: "-8", value: "UTC-8:00"),
            KeyValue_t(key: "-7", value: "UTC-7:00"),
            KeyValue_t(key: "-6", value: "UTC-6:00"),
            KeyValue_t(key: "-5", value: "UTC-5:00"),
            KeyValue_t(key: "-4:30", value: "UTC-4:30"),
            KeyValue_t(key: "-4", value: "UTC-4:00"),
            KeyValue_t(key: "-3:30", value: "UTC-3:30"),
            KeyValue_t(key: "-3", value: "UTC-3:00"),
            KeyValue_t(key: "-2", value: "UTC-2:00"),
            KeyValue_t(key: "-1", value: "UTC-1:00"),
            KeyValue_t(key: "0", value: "UTC"),
            KeyValue_t(key: "1", value: "UTC+1:00"),
            KeyValue_t(key: "2", value: "UTC+2:00"),
            KeyValue_t(key: "3", value: "UTC+3:00"),
            KeyValue_t(key: "3:30", value: "UTC+3:30"),
            KeyValue_t(key: "4", value: "UTC+4:00"),
            KeyValue_t(key: "4:30", value: "UTC+4:30"),
            KeyValue_t(key: "5", value: "UTC+5:00"),
            KeyValue_t(key: "5:30", value: "UTC+5:30"),
            KeyValue_t(key: "5:45", value: "UTC+5:45"),
            KeyValue_t(key: "6", value: "UTC+6:00"),
            KeyValue_t(key: "6:30", value: "UTC+6:30"),
            KeyValue_t(key: "7", value: "UTC+7:00"),
            KeyValue_t(key: "8", value: "UTC+8:00"),
            KeyValue_t(key: "9", value: "UTC+9:00"),
            KeyValue_t(key: "9:30", value: "UTC+9:30"),
            KeyValue_t(key: "10", value: "UTC+10:00"),
            KeyValue_t(key: "10:30", value: "UTC+10:30"),
            KeyValue_t(key: "11", value: "UTC+11:00"),
            KeyValue_t(key: "12", value: "UTC+12:00"),
            KeyValue_t(key: "13", value: "UTC+13:00"),
            KeyValue_t(key: "14", value: "UTC+14:00"),
            KeyValue_t(key: "separator", value: "separator")
        ] + TimeZone.knownTimeZoneIdentifiers.map { KeyValue_t(key: $0, value: $0) }
    }
}
