[![Travis](https://api.travis-ci.org/nicklockwood/Chess.svg?branch=master)](https://travis-ci.org/nicklockwood/Chess)
[![Platforms](https://img.shields.io/badge/platforms-iOS-lightgray.svg)]()
[![Swift 5.2](https://img.shields.io/badge/swift-5.2-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Twitter](https://img.shields.io/badge/twitter-@nicklockwood-blue.svg)](http://twitter.com/nicklockwood)

![Screenshot](Screenshot.png?raw=true)

Swift Chess
------------

This is a simple chess game for iPhone and iPad, designed for novice players.

It features a very simple AI that plays much like a beginner, looking only at the current state of the board and trying to either take an enemy piece or put them in check without immediately being taken.

You can choose between human vs human, human vs computer, or computer vs computer. Set both players to Computer to get a better sense of how it plays (spoiler: not well).

To-Do List
-----------

* Persist the game state when the app is closed
* Let user choose piece when pawn reaches other side instead of always promoting to a queen
* Add speed and intelligence settings for AI
* Detect draw conditions such as dead positions, insufficient material, repetition, etc
* Standard openings
