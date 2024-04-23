//
//  DrawingData.swift
//
//
//  Created by Aruna Udayanga on 23/04/2024.
//

import SwiftUI

public class DrawingData: ObservableObject {
    @Published var paths: [(path: Path, color: Color, isFilled: Bool)] = []
    @Published var currentTool: DrawingTool = .pen
    var history: [(path: Path, color: Color, isFilled: Bool)] = []

    func addPath(_ path: Path, color: Color, isFilled: Bool = false) {
        paths.append((path, color, isFilled))
    }

    func undo() {
        if let last = paths.popLast() {
            history.append(last)
        }
    }

    func redo() {
        if let redoPath = history.popLast() {
            paths.append(redoPath)
        }
    }

    func clear() {
        paths.removeAll()
        history.removeAll()
    }
}
