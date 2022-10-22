//
//  BoardView.swift
//  Chess
//
//  Created by Nick Lockwood on 22/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import UIKit

private extension Piece {
    var imageName: String {
        return "\(type.rawValue)_\(color.rawValue)"
    }
}

protocol BoardViewDelegate: AnyObject {
    func boardView(_ boardView: BoardView, didTap position: Position)
}

class BoardView: UIView {
    weak var delegate: BoardViewDelegate?

    private(set) var squares: [UIImageView] = []
    private(set) var pieces: [String: UIImageView] = [:]
    private(set) var moveIndicators: [UIView] = []

    var board = Board() {
        didSet { updatePieces() }
    }

    var selection: Position? {
        didSet { updateSelection() }
    }

    var moves: [Position] = [] {
        didSet { updateMoveIndicators() }
    }

    func jigglePiece(at position: Position) {
        if let piece = board.piece(at: position) {
            pieces[piece.id]?.jiggle()
        }
    }

    func pulsePiece(at position: Position, completion: (() -> Void)?) {
        if let piece = board.piece(at: position) {
            pieces[piece.id]?.pulse(completion: completion)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedSetup()
    }

    private func sharedSetup() {
        for i in 0 ..< 8 {
            for j in 0 ..< 8 {
                let white = i % 2 == j % 2
                let image = UIImage(named: white ? "square_white": "square_black")
                let view = UIImageView(image: image)
                squares.append(view)
                addSubview(view)
            }
        }

        for row in board.pieces {
            for piece in row {
                guard let piece = piece else {
                    continue
                }
                let view = UIImageView()
                view.contentMode = .scaleAspectFit
                pieces[piece.id] = view
                addSubview(view)
            }
        }

        for _ in 0 ..< 8 {
            for _ in 0 ..< 8 {
                let view = UIView()
                view.backgroundColor = .white
                moveIndicators.append(view)
                addSubview(view)
            }
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    @objc private func didTap(_ gesture: UITapGestureRecognizer) {
        let size = squareSize
        let location = gesture.location(in: self)
        let position = Position(
            x: Int(location.x / size.width),
            y: Int(location.y / size.height)
        )
        delegate?.boardView(self, didTap: position)
    }

    private func updatePieces() {
        var usedIDs = Set<String>()
        let size = squareSize
        for (i, row) in board.pieces.enumerated() {
            for (j, piece) in row.enumerated() {
                guard let piece = piece, let view = pieces[piece.id] else {
                    continue
                }
                usedIDs.insert(piece.id)
                view.image = UIImage(named: piece.imageName)
                view.frame = frame(x: j, y: i, size: size)
                view.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0)
            }
        }
        for (id, view) in pieces where !usedIDs.contains(id) {
            view.alpha = 0
        }
        updateSelection()
    }

    private func updateSelection() {
        for (i, row) in board.pieces.enumerated() {
            for (j, piece) in row.enumerated() {
                guard let piece = piece, let view = pieces[piece.id] else {
                    continue
                }
                view.alpha = selection == Position(x: j, y: i) ? 0.5 : 1
            }
        }
    }

    private func updateMoveIndicators() {
        let size = squareSize
        for i in 0 ..< 8 {
            for j in 0 ..< 8 {
                let position = Position(x: j, y: i)
                let view = moveIndicators[i * 8 + j]
                view.frame = frame(x: j, y: i, size: size)
                view.layer.cornerRadius = size.width / 2
                view.layer.transform = CATransform3DMakeScale(0.2, 0.2, 0)
                view.alpha = moves.contains(position) ? 0.5 : 0
            }
        }
    }

    private var squareSize: CGSize {
        let bounds = self.bounds.size
        return CGSize(width: ceil(bounds.width / 8), height: ceil(frame.height / 8))
    }

    private func frame(x: Int, y: Int, size: CGSize) -> CGRect {
        let offset = CGPoint(x: CGFloat(x) * size.width, y: CGFloat(y) * size.height)
        return CGRect(origin: offset, size: size)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = squareSize
        for i in 0 ..< 8 {
            for j in 0 ..< 8 {
                squares[i * 8 + j].frame = frame(x: j, y: i, size: size)
            }
        }
        updatePieces()
        updateMoveIndicators()
    }
}

private extension UIImageView {
    func pulse(
        scale: CGFloat = 1.5,
        duration: TimeInterval = 0.6,
        completion: (() -> Void)? = nil
    ) {
        let pulseView = UIImageView(frame: frame)
        pulseView.image = image
        superview?.addSubview(pulseView)
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                pulseView.transform = .init(scaleX: 2, y: 2)
                pulseView.alpha = 0
            }, completion: { _ in
                pulseView.removeFromSuperview()
                completion?()
            }
        )
    }
}
