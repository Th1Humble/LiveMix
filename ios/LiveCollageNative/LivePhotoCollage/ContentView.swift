import Photos
import PhotosUI
import SwiftUI
import AVKit
import OSLog
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    @AppStorage("app.language") private var languageRaw = ""
    @State private var isSplashVisible = true

    private var appLanguage: AppLanguage {
        if let storedLanguage = AppLanguage(rawValue: languageRaw) {
            return storedLanguage
        }
        return .preferred
    }

    var body: some View {
        ZStack {
            NavigationStack {
                HomeScreen()
            }
            .tint(AppTheme.primary)

            if isSplashVisible {
                AppSplashScreen {
                    withAnimation(.easeOut(duration: 0.24)) {
                        isSplashVisible = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .environment(\.appLanguage, appLanguage)
        .environment(\.locale, Locale(identifier: appLanguage.localeIdentifier))
    }
}

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .preferred
}

private extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}

private enum AppTheme {
    static let primary = Color(red: 0.055, green: 0.420, blue: 0.365)
    static let primaryHover = Color(red: 0.035, green: 0.330, blue: 0.295)
    static let primarySoft = Color(red: 0.882, green: 0.956, blue: 0.936)
    static let accent = Color(red: 0.245, green: 0.390, blue: 0.760)
    static let accentSoft = Color(red: 0.902, green: 0.928, blue: 0.990)
    static let ink = Color(red: 0.075, green: 0.090, blue: 0.105)
    static let muted = Color(red: 0.310, green: 0.335, blue: 0.355)
    static let faint = Color(red: 0.490, green: 0.515, blue: 0.535)
    static let canvas = Color(red: 0.965, green: 0.973, blue: 0.974)
    static let surface = Color(red: 0.945, green: 0.955, blue: 0.956)
    static let raised = Color(red: 0.905, green: 0.922, blue: 0.923)
    static let border = Color(red: 0.835, green: 0.855, blue: 0.858)
    static let error = Color(red: 0.690, green: 0.105, blue: 0.145)
}

private struct AppSplashScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appLanguage) private var language

    let onFinished: () -> Void

    @State private var isPresented = false
    @State private var iconScale: CGFloat = 0.88
    @State private var textOffset: CGFloat = 10

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 18) {
                AppIconMark(size: 92, cornerRadius: 22)
                    .scaleEffect(iconScale)
                    .opacity(isPresented ? 1 : 0)

                VStack(spacing: 6) {
                    Text("LiveMix")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(language.text(.splashTagline))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                }
                .offset(y: textOffset)
                .opacity(isPresented ? 1 : 0)
            }
            .padding(.bottom, 22)
        }
        .task {
            await play()
        }
    }

    @MainActor
    private func play() async {
        if reduceMotion {
            isPresented = true
            iconScale = 1
            textOffset = 0
            try? await Task.sleep(nanoseconds: 450_000_000)
            onFinished()
            return
        }

        withAnimation(.spring(response: 0.48, dampingFraction: 0.84)) {
            isPresented = true
            iconScale = 1
            textOffset = 0
        }

        try? await Task.sleep(nanoseconds: 1_050_000_000)
        onFinished()
    }
}

private struct HomeScreen: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(spacing: 0) {
            HomeTopBar()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(language.text(.homeTitle))
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Text(language.text(.homeSubtitle))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .padding(.bottom, 4)

                    NavigationLink {
                        LiveTemplatePickerScreen()
                    } label: {
                        HomeLiveEntryCard()
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ImageToolPickerScreen()
                    } label: {
                        HomeImageEntryCard()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 18)
            }

            VStack(spacing: 8) {
                HomeFeedbackLink()

                NavigationLink {
                    PrivacyPolicyScreen()
                } label: {
                    Text(language.text(.privacyPolicy))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.faint)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
        }
        .background(AppTheme.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HomeTopBar: View {
    @Environment(\.appLanguage) private var language
    @AppStorage("app.language") private var languageRaw = ""

    var body: some View {
        HStack(spacing: 10) {
            BrandMark(size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("LiveMix")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(language.text(.homeTopTagline))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.faint)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                languageRaw = language.next.rawValue
            } label: {
                Text(language.toggleTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 38, height: 34)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.border, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(AppTheme.canvas.opacity(0.98))
    }
}

private struct HomeLiveEntryCard: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "livephoto")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 48, height: 48)
                .background(AppTheme.primarySoft, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(language.text(.liveEntryTitle))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(language.text(.liveEntrySubtitle))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.faint)
        }
        .padding(16)
        .frame(minHeight: 82)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}

private struct HomeImageEntryCard: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 48, height: 48)
                .background(AppTheme.accentSoft, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(language.text(.imageEntryTitle))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(language.text(.imageEntrySubtitle))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.faint)
        }
        .padding(16)
        .frame(minHeight: 82)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}

private struct HomeLiveTemplateMosaic: View {
    private let templates = [
        NativeCollageTemplate.liveTemplates[0],
        NativeCollageTemplate.liveTemplates[1],
        NativeCollageTemplate.liveTemplates[6],
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.surface

                GeometryReader { innerProxy in
                    let smallWidth = max((innerProxy.size.width - 8) * 0.34, 1)
                    let largeWidth = max(innerProxy.size.width - smallWidth - 8, 1)

                    HStack(spacing: 8) {
                        TemplateMiniPreview(template: templates[2])
                            .frame(width: largeWidth, height: innerProxy.size.height)

                        VStack(spacing: 8) {
                            TemplateMiniPreview(template: templates[0])
                            TemplateMiniPreview(template: templates[1])
                        }
                        .frame(width: smallWidth, height: innerProxy.size.height)
                    }
                }
                .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct HomeImageModePreview: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        HStack(spacing: 8) {
            HomeImageModeTile(title: language.text(.horizontalShort)) {
                ImageJoinArtworkPanel(mode: .horizontal)
            }
            HomeImageModeTile(title: language.text(.verticalShort)) {
                ImageJoinArtworkPanel(mode: .vertical)
            }
            HomeImageModeTile(title: language.text(.gridShort)) {
                SplitNinePreviewArtwork(lineWidth: 1)
            }
        }
    }
}

private struct HomeImageModeTile<Artwork: View>: View {
    let title: String
    @ViewBuilder let artwork: () -> Artwork

