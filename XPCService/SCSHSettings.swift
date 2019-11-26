//
//  SCSHSettings.swift
//  SCSHXPCService
//
//  Created by sbarex on 18/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
//
//  This file is part of SyntaxHighlight.
//  SyntaxHighlight is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SyntaxHighlight is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with SyntaxHighlight. If not, see <http://www.gnu.org/licenses/>.

import Foundation

enum SCSHFormat: String {
    case html
    case rtf
}

enum SCSHLineNumbers {
    case hidden
    case visible(omittingWrapLines: Bool)
}

enum SCSHWordWrap: Int {
    case off
    case simple
    case standard
}

class SCSHSettings {
    public struct Key {
        static let lightTheme = "theme-light"
        static let darkTheme = "theme-dark"
        static let theme = "theme"
        
        static let rtfLightBackgroundColor = "rtf-background-color-light"
        static let rtfDarkBackgroundColor = "rtf-background-color-dark"
        static let rtfBackgroundColor = "rtf-background-color"
        
        static let lineNumbers = "line-numbers"
        static let lineNumbersOmittedWrap = "line-numbers-omitted-wrap"
        
        static let wordWrap = "word-wrap"
        static let lineLength = "line-length"
        
        static let tabSpaces = "tab-spaces"
        
        static let highlightPath = "highlight"
    
        static let format = "format"
        
        static let extraArguments = "extra"
        static let utiExtraArguments = "uti-extra"
        
        static let fontFamily = "font-family"
        static let fontSize = "font-size"
        
        static let debug = "debug"
        
        static let renderForExtension = "appex"
        
        static let customizedUTISettings = "uti-settings"
        
        static let connectedUTI = "uti"
        
        static let customCSS = "css"
        static let preprocessor = "preprocessor"
        
        static let inline_theme = "inline_theme"
        static let interactive = "interactive"
        static let version = "version"
    }
    
    /// Current settings version handled by the applications.
    static let version: Float = 2
    
    /// Version of the settings.
    var version: Float = 0
    
    /// Path of highlight executable.
    var highlightProgramPath: String = "-"
    
    /// UTI associated to this settings. Is empty for globals settings.
    let uti: String
    
    /// Return if the settings are globals for all file format or specific to a single UTI.
    var isGlobal: Bool {
        return uti.isEmpty
    }
    
    /// Return if exists customized settings.
    /// Global settings are always customized.
    var isCustomized: Bool {
        if isGlobal {
            // Global settings are customized by definition.
            return true
        } else {
            if utiExtra != nil && utiExtra != "" {
                // Extra arguments are defined.
                return true
            } else if (lightTheme != nil && lightTheme != "") || (darkTheme != nil && darkTheme != "") || lineNumbers != nil || fontFamily != nil || wordWrap != nil || lineLength != nil || tabSpaces != nil || extra != nil || preprocessor != nil || allowInteractiveActions != nil {
                return true
            } else if let css = self.css {
                return !css.isEmpty
            } else {
                return false
            }
        }
    }
    
    /// Name of theme for light visualization.
    var lightTheme: String?
    /// Name of theme for dark visualization.
    var darkTheme: String?
    
    /// Background color for the rgb view in light theme.
    var rtfLightBackgroundColor: String?
    /// Background color for the rgb view in dark theme.
    var rtfDarkBackgroundColor: String?
    
    /// Name of theme overriding the light/dark settings
    var theme: String?
    /// A theme to use instead of the theme name.
    var inline_theme: SCSHTheme?
    
    /// Background color overriding the light/dark settings
    var rtfBackgroundColor: String?
    
    /// Show line number.
    var lineNumbers: SCSHLineNumbers?
    var wordWrap: SCSHWordWrap?
    var lineLength: Int?
    
    /// Number of spaces use for a tab. Set to 0 to disable converting tab to spaces.
    var tabSpaces: Int?
    
    /// Extra arguments for highlight.
    var extra: String?
    /// Extra arguments added to the common arguments relative to the associated UTI.
    var utiExtra: String?
    
    /// Output format.
    var format: SCSHFormat?
    
