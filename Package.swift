// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenVPNXor",
    products: [
        .library(
            name: "OpenVPNXor",
            targets: ["OpenVPNXor"]),
    ],
    targets: [
        .binaryTarget(
            name: "OpenVPNXor",
            url: "https://github.com/FuturraGroup/OpenVPNXor/raw/main/releases/1.0/OpenVPNXor.framework.zip",
            checksum: "f8b57e42d3a7f8883bb839d3990e4571fdc1ec6a3506881e07a695f91afee167"
        )
    ])
