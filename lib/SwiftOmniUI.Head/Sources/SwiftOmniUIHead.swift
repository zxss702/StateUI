// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// The host this build is for, to the head that depends on SwiftOmniUIHead.

#if APPKIT
@_exported import SwiftOmniUIAppKit
#elseif UIKIT
@_exported import SwiftOmniUIUIKit
#elseif ANDROID
@_exported import SwiftOmniUIAndroid
#elseif WINUI
@_exported import SwiftOmniUIWinUI
#elseif GTK
@_exported import SwiftOmniUIGTK
#elseif WEB
@_exported import SwiftOmniUIWeb
#endif