    var fontFamily: String?
    var fontSize: Float?
    
    var debug = false
    
    /// Indicate if the output is for the quicklook extension.
    var renderForExtension = true
    
    /// Domain for storing defaults.
    let domain: String
    
    /// Custom style sheet.
    /// When the settings are stored the value is written to a file.
    var css: String?
    
    var preprocessor: String?
    
    /// If true enable js action on the quicklook preview but disable dblclick and click and drag on window.
    var allowInteractiveActions: Bool?
    
    var customizedSettings: [String: SCSHSettings] = [:]
    
    /// Create a global settings.
    convenience init() {
        self.init(UTI: "")
    }
    
    /// Create a settings specific to an UTI.
    init(UTI: String) {
        self.domain = ""
        self.uti = UTI
    }
    
    /// Dictionary base initialization.
    init(dictionary: [String: Any]) {
        if let uti = dictionary[Key.connectedUTI] as? String {
            self.uti = uti
        } else {
            self.uti = ""
        }
        self.domain = ""
        self.override(fromDictionary: dictionary)
    }
    
    /// Initialize the setting based on the preferences provided.
    convenience init(settings: SCSHSettings) {
        self.init(dictionary: settings.toDictionary())
    }
    
    /// Initialize from a preferences loaded from the domain defaults.
    init(domain: String) {
        self.domain = domain
        self.uti = ""
        
        let defaults = UserDefaults.standard
        let defaultsDomain = defaults.persistentDomain(forName: domain) ?? [:]
        
        self.highlightProgramPath = defaultsDomain[Key.highlightPath] as? String ?? "-"
        if self.highlightProgramPath == "" {
            // Use embedded highlight.
            self.highlightProgramPath = "-"
        }
        
        self.lightTheme = defaultsDomain[Key.lightTheme] as? String ?? "edit-xcode"
        self.rtfLightBackgroundColor = defaultsDomain[Key.rtfLightBackgroundColor] as? String
        
        self.darkTheme = defaultsDomain[Key.darkTheme] as? String ?? "edit-xcode"
        self.rtfDarkBackgroundColor = defaultsDomain[Key.rtfDarkBackgroundColor] as? String
        
        if let ln = defaultsDomain[Key.lineNumbers] as? Bool {
            self.lineNumbers = ln ? .visible(omittingWrapLines: defaultsDomain[Key.lineNumbersOmittedWrap] as? Bool ?? true) : .hidden
        } else {
            self.lineNumbers = .visible(omittingWrapLines: true)
        }
        self.wordWrap = SCSHWordWrap(rawValue: defaultsDomain[Key.wordWrap] as? Int ?? 0) ?? .off
        self.lineLength = defaultsDomain[Key.lineLength] as? Int ?? 80
        
        self.tabSpaces = defaultsDomain[Key.tabSpaces] as? Int ?? 4
        
        self.format = SCSHFormat(rawValue: defaultsDomain[Key.format] as? String ?? "") ?? .html
        self.extra = defaultsDomain[Key.extraArguments] as? String ?? ""
        
        self.fontFamily = defaultsDomain[Key.fontFamily] as? String ?? "Menlo"
        self.fontSize = defaultsDomain[Key.fontSize] as? Float ?? 10
        
        if let custom_formats = defaultsDomain[Key.customizedUTISettings] as? [String: [String: Any]] {
            for (uti, settings) in custom_formats {
                let s = SCSHSettings(UTI: uti)
                s.override(fromDictionary: settings)
                self.customizedSettings[uti] = s
            }
        }
        
        self.debug = defaultsDomain[Key.debug] as? Bool ?? false
        self.allowInteractiveActions = defaultsDomain[Key.interactive] as? Bool ?? false
        
        self.version = defaultsDomain[Key.version] as? Float ?? 1
    }
    
    /// Save the settings to the defaults preferences.
    @discardableResult
    func synchronize(domain: String? = nil) -> Bool {
        let d = domain ?? self.domain
        guard d != "", isGlobal else {
            return false
        }
        
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: d) ?? [:]
        