    var body: some View {
        VStack(spacing: 7) {
            artwork()
                .frame(height: 58)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HomeCapabilityStrip: View {
    @Environment(\.appLanguage) private var language

    private let items: [(AppText, AppText)] = [
        (.capabilityTemplates, .capabilityTemplatesDetail),
        (.capabilityCanvas, .capabilityCanvasDetail),
        (.capabilityAlbum, .capabilityAlbumDetail),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text(item.0))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(language.text(item.1))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.faint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 11)
                .padding(.vertical, 10)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

private struct HomeFeedbackLink: View {
    @Environment(\.appLanguage) private var language

    private let email = "humility921@outlook.com"

    var body: some View {
        Link(destination: URL(string: "mailto:\(email)")!) {
            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.primarySoft, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(language.text(.feedback))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(email)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.faint)
            }
            .padding(12)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct PrivacyPolicyScreen: View {
    @Environment(\.appLanguage) private var language

    private var policy: AppPrivacyPolicyContent {
        AppPrivacyPolicy.content(language: language)
    }

    var body: some View {
        VStack(spacing: 0) {
            PageTopBar(backLabel: language.text(.backHome)) {
                Badge(text: "LiveMix", tone: .neutral)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(policy.title)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Text(policy.updatedAt)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.faint)
                        Text(policy.intro)
                            .font(.system(size: 14))
                            .lineSpacing(4)
                            .foregroundStyle(AppTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(policy.sections) { section in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(section.title)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)
                                Text(section.body)
                                    .font(.system(size: 14))
                                    .lineSpacing(4)
                                    .foregroundStyle(AppTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 34)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct PageTopBar<Trailing: View>: View {
    @Environment(\.dismiss) private var dismiss

    let backLabel: String
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text(backLabel.replacingOccurrences(of: "← ", with: ""))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
                .frame(minHeight: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            trailing()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(AppTheme.canvas.opacity(0.98))
    }
}

private struct Badge: View {
    let text: String
    var tone: BadgeTone = .primary

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(tone == .primary ? AppTheme.primary : AppTheme.muted)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                tone == .primary ? AppTheme.primarySoft : AppTheme.surface,
                in: RoundedRectangle(cornerRadius: 7)
            )
    }
}

private enum BadgeTone {
    case primary
    case neutral
}

private struct ImageJoinArtworkPanel: View {
    let mode: ImageJoinMode

    private let colors = [
        AppTheme.primarySoft,
        AppTheme.accentSoft,
        Color(red: 0.80, green: 0.95, blue: 0.91),
    ]

    var body: some View {
        ZStack {
            Color.white

            if mode == .horizontal {
                HStack(spacing: 0) {
                    ForEach(colors.indices, id: \.self) { index in
                        colors[index]
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(colors.indices, id: \.self) { index in
                        colors[index]
                    }
                }
            }

            if mode == .horizontal {
                HStack(spacing: 0) {
                    ForEach(0..<2, id: \.self) { _ in
                        Color.clear
                        Rectangle()
                            .fill(Color.white.opacity(0.92))
                            .frame(width: 2)
                    }
                    Color.clear
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(0..<2, id: \.self) { _ in
                        Color.clear
                        Rectangle()
                            .fill(Color.white.opacity(0.92))
                            .frame(height: 2)
                    }
                    Color.clear
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct LiveTemplatePickerScreen: View {
    @Environment(\.appLanguage) private var language

    private let columns = [
        GridItem(.adaptive(minimum: 168), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 0) {
            PageTopBar(backLabel: language.text(.backHome)) {
                Badge(text: language.templateCount(NativeCollageTemplate.liveTemplates.count))
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(language.text(.templatesTitle))
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Text(language.text(.templatesSubtitle))
                            .font(.system(size: 15))
                            .lineSpacing(4)
                            .foregroundStyle(AppTheme.muted)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(NativeCollageTemplate.liveTemplates) { template in
                            NavigationLink {
                                LiveComposerScreen(template: template)
                            } label: {
                                TemplateCard(template: template)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
        }
        .background(AppTheme.canvas)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct TemplateCard: View {
    @Environment(\.appLanguage) private var language

    let template: NativeCollageTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            TemplateMiniPreview(template: template)
                .frame(height: 82)
                .background(AppTheme.raised, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(template.localizedName(language))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Spacer()
                    Text(language.clipCount(template.slots.count))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.faint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.raised, in: Capsule())
                }

                Text(template.localizedDetail(language))
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}

private struct LiveComposerScreen: View {
    @Environment(\.appLanguage) private var language

    let template: NativeCollageTemplate

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LiveMix",
        category: "LivePhotoComposer"
    )
    private let composer = NativeLivePhotoComposer()

    @State private var replacementPickerItem: PhotosPickerItem?
    @State private var selectedItems: [PhotosPickerItem?]
    @State private var videoPreviews: [NativeVideoPreview?]
    @State private var loadingSlots: Set<Int> = []
    @State private var activeSlot = 0
    @State private var slotEdits: [NativeSlotEdit]
    @State private var isGenerating = false
    @State private var isResultPresented = false
    @State private var liveDraft: NativeLiveDraft?
    @State private var message: LiveComposerMessage = .none
    @State private var durationLimitAlertSlot = 0
    @State private var isDurationLimitAlertPresented = false
    @AppStorage("singleVideoCanvasStyle") private var singleVideoCanvasStyle: SingleVideoCanvasStyle = .original

    init(template: NativeCollageTemplate) {
        self.template = template
        _selectedItems = State(initialValue: Array(repeating: nil, count: template.slots.count))
        _videoPreviews = State(initialValue: Array(repeating: nil, count: template.slots.count))
        _slotEdits = State(initialValue: NativeSlotEdit.edits([], fitting: template.slots.count))
    }

    var body: some View {
        VStack(spacing: 0) {
            PageTopBar(backLabel: language.text(.backTemplate)) {
                Badge(text: "\(filledCount)/\(template.slots.count)")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(language.text(.fillVideosTitle))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text(language.text(.fillVideosSubtitle))
                            .font(.system(size: 14))
                            .lineSpacing(4)
                            .foregroundStyle(AppTheme.muted)
                        Label(
                            language.videoDurationLimit(Int(NativeVideoInputLimits.maximumDuration)),
                            systemImage: "timer"
                        )
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                        .padding(.top, 3)
                    }

                    if isSingleVideoTemplate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(language.text(.videoCanvasStyle))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                            Picker(language.text(.videoCanvasStyle), selection: $singleVideoCanvasStyle) {
                                ForEach(SingleVideoCanvasStyle.allCases) { style in
                                    Text(style.localizedTitle(language)).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                            .disabled(isGenerating)
                        }
                    }

                    VStack(spacing: 12) {
                        LiveUploadPreview(
                            template: template,
                            previews: videoPreviews,
                            edits: slotEdits,
                            activeSlot: activeSlot,
                            loadingSlots: loadingSlots,
                            isGenerating: isGenerating,
                            canvasAspectRatio: livePreviewAspectRatio,
                            maxSelectionCount: { index in
                                selectableVideoLimit(startingAt: index)
                            },
                            onPickItems: { index, items in
                                assignBatchItems(items, startingAt: index)
                            },
                            onUpdateFocal: { index, focalX, focalY in
                                updateEdit(at: index) {
                                    $0.focalX = focalX
                                    $0.focalY = focalY
                                }
                            }
                        ) { index in
                            activeSlot = index
                        }
                        .frame(maxWidth: 390)
                        .frame(maxWidth: .infinity)

                        if template.slots.count > 1 {
                            NativeSlotSelector(
                                totalCount: template.slots.count,
                                activeSlot: activeSlot,
                                previews: videoPreviews,
                                loadingSlots: loadingSlots
                            ) { index in
                                activeSlot = index
                            }
                        }
                    }

                    NativeLiveEditControls(
                        activeSlot: activeSlot,
                        activeEdit: activeEdit,
                        activePreview: activePreview,
                        isLoading: loadingSlots.contains(activeSlot),
                        isGenerating: isGenerating,
                        totalCount: template.slots.count,
                        filledCount: filledCount,
                        outputDuration: outputDuration,
                        availableClipDuration: availableClipDuration,
                        activeMaxStart: activeMaxStart,
                        activeEndTime: activeEndTime,
                        message: message,
                        onFitModeChange: { mode in
                            updateActiveEdit { $0.fitMode = mode }
                        },
                        onZoomChange: { value in
                            updateActiveEdit { $0.zoom = value }
                        },
                        onFocalXChange: { value in
                            updateActiveEdit { $0.focalX = value }
                        },
                        onFocalYChange: { value in
                            updateActiveEdit { $0.focalY = value }
                        },
                        onDurationChange: { value in
                            updateAllClipDurations(value)
                        },
                        onStartChange: { value in
                            updateActiveEdit { $0.start = value }
                        },
                        replacementPickerItem: $replacementPickerItem
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 86)
            }

            VStack(spacing: 0) {
                Divider()
                Button {
                    Task {
                        await generateLivePhoto()
                    }
                } label: {
                    Text(bottomButtonTitle)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(canGenerate ? Color.white : AppTheme.faint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canGenerate ? AppTheme.primary : AppTheme.raised, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(!canGenerate)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .background(.regularMaterial)
        }
        .background(AppTheme.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isResultPresented) {
            if let liveDraft {
                LiveResultScreen(draft: liveDraft)
            }
        }
        .alert(
            language.text(.videoTooLongTitle),
            isPresented: $isDurationLimitAlertPresented
        ) {
            Button(language.text(.chooseAnotherVideo), role: .cancel) {}
        } message: {
            Text(
                language.videoTooLong(
                    durationLimitAlertSlot,
                    maximumDuration: Int(NativeVideoInputLimits.maximumDuration)
                )
            )
        }
        .onChange(of: replacementPickerItem) { newItem in
            guard let newItem else { return }
            replaceActiveSlot(with: newItem)
            replacementPickerItem = nil
        }
        .onChange(of: singleVideoCanvasStyle) { _ in
            liveDraft = nil
        }
    }

    private var isSingleVideoTemplate: Bool {
        template.id == "video-to-live"
    }

    private var livePreviewAspectRatio: CGFloat {
        guard isSingleVideoTemplate,
              singleVideoCanvasStyle == .original,
              let sourceSize = videoPreviews.first.flatMap({ $0 })?.displaySize,
              let outputSize = NativeVideoRenderLayout.singleVideoOutputSize(for: sourceSize),
              outputSize.height > 0 else {
            return 1
        }
        return outputSize.width / outputSize.height
    }

    private var filledCount: Int {
        videoPreviews.compactMap { $0 }.count
    }

    private var activeEdit: NativeSlotEdit {
        guard slotEdits.indices.contains(activeSlot) else { return .default }
        return slotEdits[activeSlot]
    }

    private var activePreview: NativeVideoPreview? {
        guard videoPreviews.indices.contains(activeSlot) else { return nil }
        return videoPreviews[activeSlot]
    }

    private var knownDurations: [Double] {
        videoPreviews.compactMap { preview in
            guard let duration = preview?.duration, duration.isFinite else { return nil }
            return duration
        }
    }

    private var availableClipDuration: Double {
        guard let shortest = knownDurations.min() else { return NativeSlotEdit.maxDuration }
        return NativeSlotEdit.normalizedDuration(shortest)
    }

    private var outputDuration: Double {
        min(NativeSlotEdit.outputDuration(for: slotEdits), availableClipDuration)
    }

    private var activeMaxStart: Double {
        maxStart(for: activeSlot, clipDuration: outputDuration)
    }

    private var activeEndTime: Double {
        min(activePreview?.duration ?? outputDuration, activeEdit.start + outputDuration)
    }

    private var canGenerate: Bool {
        filledCount == template.slots.count && loadingSlots.isEmpty && !isGenerating
    }

    private var bottomButtonTitle: String {
        if isGenerating { return language.text(.generating) }
        if !loadingSlots.isEmpty { return language.text(.loadingVideo) }
        let missingCount = template.slots.count - filledCount
        return missingCount == 0 ? language.text(.generateLivePhoto) : language.missingVideos(missingCount)
    }

    private func selectableVideoLimit(startingAt index: Int) -> Int {
        max(batchTargetSlots(startingAt: index).count, 1)
    }

    private func batchTargetSlots(startingAt index: Int) -> [Int] {
        let ordered = orderedSlotIndexes(startingAt: index)
        let emptySlots = ordered.filter { selectedItems[$0] == nil }
        return emptySlots.isEmpty ? [index] : emptySlots
    }

    private func orderedSlotIndexes(startingAt index: Int) -> [Int] {
        let indexes = Array(selectedItems.indices)
        guard indexes.contains(index) else { return indexes }
        return Array(indexes[index...]) + Array(indexes[..<index])
    }

    private func assignBatchItems(_ items: [PhotosPickerItem], startingAt startIndex: Int) {
        let targetSlots = Array(batchTargetSlots(startingAt: startIndex).prefix(items.count))
        guard !targetSlots.isEmpty else { return }

        var assignments: [(slot: Int, item: PhotosPickerItem)] = []
        var firstRejectedSlot: Int?

        for (slotIndex, item) in zip(targetSlots, items) {
            if Self.isKnownToExceedDurationLimit(item) {
                firstRejectedSlot = firstRejectedSlot ?? slotIndex
                continue
            }

            selectedItems[slotIndex] = item
            clearPreview(at: slotIndex)
            slotEdits[slotIndex] = NativeSlotEdit.default.withDuration(outputDuration)
            assignments.append((slot: slotIndex, item: item))
        }

        if let firstRejectedSlot {
            presentDurationLimit(for: firstRejectedSlot)
        }

        guard !assignments.isEmpty else { return }

        activeSlot = assignments[0].slot
        message = assignments.count == 1 ? .loadingVideo : .loadingVideos(assignments.count)

        Task {
            await startVideoPreviewLoads(assignments: assignments)
        }
    }

    private func replaceActiveSlot(with item: PhotosPickerItem) {
        guard selectedItems.indices.contains(activeSlot) else { return }

        guard !Self.isKnownToExceedDurationLimit(item) else {
            presentDurationLimit(for: activeSlot)
            return
        }

        selectedItems[activeSlot] = item
        clearPreview(at: activeSlot)
        slotEdits[activeSlot] = NativeSlotEdit.default.withDuration(outputDuration)
        message = .loadingVideo

        Task {
            await startVideoPreviewLoads(assignments: [(slot: activeSlot, item: item)])
        }
    }

    @MainActor
    private func startVideoPreviewLoads(assignments: [(slot: Int, item: PhotosPickerItem)]) async {
        assignments.forEach { assignment in
            loadingSlots.insert(assignment.slot)
        }

        for assignment in assignments {
            Task {
                await loadSingleVideoPreview(slot: assignment.slot, item: assignment.item)
            }
        }
    }

    @MainActor
    private func loadSingleVideoPreview(slot: Int, item: PhotosPickerItem) async {
        guard selectedItems.indices.contains(slot) else { return }

        defer {
            loadingSlots.remove(slot)
            normalizeAllEditsForLoadedDurations()
            if loadingSlots.isEmpty && filledCount > 0 {
                switch message {
                case .unreadableVideo, .videoTooLong:
                    break
                default:
                    message = filledCount == template.slots.count ? .ready : .selectedVideos(filledCount)
                }
            }
        }

        do {
            let preview = try await Self.makeVideoPreview(for: item)
            clearPreview(at: slot)
            videoPreviews[slot] = preview
        } catch NativeVideoPreviewLoadError.durationTooLong {
            Self.logger.notice(
                "Rejected video longer than \(NativeVideoInputLimits.maximumDuration, privacy: .public) seconds"
            )
            selectedItems[slot] = nil
            clearPreview(at: slot)
            message = .videoTooLong(slot)
            presentDurationLimit(for: slot)
        } catch {
            Self.logger.error(
                "Video preview failed for slot \(slot + 1): \(String(reflecting: error), privacy: .public)"
            )
            selectedItems[slot] = nil
            clearPreview(at: slot)
            message = .unreadableVideo(slot)
        }
    }

    private static func makeVideoPreview(for item: PhotosPickerItem) async throws -> NativeVideoPreview {
        if let duration = photoLibraryDuration(for: item) {
            try validateVideoDuration(duration)
        }

        return try await withThrowingTaskGroup(of: NativeVideoPreview.self) { group in
            group.addTask {
                guard let pickedVideo = try await item.loadTransferable(type: PickedVideo.self) else {
                    throw NativeLivePhotoComposerError.unreadableVideo
                }
                let preview = await NativeVideoMetadataLoader.preview(for: pickedVideo.url)
                do {
                    guard let duration = preview.duration else {
                        throw NativeLivePhotoComposerError.unreadableVideo
                    }
                    try validateVideoDuration(duration)
                    return preview
                } catch {
                    try? FileManager.default.removeItem(at: preview.url)
                    throw error
                }
            }

            group.addTask {
                try await Task.sleep(nanoseconds: 90_000_000_000)
                throw NativeVideoPreviewLoadError.timeout
            }

            guard let preview = try await group.next() else {
                throw NativeLivePhotoComposerError.unreadableVideo
            }
            group.cancelAll()
            return preview
        }
    }

    private static func photoLibraryDuration(for item: PhotosPickerItem) -> Double? {
        guard let itemIdentifier = item.itemIdentifier else { return nil }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [itemIdentifier], options: nil)
        guard let asset = assets.firstObject, asset.mediaType == .video else { return nil }
        return asset.duration
    }

    private static func isKnownToExceedDurationLimit(_ item: PhotosPickerItem) -> Bool {
        guard let duration = photoLibraryDuration(for: item), duration.isFinite else { return false }
        return duration > NativeVideoInputLimits.maximumDuration
    }

    nonisolated private static func validateVideoDuration(_ duration: Double) throws {
        guard duration.isFinite, duration > 0 else {
            throw NativeLivePhotoComposerError.unreadableVideo
        }
        guard duration <= NativeVideoInputLimits.maximumDuration else {
            throw NativeVideoPreviewLoadError.durationTooLong
        }
    }

    private func presentDurationLimit(for slot: Int) {
        durationLimitAlertSlot = slot
        message = .videoTooLong(slot)
        isDurationLimitAlertPresented = true
    }

    private func clearPreview(at index: Int) {
        guard videoPreviews.indices.contains(index) else { return }
        if let url = videoPreviews[index]?.url {
            try? FileManager.default.removeItem(at: url)
        }
        videoPreviews[index] = nil
    }

    private func updateActiveEdit(_ update: (inout NativeSlotEdit) -> Void) {
        updateEdit(at: activeSlot, update)
    }

    private func updateEdit(at index: Int, _ update: (inout NativeSlotEdit) -> Void) {
        guard slotEdits.indices.contains(index) else { return }

        var next = slotEdits
        var edit = next[index]
        update(&edit)
        edit.duration = min(NativeSlotEdit.normalizedDuration(edit.duration), availableClipDuration)
        edit = edit.clamped(maxStart: maxStart(for: index, clipDuration: edit.duration))
        next[index] = edit
        slotEdits = next
    }

    private func updateAllClipDurations(_ duration: Double) {
        let nextDuration = min(NativeSlotEdit.normalizedDuration(duration), availableClipDuration)
        slotEdits = slotEdits.enumerated().map { index, edit in
            var next = edit
            next.duration = nextDuration
            return next.clamped(maxStart: maxStart(for: index, clipDuration: nextDuration))
        }
    }

    private func normalizeAllEditsForLoadedDurations() {
        updateAllClipDurations(outputDuration)
    }

    private func maxStart(for index: Int, clipDuration: Double) -> Double {
        guard videoPreviews.indices.contains(index),
              let duration = videoPreviews[index]?.duration else {
            return 0
        }
        return max(0, duration - clipDuration)
    }

    @MainActor
    private func generateLivePhoto() async {
        guard filledCount == template.slots.count,
              videoPreviews.allSatisfy({ $0 != nil }) else {
            message = .needAllVideos
            return
        }

        isGenerating = true
        message = .composing
        defer { isGenerating = false }

        do {
            let sourceURLs = videoPreviews.compactMap { $0?.url }
            let draft = try await composer.compose(
                template: template,
                videoURLs: sourceURLs,
                edits: slotEdits,
                singleVideoCanvasStyle: singleVideoCanvasStyle
            )
            liveDraft = draft
            isResultPresented = true
            message = .generated
        } catch {
            Self.logger.error(
                "Live Photo generation failed: \(String(reflecting: error), privacy: .public)"
            )
            message = .failed
        }
    }
}

private enum LiveComposerMessage: Hashable {
    case none
    case loadingVideo
    case loadingVideos(Int)
    case unreadableVideo(Int)
    case videoTooLong(Int)
    case ready
    case selectedVideos(Int)
    case needAllVideos
    case composing
    case generated
    case failed

    func text(language: AppLanguage) -> String? {
        switch self {
        case .none:
            return nil
        case .loadingVideo:
            return language.text(.loadingVideo) + "..."
        case .loadingVideos(let count):
            return language.loadingVideos(count)
        case .unreadableVideo(let index):
            return language.unreadableVideo(index)
        case .videoTooLong(let index):
            return language.videoTooLong(
                index,
                maximumDuration: Int(NativeVideoInputLimits.maximumDuration)
            )
        case .ready:
            return language.text(.liveReadyMessage)
        case .selectedVideos(let count):
            return language.selectedVideos(count)
        case .needAllVideos:
            return language.text(.needAllVideos)
        case .composing:
            return language.text(.composingLive)
        case .generated:
            return language.text(.liveGeneratedMessage)
        case .failed:
            return language.text(.liveGenerationFailed)
        }
    }
}

private struct LiveUploadPreview: View {
    @Environment(\.appLanguage) private var language

    let template: NativeCollageTemplate
    let previews: [NativeVideoPreview?]
    let edits: [NativeSlotEdit]
    let activeSlot: Int
    let loadingSlots: Set<Int>
    let isGenerating: Bool
    let canvasAspectRatio: CGFloat
    let maxSelectionCount: (Int) -> Int
    let onPickItems: (Int, [PhotosPickerItem]) -> Void
    let onUpdateFocal: (Int, CGFloat, CGFloat) -> Void
    let onSelect: (Int) -> Void

    private let panelPadding: CGFloat = 6
    private let slotGap: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white

                ZStack {
                    AppTheme.raised

                    ForEach(template.slots) { slot in
                        let preview = slot.id < previews.count ? previews[slot.id] : nil
                        let edit = slot.id < edits.count ? edits[slot.id] : .default
                        let isLoading = loadingSlots.contains(slot.id)
                        let isActive = activeSlot == slot.id
                        let frame = slotFrame(for: slot, in: innerSize(for: proxy.size))

                        LiveUploadSlot(
                            slot: slot,
                            preview: preview,
                            edit: edit,
                            isActive: isActive,
                            isLoading: isLoading,
                            maxSelectionCount: maxSelectionCount(slot.id),
                            onPickItems: { items in
                                onPickItems(slot.id, items)
                            },
                            onUpdateFocal: { focalX, focalY in
                                onUpdateFocal(slot.id, focalX, focalY)
                            },
                            onSelect: {
                                onSelect(slot.id)
                            }
                        )
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
                .frame(width: innerSize(for: proxy.size).width, height: innerSize(for: proxy.size).height)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                if isGenerating {
                    Color.white.opacity(0.72)
                    ProgressView(language.text(.generating))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                }
            }
        }
        .aspectRatio(canvasAspectRatio, contentMode: .fit)
        .frame(maxHeight: 520)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }

    private func innerSize(for size: CGSize) -> CGSize {
        CGSize(
            width: max(size.width - panelPadding * 2, 1),
            height: max(size.height - panelPadding * 2, 1)
        )
    }

    private func slotFrame(for slot: CollageSlot, in size: CGSize) -> CGRect {
        let rawFrame = CGRect(
            x: size.width * slot.x,
            y: size.height * slot.y,
            width: size.width * slot.width,
            height: size.height * slot.height
        )
        let frame = rawFrame.insetBy(dx: slotGap, dy: slotGap)

        return CGRect(
            x: frame.minX,
            y: frame.minY,
            width: max(frame.width, 1),
            height: max(frame.height, 1)
        )
    }
}

private struct LiveUploadSlot: View {
    @Environment(\.appLanguage) private var language

    let slot: CollageSlot
    let preview: NativeVideoPreview?
    let edit: NativeSlotEdit
    let isActive: Bool
    let isLoading: Bool
    let maxSelectionCount: Int
    let onPickItems: ([PhotosPickerItem]) -> Void
    let onUpdateFocal: (CGFloat, CGFloat) -> Void
    let onSelect: () -> Void

    @State private var dragStart: CGPoint?

    private let cornerRadius: CGFloat = 0
    private let emptySlotTints = [
        Color(red: 0.91, green: 0.94, blue: 0.93),
        Color(red: 0.92, green: 0.94, blue: 0.97),
        Color(red: 0.94, green: 0.94, blue: 0.91),
        Color(red: 0.92, green: 0.95, blue: 0.94),
        Color(red: 0.94, green: 0.93, blue: 0.96),
        Color(red: 0.95, green: 0.93, blue: 0.91),
    ]
    private let emptySlotAccents = [
        AppTheme.primary,
        AppTheme.accent,
        Color(red: 0.18, green: 0.56, blue: 0.48),
        Color(red: 0.70, green: 0.45, blue: 0.10),
        Color(red: 0.50, green: 0.30, blue: 0.72),
        Color(red: 0.72, green: 0.32, blue: 0.22),
    ]

    @ViewBuilder
    var body: some View {
        ZStack {
            slotBackground
            slotContent
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .compositingGroup()
        .overlay {
            slotBorder
        }
        .animation(.easeOut(duration: 0.16), value: isActive)
    }

    @ViewBuilder
    private var slotBackground: some View {
        if preview != nil {
            Color.black
        } else if isLoading {
            emptySlotTint.opacity(0.78)
        } else {
            emptySlotTint.opacity(isActive ? 0.92 : 0.58)
        }
    }

    @ViewBuilder
    private var slotContent: some View {
        if let preview {
            filledSlotContent(preview: preview)
        } else if isLoading {
            VStack(spacing: 7) {
                ProgressView()
                    .tint(emptySlotAccent)
                Text(language.text(.loading))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(emptySlotAccent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                onSelect()
            }
        } else {
            PhotosPicker(
                selection: Binding(
                    get: { [] },
                    set: { items in
                        guard !items.isEmpty else { return }
                        onPickItems(items)
                    }
                ),
                maxSelectionCount: maxSelectionCount,
                matching: .videos,
                preferredItemEncoding: .compatible
            ) {
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                    VStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(emptySlotAccent)
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.72), in: Circle())
                        Text(language.addVideo(slot.id))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                onSelect()
            })
        }
    }

    private var slotBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(slotBorderColor, lineWidth: isActive ? 2.5 : 1)
            .padding(isActive ? 1 : 0)
            .allowsHitTesting(false)
    }

    private var slotBorderColor: Color {
        if isLoading {
            return Color.white.opacity(0.42)
        }
        if isActive {
            return preview == nil ? emptySlotAccent : AppTheme.primary
        }
        return preview == nil ? Color.clear : Color.white.opacity(0.14)
    }

    private var emptySlotTint: Color {
        emptySlotTints[max(0, slot.id) % emptySlotTints.count]
    }

    private var emptySlotAccent: Color {
        emptySlotAccents[max(0, slot.id) % emptySlotAccents.count]
    }

    private func filledSlotContent(preview: NativeVideoPreview) -> some View {
        GeometryReader { proxy in
            ZStack {
                SlotVideoPreview(preview: preview, edit: edit, cornerRadius: cornerRadius)
                LinearGradient(
                    colors: [Color.black.opacity(0.26), Color.black.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .center
                )
                VStack {
                    HStack {
                        Text(language.videoSlot(slot.id))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.52), in: Capsule())
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onSelect()
                        guard edit.fitMode == .fill else { return }

                        if dragStart == nil {
                            dragStart = CGPoint(x: edit.focalX, y: edit.focalY)
                        }

                        let start = dragStart ?? CGPoint(x: edit.focalX, y: edit.focalY)
                        let deltaX = value.translation.width / max(proxy.size.width, 1)
                        let deltaY = value.translation.height / max(proxy.size.height, 1)
                        onUpdateFocal(start.x - deltaX, start.y - deltaY)
                    }
                    .onEnded { _ in
                        dragStart = nil
                    }
            )
        }
    }
}

private struct SlotVideoPreview: View {
    let preview: NativeVideoPreview
    let edit: NativeSlotEdit
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let mediaSize = preview.thumbnail?.size ?? CGSize(width: 16, height: 9)
            let baseScale = previewBaseScale(container: proxy.size, mediaSize: mediaSize, fitMode: edit.fitMode)
            let scale = baseScale * (edit.fitMode == .fill ? edit.zoom : 1)
            let renderedSize = CGSize(width: mediaSize.width * scale, height: mediaSize.height * scale)
            let overflowX = max(0, renderedSize.width - proxy.size.width)
            let overflowY = max(0, renderedSize.height - proxy.size.height)

            LoopingVideoPlayer(url: preview.url)
                .frame(width: renderedSize.width, height: renderedSize.height)
                .position(
                    x: proxy.size.width / 2 + (0.5 - edit.focalX) * overflowX,
                    y: proxy.size.height / 2 + (0.5 - edit.focalY) * overflowY
                )
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .compositingGroup()
    }

    private func previewBaseScale(container: CGSize, mediaSize: CGSize, fitMode: NativeFitMode) -> CGFloat {
        guard mediaSize.width > 0, mediaSize.height > 0 else { return 1 }
        let widthScale = container.width / mediaSize.width
        let heightScale = container.height / mediaSize.height

        switch fitMode {
        case .fill:
            return max(widthScale, heightScale)
        case .fit:
            return min(widthScale, heightScale)
        }
    }
}

private struct LoopingVideoPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingVideoPlayerView {
        let view = LoopingVideoPlayerView()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.cornerRadius = 0
        view.playerLayer.masksToBounds = true
        context.coordinator.configure(url: url, in: view)
        return view
    }

    func updateUIView(_ view: LoopingVideoPlayerView, context: Context) {
        view.playerLayer.cornerRadius = 0
        view.playerLayer.masksToBounds = true
        context.coordinator.configure(url: url, in: view)
    }

    static func dismantleUIView(_ view: LoopingVideoPlayerView, coordinator: Coordinator) {
        coordinator.stop()
        view.playerLayer.player = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private var currentURL: URL?
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?

        func configure(url: URL, in view: LoopingVideoPlayerView) {
            guard currentURL != url else {
                player?.play()
                return
            }

            stop()
            currentURL = url

            let item = AVPlayerItem(url: url)
            let queuePlayer = AVQueuePlayer()
            queuePlayer.isMuted = true
            queuePlayer.actionAtItemEnd = .none
            queuePlayer.automaticallyWaitsToMinimizeStalling = false

            player = queuePlayer
            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            view.playerLayer.player = queuePlayer
            queuePlayer.play()
        }

        func stop() {
            player?.pause()
            looper = nil
            player = nil
            currentURL = nil
        }
    }
}

private final class LoopingVideoPlayerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}

private struct NativeSlotSelector: View {
    @Environment(\.appLanguage) private var language

    let totalCount: Int
    let activeSlot: Int
    let previews: [NativeVideoPreview?]
    let loadingSlots: Set<Int>
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(0..<totalCount, id: \.self) { index in
                    let isActive = activeSlot == index
                    let preview = index < previews.count ? previews[index] : nil
                    let isLoading = loadingSlots.contains(index)

                    Button {
                        onSelect(index)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(language.videoSlot(index))
                                .font(.system(size: 12, weight: .semibold))
                            Text(slotSubtitle(preview: preview, isLoading: isLoading))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(isActive ? AppTheme.primary : AppTheme.muted)
                        }
                        .frame(width: 78, alignment: .leading)
                        .padding(.horizontal, 10)
                        .frame(height: 44)
                        .background(isActive ? AppTheme.primarySoft : Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(isActive ? AppTheme.primary : AppTheme.border, lineWidth: isActive ? 2 : 1)
                        }
                    }
                    .foregroundStyle(isActive ? AppTheme.primary : AppTheme.ink)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }

    private func slotSubtitle(preview: NativeVideoPreview?, isLoading: Bool) -> String {
        if isLoading { return language.text(.loadingShort) }
        if let duration = preview?.duration {
            return String(format: "%.2fs", duration)
        }
        return language.text(.notSelected)
    }
}

private struct NativeLiveEditControls: View {
    @Environment(\.appLanguage) private var language

    let activeSlot: Int
    let activeEdit: NativeSlotEdit
    let activePreview: NativeVideoPreview?
    let isLoading: Bool
    let isGenerating: Bool
    let totalCount: Int
    let filledCount: Int
    let outputDuration: Double
    let availableClipDuration: Double
    let activeMaxStart: Double
    let activeEndTime: Double
    let message: LiveComposerMessage
    let onFitModeChange: (NativeFitMode) -> Void
    let onZoomChange: (CGFloat) -> Void
    let onFocalXChange: (CGFloat) -> Void
    let onFocalYChange: (CGFloat) -> Void
    let onDurationChange: (Double) -> Void
    let onStartChange: (Double) -> Void
    @Binding var replacementPickerItem: PhotosPickerItem?

    private var hasMedia: Bool {
        activePreview != nil
    }

    private var controlsDisabled: Bool {
        !hasMedia || isLoading || isGenerating
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text(.currentSlot))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.primary)
                    Text(language.videoSlot(activeSlot))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                }
                Spacer()
                PhotosPicker(
                    selection: $replacementPickerItem,
                    matching: .videos,
                    preferredItemEncoding: .compatible
                ) {
                    Text(hasMedia ? language.text(.replace) : language.text(.choose))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(height: 36)
                        .padding(.horizontal, 13)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.border, lineWidth: 1)
                        }
                }
                .disabled(isGenerating)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(language.text(.displayMode))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                HStack(spacing: 0) {
                    ModePill(title: language.text(.fitFill), isActive: activeEdit.fitMode == .fill) {
                        onFitModeChange(.fill)
                    }
                    ModePill(title: language.text(.fitFull), isActive: activeEdit.fitMode == .fit) {
                        onFitModeChange(.fit)
                    }
                }
                .padding(4)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                .disabled(controlsDisabled)
                .opacity(controlsDisabled ? 0.45 : 1)
            }

            VStack(spacing: 14) {
                SliderControl(
                    title: language.text(.zoom),
                    valueText: String(format: "%.1fx", activeEdit.zoom),
                    value: Double(activeEdit.zoom),
                    range: 1...3,
                    step: 0.05,
                    isDisabled: controlsDisabled || activeEdit.fitMode == .fit
                ) { value in
                    onZoomChange(CGFloat(value))
                }

                HStack(spacing: 12) {
                    SliderControl(
                        title: language.text(.horizontal),
                        valueText: "\(Int(activeEdit.focalX * 100))%",
                        value: Double(activeEdit.focalX),
                        range: 0...1,
                        step: 0.01,
                        isDisabled: controlsDisabled
                    ) { value in
                        onFocalXChange(CGFloat(value))
                    }

                    SliderControl(
                        title: language.text(.vertical),
                        valueText: "\(Int(activeEdit.focalY * 100))%",
                        value: Double(activeEdit.focalY),
                        range: 0...1,
                        step: 0.01,
                        isDisabled: controlsDisabled
                    ) { value in
                        onFocalYChange(CGFloat(value))
                    }
                }

                SliderControl(
                    title: language.text(.clipDuration),
                    valueText: String(format: "%.2fs", outputDuration),
                    value: outputDuration,
                    range: NativeSlotEdit.minDuration...max(NativeSlotEdit.minDuration, availableClipDuration),
                    step: 0.05,
                    isDisabled: controlsDisabled || availableClipDuration <= NativeSlotEdit.minDuration
                ) { value in
                    onDurationChange(value)
                }

                SliderControl(
                    title: language.text(.startTime),
                    valueText: String(format: "%.2fs", activeEdit.start),
                    value: activeEdit.start,
                    range: 0...max(0, activeMaxStart),
                    step: 0.05,
                    isDisabled: controlsDisabled || activeMaxStart <= 0
                ) { value in
                    onStartChange(value)
                }
            }

            if let messageText = message.text(language: language) {
                Text(messageText)
                    .font(.system(size: 13))
                    .lineSpacing(3)
                    .foregroundStyle(AppTheme.muted)
            }

            Text(
                hasMedia
                ? language.exportRange(start: activeEdit.start, end: activeEndTime, filledCount: filledCount, totalCount: totalCount)
                : language.materialProgress(filledCount: filledCount, totalCount: totalCount)
            )
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.faint)
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}

private struct ModePill: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isActive ? AppTheme.primary : AppTheme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isActive ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }
}

private struct SliderControl: View {
    let title: String
    let valueText: String
    let value: Double
    let range: ClosedRange<Double>
    let step: Double
    let isDisabled: Bool
    let onChange: (Double) -> Void

