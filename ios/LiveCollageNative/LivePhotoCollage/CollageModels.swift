import CoreGraphics
import Foundation

enum AppLanguage: String, CaseIterable, Hashable {
    case zhHans = "zh-Hans"
    case en = "en"

    static var preferred: AppLanguage {
        let preferredIdentifier = Locale.preferredLanguages.first ?? ""
        return preferredIdentifier.lowercased().hasPrefix("zh") ? .zhHans : .en
    }

    var next: AppLanguage {
        self == .zhHans ? .en : .zhHans
    }

    var toggleTitle: String {
        self == .zhHans ? "EN" : "中"
    }

    var localeIdentifier: String {
        rawValue
    }

    func text(_ key: AppText) -> String {
        AppStrings.text(key, language: self)
    }

    func templateCount(_ count: Int) -> String {
        self == .zhHans ? "\(count) 个模板" : "\(count) templates"
    }

    func clipCount(_ count: Int) -> String {
        if self == .zhHans { return "\(count) 段" }
        return count == 1 ? "1 clip" : "\(count) clips"
    }

    func materialCount(_ count: Int) -> String {
        if self == .zhHans { return "\(count) 个素材" }
        return count == 1 ? "1 item" : "\(count) items"
    }

    func maxImages(_ count: Int) -> String {
        self == .zhHans ? "最多 \(count) 张" : "Up to \(count)"
    }

    func videoSlot(_ index: Int) -> String {
        self == .zhHans ? "视频 \(index + 1)" : "Video \(index + 1)"
    }

    func addVideo(_ index: Int) -> String {
        self == .zhHans ? "添加视频 \(index + 1)" : "Add video \(index + 1)"
    }

    func missingVideos(_ count: Int) -> String {
        if self == .zhHans { return "还差 \(count) 段视频" }
        return count == 1 ? "1 video missing" : "\(count) videos missing"
    }

    func loadingVideos(_ count: Int) -> String {
        if self == .zhHans { return "正在读取 \(count) 段视频..." }
        return count == 1 ? "Loading 1 video..." : "Loading \(count) videos..."
    }

    func selectedVideos(_ count: Int) -> String {
        if self == .zhHans { return "已选择 \(count) 段视频。" }
        return count == 1 ? "1 video selected." : "\(count) videos selected."
    }

    func unreadableVideo(_ index: Int) -> String {
        self == .zhHans ? "视频 \(index + 1) 暂时无法读取，请换一个视频。" : "Video \(index + 1) cannot be read. Try another video."
    }

    func liveEditorKicker(template: NativeCollageTemplate) -> String {
        if self == .zhHans {
            return "\(template.localizedName(self))模板 · \(clipCount(template.slots.count))素材"
        }
        return "\(template.localizedName(self)) · \(clipCount(template.slots.count))"
    }

    func exportRange(start: Double, end: Double, filledCount: Int, totalCount: Int) -> String {
        let startValue = String(format: "%.2fs", start)
        let endValue = String(format: "%.2fs", end)
        if self == .zhHans {
            return "导出片段 \(startValue) - \(endValue) · \(filledCount)/\(totalCount) 段"
        }
        return "Export \(startValue) - \(endValue) · \(filledCount)/\(totalCount)"
    }

    func materialProgress(filledCount: Int, totalCount: Int) -> String {
        if self == .zhHans {
            return "\(filledCount)/\(totalCount) 段素材"
        }
        return "\(filledCount)/\(totalCount) selected"
    }

    func editingImage(_ index: Int) -> String {
        self == .zhHans ? "编辑第 \(index + 1) 张" : "Edit image \(index + 1)"
    }

    func imageOutputSummary(sourceCount: Int, width: Int, height: Int) -> String {
        if self == .zhHans {
            return "\(sourceCount) 个素材 · 输出 \(width) × \(height)"
        }
        return "\(sourceCount) items · \(width) × \(height)"
    }

    func maxImagesExceeded(_ count: Int) -> String {
        self == .zhHans ? "最多只能选择 \(count) 张图片。" : "You can select up to \(count) images."
    }

    func maxMaterialsKept(_ count: Int) -> String {
        if self == .zhHans { return "最多 \(count) 个素材，已保留前 \(count) 个。" }
        return "Kept the first \(count) items."
    }

    func saveStatus(_ kind: SaveStatusKind) -> String {
        switch kind {
        case .saved:
            return text(.saveStatusSaved)
        case .savedTiles:
            return text(.saveStatusSavedTiles)
        case .failed:
            return text(.saveStatusFailed)
        case .openedPhotos:
            return text(.saveStatusOpenedPhotos)
        case .openPhotosFailed:
            return text(.saveStatusOpenPhotosFailed)
        }
    }
}

enum SaveStatusKind: Hashable {
    case saved
    case savedTiles
    case failed
    case openedPhotos
    case openPhotosFailed
}