        defaultsDomain[Key.highlightPath] = highlightProgramPath
        if let format = self.format {
            defaultsDomain[Key.format] = format.rawValue
        } else {
            defaultsDomain.removeValue(forKey: Key.format)
        }
        
        var n = 0
        var customized_formats: [String: [String: Any]] = [:]
        for (uti, settings) in self.customizedSettings {
            let d = settings.toDictionary()
            if d.count > 0 {
                customized_formats[uti] = d
                n += 1
            }
        }
        if n > 0 {
            defaultsDomain[Key.customizedUTISettings] = customized_formats
        } else {
            defaultsDomain.removeValue(forKey: Key.customizedUTISettings)
        }
        
        if let lightTheme = self.lightTheme, lightTheme != "" {
            defaultsDomain[Key.lightTheme] = lightTheme
        } else {
            defaultsDomain.removeValue(forKey: Key.lightTheme)
        }
        defaultsDomain[Key.rtfLightBackgroundColor] = rtfLightBackgroundColor
        if let darkTheme = self.darkTheme, darkTheme != "" {
            defaultsDomain[Key.darkTheme] = darkTheme
        } else {
            defaultsDomain.removeValue(forKey: Key.darkTheme)
        }
        defaultsDomain[Key.rtfDarkBackgroundColor] = rtfDarkBackgroundColor
        
        if let lineNumbers = self.lineNumbers {
            switch lineNumbers {
            case .hidden:
                defaultsDomain[Key.lineNumbers] = false
            case .visible(let omittingWrapLines):
                defaultsDomain[Key.lineNumbers] = true
                defaultsDomain[Key.lineNumbersOmittedWrap] = omittingWrapLines
            }
        } else {
            defaultsDomain.removeValue(forKey: Key.lineNumbers)
            defaultsDomain.removeValue(forKey: Key.lineNumbersOmittedWrap)
        }
        
        if let wordWrap = self.wordWrap {
            defaultsDomain[Key.wordWrap] = wordWrap.rawValue
        } else {
            defaultsDomain.removeValue(forKey: Key.wordWrap)
        }
        if let lineLength = self.lineLength {
            defaultsDomain[Key.lineLength] = lineLength
        } else {
            defaultsDomain.removeValue(forKey: Key.lineLength)
        }
        
        if let tabSpaces = self.tabSpaces {
            defaultsDomain[Key.tabSpaces] = tabSpaces
        } else {
            defaultsDomain.removeValue(forKey: Key.tabSpaces)
        }
        
        if let extra = self.extra {
            defaultsDomain[Key.extraArguments] = extra
        } else {
            defaultsDomain.removeValue(forKey: Key.extraArguments)
        }
        
        if let fontFamily = self.fontFamily {
            defaultsDomain[Key.fontFamily] = fontFamily
        } else {
            defaultsDomain.removeValue(forKey: Key.fontFamily)
        }
        if let fontSize = self.fontSize {
            defaultsDomain[Key.fontSize] = fontSize
        } else {
            defaultsDomain.removeValue(forKey: Key.fontSize)
        }
        
        if let preprocessor = self.preprocessor, !preprocessor.isEmpty {
            defaultsDomain[Key.preprocessor] = preprocessor
        } else {
            defaultsDomain.removeValue(forKey: Key.preprocessor)
        }
        
        if let v = self.allowInteractiveActions {
            defaultsDomain[Key.interactive] = v
        } else {
            defaultsDomain.removeValue(forKey: Key.interactive)
        }
        
        defaultsDomain[Key.debug] = self.debug
        
