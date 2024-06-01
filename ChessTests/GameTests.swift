//
//  GameTests.swift
//  ChessTests
//
//  Created by Nick Lockwood on 12/07/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

@testable import Chess
import XCTest

final class GameTests: XCTestCase {
    func testOneBishopIsInsufficientMaterial() {
        let game = Game(board: Board(pieces: [
            [nil, nil, nil, nil, "BK4", "BB5", nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, "WB2", nil, "WK4", "WB5", nil, nil],
        ]))
        XCTAssertFalse(game.isSufficientMaterial(for: .black))
        XCTAssertTrue(game.isSufficientMaterial(for: .white))
    }
}
