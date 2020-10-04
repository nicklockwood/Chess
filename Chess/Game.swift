//
//  Game.swift
//  Chess
//
//  Created by Nick Lockwood on 24/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

struct Move: Equatable {
    var from, to: Position
}

enum GameState {
    case idle
    case check
    case checkMate
    case staleMate
}

struct Game {
    private(set) var board: Board
    private(set) var turn: Color
    private(set) var state: GameState
    private(set) var history: [Move]
}

extension Game {
    init() {
        board = Board()
        turn = .white
        state = .idle
        history = []
    }

    // MARK: Game logic

    func canSelectPiece(at position: Position) -> Bool {
        return board.piece(at: position)?.color == turn
    }

    func canMove(from: Position, by: Delta) -> Bool {
        return canMove(from: from, to: from + by)
    }

    func canMove(from: Position, to: Position) -> Bool {
        guard let this = board.piece(at: from) else {
            return false
        }
        let delta = to - from
        if let other = board.piece(at: to) {
            guard other.color != this.color else {
                return false
            }
            if this.type == .pawn {
                return pawnCanTake(from: from, with: delta)
            }
        }
        switch this.type {
        case .pawn:
            if enPassantTakePermitted(from: from, to: to) {
                return true
            }
            if delta.x != 0 {
                return false
            }
            switch this.color {
            case .white:
                if from.y == 6 {
                    return [-1, -2].contains(delta.y) &&
                        !board.piecesExist(between: from, and: to)
                }
                return delta.y == -1
            case .black:
                if from.y == 1 {
                    return [1, 2].contains(delta.y) &&
                        !board.piecesExist(between: from, and: to)
                }
                return delta.y == 1
            }
        case .rook:
            return (delta.x == 0 || delta.y == 0) &&
                !board.piecesExist(between: from, and: to)
        case .bishop:
            return abs(delta.x) == abs(delta.y) &&
                !board.piecesExist(between: from, and: to)
        case .queen:
            return (delta.x == 0 || delta.y == 0 || abs(delta.x) == abs(delta.y)) &&
                !board.piecesExist(between: from, and: to)
        case .king:
            return (abs(delta.x) <= 1 && abs(delta.y) <= 1)
        case .knight:
            return [
                Delta(x: 1, y: 2),
                Delta(x: -1, y: 2),
                Delta(x: 2, y: 1),
                Delta(x: -2, y: 1),
                Delta(x: 1, y: -2),
                Delta(x: -1, y: -2),
                Delta(x: 2, y: -1),
                Delta(x: -2, y: -1),
            ].contains(delta)
        }
    }

    func pieceIsThreatened(at position: Position) -> Bool {
        for y in 0 ..< 8 {
            for x in 0 ..< 8 {
                let source = Position(x: x, y: y)
                if canMove(from: source, to: position) {
                    return true
                }
            }
        }
        return false
    }

    func kingIsInCheck(for color: Color) -> Bool {
        if let position = board.firstPosition(where: {
            $0.type == .king && $0.color == color
        }) {
            return pieceIsThreatened(at: position)
        }
        return false
    }

    mutating func move(from: Position, to: Position) {
        assert(canMove(from: from, to: to))
        if let piece = board.piece(at: from), piece.type == .pawn,
            enPassantTakePermitted(from: from, to: to) {
            board.removePiece(at: Position(x: to.x, y: to.y - (to.y - from.y)))
        }
        board.movePiece(from: from, to: to)
        turn = turn.other
        state = gameState(for: turn)
        history.append(Move(from: from, to: to))
    }

    func canPromotePiece(at position: Position) -> Bool {
        if let pawn = board.piece(at: position), pawn.type == .pawn,
            (pawn.color == .white && position.y == 0) ||
            (pawn.color == .black && position.y == 7) {
            return true
        }
        return false
    }

    mutating func promotePiece(at position: Position, to type: PieceType) {
        assert(canPromotePiece(at: position))
        board.promotePiece(at: position, to: type)
        state = gameState(for: turn)
    }

