//
//  DrawingData.swift
//
//
//  Created by Aruna Udayanga on 23/04/2024.
//

import SwiftUI

public class DrawingData: ObservableObject {
    @Published var paths: [(path: Path, color: Color, isFilled: Bool, lineWidth: CGFloat)] = []
     @Published var currentTool: DrawingTool = .pen
     @Published var penColor: Color = .black
     @Published var penWidth: CGFloat = 5.0 // Default pen width
     var history: [(path: Path, color: Color, isFilled: Bool, lineWidth: CGFloat)] = []

     func addPath(_ path: Path, color: Color, isFilled: Bool = false, lineWidth: CGFloat = 5.0) {
         paths.append((path, color, isFilled, lineWidth))
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