    var body: some View {
        let resolvedStep = NativeSliderBounds.resolvedStep(step)
        let resolvedRange = NativeSliderBounds.resolvedRange(
            lower: range.lowerBound,
            upper: range.upperBound,
            step: resolvedStep
        )
        let resolvedValue = NativeSliderBounds.clamped(value, in: resolvedRange)

        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text(valueText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
            }
            Slider(
                value: Binding(
                    get: { resolvedValue },
                    set: { onChange($0) }
                ),
                in: resolvedRange,
                step: resolvedStep
            )
            .tint(AppTheme.primary)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.35 : 1)
        }
    }
}

private struct VideoSlotPlaceholder: View {
    @Environment(\.appLanguage) private var language

    let index: Int
    let isFilled: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isFilled ? "checkmark.circle.fill" : "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isFilled ? AppTheme.primary : AppTheme.muted)
            Text(language.videoSlot(index))
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(height: 86)
        .frame(maxWidth: .infinity)
        .background(isFilled ? AppTheme.primary.opacity(0.08) : AppTheme.surface, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFilled ? AppTheme.primary.opacity(0.25) : Color.black.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct LiveResultScreen: View {
    @Environment(\.appLanguage) private var language

    let draft: NativeLiveDraft

    @State private var isSaving = false
    @State private var didSave = false
    @State private var status: SaveStatusKind?
    @State private var isSaveError = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(language.text(.liveResultTitle))
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(language.text(.liveResultSubtitle))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)

                    LivePhotoPreview(
                        imageURL: draft.imageURL,
                        videoURL: draft.videoURL
                    )
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .background(AppTheme.surface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    }

                    if let status {
                        Text(language.saveStatus(status))
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(isSaveError ? AppTheme.error : (didSave ? AppTheme.primary : AppTheme.muted))
                    }
                }
                .padding(16)
                .padding(.bottom, 86)
            }

            BottomActionBar(
                title: LiveResultPrimaryAction.title(isSaving: isSaving, didSave: didSave, language: language),
                isDisabled: isSaving
            ) {
                if didSave {
                    openPhotosLibrary()
                } else {
                    Task {
                        await saveLivePhoto()
                    }
                }
            }
        }
        .background(Color.white)
        .toolbar(.visible, for: .navigationBar)
        .navigationTitle(language.text(.preview))
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func saveLivePhoto() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await PhotoSaver.saveLivePhoto(
                imageURL: draft.imageURL,
                videoURL: draft.videoURL
            )
            didSave = true
            isSaveError = false
            status = .saved
        } catch {
            didSave = false
            isSaveError = true
            status = .failed
        }
    }

    @MainActor
    private func openPhotosLibrary() {
        isSaveError = false
        PhotoLibraryOpener.open { newStatus in
            status = newStatus
        }
    }
}