enum AppText: String, CaseIterable {
    case splashTagline
    case homeTitle
    case homeSubtitle
    case homeTopTagline
    case start
    case liveEntryTitle
    case liveEntrySubtitle
    case imageEntryTitle
    case imageEntrySubtitle
    case horizontalShort
    case verticalShort
    case gridShort
    case capabilityTemplates
    case capabilityTemplatesDetail
    case capabilityCanvas
    case capabilityCanvasDetail
    case capabilityAlbum
    case capabilityAlbumDetail
    case feedback
    case privacyPolicy
    case backHome
    case backTemplate
    case backImageCollage
    case templatesTitle
    case templatesSubtitle
    case localOnlyMessage
    case fillVideosTitle
    case fillVideosSubtitle
    case generating
    case loadingVideo
    case generateLivePhoto
    case loading
    case dragToAdjust
    case loadingShort
    case notSelected
    case currentSlot
    case displayMode
    case fitFill
    case fitFull
    case zoom
    case horizontal
    case vertical
    case clipDuration
    case startTime
    case choose
    case replace
    case delete
    case liveReadyMessage
    case selectedAllMessage
    case needAllVideos
    case composingLive
    case liveGeneratedMessage
    case liveGenerationFailed
    case liveResultTitle
    case liveResultSubtitle
    case generated
    case preview
    case saveAsLivePhoto
    case saving
    case openPhotos
    case imageMode
    case imageToolsTitle
    case imageToolsSubtitle
    case imageToolHorizontalTitle
    case imageToolHorizontalDetail
    case imageToolVerticalTitle
    case imageToolVerticalDetail
    case imageToolGridTitle
    case imageToolGridDetail
    case imageJoinSubtitle
    case chooseImagesFirst
    case loadingMaterials
    case generatingImage
    case generateImage
    case liveResourceUnavailablePlural
    case liveResourceUnavailableSingle
    case unreadableMaterials
    case unreadableMaterial
    case imageJoinLiveFailed
    case imageJoinImageFailed
    case splitNineBadge
    case splitNineTitle
    case splitNineSubtitle
    case loadingImage
    case splittingImage
    case cutNine
    case generateNineImages
    case unreadableImage
    case splitNineFailed
    case imageResultTitle
    case imageResultSubtitle
    case saveToAlbum
    case saveAllToAlbum
    case gridPreview
    case templatePreview
    case chooseImages
    case multiSelectHint
    case liveBadge
    case highResHint
    case splitNinePanelTitle
    case imageSelected
    case chooseOneImage
    case cropAdjustHint
    case splitPreviewHint
    case saveStatusSaved
    case saveStatusSavedTiles
    case saveStatusFailed
    case saveStatusOpenedPhotos
    case saveStatusOpenPhotosFailed
}

