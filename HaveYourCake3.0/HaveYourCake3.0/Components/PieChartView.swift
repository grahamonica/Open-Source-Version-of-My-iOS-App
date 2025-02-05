//
//  PieChartView.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import SwiftUI

struct PieChartView: View {
    var slices: [PieSliceData]
    var images: [Image]
    var onSliceTapped: (Int) -> Void
    var onSliceLongPressed: (Int) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                plateImage(geometry: geometry)

                if !slices.isEmpty {
                    drawSlices(geometry: geometry)
                    drawLabels(geometry: geometry)
                    drawSliceBorders(geometry: geometry)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }

    // MARK: - Plate Image
    private func plateImage(geometry: GeometryProxy) -> some View {
        Image("altplate")// Image may need to be changed
            .resizable()
            .scaledToFit()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }

    // MARK: - Draw Slices
    private func drawSlices(geometry: GeometryProxy) -> some View {
        ForEach(0..<min(slices.count, images.count), id: \.self) { index in
            drawSlice(index: index, geometry: geometry)
        }
    }

    // MARK: - Draw Single Slice
    private func drawSlice(index: Int, geometry: GeometryProxy) -> some View {
        let slice = slices[index]

        return PieSlice(startAngle: slice.startAngle, endAngle: slice.endAngle)
            .fill(Color.clear)
            .overlay(
                images[index]
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.9)
                    .clipped()
                    .mask(PieSlice(startAngle: slice.startAngle, endAngle: slice.endAngle)
                    )
            )
            .contentShape(PieSlice(startAngle: slice.startAngle, endAngle: slice.endAngle))
            .gesture(
                TapGesture()
                    .onEnded {
                        onSliceTapped(index) // Correctly handles tap to navigate
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.8)
                    .onEnded { _ in
                        onSliceLongPressed(index) // Handles long press action
                    }
            )
    }

    // MARK: - Draw Labels
    private func drawLabels(geometry: GeometryProxy) -> some View {
        ForEach(0..<slices.count, id: \.self) { index in
            let slice = slices[index]
            let position = labelPosition(for: slice, in: geometry.size)
            let fontSize = max(10, 24 - CGFloat(slices.count)) // Ensures a minimum readable font size

            ZStack {
                // Measure text width dynamically
                Text(slice.label)
                    .font(.custom("Palatino", size: fontSize).weight(.bold))
                    .background(GeometryReader { textGeometry in
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Constants.Colors.mainBackground.opacity(0.9)) // blended background
                            .frame(width: textGeometry.size.width + 20, height: textGeometry.size.height + 10) // Adaptive padding
                            .blur(radius: 8) // Adjust blur radius
                            .position(x: textGeometry.size.width / 2, y: textGeometry.size.height / 2)
                    })

                // Text layer
                Text(slice.label)
                    .font(.custom("Palatino", size: fontSize).weight(.bold))
                    .foregroundColor(Constants.Colors.mainText)
            }
            .position(position)
            .allowsHitTesting(false) // Ensure it doesn't interfere with taps
        }
    }

    // MARK: - Draw Thin Blurry Slice Borders
    private func drawSliceBorders(geometry: GeometryProxy) -> some View {
        ForEach(slices.indices, id: \.self) { index in
            let slice = slices[index]
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let startX = center.x + cos(slice.startAngle.radians) * geometry.size.width / 2 * 0.9
            let startY = center.y + sin(slice.startAngle.radians) * geometry.size.height / 2 * 0.9

            Path { path in
                path.move(to: center)
                path.addLine(to: CGPoint(x: startX, y: startY))
            }
            .stroke(Constants.Colors.separatorColor, lineWidth: 1)
            .blur(radius: 1)
        }
    }

    // MARK: - Label Position Helper
    private func labelPosition(for slice: PieSliceData, in size: CGSize) -> CGPoint {
        let midAngle = (slice.startAngle.radians + slice.endAngle.radians) / 2
        let radius = min(size.width, size.height) / 2 * 0.75 // Slightly inside the pie chart
        let x = size.width / 2 + cos(midAngle) * radius
        let y = size.height / 2 + sin(midAngle) * radius
        return CGPoint(x: x, y: y)
    }
}