private struct LivePhotoPreview: UIViewRepresentable {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LiveMix",
        category: "LivePhotoPreview"
    )

    let imageURL: URL
    let videoURL: URL

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        context.coordinator.attach(to: view)
        context.coordinator.load(imageURL: imageURL, videoURL: videoURL, into: view)
        return view
    }

    func updateUIView(_ view: PHLivePhotoView, context: Context) {
        context.coordinator.attach(to: view)
        context.coordinator.load(imageURL: imageURL, videoURL: videoURL, into: view)
    }

    static func dismantleUIView(_ view: PHLivePhotoView, coordinator: Coordinator) {
        coordinator.stop()
        view.livePhoto = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        private var currentResourceKey: String?
        private weak var livePhotoView: PHLivePhotoView?
        private var longPressGesture: UILongPressGestureRecognizer?

        func attach(to view: PHLivePhotoView) {
            if livePhotoView === view { return }

            if let longPressGesture, let oldView = livePhotoView {
                oldView.removeGestureRecognizer(longPressGesture)
            }

            livePhotoView = view
            view.isUserInteractionEnabled = true

            let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            gesture.minimumPressDuration = 0.18
            gesture.cancelsTouchesInView = false
            view.addGestureRecognizer(gesture)
            longPressGesture = gesture
        }

        func load(imageURL: URL, videoURL: URL, into view: PHLivePhotoView) {
            attach(to: view)
            let resourceKey = "\(imageURL.path)|\(videoURL.path)"
            guard currentResourceKey != resourceKey else { return }

            currentResourceKey = resourceKey
            view.stopPlayback()
            view.livePhoto = nil

            let placeholder = UIImage(contentsOfFile: imageURL.path)
            PHLivePhoto.request(
                withResourceFileURLs: [imageURL, videoURL],
                placeholderImage: placeholder,
                targetSize: .zero,
                contentMode: .aspectFit
            ) { [weak view] livePhoto, info in
                guard let view else { return }
                if let cancelled = info[PHLivePhotoInfoCancelledKey] as? Bool, cancelled {
                    LivePhotoPreview.logger.notice("Live Photo preview request was cancelled")
                    return
                }
                if let error = info[PHLivePhotoInfoErrorKey] as? Error {
                    LivePhotoPreview.logger.error(
                        "Live Photo preview request failed: \(String(reflecting: error), privacy: .public)"
                    )
                } else if livePhoto == nil {
                    LivePhotoPreview.logger.warning("Live Photo preview returned no error and no Live Photo")
                } else {
                    LivePhotoPreview.logger.info("Live Photo preview loaded")
                }
                view.livePhoto = livePhoto
            }
        }

        func stop() {
            livePhotoView?.stopPlayback()
            if let longPressGesture, let livePhotoView {
                livePhotoView.removeGestureRecognizer(longPressGesture)
            }
            longPressGesture = nil
            livePhotoView = nil
            currentResourceKey = nil
        }

        @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                play()
            case .ended, .cancelled, .failed:
                livePhotoView?.stopPlayback()
            default:
                break
            }
        }

        private func play() {
            guard let livePhotoView, livePhotoView.livePhoto != nil else { return }
            livePhotoView.startPlayback(with: .full)
        }
    }
}