enum AppStrings {
    private static let zhHans: [AppText: String] = [
        .splashTagline: "几段视频，一张 Live Photo",
        .homeTitle: "选择一种拼接方式？",
        .homeSubtitle: "选中入口，即刻开始。",
        .homeTopTagline: "把精彩，拼成一张 Live。",
        .start: "开始",
        .liveEntryTitle: "Video → Live",
        .liveEntrySubtitle: "多段视频，生成一张 Live Photo。",
        .imageEntryTitle: "图片拼接",
        .imageEntrySubtitle: "支持图片、Live Photo 自由拼接。",
        .horizontalShort: "左右",
        .verticalShort: "上下",
        .gridShort: "九宫格",
        .capabilityTemplates: "模板",
        .capabilityTemplatesDetail: "丰富布局",
        .capabilityCanvas: "画面",
        .capabilityCanvasDetail: "自由拖拽",
        .capabilityAlbum: "相册",
        .capabilityAlbumDetail: "直接保存",
        .feedback: "问题反馈",
        .privacyPolicy: "隐私政策",
        .backHome: "← 首页",
        .backTemplate: "← 换模板",
        .backImageCollage: "← 图片拼接",
        .templatesTitle: "选择模板",
        .templatesSubtitle: "先选画面结构，再放视频。",
        .localOnlyMessage: "当前版本会在本机合成，不上传服务端。",
        .fillVideosTitle: "填入视频并调整画面",
        .fillVideosSubtitle: "一次选择素材，选中槽位后调整画面和片段。",
        .generating: "正在生成",
        .loadingVideo: "正在读取视频",
        .generateLivePhoto: "生成 Live Photo",
        .loading: "正在读取",
        .dragToAdjust: "拖动调整",
        .loadingShort: "读取中",
        .notSelected: "未选择",
        .currentSlot: "当前槽位",
        .displayMode: "显示方式",
        .fitFill: "填满裁切",
        .fitFull: "完整展示",
        .zoom: "缩放",
        .horizontal: "水平",
        .vertical: "垂直",
        .clipDuration: "片段时长",
        .startTime: "起始时间",
        .choose: "选择",
        .replace: "替换",
        .delete: "删除",
        .liveReadyMessage: "素材已就绪，可以继续调整。",
        .selectedAllMessage: "素材已就绪，可以继续调整。",
        .needAllVideos: "请先选满当前模板需要的视频。",
        .composingLive: "正在本机合成 Live Photo...",
        .liveGeneratedMessage: "Live Photo 已生成，可以保存到相册。",
        .liveGenerationFailed: "生成失败，请换一组视频试试。",
        .liveResultTitle: "Live Photo 已生成",
        .liveResultSubtitle: "长按预览动态效果，确认无误后保存到相册。",
        .generated: "已生成",
        .preview: "预览",
        .saveAsLivePhoto: "保存为 Live Photo",
        .saving: "正在保存",
        .openPhotos: "打开相册查看",
        .imageMode: "图片模式",
        .imageToolsTitle: "图片拼接",
        .imageToolsSubtitle: "左右、上下，或者把一张图切成九宫格。",
        .imageToolHorizontalTitle: "左右拼接",
        .imageToolHorizontalDetail: "图片或 Live 横向合成一张。",
        .imageToolVerticalTitle: "上下拼接",
        .imageToolVerticalDetail: "图片或 Live 纵向合成一张。",
        .imageToolGridTitle: "一图切九宫格",
        .imageToolGridDetail: "一张图切成 9 张。",
        .imageJoinSubtitle: "多选图片或 Live Photo，在一张图里按方向等分拼好。",
        .chooseImagesFirst: "先选择图片",
        .loadingMaterials: "正在读取素材",
        .generatingImage: "正在生成图片...",
        .generateImage: "生成图片",
        .liveResourceUnavailablePlural: "有 Live Photo 的动态部分暂时无法读取，请换一张或确认它已从 iCloud 下载完成。",
        .liveResourceUnavailableSingle: "这张 Live Photo 的动态部分暂时无法读取，请确认它已从 iCloud 下载完成。",
        .unreadableMaterials: "这些素材暂时无法读取，请换一组试试。",
        .unreadableMaterial: "这个素材暂时无法读取，请换一个试试。",
        .imageJoinLiveFailed: "Live Photo 生成失败，请换一组素材试试。",
        .imageJoinImageFailed: "图片生成失败，请重试。",
        .splitNineBadge: "图片切图",
        .splitNineTitle: "一图切九宫格",
        .splitNineSubtitle: "选一张图，调好裁切后切成 9 张方图。",
        .loadingImage: "正在读取图片",
        .splittingImage: "正在切图...",
        .cutNine: "正在切图",
        .generateNineImages: "生成 9 张图片",
        .unreadableImage: "这张图片暂时无法读取，请换一张试试。",
        .splitNineFailed: "九宫格生成失败，请重试。",
        .imageResultTitle: "图片已生成",
        .imageResultSubtitle: "预览确认无误后，保存到相册。",
        .saveToAlbum: "保存到相册",
        .saveAllToAlbum: "保存全部到相册",
        .gridPreview: "九宫格预览",
        .templatePreview: "模板预览",
        .chooseImages: "选择图片",
        .multiSelectHint: "可多选，最多 9 张",
        .liveBadge: "LIVE",
        .highResHint: "建议使用高清原图",
        .splitNinePanelTitle: "九宫格切图",
        .imageSelected: "已选择图片",
        .chooseOneImage: "选择一张图片",
        .cropAdjustHint: "可调整裁切位置和缩放",
        .splitPreviewHint: "上传后可预览九宫格切分",
        .saveStatusSaved: "已保存到相册，可直接打开相册查看。",
        .saveStatusSavedTiles: "已保存 9 张图片，可直接打开相册查看。",
        .saveStatusFailed: "保存失败，请检查相册权限后重试。",
        .saveStatusOpenedPhotos: "已打开相册。",
        .saveStatusOpenPhotosFailed: "已保存，请到相册中查看。",
    ]

