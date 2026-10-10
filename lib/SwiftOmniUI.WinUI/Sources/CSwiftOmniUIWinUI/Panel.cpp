// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// The panel every SwiftOmniUI layout is: WinUI asks it to measure and arrange, and
// the host answers with the core's arithmetic.
// Design: docs/design/platforms/winui/layout.md#a-layout-is-a-panel

#include "Relay.h"

#include <algorithm>
#include <vector>

#include <winrt/Microsoft.UI.Xaml.Automation.Peers.h>
#include <winrt/Microsoft.UI.Xaml.Automation.Provider.h>

using namespace swiftomniui;
using winrt::Windows::Foundation::Size;
namespace peers = winrt::Microsoft::UI::Xaml::Automation::Peers;
namespace provider = winrt::Microsoft::UI::Xaml::Automation::Provider;

namespace {
    struct SwiftOmniUIPanel;

    /// What assistive technology reads of a panel: one it can press, as a tap, while its view listens for taps, and
    /// none of what stands in it while it is left out with its children.
    /// Design: docs/design/platforms/winui/input.md#pressed-by-assistive-technology
    struct SwiftOmniUIPanelPeer : peers::FrameworkElementAutomationPeerT<SwiftOmniUIPanelPeer, provider::IInvokeProvider> {
        using Base = peers::FrameworkElementAutomationPeerT<SwiftOmniUIPanelPeer, provider::IInvokeProvider>;

        SwiftOmniUIPanelPeer(xaml::FrameworkElement const &owner, int64_t view) : Base(owner), view(view) {}

        IInspectable GetPatternCore(peers::PatternInterface const &pattern) {
            if (pattern == peers::PatternInterface::Invoke && hearsTaps(view)) return *this;
            return Base::GetPatternCore(pattern);
        }

        void Invoke() {
            press(view);
        }

        winrt::Windows::Foundation::Collections::IVector<peers::AutomationPeer> GetChildrenCore();

        int64_t view;
    };

    struct SwiftOmniUIPanel : controls::PanelT<SwiftOmniUIPanel> {
        explicit SwiftOmniUIPanel(int64_t view) : view(view) {}

        peers::AutomationPeer OnCreateAutomationPeer() {
            IInspectable self = *this;
            return winrt::make<SwiftOmniUIPanelPeer>(self.as<xaml::FrameworkElement>(), view);
        }

        Size MeasureOverride(Size available) {
            double size[2] = {0, 0};
            callbacks.measure(view, available.Width, available.Height, size);
            return Size(static_cast<float>(size[0]), static_cast<float>(size[1]));
        }

        Size ArrangeOverride(Size final) {
            callbacks.arrange(view, final.Width, final.Height);
            return final;
        }

        int64_t view;

        /// Whether assistive technology meets none of what stands in the panel.
        bool childrenHidden = false;
        xaml::FrameworkElement::EffectiveViewportChanged_revoker viewportChanged;
    };

    /// The panel a handle or a peer's owner holds, reached through an interface the panel implements itself: the
    /// panel it is made on answers the rest.
    SwiftOmniUIPanel *panel(xaml::UIElement const &element) {
        return winrt::get_self<SwiftOmniUIPanel>(element.as<xaml::IFrameworkElementOverrides>());
    }

    winrt::Windows::Foundation::Collections::IVector<peers::AutomationPeer> SwiftOmniUIPanelPeer::GetChildrenCore() {
        if (panel(Owner())->childrenHidden) return winrt::single_threaded_vector<peers::AutomationPeer>();
        return Base::GetChildrenCore();
    }
}

extern "C" SwiftOmniUIObjectRef swiftomniui_winui_panel_make(int64_t view) {
    try {
        return detach(winrt::make<SwiftOmniUIPanel>(view).as<controls::Panel>());
    } catch (...) {
        report("making a panel");
        return nullptr;
    }
}

extern "C" void swiftomniui_winui_panel_set_children(
    SwiftOmniUIObjectRef panel, SwiftOmniUIObjectRef const *children, int32_t count
) {
    try {
        auto items = borrow<controls::Panel>(panel).Children();
        std::vector<xaml::UIElement> held;
        held.reserve(count);
        for (int32_t index = 0; index < count; ++index) held.push_back(as<xaml::UIElement>(children[index]));
        // A lazy window usually changes at its edges. Keep the intersecting
        // UIElements attached, preserving their native state and composition.
        for (uint32_t index = items.Size(); index > 0; --index) {
            auto child = items.GetAt(index - 1);
            if (std::find(held.begin(), held.end(), child) == held.end()) items.RemoveAt(index - 1);
        }
        for (uint32_t index = 0; index < held.size(); ++index) {
            if (index < items.Size() && items.GetAt(index) == held[index]) continue;
            uint32_t previous;
            if (items.IndexOf(held[index], previous)) items.RemoveAt(previous);
            items.InsertAt(index, held[index]);
        }
    } catch (...) {
        report("holding a panel's children");
    }
}

extern "C" void swiftomniui_winui_panel_hide_children(SwiftOmniUIObjectRef handle, bool hidden) {
    try {
        panel(as<xaml::UIElement>(handle))->childrenHidden = hidden;
    } catch (...) {
        report("hiding a panel's children from assistive technology");
    }
}

extern "C" void swiftomniui_winui_panel_watch_viewport(SwiftOmniUIObjectRef handle, bool enabled) {
    try {
        auto element = as<xaml::FrameworkElement>(handle);
        auto owner = panel(element);
        owner->viewportChanged.revoke();
        if (enabled) {
            owner->viewportChanged = element.EffectiveViewportChanged(winrt::auto_revoke,
                guarded("handling EffectiveViewportChanged",
                    [view = owner->view](xaml::FrameworkElement const &, xaml::EffectiveViewportChangedEventArgs const &args) {
                        auto viewport = args.EffectiveViewport();
                        callbacks.viewportChanged(view, viewport.X, viewport.Y, viewport.Width, viewport.Height,
                            args.BringIntoViewDistanceX(), args.BringIntoViewDistanceY());
                    }));
        }
    } catch (...) {
        report("watching a panel's viewport");
    }
}