private struct ImageToolPickerScreen: View {
    @Environment(\.appLanguage) private var language

    private let columns = [
        GridItem(.adaptive(minimum: 168), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 0) {
            PageTopBar(backLabel: language.text(.backHome)) {
                Badge(text: language.text(.imageMode), tone: .neutral)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(language.text(.imageToolsTitle))
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Text(language.text(.imageToolsSubtitle))
                            .font(.system(size: 15))
                            .lineSpacing(4)
                            .foregroundStyle(AppTheme.muted)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        NavigationLink {
                            ImageJoinScreen(mode: .horizontal)
                        } label: {
                            ImageToolCard(
                                title: language.text(.imageToolHorizontalTitle),
                                detail: language.text(.imageToolHorizontalDetail),
                                preview: .horizontal
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ImageJoinScreen(mode: .vertical)
                        } label: {
                            ImageToolCard(
                                title: language.text(.imageToolVerticalTitle),
                                detail: language.text(.imageToolVerticalDetail),
                                preview: .vertical
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SplitNineScreen()
                        } label: {
                            ImageToolCard(
                                title: language.text(.imageToolGridTitle),
                                detail: language.text(.imageToolGridDetail),
                                preview: .grid
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
        }
        .background(AppTheme.canvas)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private enum ImageToolPreview {
    case horizontal
    case vertical
    case grid
}

private struct ImageToolCard: View {
    let title: String
    let detail: String
    let preview: ImageToolPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                AppTheme.surface
                switch preview {
                case .horizontal:
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3).fill(AppTheme.primarySoft)
                        RoundedRectangle(cornerRadius: 3).fill(AppTheme.accentSoft)
                    }
                    .padding(8)
                case .vertical:
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3).fill(AppTheme.primarySoft)
                        RoundedRectangle(cornerRadius: 3).fill(AppTheme.accentSoft)
                    }
                    .padding(8)
                case .grid:
                    SplitNinePreviewArtwork(lineWidth: 1)
                    .padding(8)
                }
            }
            .frame(height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(detail)
                    .font(.system(size: 12))
                    .lineSpacing(2)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}

private struct SplitNinePreviewArtwork: View {
    var lineWidth: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        AppTheme.primarySoft,
                        AppTheme.accentSoft.opacity(0.85),
                        AppTheme.primarySoft.opacity(0.78),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Path { path in
                    let width = proxy.size.width
                    let height = proxy.size.height

                    for column in 1...2 {
                        let x = width * CGFloat(column) / 3
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }

                    for row in 1...2 {
                        let y = height * CGFloat(row) / 3
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.9), lineWidth: lineWidth)
            }
        }
    }
}

private struct NativeImageSource: Identifiable {
    let id = UUID()
    var image: UIImage
    var liveVideoURL: URL?
    var edit: NativeImageEdit = .default

    var isLivePhoto: Bool {
        liveVideoURL != nil
    }
}

private enum NativeImageSourceLoader {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LiveMix",
        category: "ImageSourceLoader"
    )

    enum LoadError: Error {
        case unreadableImage
        case missingPairedVideo
        case resourceWriteFailed
    }

    static func source(from item: PhotosPickerItem) async throws -> NativeImageSource {
        guard let data = try await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            throw LoadError.unreadableImage
        }
        let rawPixelSize = image.cgImage.map {
            CGSize(width: $0.width, height: $0.height)
        } ?? .zero
        let normalizedImage = ImageOrientationNormalizer.normalized(image)
        logger.info(
            "Image imported: orientation=\(image.imageOrientation.rawValue), pointSize=\(describe(image.size), privacy: .public), rawPixels=\(describe(rawPixelSize), privacy: .public), normalizedPixels=\(describe(normalizedImage.size), privacy: .public)"
        )

        let shouldContainLiveVideo = looksLikeLivePhoto(item)
        do {
            if let liveVideoURL = try await liveVideoURL(from: item) {
                return NativeImageSource(image: normalizedImage, liveVideoURL: liveVideoURL)
            }
        } catch {
            if shouldContainLiveVideo {
                throw error
            }
        }

        if shouldContainLiveVideo {
            throw LoadError.missingPairedVideo
        }

        return NativeImageSource(image: normalizedImage)
    }

    private static func describe(_ size: CGSize) -> String {
        String(format: "%.0fx%.0f", size.width, size.height)
    }

    private static func liveVideoURL(from item: PhotosPickerItem) async throws -> URL? {
        if let livePhoto = try? await item.loadTransferable(type: PHLivePhoto.self) {
            return try await pairedVideoURL(for: livePhoto)
        }

        guard let assetLocalIdentifier = item.itemIdentifier else {
            return nil
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetLocalIdentifier], options: nil)
        guard let asset = assets.firstObject else {
            return nil
        }
        guard asset.mediaSubtypes.contains(.photoLive) else {
            return nil
        }

        return try await pairedVideoURL(for: asset)
    }

    private static func pairedVideoURL(for livePhoto: PHLivePhoto) async throws -> URL {
        let resources = PHAssetResource.assetResources(for: livePhoto)
        return try await pairedVideoURL(from: resources)
    }

    private static func pairedVideoURL(for asset: PHAsset) async throws -> URL {
        let resources = PHAssetResource.assetResources(for: asset)
        return try await pairedVideoURL(from: resources)
    }

    private static func pairedVideoURL(from resources: [PHAssetResource]) async throws -> URL {
        guard let pairedVideo = resources.first(where: { $0.type == .pairedVideo }) else {
            throw LoadError.missingPairedVideo
        }

        let extensionValue = URL(fileURLWithPath: pairedVideo.originalFilename).pathExtension
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(extensionValue.isEmpty ? "mov" : extensionValue)

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                PHAssetResourceManager.default().writeData(
                    for: pairedVideo,
                    toFile: outputURL,
                    options: options
                ) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            throw LoadError.resourceWriteFailed
        }

        return outputURL
    }

    private static func looksLikeLivePhoto(_ item: PhotosPickerItem) -> Bool {
        if item.supportedContentTypes.contains(where: { contentType in
            contentType.identifier.localizedCaseInsensitiveContains("live-photo")
                || contentType.identifier.localizedCaseInsensitiveContains("livephoto")
        }) {
            return true
        }

        guard let assetLocalIdentifier = item.itemIdentifier else {
            return false
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetLocalIdentifier], options: nil)
        return assets.firstObject?.mediaSubtypes.contains(.photoLive) == true
    }
}

private struct ImageJoinScreen: View {
    @Environment(\.appLanguage) private var language

    let mode: ImageJoinMode

    private let liveComposer = NativeImageJoinLiveComposer()

    @State private var appendPickerItems: [PhotosPickerItem] = []
    @State private var replacementPickerItem: PhotosPickerItem?
    @State private var sources: [NativeImageSource] = []
    @State private var activeIndex = 0
    @State private var isLoading = false
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var isResultPresented = false
    @State private var generatedImage: GeneratedImage?
    @State private var generatedLiveDraft: NativeLiveDraft?
    @AppStorage("imageJoinCanvasStyle") private var canvasStyle: ImageJoinCanvasStyle = .long

    private let maxImages = 9

    private var activeSource: NativeImageSource? {
        guard sources.indices.contains(activeIndex) else { return nil }
        return sources[activeIndex]
    }