    private static let en: [AppText: String] = [
        .splashTagline: "Clips into one Live Photo",
        .homeTitle: "Choose a collage mode",
        .homeSubtitle: "Pick a workflow and start.",
        .homeTopTagline: "Turn moments into one Live.",
        .start: "Start",
        .liveEntryTitle: "Video → Live",
        .liveEntrySubtitle: "Combine videos into one Live Photo.",
        .imageEntryTitle: "Image Collage",
        .imageEntrySubtitle: "Join images and Live Photos freely.",
        .horizontalShort: "Side",
        .verticalShort: "Stack",
        .gridShort: "9-grid",
        .capabilityTemplates: "Layouts",
        .capabilityTemplatesDetail: "Ready grids",
        .capabilityCanvas: "Canvas",
        .capabilityCanvasDetail: "Drag & zoom",
        .capabilityAlbum: "Photos",
        .capabilityAlbumDetail: "Save direct",
        .feedback: "Feedback",
        .privacyPolicy: "Privacy Policy",
        .backHome: "← Home",
        .backTemplate: "← Templates",
        .backImageCollage: "← Images",
        .templatesTitle: "Choose Layout",
        .templatesSubtitle: "Pick a structure, then add videos.",
        .localOnlyMessage: "Everything is processed on this iPhone.",
        .fillVideosTitle: "Add videos and adjust",
        .fillVideosSubtitle: "Select clips once, then tune each slot.",
        .generating: "Generating",
        .loadingVideo: "Loading video",
        .generateLivePhoto: "Generate Live Photo",
        .loading: "Loading",
        .dragToAdjust: "Drag to adjust",
        .loadingShort: "Loading",
        .notSelected: "Empty",
        .currentSlot: "Current slot",
        .displayMode: "Display",
        .fitFill: "Fill",
        .fitFull: "Fit",
        .zoom: "Zoom",
        .horizontal: "Horizontal",
        .vertical: "Vertical",
        .clipDuration: "Duration",
        .startTime: "Start",
        .choose: "Choose",
        .replace: "Replace",
        .delete: "Delete",
        .liveReadyMessage: "Clips are ready. Adjust as needed.",
        .selectedAllMessage: "Clips are ready. Adjust as needed.",
        .needAllVideos: "Add all videos required by this layout first.",
        .composingLive: "Generating Live Photo on device...",
        .liveGeneratedMessage: "Live Photo is ready to save.",
        .liveGenerationFailed: "Generation failed. Try another set of videos.",
        .liveResultTitle: "Live Photo Ready",
        .liveResultSubtitle: "Press and hold to preview, then save to Photos.",
        .generated: "Ready",
        .preview: "Preview",
        .saveAsLivePhoto: "Save Live Photo",
        .saving: "Saving",
        .openPhotos: "Open Photos",
        .imageMode: "Images",
        .imageToolsTitle: "Image Collage",
        .imageToolsSubtitle: "Join side by side, stack, or split into 9.",
        .imageToolHorizontalTitle: "Side by Side",
        .imageToolHorizontalDetail: "Join images or Live Photos horizontally.",
        .imageToolVerticalTitle: "Stacked",
        .imageToolVerticalDetail: "Join images or Live Photos vertically.",
        .imageToolGridTitle: "Split into 9",
        .imageToolGridDetail: "Cut one image into 9 square tiles.",
        .imageJoinSubtitle: "Select images or Live Photos and split one canvas evenly.",
        .chooseImagesFirst: "Choose images first",
        .loadingMaterials: "Loading items",
        .generatingImage: "Generating image...",
        .generateImage: "Generate Image",
        .liveResourceUnavailablePlural: "A Live Photo motion resource could not be read. Try another item or download it from iCloud first.",
        .liveResourceUnavailableSingle: "This Live Photo motion resource could not be read. Make sure it is downloaded from iCloud.",
        .unreadableMaterials: "These items cannot be read. Try another set.",
        .unreadableMaterial: "This item cannot be read. Try another one.",
        .imageJoinLiveFailed: "Live Photo generation failed. Try another set.",
        .imageJoinImageFailed: "Image generation failed. Please try again.",
        .splitNineBadge: "Split",
        .splitNineTitle: "Split into 9",
        .splitNineSubtitle: "Choose one image, adjust the crop, then export 9 tiles.",
        .loadingImage: "Loading image",
        .splittingImage: "Splitting image...",
        .cutNine: "Splitting",
        .generateNineImages: "Generate 9 Images",
        .unreadableImage: "This image cannot be read. Try another one.",
        .splitNineFailed: "9-grid generation failed. Please try again.",
        .imageResultTitle: "Image Ready",
        .imageResultSubtitle: "Preview it, then save to Photos.",
        .saveToAlbum: "Save to Photos",
        .saveAllToAlbum: "Save All to Photos",
        .gridPreview: "9-grid Preview",
        .templatePreview: "Layout Preview",
        .chooseImages: "Choose Images",
        .multiSelectHint: "Select up to 9 items",
        .liveBadge: "LIVE",
        .highResHint: "Use a high-resolution image",
        .splitNinePanelTitle: "9-grid Split",
        .imageSelected: "Image selected",
        .chooseOneImage: "Choose an image",
        .cropAdjustHint: "Adjust crop and zoom",
        .splitPreviewHint: "Preview the 9-grid after upload",
        .saveStatusSaved: "Saved to Photos. You can open Photos now.",
        .saveStatusSavedTiles: "Saved 9 images to Photos. You can open Photos now.",
        .saveStatusFailed: "Save failed. Check Photos permission and try again.",
        .saveStatusOpenedPhotos: "Photos opened.",
        .saveStatusOpenPhotosFailed: "Saved. Please check it in Photos.",
    ]

    static func text(_ key: AppText, language: AppLanguage) -> String {
        switch language {
        case .zhHans:
            return zhHans[key] ?? key.rawValue
        case .en:
            return en[key] ?? zhHans[key] ?? key.rawValue
        }
    }
}

struct CollageSlot: Hashable, Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

struct NativeCollageTemplate: Hashable, Identifiable {
    let id: String
    let name: String
    let detail: String
    let slots: [CollageSlot]

