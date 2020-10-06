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
        return board.allPositions.contains(where: { canMove(from: $0, to: position) })
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
        return board.allPositions.filter { canMove(from: position, to: $0) }
    }

    // MARK: AI

    func nextMove(for color: Color) -> Move {
        var bestMove: Move?
        var bestState: GameState?
        var bestScore = 0.0
        for move in allMoves(for: color).shuffled() {
            var newBoard = self
            newBoard.move(from: move.from, to: move.to)
            if newBoard.kingIsInCheck(for: color) {
                continue
            }
            var newScore = Double(board.piece(at: move.to)?.type.value ?? 0)
            if newBoard.canPromotePiece(at: move.to) {
                newBoard.promotePiece(at: move.to, to: .queen)
                newScore += 8
            }
            switch newBoard.state {
            case .checkMate:
                break
            case .staleMate:
                if bestMove != nil {
                    continue
                }
            case .check:
                if newBoard.pieceIsThreatened(at: move.to),
                    let piece = newBoard.board.piece(at: move.to) {
                    newScore -= Double(piece.type.value) * 0.9
                }
                switch bestState {
                case .check where newScore >= bestScore,
                     .idle where newScore >= bestScore,
                     .staleMate, nil:
                    break
                case .check, .checkMate, .idle:
                    continue
                }
            case .idle:
                var worstLossRisk = 0
                for (_, piece) in newBoard.allThreats(for: color) {
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
                        board.piece(at: move.from)?.type == .pawn,
                        board.piece(at: bestMove.from)?.type != .pawn ||
                            (color == .black && move.to.y > bestMove.to.y) ||
                            (color == .white && move.to.y < bestMove.to.y) {
                        break
                    }
                    continue
                case .check, .checkMate, .idle:
                    continue
                }
            }
            if bestMove != nil, history.count > 1,
                history.dropLast().last == Move(from: move.to, to: move.from) {
                continue
            }
            bestMove = move
            bestState = newBoard.state
            bestScore = newScore
        }
        return bestMove!
    }
}

private extension Game {
    func allMoves(for color: Color) ->
        LazySequence<FlattenSequence<LazyMapSequence<[Position], LazyFilterSequence<[Move]>>>> {
        return board.allPieces
            .compactMap { $1.color == color ? $0 : nil }
            .lazy.flatMap { self.allMoves(for: $0) }
    }

    func allMoves(for position: Position) -> LazyFilterSequence<[Move]> {
        return board.allPositions
            .map { Move(from: position, to: $0) }
            .lazy.filter { self.canMove(from: $0.from, to: $0.to) }
    }

    func allThreats(for color: Color) -> LazyFilterSequence<[(position: Position, piece: Piece)]> {
        return board.allPieces.lazy.filter { position, piece in
            return piece.color == color && self.pieceIsThreatened(at: position)
        }
    }

    func gameState(for color: Color) -> GameState {
        let canMove = allMoves(for: color).contains(where: { move in
            var newBoard = self
            newBoard.board.movePiece(from: move.from, to: move.to)
            return !newBoard.kingIsInCheck(for: color)
        })
        if kingIsInCheck(for: color) {
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
}
