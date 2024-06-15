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
    @State private var cursorLocation: CGPoint = .zero

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
                    lastLocation: $lastLocation,
                    cursorLocation: $cursorLocation
                )
                // Footer for additional controls or status.
                SketchFooterView(drawingData: drawingData)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SUSketchView()
    }
}

struct SketchBodyView: View {
    @ObservedObject var drawingData: DrawingData // Observes drawing data for changes.
    @Binding var currentPath: Path // Binding to the current drawing path.
    @Binding var lastLocation: CGPoint? // Binding to track last touch location.
    @State private var inputImage: UIImage? // Holds the image selected from the picker.
    @Binding var cursorLocation: CGPoint // Binding to track cursor location.
    
    
    var body: some View {
        ZStack {
            Canvas { context, size in
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
                
//                // Render each shape with appropriate style.
//                for shape in drawingData.shapes {
//                    let rect = CGRect(origin: shape.position, size: shape.size)
//                    switch shape.type {
//                    case .triangle:
//                        let path = Path { path in
//                            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
//                            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
//                            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
//                            path.closeSubpath()
//                        }
//                        context.stroke(path, with: .color(shape.color))
//                    case .rectangle:
//                        context.stroke(Rectangle().path(in: rect), with: .color(shape.color))
//                    case .circle:
//                        context.stroke(Circle().path(in: rect), with: .color(shape.color))
//                    case .oval:
//                        context.stroke(Ellipse().path(in: rect), with: .color(shape.color))
//                    case .square:
//                        let side = min(rect.width, rect.height)
//                        let squareRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: side, height: side)
//                        context.stroke(Rectangle().path(in: squareRect), with: .color(shape.color))
//                    }
//
//                }
            }
            
            // Render draggable and resizable shape elements.
            ForEach(drawingData.shapes.indices, id: \.self) { index in
                let shape = drawingData.shapes[index]
                GeometryReader { geometry in
                    let rect = CGRect(origin: shape.position, size: shape.size)
                    let handleSize: CGFloat = 20
                    let handleOffset: CGSize = CGSize(width: shape.size.width + handleSize / 2, height: shape.size.height + handleSize / 2)
                    
                    ZStack {
                        // Shape view
                        Path { path in
                            switch shape.type {
                            case .triangle:
                                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                                path.closeSubpath()
                            case .rectangle:
                                path.addRect(rect)
                            case .circle:
                                path.addEllipse(in: rect)
                            case .oval:
                                path.addEllipse(in: rect)
                            case .square:
                                let side = min(rect.width, rect.height)
                                let squareRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: side, height: side)
                                path.addRect(squareRect)
                            }
                        }
                        .stroke(shape.color)
                        .position(shape.position)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    drawingData.shapes[index].position = value.location
                                }
                        )
                        
                        // Resize handle
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: handleSize, height: handleSize)
                            .position(x: shape.position.x + handleOffset.width, y: shape.position.y + handleOffset.height)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newSize = CGSize(width: value.location.x - shape.position.x - handleSize / 2, height: value.location.y - shape.position.y - handleSize / 2)
                                        drawingData.shapes[index].size = newSize
                                    }
                            )
                    }
                }
            }

            
            // Render draggable text elements.
            ForEach(drawingData.texts.indices, id: \.self) { index in
                let textElement = drawingData.texts[index]
                Text(textElement.text)
                    .font(.system(size: textElement.fontSize))
                    .foregroundColor(textElement.color)
                    .position(textElement.position)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                drawingData.texts[index].position = value.location
                            }
                    )
                    .onTapGesture {
                        for i in 0..<drawingData.texts.count {
                            drawingData.texts[i].isSelected = false
                        }
                        drawingData.texts[index].isSelected = true
                    }
            }
            
            // Display the cursor based on the selected tool
            if drawingData.currentTool != .fill {
                cursorView
                    .position(cursorLocation)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    cursorLocation = value.location // Update cursor location
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
                    case .eraser, .fill:
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
                }
        )
        .contentShape(Rectangle())
        
    }
    
    private var cursorView: some View {
        Group {
            switch drawingData.currentTool {
            case .pen:
                Image(systemName: "pencil.tip")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
            case .eraser:
                Image(systemName: "eraser")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.red)
            case .brush:
                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 24, height: 24)
            default:
                EmptyView()
            }
        }
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
    @State private var draggedElement: TextElement?
    @State private var dropAreaIndex: Int?
    @State private var dragOffset: CGSize = .zero
    @State private var showShapeSelection: Bool = false // State variable for shape selection modal
    
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
                
                // Show shape selection modal button
                Button(action: {
                    showShapeSelection = true
                }) {
                    Image(systemName: "square.on.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .sheet(isPresented: $showShapeSelection) {
                    ShapeSelectionView(drawingData: drawingData, isPresented: $showShapeSelection)
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
        print("Adding text element: \(inputText)")
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

// Shape selection modal view
struct ShapeSelectionView: View {
    @ObservedObject var drawingData: DrawingData
    @Binding var isPresented: Bool // Binding to control the modal's visibility
    
    var body: some View {
        VStack {
            Text("Select Shape")
                .font(.headline)
                .padding()
            
            ForEach([ShapeElement.ShapeType.triangle, ShapeElement.ShapeType.rectangle, ShapeElement.ShapeType.circle, ShapeElement.ShapeType.oval, ShapeElement.ShapeType.square], id: \.self) { shape in
                Button(action: {
                    drawingData.addShape(shape)
                    isPresented = false // Dismiss the modal after selecting a shape
                }) {
                    HStack {
                        Text(shape.description)
                            .font(.title2)
                            .foregroundColor(drawingData.currentShape == shape ? .blue : .primary)
                        Spacer()
                    }
                    .padding()
                    .background(drawingData.currentShape == shape ? Color(.systemGray5) : Color.clear)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

struct SketchFooterView: View {
    @ObservedObject var drawingData: DrawingData // Observes changes in drawing data.
    
    var body: some View {
        HStack(spacing: 20) {
            // Undo button with icon
            Button(action: {
                drawingData.undo()
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            // Redo button with icon
            Button(action: {
                drawingData.redo()
            }) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            // Clear button with icon
            Button(action: {
                drawingData.clear()
            }) {
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            
           // Spacer()
            
            // Drawing tools buttons
            ForEach([DrawingTool.pen, DrawingTool.eraser, DrawingTool.brush, DrawingTool.fill], id: \.self) { tool in
                Button(action: {
                    drawingData.currentTool = tool
                }) {
                    VStack {
                        Image(systemName: tool.iconName)
                            .font(.title2)
                            .foregroundColor(drawingData.currentTool == tool ? .blue : .primary)
                        Text(tool.description)
                            .font(.caption)
                            .foregroundColor(drawingData.currentTool == tool ? .blue : .primary)
                    }
                }
            }
            
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding([.leading, .trailing, .bottom])
        
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