    static let liveTemplates: [NativeCollageTemplate] = [
        NativeCollageTemplate(
            id: "left-right",
            name: "左右",
            detail: "两段并排",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 0.5, height: 1),
                CollageSlot(id: 1, x: 0.5, y: 0, width: 0.5, height: 1),
            ]
        ),
        NativeCollageTemplate(
            id: "top-bottom",
            name: "上下",
            detail: "两段叠放",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 1, height: 0.5),
                CollageSlot(id: 1, x: 0, y: 0.5, width: 1, height: 0.5),
            ]
        ),
        NativeCollageTemplate(
            id: "three-columns",
            name: "三列",
            detail: "三段横排",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 1 / 3, height: 1),
                CollageSlot(id: 1, x: 1 / 3, y: 0, width: 1 / 3, height: 1),
                CollageSlot(id: 2, x: 2 / 3, y: 0, width: 1 / 3, height: 1),
            ]
        ),
        NativeCollageTemplate(
            id: "three-rows",
            name: "三行",
            detail: "三段竖排",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 1, height: 1 / 3),
                CollageSlot(id: 1, x: 0, y: 1 / 3, width: 1, height: 1 / 3),
                CollageSlot(id: 2, x: 0, y: 2 / 3, width: 1, height: 1 / 3),
            ]
        ),
        NativeCollageTemplate(
            id: "grid-2x2",
            name: "四宫格",
            detail: "四段网格",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 0.5, height: 0.5),
                CollageSlot(id: 1, x: 0.5, y: 0, width: 0.5, height: 0.5),
                CollageSlot(id: 2, x: 0, y: 0.5, width: 0.5, height: 0.5),
                CollageSlot(id: 3, x: 0.5, y: 0.5, width: 0.5, height: 0.5),
            ]
        ),
        NativeCollageTemplate(
            id: "one-big-two-small",
            name: "一大两小",
            detail: "主画面加两个小画面",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 0.64, height: 1),
                CollageSlot(id: 1, x: 0.64, y: 0, width: 0.36, height: 0.5),
                CollageSlot(id: 2, x: 0.64, y: 0.5, width: 0.36, height: 0.5),
            ]
        ),
    ]

    func localizedName(_ language: AppLanguage) -> String {
        switch id {
        case "left-right":
            return language == .zhHans ? "左右" : "Side by Side"
        case "top-bottom":
            return language == .zhHans ? "上下" : "Stacked"
        case "three-columns":
            return language == .zhHans ? "三列" : "Three Columns"
        case "three-rows":
            return language == .zhHans ? "三行" : "Three Rows"
        case "grid-2x2":
            return language == .zhHans ? "四宫格" : "2 x 2 Grid"
        case "one-big-two-small":
            return language == .zhHans ? "一大两小" : "Hero + Two"
        default:
            return name
        }
    }

    func localizedDetail(_ language: AppLanguage) -> String {
        switch id {
        case "left-right":
            return language == .zhHans ? "两段并排" : "Two clips side by side"
        case "top-bottom":
            return language == .zhHans ? "两段叠放" : "Two clips stacked"
        case "three-columns":
            return language == .zhHans ? "三段横排" : "Three vertical columns"
        case "three-rows":
            return language == .zhHans ? "三段竖排" : "Three horizontal rows"
        case "grid-2x2":
            return language == .zhHans ? "四段网格" : "Four clip grid"
        case "one-big-two-small":
            return language == .zhHans ? "主画面加两个小画面" : "One hero clip with two smaller clips"
        default:
            return detail
        }
    }
}

enum NativeFitMode: String, Hashable {
    case fill
    case fit
}

struct NativeSlotEdit: Hashable {
    static let minDuration: Double = 0.5
    static let maxDuration: Double = 3
    static let defaultZoom: CGFloat = 1
    static let maxZoom: CGFloat = 3
    static let `default` = NativeSlotEdit()

    var fitMode: NativeFitMode
    var focalX: CGFloat
    var focalY: CGFloat
    var zoom: CGFloat
    var start: Double
    var duration: Double

    init(
        fitMode: NativeFitMode = .fill,
        focalX: CGFloat = 0.5,
        focalY: CGFloat = 0.5,
        zoom: CGFloat = NativeSlotEdit.defaultZoom,
        start: Double = 0,
        duration: Double = NativeSlotEdit.maxDuration
    ) {
        self.fitMode = fitMode
        self.focalX = focalX
        self.focalY = focalY
        self.zoom = zoom
        self.start = start
        self.duration = duration
    }

    func clamped(maxStart: Double) -> NativeSlotEdit {
        NativeSlotEdit(
            fitMode: fitMode,
            focalX: Self.clamp(focalX, min: 0, max: 1),
            focalY: Self.clamp(focalY, min: 0, max: 1),
            zoom: Self.clamp(zoom, min: Self.defaultZoom, max: Self.maxZoom),
            start: Self.clamp(start, min: 0, max: max(0, maxStart)),
            duration: Self.normalizedDuration(duration)
        )
    }