    func movesForPiece(at position: Position) -> [Position] {
        return board.potentialMovesForPiece(at: position).filter {
            canMove(from: position, to: $0)
        }
    }

    // MARK: AI

    func nextMove(for color: Color) -> Move {
        var bestMove: Move?
        var bestState: GameState?
        var bestScore = 0.0
        enumerateMoves(for: color) { from, to, shouldBreak in
            var newBoard = self
            newBoard.move(from: from, to: to)
            if newBoard.kingIsInCheck(for: color) {
                return
            }
            var newScore = Double(board.piece(at: to)?.type.value ?? 0)
            if newBoard.canPromotePiece(at: to) {
                newBoard.promotePiece(at: to, to: .queen)
                newScore += 8
            }
            switch newBoard.state {
            case .checkMate:
                break
            case .staleMate:
                if bestMove != nil {
                    return
                }
            case .check:
                if newBoard.pieceIsThreatened(at: to),
                    let piece = newBoard.board.piece(at: to) {
                    newScore -= Double(piece.type.value) * 0.9
                }
                switch bestState {
                case .check where newScore >= bestScore,
                     .idle where newScore >= bestScore,
                     .staleMate, nil:
                    break
                case .check, .checkMate, .idle:
                    return
                }
            case .idle:
                var worstLossRisk = 0
                newBoard.enumerateThreats(for: color) { position, piece, _ in
                    worstLossRisk = max(worstLossRisk, piece.type.value)
                }
                newScore -= Double(worstLossRisk) * 0.9
                switch bestState {
                case .idle where newScore > bestScore,
                     .check where newScore > bestScore,
                     .staleMate, nil:
                    break
                case .idle where newScore == bestScore:
                    // All other things being equal, try to get pawn to other side
                    if let bestMove = bestMove,
                        board.piece(at: from)?.type == .pawn,
                        board.piece(at: bestMove.from)?.type != .pawn ||
                        (color == .black && to.y > bestMove.to.y) ||
                        (color == .white && to.y < bestMove.to.y) {
                        break
                    }
                    return
                case .check, .checkMate, .idle:
                    return
                }
            }
            if bestMove != nil, history.count > 1,
                history.dropLast().last == Move(from: to, to: from) {
                return
            }
            bestMove = Move(from: from, to: to)
            bestState = newBoard.state
            bestScore = newScore
        }
        return bestMove!
    }
}

private extension Game {
    func enumerateMoves(for color: Color,
                        fn: (Position, Position, inout Bool) -> Void) {
        var shouldBreak = false
        for y in (0 ..< 8).shuffled() {
            for x in (0 ..< 8).shuffled() {
                let position = Position(x: x, y: y)
                guard board.piece(at: position)?.color == color else {
                    continue
                }
                enumerateMoves(for: position, shouldBreak: &shouldBreak) {
                    fn(position, $0, &$1)
                }
                if shouldBreak {
                    return
                }
            }
        }
    }

    func enumerateMoves(for position: Position, shouldBreak: inout Bool,
                        fn: (Position, inout Bool) -> Void) {
        for y in (0 ..< 8).shuffled() {
            for x in (0 ..< 8).shuffled() {
                let destination = Position(x: x, y: y)
                if canMove(from: position, to: destination) {
                    fn(destination, &shouldBreak)
                    if shouldBreak {
                        return
                    }
                }
            }
        }
    }

    func enumerateThreats(for color: Color, fn: (Position, Piece, inout Bool) -> Void) {
        board.enumeratePieces(for: color) { position, piece, shouldBreak in
            if pieceIsThreatened(at: position) {
                fn(position, piece, &shouldBreak)
            }
        }
    }

    func gameState(for color: Color) -> GameState {
        guard let position = board.firstPosition(where: {
            $0.type == .king && $0.color == color
        }) else {
            return .idle
        }
        var canMove = false
        enumerateMoves(for: color) { from, to, shouldBreak in
            var newBoard = self
            newBoard.board.movePiece(from: from, to: to)
            if !newBoard.kingIsInCheck(for: color) {
                canMove = true
                shouldBreak = true
            }
        }
        if pieceIsThreatened(at: position) {
            return canMove ? .check : .checkMate
        }
        return canMove ? .idle : .staleMate
    }