        let userDefaults = UserDefaults()
        userDefaults.setPersistentDomain(defaultsDomain, forName: d)
        return userDefaults.synchronize()
    }
    
    /// Output the settings to a dictionary.
    func toDictionary() -> [String: Any] {
        guard self.isCustomized else {
            return [:]
        }
        
        var r: [String: Any] = [:]
        
        if isGlobal {
            r[Key.highlightPath] = self.highlightProgramPath
            if let format = self.format {
                r[Key.format] = format.rawValue
            }
            
            r[Key.renderForExtension] = self.renderForExtension
            
            var customized_formats: [String: [String: Any]] = [:]
            for (uti, settings) in self.customizedSettings {
                let d = settings.toDictionary()
                if d.count > 0 {
                    customized_formats[uti] = d
                }
            }
            r[Key.customizedUTISettings] = customized_formats
            
            r[Key.debug] = self.debug
            r[Key.version] = SCSHSettings.version
        } else {
            if let utiExtra = self.utiExtra {
                r[Key.utiExtraArguments] = utiExtra
            }
        }
        if let lightTheme = self.lightTheme {
            r[Key.lightTheme] = lightTheme
            r[Key.rtfLightBackgroundColor] = rtfLightBackgroundColor ?? "ffffff"
        }
        if let darkTheme = self.darkTheme {
            r[Key.darkTheme] = darkTheme
            r[Key.rtfDarkBackgroundColor] = rtfDarkBackgroundColor ?? "000000"
        }
        if let wordWrap = self.wordWrap {
            r[Key.wordWrap] = wordWrap.rawValue
        }
        if let lineLength = self.lineLength {
            r[Key.lineLength] = lineLength
        }
        if let tabSpaces = self.tabSpaces {
            r[Key.tabSpaces] = tabSpaces
        }
        if let extra = self.extra {
            r[Key.extraArguments] = extra
        }
        if let fontFamily = self.fontFamily {
            r[Key.fontFamily] = fontFamily
        }
        if let fontSize = self.fontSize {
            r[Key.fontSize] = fontSize
        }
        if let css = self.css {
            r[Key.customCSS] = css
        }
        
        if let preprocessor = self.preprocessor, !preprocessor.isEmpty {
            r[Key.preprocessor] = preprocessor
        }
        
        if let lineNumbers = self.lineNumbers {
            switch lineNumbers {
            case .hidden:
                r[Key.lineNumbers] = false
            case .visible(let omittingWrapLines):
                r[Key.lineNumbers] = true
                r[Key.lineNumbersOmittedWrap] = omittingWrapLines
            }
        }
        
        if let theme = self.theme {
            r[Key.theme] = theme
        }
        if let color = self.rtfBackgroundColor {
            r[Key.rtfBackgroundColor] = color
        }
        
        if let inline_theme = self.inline_theme {
            r[Key.inline_theme] = inline_theme.toDictionary()
        } else {
            r[Key.inline_theme] = nil
        }
        
        if let allowInteractiveActions = self.allowInteractiveActions {
            r[Key.interactive] = allowInteractiveActions
        }
        
        return r
    }
    
    /// Updating values from a dictionary. Settings not defined on dictionary are not updated.
    /// - parameters:
    ///   - data: NSDictionary [String: Any]
    func override(fromDictionary dict: [String: Any]?) {
        guard let data = dict else {
            return
        }
        if isGlobal {
            if let v = data[Key.highlightPath] as? String {
                self.highlightProgramPath = v
            }
            // Output format.
            if let v = data[Key.format] as? String, let f = SCSHFormat(rawValue: v) {
                self.format = f
            }
            if let customized_formats = data[Key.customizedUTISettings] as? [String: [String: Any]] {
                self.customizedSettings = [:]
                for (uti, dict) in customized_formats {
                    let uti_settings = self.customizedSettings[uti] ?? SCSHSettings(UTI: uti)
                    uti_settings.override(fromDictionary: dict)
                    self.customizedSettings[uti] = uti_settings
                }
            }
            // Debug
            if let debug = data[Key.debug] as? Bool {
                self.debug = debug
            }
        } else {
            if let v = data[Key.utiExtraArguments] as? String {
                self.utiExtra = v
            }
        }
        
        // Light theme.
        if let v = data[Key.lightTheme] as? String {
            self.lightTheme = v
        }
        // Light background color.
        if let v = data[Key.rtfLightBackgroundColor] as? String {
            self.rtfLightBackgroundColor = v
        }
        
        // Dark theme.
        if let v = data[Key.darkTheme] as? String {
            self.darkTheme = v
        }
        // Dark background color.
        if let v = data[Key.rtfDarkBackgroundColor] as? String {
            self.rtfDarkBackgroundColor = v
        }
        
        // Forcing a theme.
        if let _ = data.keys.first(where: { $0 == Key.theme }) {
            self.theme = data[Key.theme] as? String
        }
        // Forcing a background color.
        if let _ = data.keys.first(where: { $0 == Key.rtfBackgroundColor }) {
            self.rtfBackgroundColor = data[Key.rtfBackgroundColor] as? String
        }
        
        // Font
        if let v = data[Key.fontFamily] as? String {
            self.fontFamily = v
        }
        if let v = data[Key.fontSize] as? Float {
            self.fontSize = v
        }
        
        // Show line numbers.
        if let v = data[Key.lineNumbers] as? Bool {
            self.lineNumbers = v ? .visible(omittingWrapLines: data[Key.lineNumbersOmittedWrap] as? Bool ?? true) : .hidden
        }
        
        if let v = data[Key.wordWrap] as? Int {
            self.wordWrap = SCSHWordWrap(rawValue: v) ?? .off
        }
        if let v = data[Key.lineLength] as? Int {
            self.lineLength = v
        }
        
        // Convert tab to spaces.
        if let v = data[Key.tabSpaces] as? Int {
            self.tabSpaces = v
        }
        
        // Extra arguments for _highlight_.
        if let v = data[Key.extraArguments] as? String {
            self.extra = v
        }
        
        // Font family.
        if let v = data[Key.fontFamily] as? String {
            self.fontFamily = v
        }
        // Font size.
        if let v = data[Key.fontSize] as? Float {
            self.fontSize = v
        }
        if let v = data[Key.customCSS] as? String {
            self.css = v
        }
        
        if let v = data[Key.preprocessor] as? String {
            self.preprocessor = v
        }
        
        if let v = data[Key.renderForExtension] as? Bool {
            self.renderForExtension = v
        }
        
        if let v = data[Key.interactive] as? Bool {
            self.allowInteractiveActions = v
        }
        
        if let inline_theme = data[Key.inline_theme] as? [String: Any] {
            self.inline_theme = SCSHTheme(dict: inline_theme)
        }
    }
    
    func override(fromSettings settings: SCSHSettings) {
        override(fromDictionary: settings.toDictionary())
    }
    
    /// Create a new settings overriding current values
    /// - parameters:
    ///   - override:
    func overriding(fromDictionary override: [String: Any]?) -> SCSHSettings {
        let final_settings = SCSHSettings(settings: self)
        if let o = override {
            final_settings.override(fromDictionary: o)
        }
        return final_settings
    }
    
    func getGlobalSettingsForUti(_ uti: String) -> SCSHSettings? {
        guard isGlobal else {
            return nil
        }
        
        let settings = SCSHSettings(settings: self)
        if let s = self.customizedSettings[uti] {
            settings.override(fromSettings: s)
            if let extra = s.utiExtra, extra != "" {
                settings.extra = (settings.extra != nil ? settings.extra! + " " : "") + extra
            }
        }
        
        return settings
    }
    
    /// Clear all customized settings for UTIs.
    func clearUTISettings() {
        self.customizedSettings = [:]
    }
    
    /// Get customized settings for a UTI.
    /// If not exists it will be created.
    /// The returned  settings are only customized value.
    func getSettings(forUTI uti: String) -> SCSHSettings?
    {
        guard isGlobal else {
            return nil
        }
        if let s = self.customizedSettings[uti] {
            return s
        } else {
            let s = SCSHSettings(UTI: uti)
            self.customizedSettings[uti] = s
            return s
        }
    }
    
    func setUTISettings(_ settings: SCSHSettings) {
        self.customizedSettings[settings.uti] = settings
    }
    
    func removeUTISettings(uti: String) -> SCSHSettings? {
        return self.customizedSettings.removeValue(forKey: uti)
    }
    
    func hasCustomizedUTI(_ uti: String) -> Bool {
        if let s = self.customizedSettings[uti] {
            return s.isCustomized
        } else {
            return false
        }
    }
}