    private var outputSize: CGSize {
        if sources.contains(where: \.isLivePhoto) {
            return ImageJoinLayout.liveOutputSize(
                for: sources.count,
                mode: mode,
                canvasStyle: canvasStyle
            )
        }

        return ImageJoinLayout.outputSize(
            for: sources.count,
            mode: mode,
            canvasStyle: canvasStyle,
            tileSize: canvasStyle == .long
                ? ImageJoinLayout.longImageTileSize
                : ImageJoinLayout.squareImageCanvasSize
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            PageTopBar(backLabel: language.text(.backImageCollage)) {
                Badge(text: language.maxImages(maxImages), tone: .neutral)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mode.localizedTitle(language))
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                        Text(language.text(.imageJoinSubtitle))
                            .font(.system(size: 14))
                            .lineSpacing(4)
                            .foregroundStyle(AppTheme.muted)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(language.text(.canvasStyle))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        Picker(language.text(.canvasStyle), selection: $canvasStyle) {
                            ForEach(ImageJoinCanvasStyle.allCases) { style in
                                Text(style.localizedTitle(language)).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(isLoading || isGenerating)
                    }

                    if sources.isEmpty {
                        PhotosPicker(
                            selection: $appendPickerItems,
                            maxSelectionCount: maxImages,
                            matching: .any(of: [.images, .livePhotos]),
                            preferredItemEncoding: .current
                        ) {
                            ImageJoinEmptyPicker(mode: mode)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                    } else {
                        VStack(spacing: 14) {
                            ImageJoinCanvas(
                                sources: sources,
                                mode: mode,
                                canvasStyle: canvasStyle,
                                activeIndex: activeIndex,
                                isLoading: isLoading || isGenerating,
                                loadingTitle: isGenerating ? ImageGenerationFeedback.imageJoinTitle(language: language) : nil,
                                onEditChange: updateImageEdit
                            ) { index in
                                activeIndex = index
                            }

                            ImageJoinThumbnailRail(
                                sources: sources,
                                activeIndex: activeIndex,
                                maxImages: maxImages,
                                isDisabled: isLoading || isGenerating,
                                appendPickerItems: $appendPickerItems
                            ) { index in
                                activeIndex = index
                            }

                            ImageJoinEditPanel(
                                mode: mode,
                                activeIndex: activeIndex,
                                sourceCount: sources.count,
                                outputSize: outputSize,
                                activeSource: activeSource,
                                isDisabled: isLoading || isGenerating,
                                replacementPickerItem: $replacementPickerItem,
                                onDelete: removeActiveSource,
                                onZoomChange: { updateActiveEdit(zoom: $0) },
                                onFocalXChange: { updateActiveEdit(focalX: $0) },
                                onFocalYChange: { updateActiveEdit(focalY: $0) }
                            )

                            if isLoading {
                                Text(language.text(.loadingMaterials) + "...")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.muted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.error.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(16)
                .padding(.bottom, 86)
            }

            BottomActionBar(
                title: bottomActionTitle,
                isDisabled: sources.isEmpty || isLoading || isGenerating
            ) {
                generateImage()
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isResultPresented) {
            if let generatedLiveDraft {
                LiveResultScreen(draft: generatedLiveDraft)
            } else if let generatedImage {
                ImageResultScreen(image: generatedImage.image, title: mode.localizedTitle(language))
            }
        }
        .onChange(of: appendPickerItems) { newItems in
            guard !newItems.isEmpty else { return }
            Task {
                await appendImages(from: newItems)
                appendPickerItems = []
            }
        }
        .onChange(of: replacementPickerItem) { newItem in
            guard newItem != nil else { return }
            Task {
                await replaceActiveImage(with: newItem)
                replacementPickerItem = nil
            }
        }
        .onChange(of: canvasStyle) { _ in
            generatedImage = nil
            generatedLiveDraft = nil
        }
    }

    private var bottomActionTitle: String {
        if sources.isEmpty { return language.text(.chooseImagesFirst) }
        if isLoading { return language.text(.loadingMaterials) }
        if isGenerating { return language.text(.generating) }
        return sources.contains(where: \.isLivePhoto) ? language.text(.generateLivePhoto) : language.text(.generateImage)
    }

    @MainActor
    private func appendImages(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        let slotsLeft = maxImages - sources.count
        guard slotsLeft > 0 else {
            errorMessage = language.maxImagesExceeded(maxImages)
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var loadedSources: [NativeImageSource] = []

        for item in items.prefix(slotsLeft) {
            do {
                let source = try await NativeImageSourceLoader.source(from: item)
                loadedSources.append(source)
            } catch NativeImageSourceLoader.LoadError.missingPairedVideo,
                    NativeImageSourceLoader.LoadError.resourceWriteFailed {
                errorMessage = language.text(.liveResourceUnavailablePlural)
            } catch {
                continue
            }
        }

        if loadedSources.isEmpty {
            if errorMessage == nil {
                errorMessage = language.text(.unreadableMaterials)
            }
            return
        }

        let wasEmpty = sources.isEmpty
        sources.append(contentsOf: loadedSources)
        if wasEmpty {
            activeIndex = 0
        }
        generatedImage = nil
        generatedLiveDraft = nil

        if items.count > slotsLeft {
            errorMessage = language.maxMaterialsKept(slotsLeft)
        }
    }

    @MainActor
    private func replaceActiveImage(with item: PhotosPickerItem?) async {
        guard let item, sources.indices.contains(activeIndex) else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let source = try await NativeImageSourceLoader.source(from: item)
            cleanup(source: sources[activeIndex])
            sources[activeIndex] = source
            generatedImage = nil
            generatedLiveDraft = nil
        } catch NativeImageSourceLoader.LoadError.missingPairedVideo,
                NativeImageSourceLoader.LoadError.resourceWriteFailed {
            errorMessage = language.text(.liveResourceUnavailableSingle)
        } catch {
            errorMessage = language.text(.unreadableMaterial)
        }
    }

    private func updateActiveEdit(
        zoom: CGFloat? = nil,
        focalX: CGFloat? = nil,
        focalY: CGFloat? = nil
    ) {
        guard sources.indices.contains(activeIndex) else { return }

        var edit = sources[activeIndex].edit
        if let zoom { edit.zoom = zoom }
        if let focalX { edit.focalX = focalX }
        if let focalY { edit.focalY = focalY }
        sources[activeIndex].edit = edit.clamped()
        generatedImage = nil
        generatedLiveDraft = nil
    }

    private func updateImageEdit(index: Int, edit: NativeImageEdit) {
        guard sources.indices.contains(index) else { return }

        activeIndex = index
        sources[index].edit = edit.clamped()
        generatedImage = nil
        generatedLiveDraft = nil
    }

    private func removeActiveSource() {
        guard sources.indices.contains(activeIndex) else { return }

        let removedIndex = activeIndex
        cleanup(source: sources[removedIndex])
        sources.remove(at: removedIndex)
        activeIndex = sources.isEmpty ? 0 : max(0, min(removedIndex - 1, sources.count - 1))
        generatedImage = nil
        generatedLiveDraft = nil
    }

    private func generateImage() {
        guard !sources.isEmpty else { return }
        isGenerating = true
        errorMessage = nil

        Task { @MainActor in
            defer { isGenerating = false }
            try? await Task.sleep(nanoseconds: ImageGenerationFeedback.minimumVisibleNanoseconds)

            do {
                if sources.contains(where: \.isLivePhoto) {
                    let draft = try await liveComposer.compose(
                        sources: sources.map {
                            NativeImageJoinLiveSource(
                                image: $0.image,
                                liveVideoURL: $0.liveVideoURL,
                                edit: $0.edit
                            )
                        },
                        mode: mode,
                        canvasStyle: canvasStyle
                    )
                    generatedImage = nil
                    generatedLiveDraft = draft
                } else {
                    let image = try ImageCollageRenderer.join(
                        images: sources.map(\.image),
                        edits: sources.map(\.edit),
                        mode: mode,
                        canvasStyle: canvasStyle,
                        tileSize: canvasStyle == .long
                            ? ImageJoinLayout.longImageTileSize
                            : ImageJoinLayout.squareImageCanvasSize
                    )
                    generatedLiveDraft = nil
                    generatedImage = GeneratedImage(image: image)
                }
                isResultPresented = true
            } catch {
                errorMessage = sources.contains(where: \.isLivePhoto) ? language.text(.imageJoinLiveFailed) : language.text(.imageJoinImageFailed)
            }
        }
    }

    private func cleanup(source: NativeImageSource) {
        if let liveVideoURL = source.liveVideoURL {
            try? FileManager.default.removeItem(at: liveVideoURL)
        }
    }
}

private struct SplitNineScreen: View {
    @Environment(\.appLanguage) private var language

    @State private var pickerItem: PhotosPickerItem?
    @State private var sourceImage: UIImage?
    @State private var edit = NativeImageEdit.default
    @State private var isLoading = false
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var isResultPresented = false
    @State private var generatedTiles: GeneratedTiles?

    var body: some View {
        VStack(spacing: 0) {
            PageTopBar(backLabel: language.text(.backImageCollage)) {
                Badge(text: language.text(.splitNineBadge), tone: .neutral)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(language.text(.splitNineTitle))
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                        Text(language.text(.splitNineSubtitle))
                            .font(.system(size: 14))
                            .lineSpacing(4)
                            .foregroundStyle(AppTheme.muted)
                    }

                    if let sourceImage {
                        SplitNinePickerPreview(
                            image: sourceImage,
                            edit: edit,
                            isDraggable: !(isLoading || isGenerating),
                            loadingTitle: isGenerating ? ImageGenerationFeedback.splitNineTitle(language: language) : nil,
                            onDragEditChange: { newEdit in
                                edit = newEdit
                                generatedTiles = nil
                            }
                        )
                    } else {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            SplitNinePickerPreview(image: nil, edit: edit)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                    }

                    if isLoading {
                        Text(language.text(.loadingImage) + "...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.muted)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.error.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }

                    SplitNineEditPanel(
                        hasImage: sourceImage != nil,
                        edit: edit,
                        isDisabled: sourceImage == nil || isLoading || isGenerating,
                        isPickerDisabled: isLoading || isGenerating,
                        pickerItem: $pickerItem,
                        onZoomChange: { updateEdit(zoom: $0) },
                        onFocalXChange: { updateEdit(focalX: $0) },
                        onFocalYChange: { updateEdit(focalY: $0) }
                    )
                }
                .padding(16)
                .padding(.bottom, 86)
            }

            BottomActionBar(
                title: bottomActionTitle,
                isDisabled: sourceImage == nil || isLoading || isGenerating
            ) {
                generateTiles()
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isResultPresented) {
            if let generatedTiles {
                SplitNineResultScreen(tiles: generatedTiles.tiles)
            }
        }
        .onChange(of: pickerItem) { newItem in
            guard newItem != nil else { return }
            Task {
                await loadImage(from: newItem)
                pickerItem = nil
            }
        }
    }

    private var bottomActionTitle: String {
        if sourceImage == nil { return language.text(.chooseImagesFirst) }
        if isLoading { return language.text(.loadingImage) }
        return isGenerating ? language.text(.cutNine) : language.text(.generateNineImages)
    }

    @MainActor
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        isLoading = true
        errorMessage = nil

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            sourceImage = image
            edit = .default
            generatedTiles = nil
        } else {
            errorMessage = language.text(.unreadableImage)
        }

        isLoading = false
    }

    private func updateEdit(
        zoom: CGFloat? = nil,
        focalX: CGFloat? = nil,
        focalY: CGFloat? = nil
    ) {
        if let zoom { edit.zoom = zoom }
        if let focalX { edit.focalX = focalX }
        if let focalY { edit.focalY = focalY }
        edit = edit.clamped()
        generatedTiles = nil
    }

    private func generateTiles() {
        guard let sourceImage else { return }
        isGenerating = true
        errorMessage = nil

        Task { @MainActor in
            defer { isGenerating = false }
            try? await Task.sleep(nanoseconds: ImageGenerationFeedback.minimumVisibleNanoseconds)

            do {
                let tiles = try ImageCollageRenderer.splitNine(image: sourceImage, edit: edit)
                generatedTiles = GeneratedTiles(tiles: tiles)
                isResultPresented = true
            } catch {
                errorMessage = language.text(.splitNineFailed)
            }
        }
    }
}

private struct ImageResultScreen: View {
    @Environment(\.appLanguage) private var language

    let image: UIImage
    let title: String

    @State private var isSaving = false
    @State private var didSave = false
    @State private var status: SaveStatusKind?
    @State private var isSaveError = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(language.text(.imageResultTitle))
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Text(language.text(.imageResultSubtitle))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.surface)
                        .overlay {
                            Rectangle()
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        }

                    if let status {
                        Text(language.saveStatus(status))
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(isSaveError ? AppTheme.error : (didSave ? AppTheme.primary : AppTheme.muted))
                    }
                }
                .padding(16)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BottomActionBar(
                    title: PhotoResultPrimaryAction.title(
                        saveTitle: language.text(.saveToAlbum),
                        isSaving: isSaving,
                        didSave: didSave,
                        language: language
                    ),
                    isDisabled: isSaving
                ) {
                    if didSave {
                        openPhotosLibrary()
                    } else {
                        Task {
                            await saveImage()
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .toolbar(.visible, for: .navigationBar)
        .navigationTitle(language.text(.preview))
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func saveImage() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await PhotoSaver.save(image: image)
            didSave = true
            isSaveError = false
            status = .saved
        } catch {
            didSave = false
            isSaveError = true
            status = .failed
        }
    }

    @MainActor
    private func openPhotosLibrary() {
        isSaveError = false
        PhotoLibraryOpener.open { newStatus in
            status = newStatus
        }
    }
}

private struct SplitNineResultScreen: View {
    @Environment(\.appLanguage) private var language

    let tiles: [UIImage]

    @State private var isSaving = false
    @State private var didSave = false
    @State private var status: SaveStatusKind?
    @State private var isSaveError = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                Text(language.text(.gridPreview))
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(Array(tiles.enumerated()), id: \.offset) { _, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()
                    }
                }
                .padding(16)

                if let status {
                    Text(language.saveStatus(status))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(isSaveError ? AppTheme.error : (didSave ? AppTheme.primary : AppTheme.muted))
                        .padding(.horizontal, 16)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BottomActionBar(
                    title: PhotoResultPrimaryAction.title(
                        saveTitle: language.text(.saveAllToAlbum),
                        isSaving: isSaving,
                        didSave: didSave,
                        language: language
                    ),
                    isDisabled: isSaving
                ) {
                    if didSave {
                        openPhotosLibrary()
                    } else {
                        Task {
                            await saveTiles()
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .toolbar(.visible, for: .navigationBar)
        .navigationTitle(language.text(.preview))
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func saveTiles() async {
        isSaving = true
        defer { isSaving = false }

        do {
            for image in tiles {
                try await PhotoSaver.save(image: image)
            }
            didSave = true
            isSaveError = false
            status = .savedTiles
        } catch {
            didSave = false
            isSaveError = true
            status = .failed
        }
    }

    @MainActor
    private func openPhotosLibrary() {
        isSaveError = false
        PhotoLibraryOpener.open { newStatus in
            status = newStatus
        }
    }
}

private struct TemplatePreviewCard: View {
    @Environment(\.appLanguage) private var language

    let template: NativeCollageTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.text(.templatePreview))
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                    Text(template.localizedName(language))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                }
                Spacer()
                Text(language.clipCount(template.slots.count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.white, in: Capsule())
            }

            TemplateMiniPreview(template: template)
                .aspectRatio(1, contentMode: .fit)
        }
        .padding(14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct TemplateMiniPreview: View {
    let template: NativeCollageTemplate

    private let slotInset: CGFloat = 2
    private let slotColors = [
        AppTheme.primary,
        AppTheme.accent,
        Color(red: 0.86, green: 0.58, blue: 0.20),
        Color(red: 0.36, green: 0.62, blue: 0.54),
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.surface
                ForEach(template.slots) { slot in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(slotColors[max(0, slot.id) % slotColors.count])
                        .frame(
                            width: max(proxy.size.width * slot.width - slotInset * 2, 1),
                            height: max(proxy.size.height * slot.height - slotInset * 2, 1)
                        )
                        .position(
                            x: proxy.size.width * (slot.x + slot.width / 2),
                            y: proxy.size.height * (slot.y + slot.height / 2)
                        )
                }
            }
        }
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct EditableImageView: View {
    let image: UIImage
    let edit: NativeImageEdit
    var isDraggable = false
    var onDragEditChange: (NativeImageEdit) -> Void = { _ in }

    var body: some View {
        GeometryReader { proxy in
            let targetSize = proxy.size
            let imageSize = image.size

            ZStack {
                if imageSize.width > 0, imageSize.height > 0, targetSize.width > 0, targetSize.height > 0 {
                    let resolvedEdit = edit.clamped()
                    let baseScale = max(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
                    let scale = baseScale * resolvedEdit.zoom
                    let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
                    let overflowX = max(0, drawSize.width - targetSize.width)
                    let overflowY = max(0, drawSize.height - targetSize.height)

                    Image(uiImage: image)
                        .resizable()
                        .frame(width: drawSize.width, height: drawSize.height)
                        .position(
                            x: drawSize.width / 2 - overflowX * resolvedEdit.focalX,
                            y: drawSize.height / 2 - overflowY * resolvedEdit.focalY
                        )
                } else {
                    AppTheme.raised
                }
            }
            .frame(width: targetSize.width, height: targetSize.height)
            .modifier(
                ImageEditDragModifier(
                    isEnabled: isDraggable,
                    edit: edit,
                    imageSize: imageSize,
                    targetSize: targetSize,
                    onChange: onDragEditChange
                )
            )
        }
        .clipped()
    }
}

private struct ImageEditDragModifier: ViewModifier {
    let isEnabled: Bool
    let edit: NativeImageEdit
    let imageSize: CGSize
    let targetSize: CGSize
    let onChange: (NativeImageEdit) -> Void

    @State private var dragStartEdit: NativeImageEdit?

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 2, coordinateSpace: .local)
                        .onChanged { value in
                            let baseEdit = dragStartEdit ?? edit
                            if dragStartEdit == nil {
                                dragStartEdit = edit
                            }
                            onChange(
                                baseEdit.dragged(
                                    translation: value.translation,
                                    imageSize: imageSize,
                                    targetSize: targetSize
                                )
                            )
                        }
                        .onEnded { _ in
                            dragStartEdit = nil
                        }
                )
        } else {
            content
        }
    }
}

private struct ImageJoinEmptyPicker: View {
    @Environment(\.appLanguage) private var language

    let mode: ImageJoinMode

    var body: some View {
        ZStack {
            AppTheme.raised

            GeometryReader { proxy in
                let frames = ImageJoinLayout.previewFrames(for: 2, mode: mode)

                ForEach(frames.indices, id: \.self) { index in
                    let frame = frames[index]

                    RoundedRectangle(cornerRadius: 8)
                        .fill(index == 0 ? AppTheme.primarySoft : AppTheme.accentSoft)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(index == 0 ? AppTheme.primary.opacity(0.22) : AppTheme.accent.opacity(0.18), lineWidth: 1)
                        }
                        .frame(
                            width: max(1, proxy.size.width * frame.width - 8),
                            height: max(1, proxy.size.height * frame.height - 8)
                        )
                        .position(
                            x: proxy.size.width * frame.midX,
                            y: proxy.size.height * frame.midY
                        )
                }
            }
            .padding(4)

            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.primary, in: Circle())
                Text(language.text(.chooseImages))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(language.text(.multiSelectHint))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 12))
        }
        .aspectRatio(1, contentMode: .fit)
        .background(AppTheme.raised)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}

