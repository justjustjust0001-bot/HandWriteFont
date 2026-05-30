import Foundation

struct FontBuildMetadata {
    let fontRevision: Float
    let versionString: String
    let exportStamp: String

    static let `default` = FontBuildMetadata(
        fontRevision: 1.0,
        versionString: "Version 1.000",
        exportStamp: "test"
    )
}
