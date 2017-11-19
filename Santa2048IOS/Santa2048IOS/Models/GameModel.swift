//
//  GameModel.swift
//  Santa2048IOS
//
//  Created by Daniel Burgner on 11/12/17.
//  Copyright © 2017 Daniel Burgner. All rights reserved.
//

import UIKit

protocol GameModelProtocol : class {
    func scoreChange(score: Int)
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int)
    func moveTwoTile(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int)
    func insertTile(location: (Int, Int), value: Int)
}

class GameModel: NSObject {
    let dimension: Int
    let threshold: Int
    
    var score: Int = 0 {
        didSet {
            delegate.scoreChanged(score)
        }
    }
    var gameboard: SquareGameboard<TileObject>
    
    let delegate: GameModelProtocol
    
    var queue: [MoveCommand]
    var timer: NSTimer

    let maxCommands = 100
    let queueDelay = 0.3
    
    init(dimension d: Int, threshold t: Int, delegate: GameModelProtocol) {
        dimension = d
        threshold = t
        self.delegate = delegate
        queue = [MoveCommand]()
        timer = NSTimer()
        gameboard = SquareGameboard(dimension: d, initialValue: .Empty)
        super.init()
    }
    
    func reset() {
        score = 0
        gameboard.setAll(.Empty)
        queue.removeAll(keepCapacity: true)
        timer.invalidate()
    }
    
    func queueMove(direction: MoveDirection, completion: (Bool) -> ()) {
        if queue.count > maxCommands {
            return
        }

        let command = MoveCommand(d: direction, c: completion)
        queue.append(command)
        if (!timer.valid) {
            timerFired(timer)
        }
    }
    
    func timerFired(timer: NSTimer) {
        if queue.count == 0 {
            return
        }
        
        var changed = false
        while queue.count > 0 {
            let command = queue[0]
            queue.removeAtIndex(0)
            changed = preformMove(command.direction)
            command.completion(changed)
            if (changed) {
                break
            }
            if changed {
                self.timer = NSTimer.scheduledTimerWithTimeInterval
                (queueDelay, target: self, selector: Selector("timerFired:"),
                 userInfo: nil, repeats: false)
            }
        }
    }
    
    func insertTile(pos: (Int, Int), value: Int) {
        let (x, y) = pos
        switch gameboard[x, y] {
            case .Empty:
                gameboard[x, y] = TileObject.Tile(value)
                delegate.insertTile(pos, value: value)
            case .Tile:
                break
        }
    }
    
    func insertTileAtRandomLocation(value: Int) {
        let openSpots = gameboardEmptySpots()
        if openSpots.count == 0 {
            // No more open spots, don't even bother
            return
        }
        // Randomly select an open spot, and put a new tile there
        let idx = Int(arc4random_uniform(UInt32(openSpots.count-1)))
        let (x, y) = openSpots[idx]
        insertTile((x, y), value: value)
    }
    
    func gameboardEmptySpots() -> [(Int, Int)] {
        var buffer = Array<(Int, Int)>()
        for i in 0..<dimension {
            for j in 0..<dimension {
                switch gameboard[i, j] {
                    case .Empty:
                        buffer += [(i, j)]
                    case .Tile:
                        break
                }
            }
        }
    }
    
    func gameboardFull() -> Bool {
        return gameboardEmptySpots().count == 0
    }
    
    func tileBelowHasSameValue(loc: (Int, Int), _ value: Int) -> Bool {
        let (x, y) = loc
        if y == dimension - 1 {
            return false
        }
        switch gameboard[x, y + 1] {
            case let .Tile(v):
                return v = value
            default:
                return false
        }
    }
    
    func tileToRightHasSameValue(loc: (Int, Int), _ value: Int) -> Bool {
        let (x, y) = loc
        if x == dimension - 1 {
            return false
        }
        switch gameboard[x + 1, y] {
            case let .Tile(v):
                return v = value
            default:
                return false
        }
    }
    
    func userHasLost() -> Bool {
        if !gameboardFull() {
            // Player can't lose before filling up the board
            return false
        }
        
        // run through all tiles and check for possible moves
        for i in 0..<dimension {
            for j in 0..<dimension {
                switch gameboard[i, j] {
                    case .Empty:
                        assert(false, "Gameboard reported itself as full, but we still found an empty tile. This is a logic error.")
                    case let .Tile(v):
                        if self.tileBelowHasSameValue(loc: (i, j), v) || self.tileToRightHasSameValue(loc: (i, j), v) {
                            return false
                        }
                }
            }
        }
        return true
    }
    
    func userHasWon() -> (Bool, (Int, Int)?) {
        for i in 0..<dimension {
            for j in 0..<dimension {
                // Look for a tile with the winning score or greater
                switch gameboard[i, j] {
                    case let .Tile(v) where v >= threshold:
                        return (true, (i, j))
                    default:
                        continue
                }
            }
        }
        return (false, nil)
    }
    
