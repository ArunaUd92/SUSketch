//
//  File.swift
//  
//
//  Created by Aruna Udayanga on 23/04/2024.
//

enum DrawingTool: CustomStringConvertible {
    case pen, eraser, stamp, fill, brush
    
    var description: String {
        switch self {
        case .pen:
            return "Pen"
        case .eraser:
            return "Eraser"
        case .stamp:
            return "Stamp"
        case .fill:
            return "Fill"
        case .brush:
            return "Brush"
        }
    }
}