    func withDuration(_ duration: Double) -> NativeSlotEdit {
        var edit = self
        edit.duration = Self.normalizedDuration(duration)
        return edit
    }

    static func normalizedDuration(_ value: Double) -> Double {
        guard value.isFinite else { return maxDuration }
        return clamp(value, min: minDuration, max: maxDuration)
    }

    static func outputDuration(for edits: [NativeSlotEdit]) -> Double {
        guard !edits.isEmpty else { return maxDuration }
        return edits.map { normalizedDuration($0.duration) }.min() ?? maxDuration
    }

    static func edits(_ edits: [NativeSlotEdit], fitting slotCount: Int) -> [NativeSlotEdit] {
        (0..<slotCount).map { index in
            index < edits.count ? edits[index] : .default
        }
    }

    private static func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
        Swift.min(Swift.max(value, minValue), maxValue)
    }
}

enum NativeSliderBounds {
    static func resolvedStep(_ step: Double) -> Double {
        step.isFinite && step > 0 ? step : 0.01
    }

    static func resolvedRange(lower: Double, upper: Double, step: Double) -> ClosedRange<Double> {
        let safeLower = lower.isFinite ? lower : 0
        let safeUpper = upper.isFinite ? upper : safeLower
        let safeStep = resolvedStep(step)

        if safeUpper - safeLower >= safeStep {
            return safeLower...safeUpper
        }

        return safeLower...(safeLower + safeStep)
    }

    static func clamped(_ value: Double, in range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return range.lowerBound }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}

enum LiveResultPrimaryAction {
    static func title(isSaving: Bool, didSave: Bool, language: AppLanguage = .zhHans) -> String {
        if isSaving { return language.text(.saving) }
        return didSave ? language.text(.openPhotos) : language.text(.saveAsLivePhoto)
    }
}

enum PhotoResultPrimaryAction {
    static func title(saveTitle: String, isSaving: Bool, didSave: Bool, language: AppLanguage = .zhHans) -> String {
        if isSaving { return language.text(.saving) }
        return didSave ? language.text(.openPhotos) : saveTitle
    }
}

enum ImageGenerationFeedback {
    static let minimumVisibleNanoseconds: UInt64 = 180_000_000

    static func imageJoinTitle(language: AppLanguage) -> String {
        language.text(.generatingImage)
    }

    static func splitNineTitle(language: AppLanguage) -> String {
        language.text(.splittingImage)
    }
}

struct AppPrivacyPolicyContent: Hashable {
    let title: String
    let updatedAt: String
    let intro: String
    let sections: [AppPrivacyPolicySection]
}

struct AppPrivacyPolicySection: Hashable, Identifiable {
    let id: String
    let title: String
    let body: String
}

enum AppPrivacyPolicy {
    static let contactEmail = "humility921@outlook.com"

    static func content(language: AppLanguage) -> AppPrivacyPolicyContent {
        switch language {
        case .zhHans:
            return zhHans
        case .en:
            return en
        }
    }

    private static let zhHans = AppPrivacyPolicyContent(
        title: "隐私政策",
        updatedAt: "生效日期：2026 年 7 月 6 日",
        intro: "LiveMix 是一个本机媒体拼接工具。我们尽量少处理数据，并让你的照片、视频和 Live Photo 留在你的设备上。",
        sections: [
            AppPrivacyPolicySection(
                id: "collection",
                title: "我们收集的数据",
                body: "LiveMix 不要求创建账号，不收集姓名、手机号、精确位置，也不接入广告、分析或追踪 SDK。当前版本不会自动收集可识别你的个人数据。"
            ),
            AppPrivacyPolicySection(
                id: "media",
                title: "照片、视频和 Live Photo",
                body: "你选择的照片、视频和 Live Photo 仅用于生成拼接内容，并在你的设备上本机处理。LiveMix 不会把这些素材上传到我们的服务器，也不会在你未选择素材时读取整个相册。"
            ),
            AppPrivacyPolicySection(
                id: "permissions",
                title: "相册权限",
                body: "读取相册权限用于选择视频、图片和 Live Photo。写入相册权限用于保存生成的 Live Photo、拼接图片和九宫格切图。你可以随时在 iOS 设置中撤销这些权限。"
            ),
            AppPrivacyPolicySection(
                id: "temporary-files",
                title: "临时文件",
                body: "生成过程中，LiveMix 可能会在设备本地创建临时图片或视频文件。它们仅用于生成结果，处理完成后会被清理或交由系统临时目录管理。"
            ),
            AppPrivacyPolicySection(
                id: "support",
                title: "问题反馈",
                body: "如果你主动通过邮件联系我们，我们会收到你的邮箱地址和邮件内容。这些信息只用于回复问题、处理反馈。你可以通过 \(contactEmail) 要求删除邮件沟通记录。"
            ),
            AppPrivacyPolicySection(
                id: "third-party",
                title: "第三方服务",
                body: "当前版本不集成第三方广告、统计或追踪服务。App Store、TestFlight、iCloud 和系统相册等 Apple 服务的数据处理由 Apple 的隐私政策约束。"
            ),
            AppPrivacyPolicySection(
                id: "children",
                title: "儿童隐私",
                body: "LiveMix 不面向 13 岁以下儿童，也不会有意收集儿童个人信息。"
            ),
            AppPrivacyPolicySection(
                id: "updates",
                title: "政策更新",
                body: "如果未来加入账号、云端处理、统计、广告、付费或模板社区等能力，我们会更新本隐私政策，并在必要时更新 App Store 隐私信息。"
            ),
        ]
    )

