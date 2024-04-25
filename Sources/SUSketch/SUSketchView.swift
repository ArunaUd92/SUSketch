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
    
    public init() {}
    
    public var body: some View {
        VStack {
            HStack {
                    ColorPicker("Pen Color", selection: $drawingData.penColor)
                    Slider(value: $drawingData.penWidth, in: 1...20)
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
                        case .pen:
                            currentPath.addLine(to: value.location)
                        case .eraser:
                            currentPath.addLine(to: value.location)
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
                        let lineWidth = isErasing ? 10 : drawingData.penWidth // Use a default width for eraser
                        let isFilled = drawingData.currentTool == .fill
                        drawingData.addPath(currentPath, color: color, isFilled: isFilled, lineWidth: lineWidth)
                        currentPath = Path()
                    }
            )
            HStack {
                Button("Undo") { drawingData.undo() }
                Button("Redo") { drawingData.redo() }
                Button("Clear") { drawingData.clear() }
                ForEach([DrawingTool.pen, DrawingTool.eraser, DrawingTool.stamp, DrawingTool.fill], id: \.self) { tool in
                    Button(tool.description) {
                        drawingData.currentTool = tool
                    }
                }
            }
        }
    }
}
