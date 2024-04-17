//
//  ViewController.swift
//  Chess
//
//  Created by Nick Lockwood on 22/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private var game = Game()

    @IBOutlet var boardView: BoardView?
    @IBOutlet var whiteToggle: UISegmentedControl?
    @IBOutlet var blackToggle: UISegmentedControl?

    override func viewDidLoad() {
        super.viewDidLoad()
        boardView?.delegate = self
        update()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    @IBAction private func togglePlayerType() {
        makeComputerMove()
    }

    @IBAction private func resetGame() {
        game = Game()
        UIView.animate(withDuration: 0.4, animations: {
            self.boardView?.board = self.game.board
        }, completion: { [weak self] _ in
            self?.update()
        })
        setSelection(nil)
    }
}

extension ViewController: BoardViewDelegate {
    func boardView(_ boardView: BoardView, didTap position: Position) {
        guard let selection = boardView.selection else {
            if game.canSelectPiece(at: position) {
                setSelection(position)
            } else {
                boardView.jigglePiece(at: position)
            }
            return
        }
        guard game.canMove(from: selection, to: position) else {
            if selection == position {
                setSelection(nil)
            } else if game.canSelectPiece(at: position) {
                setSelection(position)
            }
            return
        }
        makeMove(Move(from: selection, to: position))
    }

    private func playerIsHuman(_ color: Color) -> Bool {
        switch color {
        case .white:
            return whiteToggle?.selectedSegmentIndex == 0
        case.black:
            return blackToggle?.selectedSegmentIndex == 0
        }
    }

    private func update() {
        let gameState = game.state
        switch gameState {
        case .checkMate, .staleMate:
            let alert = UIAlertController(
                title: "Game Over",
                message: gameState == .staleMate ?
                    "Stalemate: Nobody wins" :
                    "Checkmate: \(game.turn.other) wins",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        case .check:
            boardView?.pulsePiece(at: game.kingPosition(for: game.turn)) {
                self.makeComputerMove()
            }
        case .idle:
            makeComputerMove()
        }
    }

    private func setSelection(_ position: Position?) {
        let moves = position.map(game.movesForPiece(at:)) ?? []
        UIView.animate(withDuration: 0.2, animations: {
            self.boardView?.selection = position
            self.boardView?.moves = moves
        })
    }

    private func makeComputerMove() {
        if !playerIsHuman(game.turn),
           let move = game.nextMove(for: game.turn)
        {
            makeMove(move)
        }
    }

    private func makeMove(_ move: Move) {
        let position = move.to
        guard let boardView = boardView else {
            return
        }
        let oldGame = game
        game.move(from: move.from, to: position)
        let board1 = game.board
        let kingPosition = game.kingPosition(for: oldGame.turn)
        let wasInCheck = game.pieceIsThreatened(at: kingPosition)
        let wasPromoted = !wasInCheck && game.canPromotePiece(at: position)
        let wasHuman = playerIsHuman(oldGame.turn)
        if wasInCheck {
            game = oldGame
        }
        let board2 = game.board
        UIView.animate(withDuration: 0.4, animations: {
            boardView.selection = nil
            boardView.board = board1
            boardView.moves = []
        }, completion: { [weak self] _ in
            guard let self = self, board2 == self.game.board else { return }
            if wasInCheck {
                UIView.animate(withDuration: 0.2, animations: {
                    boardView.board = board2
                })
                boardView.jigglePiece(at: kingPosition)
                return
            }
            if wasPromoted {
                if !wasHuman {
                    self.game.promotePiece(at: position, to: .queen)
                    let board2 = self.game.board
                    UIView.animate(withDuration: 0.4, animations: {
                        boardView.board = board2
                    }, completion: { [weak self] _ in
                        guard board2 == self?.game.board else { return }
                        self?.update()
                    })
                    return
                }
                let alert = UIAlertController(
                    title: "Promote Pawn",
                    message: nil,
                    preferredStyle: .alert
                )
                for piece in [PieceType.queen, .rook, .bishop, .knight] {
                    alert.addAction(UIAlertAction(
                        title: piece.rawValue.capitalized,
                        style: .default
                    ) { [weak self] _ in
                        guard let self = self else { return }
                        self.game.promotePiece(at: position, to: piece)
                        boardView.board = self.game.board
                        self.update()
                    })
                }
                self.present(alert, animated: true)
                return
            }
            self.update()
        })
    }
}