    private static let en = AppPrivacyPolicyContent(
        title: "Privacy Policy",
        updatedAt: "Effective date: July 6, 2026",
        intro: "LiveMix is an on-device media collage tool. We keep data handling minimal and aim to keep your photos, videos, and Live Photos on your device.",
        sections: [
            AppPrivacyPolicySection(
                id: "collection",
                title: "Data We Collect",
                body: "LiveMix does not require an account, does not collect your name, phone number, precise location, and does not include advertising, analytics, or tracking SDKs. The current version does not automatically collect personal data that identifies you."
            ),
            AppPrivacyPolicySection(
                id: "media",
                title: "Photos, Videos, and Live Photos",
                body: "The photos, videos, and Live Photos you choose are used only to create collage outputs and are processed on your device. LiveMix does not upload these media files to our servers and does not read your full photo library unless you choose specific items."
            ),
            AppPrivacyPolicySection(
                id: "permissions",
                title: "Photo Library Permissions",
                body: "Photo library access is used to let you select videos, images, and Live Photos. Photo library write access is used to save generated Live Photos, image collages, and 9-grid images. You can revoke these permissions at any time in iOS Settings."
            ),
            AppPrivacyPolicySection(
                id: "temporary-files",
                title: "Temporary Files",
                body: "During generation, LiveMix may create temporary image or video files locally on your device. They are used only to produce the output and are cleaned up after processing or managed by the system temporary directory."
            ),
            AppPrivacyPolicySection(
                id: "support",
                title: "Support Email",
                body: "If you contact us by email, we receive your email address and message content. We use this information only to reply to your request and handle feedback. You may contact \(contactEmail) to request deletion of support email records."
            ),
            AppPrivacyPolicySection(
                id: "third-party",
                title: "Third-Party Services",
                body: "The current version does not integrate third-party advertising, analytics, or tracking services. Data handling by Apple services such as the App Store, TestFlight, iCloud, and Photos is governed by Apple's privacy policy."
            ),
            AppPrivacyPolicySection(
                id: "children",
                title: "Children's Privacy",
                body: "LiveMix is not directed to children under 13, and we do not knowingly collect personal information from children."
            ),
            AppPrivacyPolicySection(
                id: "updates",
                title: "Policy Updates",
                body: "If we add accounts, cloud processing, analytics, advertising, paid features, or a template community in the future, we will update this Privacy Policy and the App Store privacy information as needed."
            ),
        ]
    )
}

struct NativeImageEdit: Hashable {
    static let defaultZoom: CGFloat = 1
    static let maxZoom: CGFloat = 3
    static let `default` = NativeImageEdit()

    var zoom: CGFloat
    var focalX: CGFloat
    var focalY: CGFloat

    init(
        zoom: CGFloat = NativeImageEdit.defaultZoom,
        focalX: CGFloat = 0.5,
        focalY: CGFloat = 0.5
    ) {
        self.zoom = zoom
        self.focalX = focalX
        self.focalY = focalY
    }

    func clamped() -> NativeImageEdit {
        NativeImageEdit(
            zoom: Self.clamp(zoom, min: Self.defaultZoom, max: Self.maxZoom),
            focalX: Self.clamp(focalX, min: 0, max: 1),
            focalY: Self.clamp(focalY, min: 0, max: 1)
        )
    }

    func dragged(translation: CGSize, imageSize: CGSize, targetSize: CGSize) -> NativeImageEdit {
        guard imageSize.width > 0,
              imageSize.height > 0,
              targetSize.width > 0,
              targetSize.height > 0 else {
            return clamped()
        }

        let edit = clamped()
        let baseScale = max(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
        let scale = baseScale * edit.zoom
        let renderedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let overflowX = max(0, renderedSize.width - targetSize.width)
        let overflowY = max(0, renderedSize.height - targetSize.height)

        return NativeImageEdit(
            zoom: edit.zoom,
            focalX: overflowX > 0 ? edit.focalX - translation.width / overflowX : edit.focalX,
            focalY: overflowY > 0 ? edit.focalY - translation.height / overflowY : edit.focalY
        ).clamped()
    }

    static func edits(_ edits: [NativeImageEdit], fitting imageCount: Int) -> [NativeImageEdit] {
        (0..<imageCount).map { index in
            index < edits.count ? edits[index].clamped() : .default
        }
    }

    private static func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        guard value.isFinite else { return minValue }
        return Swift.min(Swift.max(value, minValue), maxValue)
    }
}

