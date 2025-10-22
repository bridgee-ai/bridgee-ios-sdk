// swift-tools-version: 5.5
// O swift-tools-version 5.5 é necessário para `async/await`.

import PackageDescription

let package = Package(
    name: "BridgeeSDK",
    // Define o Minimum Deployment Target como iOS 14.0
    platforms: [
        .iOS(.v14) 
    ],
    products: [
        // O produto de biblioteca consumível
        .library(
            name: "BridgeeSDK",
            targets: ["BridgeeSDK"]),
    ],
    dependencies: [
        // Sem dependências externas - o SDK é completamente desacoplado
    ],
    targets: [
        // O target do código-fonte do SDK
        .target(
            name: "BridgeeSDK",
            dependencies: [
                // Sem dependências - usa apenas o protocolo AnalyticsProvider
            ],
            path: "Sources/BridgeeSDK",
            resources: [
                // Inclui o Privacy Manifest como um recurso
                .process("Resources/PrivacyInfo.xcprivacy")
            ]
        ),
        // O target de testes
        .testTarget(
            name: "BridgeeSDKTests",
            dependencies: ["BridgeeSDK"],
            path: "Tests/BridgeeSDKTests"
        ),
    ]
)
