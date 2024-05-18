//
//  File.swift
//
//
//  Created by Aruna Udayanga on 23/04/2024.
//

import SwiftUI
import PhotosUI

// SwiftUI view for a sketching app.
public struct SUSketchView: View {
    @StateObject private var drawingData = DrawingData() // Manages drawing data.
    @State private var currentPath = Path() // Current drawing path.
    @State private var lastLocation: CGPoint? // Last touch point.
    @State private var showImagePicker = false // Toggle for image picker.
    @State private var inputImage: UIImage? // Selected image.
    @State private var inputText: String = "" // User-entered text.
    @State private var showTextEditor: Bool = false // Toggle for text editor.
    @State private var textColor: Color = .black // Color for text.
    @State private var fontSize: CGFloat = 20 // Font size for text.

    public init() {} // Empty initializer for public struct.

    public var body: some View {
        GeometryReader { geometry in
            VStack {
                // Header for tools like text editor and image picker.
                SketchHeaderView(
                    showTextEditor: $showTextEditor,
                    inputText: $inputText,
                    textColor: $textColor,
                    fontSize: $fontSize,
                    showImagePicker: $showImagePicker,
                    inputImage: $inputImage,
                    drawingData: drawingData
                )
                // Main drawing area handling touch and drawing.
                SketchBodyView(
                    drawingData: drawingData,
                    currentPath: $currentPath,
                    lastLocation: $lastLocation
                )
                // Footer for additional controls or status.
                SketchFooterView(drawingData: drawingData)
            }
        }
    }
}

struct SketchBodyView: View {
    @ObservedObject var drawingData: DrawingData // Observes drawing data for changes.
    @Binding var currentPath: Path // Binding to the current drawing path.
    @Binding var lastLocation: CGPoint? // Binding to track last touch location.
    @State private var inputImage: UIImage? // Holds the image selected from the picker.
    
    var body: some View {
        Canvas { context, size in
            // Render each text element as an image in the drawing context.
            for textElement in drawingData.texts {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: textElement.fontSize),
                    .foregroundColor: UIColor(textElement.color)
                ]
                let attributedString = NSAttributedString(string: textElement.text, attributes: attributes)
                let textSize = attributedString.size()
                let textImage = attributedString.toImage(with: textSize)
                context.draw(textImage, in: CGRect(origin: textElement.position, size: textSize))
            }
            // Draw the input image if available.
            if let uiImage = inputImage {
                let image = Image(uiImage: uiImage)
                image.resizable().aspectRatio(contentMode: .fit).frame(width: size.width, height: size.height)
            }
            // Render background or foreground images and fills.
            if let image = drawingData.image {
                context.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            }
            if drawingData.currentTool == .fill {
                context.fill(Rectangle().path(in: CGRect(x: 0, y: 0, width: size.width, height: size.height)), with: .color(drawingData.penColor))
            }
            // Render each path with appropriate style.
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
                    // Handle drag for moving text or drawing with selected tool.
                    if let index = drawingData.texts.firstIndex(where: { $0.isSelected }) {
                        // Move selected text.
                        drawingData.texts[index].position = CGPoint(
                            x: drawingData.texts[index].position.x + value.translation.width,
                            y: drawingData.texts[index].position.y + value.translation.height
                        )
                    }
                    switch drawingData.currentTool {
                    case .pen, .brush:
                        if currentPath.isEmpty {
                            currentPath.move(to: value.startLocation)
                            lastLocation = value.startLocation
                        }
                        if drawingData.currentTool == .brush {
                            if let lastLocation = lastLocation {
                                let newPoint = value.location
                                let midPoint = CGPoint(x: (lastLocation.x + newPoint.x) / 2, y: (lastLocation.y + newPoint.y) / 2)
                                currentPath.addQuadCurve(to: midPoint, control: lastLocation)
                                currentPath.addLine(to: newPoint)
                            }
                        } else {
                            currentPath.addLine(to: value.location)
                        }
                        lastLocation = value.location
                    case .eraser, .stamp, .fill:
                        // Handle eraser, stamp, and fill tools.
                        currentPath.addLine(to: value.location)
                        lastLocation = value.location
                    }
                }
                .onEnded { _ in
                    // Finalize the drawing path when the gesture ends.
                    let isErasing = drawingData.currentTool == .eraser
                    let color = isErasing ? .white : drawingData.penColor
                    let lineWidth = isErasing ? 10 : drawingData.currentWidth
                    let isFilled = drawingData.currentTool == .fill
                    drawingData.addPath(currentPath, color: color, isFilled: isFilled, lineWidth: lineWidth)
                    currentPath = Path()
                    for i in 0..<drawingData.texts.count {
                        drawingData.texts[i].isSelected = false
                    }
                }
        )
        .contentShape(Rectangle())
    }
}