private struct ImageJoinCanvas: View {
    let sources: [NativeImageSource]
    let mode: ImageJoinMode
    let canvasStyle: ImageJoinCanvasStyle
    let activeIndex: Int
    let isLoading: Bool
    var loadingTitle: String? = nil
    let onEditChange: (Int, NativeImageEdit) -> Void
    let onSelect: (Int) -> Void

    private let panelPadding: CGFloat = 6
    private let slotGap: CGFloat = 0

    var body: some View {
        Group {
            if canvasStyle == .square || sources.count <= 1 {
                canvasContent
                    .aspectRatio(1, contentMode: .fit)
            } else {
                longCanvas
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        }
        .overlay {
            if let loadingTitle {
                GenerationLoadingOverlay(title: loadingTitle)
                    .padding(panelPadding)
                    .transition(.opacity)
            }
        }
        .opacity(isLoading ? 0.62 : 1)
        .animation(.easeInOut(duration: 0.16), value: activeIndex)
        .animation(.easeInOut(duration: 0.16), value: isLoading)
    }

    private var canvasContent: some View {
        GeometryReader { proxy in
            let frames = ImageJoinLayout.previewFrames(for: sources.count, mode: mode)

            ZStack {
                Color.white

                ZStack {
                    AppTheme.raised

                    ForEach(sources.indices, id: \.self) { index in
                        let source = sources[index]
                        let frame = frames[min(index, frames.count - 1)]
                        let slotRect = slotFrame(for: frame, in: innerSize(for: proxy.size))
                        let isActive = activeIndex == index

                        ZStack(alignment: .topLeading) {
                            EditableImageView(
                                image: source.image,
                                edit: source.edit,
                                isDraggable: isActive && !isLoading,
                                onDragEditChange: { onEditChange(index, $0) }
                            )

                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .frame(minWidth: 20, minHeight: 20)
                                .background(Color.black.opacity(0.62), in: Capsule())
                                .padding(5)
                        }
                        .overlay(alignment: .topTrailing) {
                            if source.isLivePhoto {
                                LiveSourceBadge()
                                    .padding(5)
                            }
                        }
                        .overlay {
                            Rectangle()
                                .strokeBorder(isActive ? AppTheme.primary : Color.clear, lineWidth: 2)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !isLoading else { return }
                            onSelect(index)
                        }
                        .frame(
                            width: slotRect.width,
                            height: slotRect.height
                        )
                        .position(
                            x: slotRect.midX,
                            y: slotRect.midY
                        )
                    }
                }
                .frame(width: innerSize(for: proxy.size).width, height: innerSize(for: proxy.size).height)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            }
        }
    }

    private var longCanvas: some View {
        GeometryReader { proxy in
            let count = CGFloat(max(1, sources.count))
            let tileEdge = mode == .horizontal
                ? max(proxy.size.height - panelPadding * 2, 1)
                : max(proxy.size.width - panelPadding * 2, 1)
            let canvasSize = mode == .horizontal
                ? CGSize(width: tileEdge * count + panelPadding * 2, height: tileEdge + panelPadding * 2)
                : CGSize(width: tileEdge + panelPadding * 2, height: tileEdge * count + panelPadding * 2)

            ScrollView(mode == .horizontal ? .horizontal : .vertical, showsIndicators: true) {
                canvasContent
                    .frame(width: canvasSize.width, height: canvasSize.height)
            }
        }
        .frame(height: longCanvasViewportHeight)
    }

    private var longCanvasViewportHeight: CGFloat {
        if mode == .horizontal {
            return 240
        }
        return min(CGFloat(max(1, sources.count)) * 200, 420)
    }

    private func innerSize(for size: CGSize) -> CGSize {
        CGSize(
            width: max(size.width - panelPadding * 2, 1),
            height: max(size.height - panelPadding * 2, 1)
        )
    }

    private func slotFrame(for normalizedFrame: CGRect, in size: CGSize) -> CGRect {
        let rawFrame = CGRect(
            x: size.width * normalizedFrame.minX,
            y: size.height * normalizedFrame.minY,
            width: size.width * normalizedFrame.width,
            height: size.height * normalizedFrame.height
        )
        let frame = rawFrame.insetBy(dx: slotGap, dy: slotGap)

        return CGRect(
            x: frame.minX,
            y: frame.minY,
            width: max(frame.width, 1),
            height: max(frame.height, 1)
        )
    }
}

private struct ImageJoinThumbnailRail: View {
    let sources: [NativeImageSource]
    let activeIndex: Int
    let maxImages: Int
    let isDisabled: Bool
    @Binding var appendPickerItems: [PhotosPickerItem]
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if sources.count < maxImages {
                    PhotosPicker(
                        selection: $appendPickerItems,
                        maxSelectionCount: max(1, maxImages - sources.count),
                        matching: .any(of: [.images, .livePhotos]),
                        preferredItemEncoding: .current
                    ) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppTheme.primary)
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.border, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                }

