//
//  DrawingData.swift
//
//
//  Created by Aruna Udayanga on 23/04/2024.
//

import SwiftUI

struct TextElement: Identifiable {
    let id: UUID = UUID()
    var text: String
    var position: CGPoint
    var color: Color
    var fontSize: CGFloat
    var isSelected: Bool = false
}

// Observable class to manage and update drawing data.
public class DrawingData: ObservableObject {
    @Published var paths: [(path: Path, color: Color, isFilled: Bool, lineWidth: CGFloat)] = [] // Stores drawn paths.
    @Published var currentTool: DrawingTool = .pen // Active drawing tool.
    @Published var penColor: Color = .black // Default color for pen.
    @Published var penWidth: CGFloat = 1.0 // Default width for pen.
    @Published var brushWidth: CGFloat = 10.0 // Default width for brush.
    @Published var image: Image? = nil // Optional image that can be added to the canvas.
    @Published var texts: [TextElement] = [] // Array of text elements.

    // Computed property to adjust the line width based on the current tool.
    var currentWidth: CGFloat {
        get {
            switch currentTool {
            case .pen:
                return penWidth
            case .brush:
                return brushWidth
            default:
                return 1.0 // Default width for other tools.
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
    
    // Array to store paths for undo functionality.
    var history: [(path: Path, color: Color, isFilled: Bool, lineWidth: CGFloat)] = []
    
    // Adds a path to the paths array.
    func addPath(_ path: Path, color: Color, isFilled: Bool = false, lineWidth: CGFloat = 5.0) {
        paths.append((path, color, isFilled, lineWidth))
    }
    
    // Undo the last drawing action.
    func undo() {
        if let last = paths.popLast() {
            history.append(last)
        }
    }
    
    // Redo the last undone drawing action.
    func redo() {
        if let redoPath = history.popLast() {
            paths.append(redoPath)
        }
    }
    
    // Clears all drawing data.
    func clear() {
        paths.removeAll()
        history.removeAll()
    }
}

