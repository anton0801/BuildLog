import SwiftUI

// MARK: - Material Calculator View
struct MaterialCalculatorView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode

    var preselectedRoom: Room? = nil
    var project: Project? = nil

    enum Step { case room, materialType, inputs, result }
    enum MaterialType: String, CaseIterable {
        case floorTiles    = "Floor Tiles / Flooring"
        case wallPaint     = "Wall Paint"
        case ceilingPaint  = "Ceiling Paint"
        case wallpaper     = "Wallpaper"
        case wallTiles     = "Wall Tiles"

        var icon: String {
            switch self {
            case .floorTiles:   return "square.grid.3x3"
            case .wallPaint:    return "paintbrush"
            case .ceilingPaint: return "cloud"
            case .wallpaper:    return "square.on.square"
            case .wallTiles:    return "square.grid.2x2"
            }
        }
    }

    @State private var step: Step = .room
    @State private var selectedRoom: Room? = nil
    @State private var selectedProject: Project? = nil
    @State private var manualLength = ""
    @State private var manualWidth = ""
    @State private var manualHeight = ""
    @State private var selectedType: MaterialType = .wallPaint

    // Extra inputs
    @State private var coveragePerLiter = "10"
    @State private var numberOfCoats = "2"
    @State private var doorCount = "0"
    @State private var windowCount = "0"
    @State private var rollWidth = "0.53"
    @State private var rollLength = "10.05"
    @State private var patternRepeat = "0"
    @State private var tileWidth = "30"
    @State private var tileHeight = "30"

    // Result
    @State private var calcResult: CalcResult? = nil
    @State private var showAddMaterial = false

    struct CalcResult {
        let value: Double
        let unit: String
        let steps: [(String, String)]  // (formula description, result string)
        let materialType: String
        let roomName: String
    }

    private var effectiveRoom: Room? { selectedRoom ?? preselectedRoom }
    private var roomLength: Double {
        if let r = effectiveRoom, let l = r.length { return l }
        return Double(manualLength.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var roomWidth: Double {
        if let r = effectiveRoom, let w = r.width { return w }
        return Double(manualWidth.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var roomHeight: Double {
        if let r = effectiveRoom, let h = r.height { return h }
        return Double(manualHeight.replacingOccurrences(of: ",", with: ".")) ?? 2.7
    }
    private var roomHasDimensions: Bool {
        roomLength > 0 && roomWidth > 0 && roomHeight > 0
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Step indicator
                stepIndicator

                ScrollView {
                    VStack(spacing: 20) {
                        switch step {
                        case .room:         roomStep
                        case .materialType: materialTypeStep
                        case .inputs:       inputsStep
                        case .result:       resultStep
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .background(AppColors.background)

                // Bottom navigation
                bottomNavBar
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Material Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppColors.primary)
                }
            }
            .sheet(isPresented: $showAddMaterial) {
                if let result = calcResult {
                    AddMaterialView(
                        isPresented: $showAddMaterial,
                        preselectedRoomID: effectiveRoom?.id,
                        preselectedProjectID: selectedProject?.id ?? project?.id,
                        prefillName: result.materialType,
                        prefillQuantity: result.value,
                        prefillUnit: result.unit
                    )
                    .environmentObject(appViewModel)
                    .environmentObject(settingsViewModel)
                }
            }
        }
        .onAppear {
            if let pre = preselectedRoom {
                selectedRoom = pre
                selectedProject = project
                step = .materialType
            }
        }
    }

    // MARK: - Step Indicator
    private var stepIndicator: some View {
        let labels = ["Room", "Type", "Inputs", "Result"]
        let current = stepIndex
        return HStack(spacing: 0) {
            ForEach(0..<labels.count, id: \.self) { idx in
                stepItem(idx: idx, label: labels[idx], currentIdx: current)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func stepItem(idx: Int, label: String, currentIdx: Int) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(idx <= currentIdx ? AppColors.primary : Color(.systemGray4))
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(idx + 1)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                )
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(idx <= currentIdx ? AppColors.primary : AppColors.secondaryText)
        }
        if idx < 3 {
            Rectangle()
                .fill(idx < currentIdx ? AppColors.primary : Color(.systemGray4))
                .frame(height: 2)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
        }
    }

    private var stepIndex: Int {
        switch step {
        case .room: return 0
        case .materialType: return 1
        case .inputs: return 2
        case .result: return 3
        }
    }

    // MARK: - Room Step
    private var roomStep: some View {
        VStack(spacing: 16) {
            Text("Select a room or enter dimensions manually")
                .font(AppFonts.body())
                .foregroundColor(AppColors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Room list
            ForEach(appViewModel.allRooms()) { pair in
                Button(action: {
                    selectedRoom = pair.room
                    selectedProject = pair.project
                    manualLength = ""
                    manualWidth = ""
                    manualHeight = ""
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: pair.room.icon)
                            .font(.system(size: 18))
                            .foregroundColor(selectedRoom?.id == pair.room.id ? .white : AppColors.primary)
                            .frame(width: 40, height: 40)
                            .background(selectedRoom?.id == pair.room.id ? AppColors.primary : AppColors.primary.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(pair.room.name)
                                .font(AppFonts.headline())
                                .foregroundColor(AppColors.labelColor)
                            Text(pair.project.name)
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.secondaryText)
                            if let l = pair.room.length, let w = pair.room.width {
                                Text(String(format: "%.1f × %.1f m", l, w))
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.primary)
                            } else {
                                Text("No dimensions saved")
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.secondaryText.opacity(0.7))
                            }
                        }
                        Spacer()
                        if selectedRoom?.id == pair.room.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.progress)
                        }
                    }
                    .padding(14)
                    .background(selectedRoom?.id == pair.room.id ? AppColors.primary.opacity(0.05) : AppColors.cardBackground)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Manual dimensions
            if selectedRoom == nil || !(roomLength > 0 && roomWidth > 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(selectedRoom != nil ? "Override dimensions" : "Enter dimensions manually")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.labelColor)

                    HStack(spacing: 12) {
                        dimensionField("Length (m)", text: $manualLength)
                        dimensionField("Width (m)", text: $manualWidth)
                        dimensionField("Height (m)", text: $manualHeight, placeholder: "2.7")
                    }
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Material Type Step
    private var materialTypeStep: some View {
        VStack(spacing: 12) {
            if let room = effectiveRoom {
                HStack(spacing: 8) {
                    Image(systemName: room.icon)
                        .foregroundColor(AppColors.primary)
                    Text(room.name)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.labelColor)
                    if roomLength > 0 && roomWidth > 0 {
                        Text(String(format: "%.1f×%.1f m", roomLength, roomWidth))
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppColors.primary.opacity(0.06))
                .cornerRadius(12)
            }

            Text("What material do you need to calculate?")
                .font(AppFonts.body())
                .foregroundColor(AppColors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(MaterialCalculatorView.MaterialType.allCases, id: \.self) { type in
                Button(action: { selectedType = type }) {
                    HStack(spacing: 14) {
                        Image(systemName: type.icon)
                            .font(.system(size: 20))
                            .foregroundColor(selectedType == type ? .white : AppColors.primary)
                            .frame(width: 44, height: 44)
                            .background(selectedType == type ? AppColors.primary : AppColors.primary.opacity(0.1))
                            .clipShape(Circle())
                        Text(type.rawValue)
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.labelColor)
                        Spacer()
                        if selectedType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.progress)
                        }
                    }
                    .padding(14)
                    .background(selectedType == type ? AppColors.primary.opacity(0.05) : AppColors.cardBackground)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Extra Inputs Step
    private var inputsStep: some View {
        VStack(spacing: 16) {
            summaryHeader

            switch selectedType {
            case .floorTiles, .wallTiles:
                if selectedType == .wallTiles {
                    wallTileInputs
                } else {
                    Text("No additional inputs needed for flooring.")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.secondaryText)
                        .cardStyle()
                }

            case .wallPaint:
                wallPaintInputs

            case .ceilingPaint:
                ceilingPaintInputs

            case .wallpaper:
                wallpaperInputs
            }
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: selectedType.icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedType.rawValue)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.labelColor)
                if let room = effectiveRoom {
                    Text(room.name + (roomLength > 0 ? String(format: " — %.1f×%.1f×%.1f m", roomLength, roomWidth, roomHeight) : ""))
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            Spacer()
        }
        .cardStyle()
    }

    private var wallPaintInputs: some View {
        VStack(spacing: 14) {
            inputRow("Coverage (m²/L)", binding: $coveragePerLiter, placeholder: "10")
            inputRow("Number of coats", binding: $numberOfCoats, placeholder: "2")
            inputRow("Doors (each = 2 m²)", binding: $doorCount, placeholder: "0")
            inputRow("Windows (each = 1.5 m²)", binding: $windowCount, placeholder: "0")
        }
        .cardStyle()
    }

    private var ceilingPaintInputs: some View {
        VStack(spacing: 14) {
            inputRow("Coverage (m²/L)", binding: $coveragePerLiter, placeholder: "10")
            inputRow("Number of coats", binding: $numberOfCoats, placeholder: "2")
        }
        .cardStyle()
    }

    private var wallpaperInputs: some View {
        VStack(spacing: 14) {
            inputRow("Roll width (m)", binding: $rollWidth, placeholder: "0.53")
            inputRow("Roll length (m)", binding: $rollLength, placeholder: "10.05")
            inputRow("Pattern repeat (cm, 0 = none)", binding: $patternRepeat, placeholder: "0")
        }
        .cardStyle()
    }

    private var wallTileInputs: some View {
        VStack(spacing: 14) {
            inputRow("Tile width (cm)", binding: $tileWidth, placeholder: "30")
            inputRow("Tile height (cm)", binding: $tileHeight, placeholder: "30")
        }
        .cardStyle()
    }

    // MARK: - Result Step
    private var resultStep: some View {
        VStack(spacing: 20) {
            if let res = calcResult {
                // Big result card
                VStack(spacing: 8) {
                    Text(res.roomName)
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.secondaryText)
                    Text(res.materialType)
                        .font(AppFonts.title3())
                        .foregroundColor(AppColors.labelColor)
                    Text(String(format: "%.2f", res.value))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primary)
                    Text(res.unit)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .cardStyle()

                // Formula breakdown
                VStack(alignment: .leading, spacing: 10) {
                    Text("Calculation Breakdown")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.labelColor)
                    ForEach(Array(res.steps.enumerated()), id: \.offset) { _, step in
                        HStack(alignment: .top) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.primary)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.0)
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.secondaryText)
                                Text(step.1)
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(AppColors.labelColor)
                            }
                        }
                    }
                }
                .cardStyle()

                // Buttons
                PrimaryButton(title: "Add to Materials", action: { showAddMaterial = true })
                SecondaryButton(title: "Recalculate", action: {
                    step = selectedType == .floorTiles ? .materialType : .inputs
                })
            }
        }
    }

    // MARK: - Bottom Navigation
    private var bottomNavBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                if step != .room {
                    SecondaryButton(title: "Back", action: goBack, isFullWidth: false)
                        .frame(maxWidth: .infinity)
                }
                PrimaryButton(title: nextButtonTitle, action: goNext)
                    .disabled(!canProceed)
                    .opacity(canProceed ? 1 : 0.4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }

    private var nextButtonTitle: String {
        switch step {
        case .room: return "Next: Material Type"
        case .materialType: return selectedType == .floorTiles ? "Calculate" : "Next: Details"
        case .inputs: return "Calculate"
        case .result: return "Done"
        }
    }

    private var canProceed: Bool {
        switch step {
        case .room:
            return roomLength > 0 && roomWidth > 0
        case .materialType: return true
        case .inputs: return roomHasDimensions
        case .result: return true
        }
    }

    private func goNext() {
        switch step {
        case .room:
            step = .materialType
        case .materialType:
            if selectedType == .floorTiles {
                calculate()
                step = .result
            } else {
                step = .inputs
            }
        case .inputs:
            calculate()
            step = .result
        case .result:
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func goBack() {
        switch step {
        case .result: step = selectedType == .floorTiles ? .materialType : .inputs
        case .inputs: step = .materialType
        case .materialType: step = .room
        case .room: break
        }
    }

    // MARK: - Calculation Logic
    private func calculate() {
        let L = roomLength, W = roomWidth, H = roomHeight
        let roomName = effectiveRoom?.name ?? "Room"
        var steps: [(String, String)] = []
        var finalValue: Double = 0
        var unit = ""

        switch selectedType {
        case .floorTiles:
            let area = L * W
            steps.append(("Floor area", String(format: "%.2f × %.2f = %.2f m²", L, W, area)))
            let withWaste = area * 1.10
            steps.append(("+ 10% waste", String(format: "%.2f × 1.1 = %.2f m²", area, withWaste)))
            finalValue = withWaste; unit = "m²"

        case .wallPaint:
            let coverage = Double(coveragePerLiter.replacingOccurrences(of: ",", with: ".")) ?? 10
            let coats = Double(numberOfCoats.replacingOccurrences(of: ",", with: ".")) ?? 2
            let doors = Double(doorCount.replacingOccurrences(of: ",", with: ".")) ?? 0
            let windows = Double(windowCount.replacingOccurrences(of: ",", with: ".")) ?? 0
            let perimeter = 2 * (L + W)
            let wallArea = perimeter * H
            let doorsArea = doors * 2.0
            let windowsArea = windows * 1.5
            let netArea = max(wallArea - doorsArea - windowsArea, 0)
            steps.append(("Perimeter × height", String(format: "2×(%.2f+%.2f)×%.2f = %.2f m²", L, W, H, wallArea)))
            if doorsArea > 0 || windowsArea > 0 {
                steps.append(("- Doors & windows", String(format: "– %.2f – %.2f = %.2f m²", doorsArea, windowsArea, netArea)))
            }
            let totalPaintArea = netArea * coats
            steps.append(("× \(Int(coats)) coat(s)", String(format: "%.2f × %.0f = %.2f m²", netArea, coats, totalPaintArea)))
            let liters = (totalPaintArea / coverage) * 1.10
            steps.append(("÷ coverage × 1.1 waste", String(format: "%.2f ÷ %.0f × 1.1 = %.2f L", totalPaintArea, coverage, liters)))
            finalValue = liters; unit = "L"

        case .ceilingPaint:
            let coverage = Double(coveragePerLiter.replacingOccurrences(of: ",", with: ".")) ?? 10
            let coats = Double(numberOfCoats.replacingOccurrences(of: ",", with: ".")) ?? 2
            let area = L * W
            steps.append(("Ceiling area", String(format: "%.2f × %.2f = %.2f m²", L, W, area)))
            let totalArea = area * coats
            steps.append(("× \(Int(coats)) coat(s)", String(format: "%.2f × %.0f = %.2f m²", area, coats, totalArea)))
            let liters = (totalArea / coverage) * 1.10
            steps.append(("÷ coverage × 1.1 waste", String(format: "%.2f ÷ %.0f × 1.1 = %.2f L", totalArea, coverage, liters)))
            finalValue = liters; unit = "L"

        case .wallpaper:
            let rw = Double(rollWidth.replacingOccurrences(of: ",", with: ".")) ?? 0.53
            let rl = Double(rollLength.replacingOccurrences(of: ",", with: ".")) ?? 10.05
            let repeat_cm = Double(patternRepeat.replacingOccurrences(of: ",", with: ".")) ?? 0
            let perimeter = 2 * (L + W)
            let stripHeight = H + (repeat_cm / 100)
            let stripsPerRoll = max(1, Int(rl / stripHeight))
            let totalStrips = Int(ceil(perimeter / rw))
            let rolls = Int(ceil(Double(totalStrips) / Double(stripsPerRoll))) + 1 // +1 for waste
            steps.append(("Perimeter", String(format: "2×(%.2f+%.2f) = %.2f m", L, W, perimeter)))
            steps.append(("Strips needed", String(format: "%.2f ÷ %.2f = %d strips", perimeter, rw, totalStrips)))
            steps.append(("Strips per roll", String(format: "%.2f ÷ %.2f = %d strips/roll", rl, stripHeight, stripsPerRoll)))
            steps.append(("Rolls + 1 waste", String(format: "%d strips ÷ %d = %d rolls", totalStrips, stripsPerRoll, rolls)))
            finalValue = Double(rolls); unit = "rolls"

        case .wallTiles:
            let tw = Double(tileWidth.replacingOccurrences(of: ",", with: ".")) ?? 30
            let th = Double(tileHeight.replacingOccurrences(of: ",", with: ".")) ?? 30
            let wallArea = 2 * (L + W) * H
            let tileArea = (tw / 100) * (th / 100)
            let rawTiles = wallArea / tileArea
            let withWaste = rawTiles * 1.10
            steps.append(("Wall area", String(format: "2×(%.2f+%.2f)×%.2f = %.2f m²", L, W, H, wallArea)))
            steps.append(("Tile area", String(format: "%.0f×%.0f cm = %.4f m²", tw, th, tileArea)))
            steps.append(("Tiles needed", String(format: "%.2f ÷ %.4f = %.0f tiles", wallArea, tileArea, rawTiles)))
            steps.append(("+ 10% waste", String(format: "%.0f × 1.1 = %.0f tiles", rawTiles, withWaste)))
            finalValue = withWaste; unit = "tiles"
        }

        calcResult = CalcResult(
            value: finalValue,
            unit: unit,
            steps: steps,
            materialType: selectedType.rawValue,
            roomName: roomName
        )

        // Save to history
        let record = CalculationRecord(
            roomName: roomName,
            materialType: selectedType.rawValue,
            result: finalValue,
            unit: unit
        )
        appViewModel.addCalculationRecord(record)
    }

    // MARK: - Field helpers
    private func inputRow(_ label: String, binding: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.labelColor)
            Spacer()
            TextField(placeholder, text: binding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.primary)
                .frame(width: 80)
        }
    }

    private func dimensionField(_ label: String, text: Binding<String>, placeholder: String = "0") -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFonts.caption())
                .foregroundColor(AppColors.secondaryText)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .font(AppFonts.body())
                .padding(.horizontal, 10)
                .frame(height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}
