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

    // MARK: Castling

    func testCastlingRequiresOwnRook() {
        // f1/g1 are clear but h1 holds an enemy bishop instead of the rook
        let game = Game(board: Board(pieces: [
            [nil, nil, nil, nil, nil, nil, nil, "BK4"],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, "WK4", nil, nil, "BB5"],
        ]))
        XCTAssertFalse(game.canMove(from: .init(x: 4, y: 7), to: .init(x: 6, y: 7)))
    }

    func testCastlingMovesRook() {
        var game = Game(board: Board(pieces: [
            [nil, nil, nil, nil, nil, nil, nil, "BK4"],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, "WK4", nil, nil, "WR7"],
        ]))
        XCTAssertTrue(game.canMove(from: .init(x: 4, y: 7), to: .init(x: 6, y: 7)))
        game.makeMove(.init(from: .init(x: 4, y: 7), to: .init(x: 6, y: 7)))
        XCTAssertEqual(game.board.piece(at: .init(x: 5, y: 7))?.type, .rook)
        XCTAssertNil(game.board.piece(at: .init(x: 7, y: 7)))
    }

    // MARK: Check

    func testEnPassantCanEscapeCheck() {
        // After h2-h3 b7-b5 the white king on a4 is in check from the b5 pawn,
        // has no free square, and capturing en passant is the only escape
        var game = Game(board: Board(pieces: [
            [nil, "BR1", nil, nil, nil, nil, nil, "BK4"],
            [nil, "BP1", nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            ["WP0", nil, "WP2", nil, nil, nil, nil, nil],
            ["WK4", "WP1", nil, nil, nil, nil, nil, nil],
            ["WP3", "WP4", nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, "WP5"],
            [nil, nil, nil, nil, nil, nil, nil, nil],
        ]))
        game.makeMove(.init(from: .init(x: 7, y: 6), to: .init(x: 7, y: 5)))
        game.makeMove(.init(from: .init(x: 1, y: 1), to: .init(x: 1, y: 3)))
        XCTAssertTrue(game.kingIsInCheck(for: .white))
        XCTAssertTrue(game.canMove(from: .init(x: 2, y: 3), to: .init(x: 1, y: 2)))
        XCTAssertEqual(game.state, .check)
        game.makeMove(.init(from: .init(x: 2, y: 3), to: .init(x: 1, y: 2)))
        XCTAssertNil(game.board.piece(at: .init(x: 1, y: 3)))
        XCTAssertFalse(game.kingIsInCheck(for: .white))
    }
}
