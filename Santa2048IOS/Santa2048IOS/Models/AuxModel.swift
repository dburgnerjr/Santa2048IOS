//
//  AuxModel.swift
//  Santa2048IOS
//
//  Created by Daniel Burgner on 11/12/17.
//  Copyright © 2017 Daniel Burgner. All rights reserved.
//

import Foundation

enum MoveDirection {
    case Up
    case Down
    case Left
    case Right
}

struct MoveCommand {
    var direction: MoveDirection
    var completion: (Bool) -> ()
    init(d: MoveDirection, c: @escaping (Bool) -> ()) {
        direction = d
        completion = c
    }
}

enum MoveOrder {
    case SingleMoveOrder(source: Int, destination: Int, value: Int, wasMerge: Bool)
    case DoubleMoveOrder(firstSource: Int, secondSource: Int, destination: Int, value: Int)
}

enum TileObject {
    case Empty
    case Tile(Int)
}

enum ActionToken {
    case NoAction(source: Int, value: Int)
    case Move(source: Int, value: Int)
    case SingleCombine(source: Int, value: Int)
    case DoubleCombine(source: Int, second: Int, value: Int)
    
    func getValue() -> Int {
        switch self {
            case let .NoAction(_, v): return v
            case let .Move(_, v): return v
            case let .SingleCombine(_, v): return v
            case let .DoubleCombine(_, _, v): return v
        }
    }
    
    func getSource() -> Int {
        switch self {
        case let .NoAction(_, s): return s
        case let .Move(_, s): return s
        case let .SingleCombine(_, s): return s
        case let .DoubleCombine(_, _, s): return s
        }
    }
}

struct SquareGameboard<T> {
    let dimension: Int
    var boardArray: [T]
    
    init(dimension d: Int, initialValue: T) {
        dimension = d
        boardArray = [T](repeating: initialValue, count: d*d)
    }
    
    subscript(row: Int, col: Int) -> T {
        get {
            assert(row >= 0 && row < dimension)
            assert(col >= 0 && col < dimension)
            return boardArray[row * dimension + col]
        }
        set {
            assert(row >= 0 && row < dimension)
            assert(col >= 0 && col < dimension)
            boardArray[row * dimension + col] = newValue
        }
    }
    
    mutating func setAll(item: T) {
        for i in 0..<dimension {
            for j in 0..<dimension {
                self[i, j] = item
            }
        }
    }
}