enum NativeVideoRenderLayout {
    static func slotRect(for slot: CollageSlot, in renderSize: CGSize) -> CGRect {
        let minX = (slot.x * renderSize.width).rounded()
        let minY = (slot.y * renderSize.height).rounded()
        let maxX = ((slot.x + slot.width) * renderSize.width).rounded()
        let maxY = ((slot.y + slot.height) * renderSize.height).rounded()

        return CGRect(
            x: minX,
            y: minY,
            width: max(1, maxX - minX),
            height: max(1, maxY - minY)
        )
    }

    static func mediaTransform(
        sourceSize: CGSize,
        targetSize: CGSize,
        edit: NativeSlotEdit
    ) -> CGAffineTransform {
        guard sourceSize.width > 0,
              sourceSize.height > 0,
              targetSize.width > 0,
              targetSize.height > 0 else {
            return .identity
        }

        let baseScale: CGFloat
        switch edit.fitMode {
        case .fill:
            baseScale = max(targetSize.width / sourceSize.width, targetSize.height / sourceSize.height)
        case .fit:
            baseScale = min(targetSize.width / sourceSize.width, targetSize.height / sourceSize.height)
        }

        let scale = baseScale * (edit.fitMode == .fill ? edit.zoom : 1)
        let scaledSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let overflowX = max(0, scaledSize.width - targetSize.width)
        let overflowY = max(0, scaledSize.height - targetSize.height)
        let translateX: CGFloat
        let translateY: CGFloat

        switch edit.fitMode {
        case .fill:
            translateX = -overflowX * edit.focalX
            translateY = -overflowY * edit.focalY
        case .fit:
            translateX = (targetSize.width - scaledSize.width) / 2
            translateY = (targetSize.height - scaledSize.height) / 2
        }

        return CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(translationX: translateX, y: translateY))
    }
}

enum ImageJoinMode: String, CaseIterable, Identifiable {
    case horizontal
    case vertical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .horizontal:
            return "左右拼接"
        case .vertical:
            return "上下拼接"
        }
    }

    func localizedTitle(_ language: AppLanguage) -> String {
        switch self {
        case .horizontal:
            return language == .zhHans ? "左右拼接" : "Side by Side"
        case .vertical:
            return language == .zhHans ? "上下拼接" : "Stacked"
        }
    }
}

enum ImageJoinLayout {
    static let maxPreviewCount = 9

    static func outputSize(for imageCount: Int, mode: ImageJoinMode, tileSize: CGFloat) -> CGSize {
        CGSize(width: tileSize, height: tileSize)
    }

    static func tileRect(index: Int, imageCount: Int, mode: ImageJoinMode, tileSize: CGFloat) -> CGRect {
        let count = max(1, min(maxPreviewCount, imageCount))
        let safeIndex = max(0, min(index, count - 1))

        switch mode {
        case .horizontal:
            let width = floor(tileSize / CGFloat(count))
            let x = CGFloat(safeIndex) * width
            let maxX = safeIndex == count - 1 ? tileSize : x + width
            return CGRect(x: x, y: 0, width: max(1, maxX - x), height: tileSize)
        case .vertical:
            let height = floor(tileSize / CGFloat(count))
            let y = CGFloat(safeIndex) * height
            let maxY = safeIndex == count - 1 ? tileSize : y + height
            return CGRect(x: 0, y: y, width: tileSize, height: max(1, maxY - y))
        }
    }

    static func previewFrames(for imageCount: Int, mode: ImageJoinMode) -> [CGRect] {
        let count = max(1, min(maxPreviewCount, imageCount))

        return (0..<count).map { index in
            switch mode {
            case .horizontal:
                let width = 1 / CGFloat(count)
                return CGRect(x: CGFloat(index) * width, y: 0, width: width, height: 1)
            case .vertical:
                let height = 1 / CGFloat(count)
                return CGRect(x: 0, y: CGFloat(index) * height, width: 1, height: height)
            }
        }
    }

    static func liveTemplate(for imageCount: Int, mode: ImageJoinMode) -> NativeCollageTemplate {
        let slots = previewFrames(for: imageCount, mode: mode).enumerated().map { index, frame in
            CollageSlot(
                id: index,
                x: frame.minX,
                y: frame.minY,
                width: frame.width,
                height: frame.height
            )
        }

        return NativeCollageTemplate(
            id: "image-join-\(mode.rawValue)-\(slots.count)",
            name: mode.title,
            detail: "图片与 Live Photo 拼接",
            slots: slots
        )
    }
}

enum SplitNineLayout {
    static func tiles(in size: CGSize) -> [CGRect] {
        let tileWidth = size.width / 3
        let tileHeight = size.height / 3

        return (0..<9).map { index in
            let column = index % 3
            let row = index / 3
            return CGRect(
                x: CGFloat(column) * tileWidth,
                y: CGFloat(row) * tileHeight,
                width: tileWidth,
                height: tileHeight
            )
        }
    }
}