    func performMove(direction: MoveDirection) -> Bool {
        let coordinateGenerator: (Int) -> [(Int, Int)] = { (iteration: Int) -> [(Int, Int)] in
            var buffer = Array<(Int, Int)>(count: self.dimension, repeatedValue: (0, 0))
            for i in 0..<self.dimension {
                switch direction {
                    case .Up:
                        buffer[i] = (i, iteration)
                    case .Down:
                        buffer[i] = (self.dimension - i - 1, iteration)
                    case .Left:
                        buffer[i] = (iteration, i)
                    case .Right:
                        buffer[i] = (iteration, self.dimension - i - 1)
                }
            }
            return buffer
        }
        
        var atLeastOneMove = false
        for i in 0..<dimension {
            let coords = coordinateGenerator
            
            let tiles = coords.map() { (c: (Int, Int)) -> TileObject in
                let (x, y) = c
                return self.gameboard[x, y]
            }
            let orders = merge(tiles)
            atLeastOneMove = orders.count > 0 ? true : atLeastOneMove
            
            // write back the results
            for object in orders {
                switch object {
                    case let MoveOrder.SingleMoveOrder(s, d, v, wasMerge):
                        // Perform a single-tile move
                        let (sx, sy) = coords[s]
                        let (dx, dy) = coords[d]
                        if (wasMerge) {
                            score += v
                        }
                        gameboard[sx, sy] = TileObject.Empty
                        gameboard[dx, dy] = TileObject.Tile(v)
                        delegate.moveOneTile(coords[s], to: coords[d], value: v)
                    case let MoveOrder.DoubleMoveOrder(s1, s2, d, v):
                        // Perform a simultaneous two-tile move
                        let (s1x, s1y) = coords[s1]
                        let (s2x, s2y) = coords[s2]
                        let (dx, dy) = coords[d]
                        score += v
                        gameboard[s1x, s1y] = TileObject.Empty
                        gameboard[s2x, s2y] = TileObject.Empty
                        gameboard[dx, dy] = TileObject.Tile(v)
                        delegate.moveTwoTiles((coords[s1], coords[s2]), to: coords[d], value: v)
                }
            }
        }
        return atLeastOneMove
    }
    
    func condense(group: [TileObject]) -> [ActionToken] {
        var tokenBuffer = [ActionToken]()
        for (idx, tile) in enumerate(group) {
            switch tile {
                case let .Tile(value) where tokenBuffer.count == idx:
                    tokenBuffer.append(ActionToken.NoAction(source: idx, value: value))
                case let .Tile(value):
                    tokenBuffer.append(ActionToken.Move(source: idx, value: value))
                default:
                    break
            }
        }
        return tokenBuffer;
    }
    
    class func quiescentTileStillQuiescent(inputPosition: Int, outputLength: Int, originalPosition: Int) -> Bool {
        return (inputPosition == outputLength) && (originalPosition == inputPosition)
    }
    
    func collapse(group: [ActionToken]) -> [ActionToken] {
        var tokenBuffer = [ActionToken]()
        var skipNext = false
        for (idx, token) in enumerate(group) {
            if skipNext {
                skipNext = false
                continue
            }
            switch token {
                case .SingleCombine:
                    assert(false, "Cannot have single combine token in input")
                case .DoubleCombine:
                    assert(false, "Cannot have double combine token in input")
                case let .NoAction(s, v)
                    where(idx < group.count - 1
                        && v == group[idx + 1].getValue()
                        && GameModel.quiescentTileStillQuiescent(inputPosition: idx, outputLength: tokenBuffer.count, originalPosition: s)):
                    let next = group[idx + 1]
                    let nv = v + group[idx + 1].getValue()
                    skipNext = true
                    tokenBuffer.append(ActionToken.SingleCombine(source: next.getSource(), value: nv))
                case let t where (idx < group.count - 1 && t.getValue() == group[idx + 1].getValue()):
                    let next = group[idx + 1]
                    let nv = t.getValue() + group[idx + 1].getValue()
                    skipNext = true
                    tokenBuffer.append(ActionToken.DoubleCombine(source: t.getSource(), second: next.getSource(), value: nv))
                case let .NoAction(s, v) where !GameModel.quiescentTileStillQuiescent(inputPosition: idx, outputLength: tokenBuffer.count, originalPosition: s):
                    tokenBuffer.append(ActionToken.Move(source: s, value: v))
                case let .NoAction(s, v):
                    tokenBuffer.append(ActionToken.NoAction(source: s, value: v))
                case let .Move(s, v):
                    tokenBuffer.append(ActionToken.Move(source: s, value: v))
                default:
                    break
            }
        }
        return tokenBuffer
    }
    
    func convert(group: [ActionToken]) -> [MoveOrder] {
        var moveBuffer = [MoveOrder]()
        for (idx, t) in enumerate(group) {
            switch t {
                case let .Move(s, v):
                    moveBuffer.append(MoveOrder.SingleMoveOrder(source: s, destination: idx, value: v, wasMerge: false))
                case let .SingleCombine(s, v):
                    moveBuffer.append(MoveOrder.SingleMoveOrder(source: s, destination: idx, value: v, wasMerge: true))
                case let .DoubleCombine(s1, s2, v):
                    moveBuffer.append(MoveOrder.DoubleMoveOrder(firstSource: s1, secondSource: s2, destination: idx, value: v))
                default:
                    break
            }
        }
        return moveBuffer
    }
    
    func merge(group: [TileObject]) -> [MoveOrder] {
        return convert(collapse(condense(group)))
    }
}



















