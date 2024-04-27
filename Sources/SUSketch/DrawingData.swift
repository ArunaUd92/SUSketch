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
    @Published var penWidth: CGFloat = 1.0 // Default pen width
    @Published var brushWidth: CGFloat = 10.0 // Default brush width
    
    // Computed property to return the current width based on the tool
    var currentWidth: CGFloat {
        get {
            switch currentTool {
            case .pen:
                return penWidth
            case .brush:
                return brushWidth
            default:
                return 1.0 // Default for other tools
            }
        }
        set {
            switch currentTool {
            case .pen:
                penWidth = newValue
            case .brush:
                brushWidth = newValue
            default:
                break
            }
        }
    }
    
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

