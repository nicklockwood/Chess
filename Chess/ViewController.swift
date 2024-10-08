//
//  ViewController.swift
//  Chess
//
//  Created by Nick Lockwood on 22/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private var game: Game = .init()
    private var isPaused: Bool = false

    @IBOutlet var boardView: BoardView?
    @IBOutlet var undoButton: UIButton?
    @IBOutlet var resetButton: UIButton?
    @IBOutlet var whiteToggle: UISegmentedControl?
    @IBOutlet var blackToggle: UISegmentedControl?

    private lazy var saveURL: URL = {
        var directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        #if os(macOS)
        directory = directory.appendingPathComponent(Bundle.main.bundleIdentifier!)
        #endif
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("game.json")
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        boardView?.delegate = self
        try? load(from: saveURL)
        whiteToggle?.selectedSegmentIndex = game.whiteIsHuman ? 0 : 1
        blackToggle?.selectedSegmentIndex = game.blackIsHuman ? 0 : 1
        boardView?.board = game.board
        isPaused = game.inProgress
        updateUI()
        update()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func didEnterBackground() {
        try? save(to: saveURL)
        if game.inProgress {
            pause()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isPaused {
            pause()
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    @IBAction private func togglePlayerType() {
        game.whiteIsHuman = whiteToggle?.selectedSegmentIndex == 0
        game.blackIsHuman = blackToggle?.selectedSegmentIndex == 0
        makeComputerMove()
    }

    @IBAction private func resetGame() {
        game.reset()
        UIView.animate(withDuration: 0.4, animations: {
            self.boardView?.board = self.game.board
            self.updateUI()
        }, completion: { [weak self] _ in
            self?.update()
        })
        setSelection(nil)
    }

    @IBAction private func undo() {
        game.undo()
        UIView.animate(withDuration: 0.4, animations: {
            self.boardView?.board = self.game.board
            self.updateUI()
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            if self.game.playerIsHuman() || !self.game.playerIsHuman(self.game.turn.other) {
                self.update()
            } else {
                self.undo()
            }
        })
        setSelection(nil)
    }

    @IBAction private func settings() {
        let vc = SettingsViewController()
        vc.onThemeSelect = { self.boardView?.theme = $0 }
        vc.onFlipBlackWhenHuman = {
            self.boardView?.flipBlackPieces = $0 && self.game.blackIsHuman
        }
        present(vc, animated: true)
    }
}

extension ViewController {
    func load(from url: URL) throws {
        let data = try Data(contentsOf: url)
        game = try JSONDecoder().decode(Game.self, from: data)
    }

    func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(game)
        try data.write(to: url, options: .atomic)
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
}

private extension ViewController {
    var canUndo: Bool {
        game.inProgress && (game.playerIsHuman() || game.playerIsHuman(game.turn.other))
    }

    func updateUI() {
        setControl(undoButton, enabled: canUndo)
        setControl(resetButton, enabled: game.inProgress)
        boardView?.flipBlackPieces = game.blackIsHuman && Storage.shared.flipBlackWhenHuman
    }

    func setControl(_ control: UIControl?, enabled: Bool) {
        control?.isEnabled = enabled
        control?.alpha = enabled ? 1 : 0.5
    }

    func update() {
        let gameState = game.state
        switch gameState {
        case .checkMate, .staleMate, .insufficientMaterial:
            let message: String
            switch gameState {
            case .staleMate:
                message = "Stalemate: Nobody wins"
            case .insufficientMaterial:
                message = "Insufficient material: Nobody wins"
            case .checkMate:
                message = "Checkmate: \(game.turn.other) wins"
            case .check, .idle:
                preconditionFailure()
            }
            let alert = UIAlertController(
                title: "Game Over",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        case .check:
            boardView?.pulsePiece(at: game.kingPosition(for: game.turn)) {
                self.makeComputerMove()
            }
        case .idle:
            makeComputerMove()
        }
    }

    func pause() {
        isPaused = true
        switch game.state {
        case .check, .idle:
            let alert = UIAlertController(
                title: "Game in Progress",
                message: "\(game.turn.rawValue.capitalized)'s turn",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Resume", style: .default) { _ in
                self.isPaused = false
                self.update()
            })
            alert.addAction(UIAlertAction(title: "Restart", style: .default) { _ in
                self.isPaused = false
                self.resetGame()
            })
            present(alert, animated: true)
        case .checkMate, .staleMate, .insufficientMaterial:
            update()
        }
    }

    func setSelection(_ position: Position?) {
        let moves = position.map(game.movesForPiece(at:)) ?? []
        UIView.animate(withDuration: 0.2, animations: {
            self.boardView?.selection = position
            self.boardView?.moves = moves
        })
    }

    func makeComputerMove() {
        if !isPaused, !game.playerIsHuman(), let move = game.nextMove(for: game.turn) {
            makeMove(move)
        } else {
            updateUI()
        }
    }

    func makeMove(_ move: Move) {
        guard let boardView = boardView else {
            return
        }
        let oldGame = game
        game.makeMove(move)
        let board1 = game.board
        let kingPosition = game.kingPosition(for: oldGame.turn)
        let wasInCheck = game.pieceIsThreatened(at: kingPosition)
        let wasPromoted = !wasInCheck && game.canPromotePiece(at: move.to)
        let wasHuman = oldGame.playerIsHuman()
        if wasInCheck {
            game = oldGame
        }
        let board2 = game.board
        UIView.animate(withDuration: 0.4, animations: {
            boardView.selection = nil
            boardView.board = board1
            boardView.moves = []
            self.updateUI()
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
                    self.game.promotePiece(at: move.to, to: .queen)
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
                        self.game.promotePiece(at: move.to, to: piece)
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

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in _: UIPickerView) -> Int {
        1
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        Theme.allCases.count
    }

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        Theme.allCases[row].rawValue
    }

    func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        boardView?.theme = Theme.allCases[row]
    }
}