    func pawnCanTake(from: Position, with delta: Delta) -> Bool {
        guard abs(delta.x) == 1, let pawn = board.piece(at: from) else {
            return false
        }
        assert(pawn.type == .pawn)
        switch pawn.color {
        case .white:
            return delta.y == -1
        case .black:
            return delta.y == 1
        }
    }

    func enPassantTakePermitted(from: Position, to: Position) -> Bool {
        guard let this = board.piece(at: from),
            pawnCanTake(from: from, with: to - from),
            let lastMove = history.last, lastMove.to.x == to.x,
            let piece = board.piece(at: lastMove.to),
            piece.type == .pawn, piece.color != this.color
        else {
            return false
        }
        switch piece.color {
        case .white:
            return lastMove.from.y == to.y + 1 && lastMove.to.y == to.y - 1
        default:
            return lastMove.from.y == to.y - 1 && lastMove.to.y == to.y + 1
        }
    }
}

private extension Board {
    func enumeratePieces(for color: Color, fn: (Position, Piece, inout Bool) -> Void) {
        var shouldBreak = false
        for (y, row) in pieces.enumerated() {
            for (x, piece) in row.enumerated() where piece?.color == color {
                let position = Position(x: x, y: y)
                if let piece = piece {
                    fn(position, piece, &shouldBreak)
                    if shouldBreak {
                        return
                    }
                }
            }
        }
    }

    func piecesExist(between: Position, and: Position) -> Bool {
        let step = Delta(
            x: between.x > and.x ? -1 : (between.x < and.x ? 1 : 0),
            y: between.y > and.y ? -1 : (between.y < and.y ? 1 : 0)
        )
        var position = between
        position += step
        while position != and {
            if piece(at: position) != nil {
                return true
            }
            position += step
        }
        return false
    }

    func potentialMovesForPiece(at position: Position) -> [Position] {
        guard let this = piece(at: position) else {
            return []
        }
        switch this.type {
        case .pawn:
            switch this.color {
            case .white:
                return [
                    position + Delta(x: -1, y: -1),
                    position + Delta(x: 0, y: -1),
                    position + Delta(x: 0, y: -2),
                    position + Delta(x: 1, y: -1),
                ]
            case .black:
                return [
                    position + Delta(x: -1, y: 1),
                    position + Delta(x: 0, y: 1),
                    position + Delta(x: 0, y: 2),
                    position + Delta(x: 1, y: 1),
                ]
            }
        case .rook:
            return (0 ..< 8).flatMap {
                [Position(x: position.x, y: $0), Position(x: $0, y: position.y)]
            }
        case .bishop:
            return (-7 ..< 7).flatMap {
                [position + Delta(x: $0, y: $0), position + Delta(x: $0, y: -$0)]
            }
        case .queen:
            return (-7 ..< 7).flatMap {
                [
                    position + Delta(x: 0, y: $0),
                    position + Delta(x: $0, y: $0),
                    position + Delta(x: $0, y: -$0),
                    position + Delta(x: $0, y: 0),
                ]
            }
        case .king:
            return [
                position + Delta(x: -1, y: -1),
                position + Delta(x: 0, y: -1),
                position + Delta(x: 1, y: -1),
                position + Delta(x: 1, y: 0),
                position + Delta(x: 1, y: 1),
                position + Delta(x: 0, y: 1),
                position + Delta(x: -1, y: 1),
                position + Delta(x: -1, y: 0),
            ]
        case .knight:
            return [
                position + Delta(x: 1, y: 2),
                position + Delta(x: -1, y: 2),
                position + Delta(x: 2, y: 1),
                position + Delta(x: -2, y: 1),
                position + Delta(x: 1, y: -2),
                position + Delta(x: -1, y: -2),
                position + Delta(x: 2, y: -1),
                position + Delta(x: -2, y: -1),
            ]
        }
    }
}
