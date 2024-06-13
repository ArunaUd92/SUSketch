//
//  File.swift
//  
//
//  Created by Aruna Udayanga on 23/04/2024.
//

import SwiftUI

enum DrawingTool: String, CaseIterable, Identifiable {
    case pen
    case eraser
    case brush
    case fill
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .pen: return "Pen"
        case .eraser: return "Eraser"
        case .brush: return "Brush"
        case .fill: return "Fill"
        }
    }
    
    var iconName: String {
        switch self {
        case .pen: return "pencil"
        case .eraser: return "eraser"
        case .brush: return "paintbrush"
        case .fill: return "eyedropper"
        }
    }
}

struct ShapeElement: Identifiable {
    let id: UUID = UUID()
    var type: ShapeType
    var position: CGPoint
    var size: CGSize
    var color: Color
    var isSelected: Bool = false
    
    enum ShapeType {
        case triangle, rectangle, circle, oval, square
        
        var description: String {
            switch self {
            case .triangle: return "Triangle"
            case .rectangle: return "Rectangle"
            case .circle: return "Circle"
            case .oval: return "Oval"
            case .square: return "Square"
            }
        }
    }
}


