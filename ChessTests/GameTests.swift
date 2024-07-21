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
    // MARK: History

    func testPawnPromotionRecordedInHistory() {
        var game = Game(board: Board(pieces: [
            [nil, nil, nil, nil, nil, nil, nil, nil],
            ["WP0", nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
        ]))
        game.makeMove(.init(from: .init(x: 0, y: 1), to: .init(x: 0, y: 0)))
        game.promotePiece(at: .init(x: 0, y: 0), to: .queen)
        XCTAssertEqual(game.board.piece(at: .init(x: 0, y: 0))?.type, .queen)
        XCTAssertEqual(game.history.count, 1)
        game.makeMove(.init(from: .init(x: 0, y: 0), to: .init(x: 1, y: 0)))
        game.undo()
        XCTAssertEqual(game.board.piece(at: .init(x: 0, y: 0))?.type, .queen)
        game.undo()
        XCTAssertNil(game.board.piece(at: .init(x: 0, y: 0)))
        XCTAssertEqual(game.board.piece(at: .init(x: 0, y: 1))?.type, .pawn)
        XCTAssertEqual(game.history.count, 0)
    }

    // MARK: End conditions

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
