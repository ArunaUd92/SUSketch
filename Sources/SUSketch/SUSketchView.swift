//
//  File.swift
//  
//
//  Created by Aruna Udayanga on 23/04/2024.
//

import SwiftUI

public struct SUSketchView: View {
    @StateObject private var drawingData = DrawingData()
    @State private var currentPath = Path()
    @State private var lastLocation: CGPoint? = nil  // Add this to store the last location
    
    public init() {}
    
    public var body: some View {
        VStack {
            HStack {
                ColorPicker("Pen Color", selection: $drawingData.penColor)
                if drawingData.currentTool == .pen {
                    Slider(value: $drawingData.penWidth, in: 1...6)
                } else if drawingData.currentTool == .brush {
                    Slider(value: $drawingData.brushWidth, in: 1...40)
                }
            }
            .padding()
            Canvas { context, size in
                for (path, color, isFilled, lineWidth) in drawingData.paths {
                    if isFilled {
                        context.fill(path, with: .color(color))
                    } else {
                        context.stroke(path, with: .color(color), lineWidth: lineWidth)
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        switch drawingData.currentTool {
                        case .pen, .brush:
                            // If this is the start of the drag, set the initial point
                            if currentPath.isEmpty {
                                currentPath.move(to: value.startLocation)
                                lastLocation = value.startLocation
                            }
                            // If it's a brush stroke, use a quadratic curve
                            if drawingData.currentTool == .brush {
                                if let lastLocation = lastLocation {
                                    let newPoint = value.location
                                    let midPoint = CGPoint(x: (lastLocation.x + newPoint.x) / 2, y: (lastLocation.y + newPoint.y) / 2)
                                    currentPath.addQuadCurve(to: midPoint, control: lastLocation)
                                    currentPath.addLine(to: newPoint)  // This creates a more continuous stroke
                                }
                            } else {
                                currentPath.addLine(to: value.location)
                            }
                            lastLocation = value.location  // Update the last known location
                        case .eraser:
                            currentPath.addLine(to: value.location)
                            lastLocation = value.location
                        case .stamp:
                            // Implement stamp logic
                            break
                        case .fill:
                            //currentPath.addLine(to: value.location)  // Just collect the points
                            break
                        }
                    }
                    .onEnded { _ in
                        let isErasing = drawingData.currentTool == .eraser
                        let color = isErasing ? .white : drawingData.penColor
                        let lineWidth = isErasing ? 10 : drawingData.currentWidth // Use the appropriate width for the tool
                        let isFilled = drawingData.currentTool == .fill
                        self.lastLocation = nil
                        drawingData.addPath(currentPath, color: color, isFilled: isFilled, lineWidth: lineWidth)
                        currentPath = Path()
                    }
            )
            HStack {
                Button("Undo") { drawingData.undo() }
                Button("Redo") { drawingData.redo() }
                Button("Clear") { drawingData.clear() }
                ForEach([DrawingTool.pen, DrawingTool.eraser, DrawingTool.brush, DrawingTool.fill], id: \.self) { tool in
                    Button(tool.description) {
                        drawingData.currentTool = tool
                    }
                }
            }
        }
    }
}