                ForEach(sources.indices, id: \.self) { index in
                    let source = sources[index]
                    let isActive = activeIndex == index

                    Button {
                        onSelect(index)
                    } label: {
                        ZStack(alignment: .topLeading) {
                            EditableImageView(image: source.image, edit: source.edit)
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 6)
                                .frame(height: 18)
                                .background(Color.black.opacity(0.62), in: Capsule())
                                .padding(4)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            if source.isLivePhoto {
                                LiveSourceBadge()
                                    .scaleEffect(0.82)
                                    .padding(4)
                            }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(isActive ? AppTheme.primary : AppTheme.border, lineWidth: isActive ? 2 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                }
            }
            .padding(.vertical, 1)
        }
    }
}

private struct LiveSourceBadge: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        Text(language.text(.liveBadge))
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 5)
            .frame(height: 17)
            .background(AppTheme.primary.opacity(0.88), in: Capsule())
    }
}

private struct ImageJoinEditPanel: View {
    @Environment(\.appLanguage) private var language

    let mode: ImageJoinMode
    let activeIndex: Int
    let sourceCount: Int
    let outputSize: CGSize
    let activeSource: NativeImageSource?
    let isDisabled: Bool
    @Binding var replacementPickerItem: PhotosPickerItem?
    let onDelete: () -> Void
    let onZoomChange: (CGFloat) -> Void
    let onFocalXChange: (CGFloat) -> Void
    let onFocalYChange: (CGFloat) -> Void

    var body: some View {
        let edit = activeSource?.edit ?? .default
        let controlsDisabled = isDisabled || activeSource == nil

        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.localizedTitle(language))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.primary)
                    Text(language.editingImage(activeIndex))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(language.imageOutputSummary(sourceCount: sourceCount, width: Int(outputSize.width), height: Int(outputSize.height)))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer()

                HStack(spacing: 8) {
                    PhotosPicker(selection: $replacementPickerItem, matching: .any(of: [.images, .livePhotos]), preferredItemEncoding: .current) {
                        Text(language.text(.replace))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .frame(height: 36)
                            .padding(.horizontal, 13)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(controlsDisabled)

                    Button(action: onDelete) {
                        Text(language.text(.delete))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.error)
                            .frame(height: 36)
                            .padding(.horizontal, 13)
                            .background(AppTheme.error.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(controlsDisabled)
                }
            }

            VStack(spacing: 14) {
                SliderControl(
                    title: language.text(.zoom),
                    valueText: String(format: "%.1fx", edit.zoom),
                    value: Double(edit.zoom),
                    range: 1...3,
                    step: 0.05,
                    isDisabled: controlsDisabled
                ) { value in
                    onZoomChange(CGFloat(value))
                }

                HStack(spacing: 12) {
                    SliderControl(
                        title: language.text(.horizontal),
                        valueText: "\(Int(edit.focalX * 100))%",
                        value: Double(edit.focalX),
                        range: 0...1,
                        step: 0.01,
                        isDisabled: controlsDisabled
                    ) { value in
                        onFocalXChange(CGFloat(value))
                    }

                    SliderControl(
                        title: language.text(.vertical),
                        valueText: "\(Int(edit.focalY * 100))%",
                        value: Double(edit.focalY),
                        range: 0...1,
                        step: 0.01,
                        isDisabled: controlsDisabled
                    ) { value in
                        onFocalYChange(CGFloat(value))
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}

private struct SplitNinePickerPreview: View {
    @Environment(\.appLanguage) private var language

    let image: UIImage?
    let edit: NativeImageEdit
    var isDraggable = false
    var loadingTitle: String? = nil
    var onDragEditChange: (NativeImageEdit) -> Void = { _ in }

    private let panelPadding: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white

                ZStack {
                    AppTheme.raised

                    if let image {
                        ZStack {
                            EditableImageView(
                                image: image,
                                edit: edit,
                                isDraggable: isDraggable,
                                onDragEditChange: onDragEditChange
                            )
                            GridOverlay()
                        }
                    } else {
                        SplitNinePreviewArtwork(lineWidth: 1.2)

                        VStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .frame(width: 48, height: 48)
                                .background(AppTheme.primary, in: Circle())
                            Text(language.text(.chooseImages))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                            Text(language.text(.highResHint))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.muted)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(width: innerSize(for: proxy.size).width, height: innerSize(for: proxy.size).height)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                if let loadingTitle {
                    GenerationLoadingOverlay(title: loadingTitle)
                        .padding(panelPadding)
                        .transition(.opacity)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }

    private func innerSize(for size: CGSize) -> CGSize {
        CGSize(
            width: max(size.width - panelPadding * 2, 1),
            height: max(size.height - panelPadding * 2, 1)
        )
    }
}

private struct SplitNineEditPanel: View {
    @Environment(\.appLanguage) private var language

    let hasImage: Bool
    let edit: NativeImageEdit
    let isDisabled: Bool
    let isPickerDisabled: Bool
    @Binding var pickerItem: PhotosPickerItem?
    let onZoomChange: (CGFloat) -> Void
    let onFocalXChange: (CGFloat) -> Void
    let onFocalYChange: (CGFloat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text(.splitNinePanelTitle))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.primary)
                    Text(hasImage ? language.text(.imageSelected) : language.text(.chooseOneImage))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(hasImage ? language.text(.cropAdjustHint) : language.text(.splitPreviewHint))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer()

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text(hasImage ? language.text(.replace) : language.text(.choose))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(height: 36)
                        .padding(.horizontal, 13)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.border, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(isPickerDisabled)
            }

            VStack(spacing: 14) {
                SliderControl(
                    title: language.text(.zoom),
                    valueText: String(format: "%.1fx", edit.zoom),
                    value: Double(edit.zoom),
                    range: 1...3,
                    step: 0.05,
                    isDisabled: isDisabled
                ) { value in
                    onZoomChange(CGFloat(value))
                }

                HStack(spacing: 12) {
                    SliderControl(
                        title: language.text(.horizontal),
                        valueText: "\(Int(edit.focalX * 100))%",
                        value: Double(edit.focalX),
                        range: 0...1,
                        step: 0.01,
                        isDisabled: isDisabled
                    ) { value in
                        onFocalXChange(CGFloat(value))
                    }

                    SliderControl(
                        title: language.text(.vertical),
                        valueText: "\(Int(edit.focalY * 100))%",
                        value: Double(edit.focalY),
                        range: 0...1,
                        step: 0.01,
                        isDisabled: isDisabled
                    ) { value in
                        onFocalYChange(CGFloat(value))
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}

private struct GridOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let width = proxy.size.width
                let height = proxy.size.height
                for column in 1...2 {
                    let x = width * CGFloat(column) / 3
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                for row in 1...2 {
                    let y = height * CGFloat(row) / 3
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.85), lineWidth: 1)
        }
    }
}

private struct BottomActionBar: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: action) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(isDisabled ? AppTheme.faint : Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(isDisabled ? AppTheme.raised : AppTheme.primary, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)
        }
        .background(.regularMaterial)
    }
}

private struct GenerationLoadingOverlay: View {
    let title: String

    var body: some View {
        ZStack {
            Color.white.opacity(0.68)

            HStack(spacing: 10) {
                ProgressView()
                    .tint(AppTheme.primary)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
        }
        .allowsHitTesting(true)
    }
}

private struct BrandMark: View {
    let size: CGFloat

    var body: some View {
        AppIconMark(size: size, cornerRadius: size * 0.24)
    }
}

private struct AppIconMark: View {
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Image("AppIconPreview")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 0.5)
            }
    }
}

private struct GeneratedImage: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage

    static func == (lhs: GeneratedImage, rhs: GeneratedImage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private struct GeneratedTiles: Identifiable, Hashable {
    let id = UUID()
    let tiles: [UIImage]

    static func == (lhs: GeneratedTiles, rhs: GeneratedTiles) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private enum PhotoLibraryOpener {
    private static let urls = [
        URL(string: "photos-redirect://")!,
        URL(string: "photos://")!,
    ]

    @MainActor
    static func open(onStatusChange: @escaping @MainActor (SaveStatusKind) -> Void) {
        openURL(at: 0, onStatusChange: onStatusChange)
    }

    @MainActor
    private static func openURL(at index: Int, onStatusChange: @escaping @MainActor (SaveStatusKind) -> Void) {
        guard index < urls.count else {
            onStatusChange(.openPhotosFailed)
            return
        }

        UIApplication.shared.open(urls[index], options: [:]) { success in
            Task { @MainActor in
                if success {
                    onStatusChange(.openedPhotos)
                } else {
                    openURL(at: index + 1, onStatusChange: onStatusChange)
                }
            }
        }
    }
}

private enum PhotoSaver {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LiveMix",
        category: "PhotoSaver"
    )

    static func save(image: UIImage) async throws {
        let authorized = await requestAuthorization()
        guard authorized else {
            throw PhotoSaveError.permissionDenied
        }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoSaveError.writeFailed)
                }
            }
        }
    }

    static func saveLivePhoto(imageURL: URL, videoURL: URL) async throws {
        let authorized = await requestAuthorization()
        guard authorized else {
            logger.error("Live Photo save denied because Photos authorization is unavailable")
            throw PhotoSaveError.permissionDenied
        }

        logger.info(
            "Saving Live Photo: imageBytes=\(fileSize(at: imageURL)), videoBytes=\(fileSize(at: videoURL))"
        )

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()

                let photoOptions = PHAssetResourceCreationOptions()
                photoOptions.shouldMoveFile = false

                let videoOptions = PHAssetResourceCreationOptions()
                videoOptions.shouldMoveFile = false

                request.addResource(with: .photo, fileURL: imageURL, options: photoOptions)
                request.addResource(with: .pairedVideo, fileURL: videoURL, options: videoOptions)
            } completionHandler: { success, error in
                if success {
                    logger.info("Photos accepted the Live Photo resources")
                    continuation.resume()
                } else {
                    logger.error(
                        "Photos rejected the Live Photo resources: \(String(reflecting: error), privacy: .public)"
                    )
                    continuation.resume(throwing: error ?? PhotoSaveError.writeFailed)
                }
            }
        }
    }

    private static func fileSize(at url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    private static func requestAuthorization() async -> Bool {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if current == .authorized || current == .limited {
            return true
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }
}

private enum PhotoSaveError: Error {
    case permissionDenied
    case writeFailed
}