struct SketchHeaderView: View {
    @Binding var showTextEditor: Bool // Toggles visibility of the text editor.
    @Binding var inputText: String // Binds to the text input for annotations.
    @Binding var textColor: Color // Binds to the selected text color.
    @Binding var fontSize: CGFloat // Binds to the font size for text.
    @Binding var showImagePicker: Bool // Toggles the image picker visibility.
    @Binding var inputImage: UIImage? // Holds the selected image.
    @ObservedObject var drawingData: DrawingData // Observes changes in drawing data.
    
    var body: some View {
        VStack {
            // Top bar with text editor, image picker, and drawing tools
            HStack(spacing: 20) {
                // Toggle text editor button
                Button(action: {
                    showTextEditor.toggle()
                }) {
                    Image(systemName: "textformat")
                        .font(.title2)
                        .foregroundColor(showTextEditor ? .blue : .primary)
                }
                
                // Open image picker button
                Button(action: {
                    showImagePicker = true
                }) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
                    ImagePicker(image: $inputImage)
                }
                
                // Pen color picker
                ColorPicker("", selection: $drawingData.penColor)
                    .labelsHidden()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                // Pen or brush width slider
                if drawingData.currentTool == .pen {
                    Slider(value: $drawingData.penWidth, in: 1...6)
                        .frame(width: 100)
                } else if drawingData.currentTool == .brush {
                    Slider(value: $drawingData.brushWidth, in: 1...40)
                        .frame(width: 100)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Text editor view
            if showTextEditor {
                VStack {
                    // Text input field
                    TextField("Enter text here", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding([.top, .leading, .trailing])
                    
                    HStack {
                        // Text color picker
                        ColorPicker("Text Color", selection: $textColor)
                        
                        // Font size slider
                        Slider(value: $fontSize, in: 12...36, step: 1)
                            .frame(width: 100)
                            .padding([.leading, .trailing])
                        
                        // Add text element button
                        Button(action: {
                            addTextElement()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.large)
                                    .frame(height: 26)
                                Text("Add")
                                    .font(.system(size: 15))
                            }
                            .frame(height: 45)
                        }
                        .padding(.trailing)
                    }
                    .padding([.bottom, .leading, .trailing])
                }
                .background(Color(.systemGray5))
                .cornerRadius(10)
            }
        }
        .padding()
    }
    // Function to add a new text element to the drawing canvas.
    private func addTextElement() {
        let textElement = TextElement(text: inputText, position: CGPoint(x: 150, y: 150), color: textColor, fontSize: fontSize)
        drawingData.texts.append(textElement)
        showTextEditor = false
        inputText = "" // Resets the input field.
    }
    
    // Loads the selected image into the drawing data.
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        drawingData.image = Image(uiImage: inputImage)
    }
}

struct SketchFooterView: View {
    @ObservedObject var drawingData: DrawingData // Observes changes in drawing data.
    
    var body: some View {
        HStack {
            // Buttons for undo, redo, and clear actions.
            Button("Undo") { drawingData.undo() } // Undoes the last action.
            Button("Redo") { drawingData.redo() } // Redoes the last undone action.
            Button("Clear") { drawingData.clear() } // Clears all drawing data.

            // Dynamically creates buttons for each drawing tool.
            ForEach([DrawingTool.pen, DrawingTool.eraser, DrawingTool.brush, DrawingTool.fill], id: \.self) { tool in
                Button(tool.description) {
                    drawingData.currentTool = tool // Sets the current tool.
                }
            }
        }
    }
}

extension NSAttributedString {
    func toImage(with size: CGSize) -> Image {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        return Image(uiImage: image)
    }
}
