//
//  ClickGirlTests.swift
//  ClickGirlTests
//
//  Created by 石田健雄 on 2026/03/08.
//

import Foundation
import Testing
@testable import ClickGirl

struct ClickGirlTests {

    @Test func bgmSettingPersists() throws {
        let suiteName = "ClickGirlTests.AppSettings.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        #expect(settings.isBGMEnabled)

        settings.isBGMEnabled = false
        #expect(!AppSettings(defaults: defaults).isBGMEnabled)
    }

    @Test func settingsReturnsToRequestedScene() {
        let size = CGSize(width: 390, height: 844)
        #expect(SettingScene(size: size, returnDestination: .title).makeReturnScene() is TitleScene)
        #expect(SettingScene(size: size, returnDestination: .game).makeReturnScene() is GameScene)
    }

}
