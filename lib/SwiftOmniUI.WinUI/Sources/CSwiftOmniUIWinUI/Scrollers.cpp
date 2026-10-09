// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// A ScrollView's scroller: WinUI's ScrollViewer around the document the host
// lays out, saying where its view stands and when the user holds it.
// Design: docs/design/platforms/winui/layout.md#scrolling

#include "Relay.h"

#include <algorithm>
#include <cmath>
#include <winrt/Microsoft.UI.Composition.h>
#include <winrt/Microsoft.UI.Xaml.Hosting.h>
#include <winrt/Microsoft.UI.Xaml.Media.h>
#include <winrt/Windows.Foundation.h>

using namespace swiftomniui;

namespace {
    controls::ScrollBarVisibility visibility(bool scrolls, int32_t bar) {
        if (!scrolls) return controls::ScrollBarVisibility::Disabled;
        switch (bar) {
        case 1: return controls::ScrollBarVisibility::Visible;
        case 2: return controls::ScrollBarVisibility::Hidden;
        default: return controls::ScrollBarVisibility::Auto;
        }
    }
}

extern "C" SwiftOmniUIObjectRef swiftomniui_winui_scroller_make(int64_t view) {
    try {
        controls::ScrollViewer scroller;
        scroller.ViewChanging(guarded("handling ViewChanging",
            [view](IInspectable const &, controls::ScrollViewerViewChangingEventArgs const &args) {
            auto next = args.NextView();
            callbacks.scrolling(view, next.HorizontalOffset(), next.VerticalOffset());
        }));
        scroller.ViewChanged(guarded("handling ViewChanged",
            [view](IInspectable const &sender, controls::ScrollViewerViewChangedEventArgs const &) {
            auto scroller = sender.as<controls::ScrollViewer>();
            callbacks.scrolled(view, scroller.HorizontalOffset(), scroller.VerticalOffset());
        }));
        scroller.DirectManipulationStarted(guarded("handling DirectManipulationStarted",
            [view](IInspectable const &, IInspectable const &) {
            callbacks.held(view, true);
        }));
        scroller.DirectManipulationCompleted(guarded("handling DirectManipulationCompleted",
            [view](IInspectable const &, IInspectable const &) {
            callbacks.held(view, false);
        }));
        return detach(scroller);
    } catch (...) {
        report("making a scroller");
        return nullptr;
    }
}

extern "C" void swiftomniui_winui_scroller_set(
    SwiftOmniUIObjectRef handle, SwiftOmniUIObjectRef content, int32_t orientation, int32_t verticalBar, int32_t horizontalBar
) {
    try {
        auto scroller = borrow<controls::ScrollViewer>(handle);
        auto down = orientation == 0 || orientation == 2;
        auto across = orientation == 1 || orientation == 2;
        scroller.VerticalScrollMode(down ? controls::ScrollMode::Enabled : controls::ScrollMode::Disabled);
        scroller.HorizontalScrollMode(across ? controls::ScrollMode::Enabled : controls::ScrollMode::Disabled);
        scroller.VerticalScrollBarVisibility(visibility(down, verticalBar));
        scroller.HorizontalScrollBarVisibility(visibility(across, horizontalBar));
        auto element = content ? as<xaml::UIElement>(content) : xaml::UIElement{nullptr};
        if (scroller.Content() != element) scroller.Content(element);
    } catch (...) {
        report("setting a scroller");
    }
}

extern "C" void swiftomniui_winui_scroller_modes(
    SwiftOmniUIObjectRef handle, int32_t verticalMode, int32_t horizontalMode) {
    try {
        auto scroller = borrow<controls::ScrollViewer>(handle);
        scroller.VerticalScrollMode(static_cast<controls::ScrollMode>(verticalMode));
        scroller.HorizontalScrollMode(static_cast<controls::ScrollMode>(horizontalMode));
    } catch (...) {
        report("setting a scroller's modes");
    }
}

extern "C" void swiftomniui_winui_scroller_move(SwiftOmniUIObjectRef handle, double x, double y, bool animated) {
    try {
        borrow<controls::ScrollViewer>(handle).ChangeView(
            winrt::box_value(x).as<winrt::Windows::Foundation::IReference<double>>(),
            winrt::box_value(y).as<winrt::Windows::Foundation::IReference<double>>(), nullptr, !animated);
    } catch (...) {
        report("moving a scroller");
    }
}

extern "C" void swiftomniui_winui_scroller_commit(SwiftOmniUIObjectRef content, double x, double y, bool virtualized) {
    try {
        auto element = as<xaml::UIElement>(content);
        auto visual = xaml::Hosting::ElementCompositionPreview::GetElementVisual(element);
        auto properties = visual.Properties();
        winrt::Windows::Foundation::Numerics::float3 committed;
        auto status = properties.TryGetVector3(L"RealizedScrollOffset", committed);
        float active = 0;
        properties.TryGetScalar(L"RealizedScrolling", active);
        if (!virtualized) {
            if (status == winrt::Microsoft::UI::Composition::CompositionGetValueStatus::Succeeded) {
                visual.StopAnimation(L"Translation");
                properties.InsertVector3(L"Translation", {0, 0, 0});
                properties.InsertScalar(L"RealizedScrolling", 0);
            }
            return;
        }
        properties.InsertVector3(L"RealizedScrollOffset", {static_cast<float>(x), static_cast<float>(y), 0});
        if (active != 1) {
            xaml::Hosting::ElementCompositionPreview::SetIsTranslationEnabled(element, true);
            // XAML owns the primary visual's offset and manipulation matrix. Translation is a separate
            // prepend visual: cancel independent scrolling and apply only the offset arranged this pass.
            auto expression = visual.Compositor().CreateExpressionAnimation(
                L"Vector3(-Native.Offset.X - Native.TransformMatrix._41, "
                L"-Native.Offset.Y - Native.TransformMatrix._42, 0) - Realized.RealizedScrollOffset");
            expression.SetReferenceParameter(L"Native", visual);
            expression.SetReferenceParameter(L"Realized", properties);
            visual.StartAnimation(L"Translation", expression);
            properties.InsertScalar(L"RealizedScrolling", 1);
        }
    } catch (...) { report("committing a virtualized scroller"); }
}

extern "C" void swiftomniui_winui_scroller_place_for(
    SwiftOmniUIObjectRef handle, SwiftOmniUIObjectRef descendant, double anchorX, double anchorY,
    int32_t *found, double *place)
{
    try {
        auto scroller = borrow<controls::ScrollViewer>(handle);
        auto element = as<xaml::FrameworkElement>(descendant);
        auto content = scroller.Content().try_as<xaml::UIElement>();
        if (!element || !content) { *found = 0; return; }

        auto bounds = element.TransformToVisual(content).TransformBounds(
            winrt::Windows::Foundation::Rect(
                0, 0, (float)element.ActualWidth(), (float)element.ActualHeight()));

        auto nearest = [](double start, double length, double room, double now) {
            if (start >= now && start + length <= now + room) return now;
            return start < now ? start : start + length - room;
        };

        double x = scroller.HorizontalOffset();
        double y = scroller.VerticalOffset();
        if (scroller.HorizontalScrollMode() == controls::ScrollMode::Enabled) {
            x = std::isnan(anchorX)
                ? nearest(bounds.X, bounds.Width, scroller.ViewportWidth(), x)
                : bounds.X + anchorX * bounds.Width - anchorX * scroller.ViewportWidth();
        }
        if (scroller.VerticalScrollMode() == controls::ScrollMode::Enabled) {
            y = std::isnan(anchorY)
                ? nearest(bounds.Y, bounds.Height, scroller.ViewportHeight(), y)
                : bounds.Y + anchorY * bounds.Height - anchorY * scroller.ViewportHeight();
        }
        place[0] = x;
        place[1] = y;
        *found = 1;
    } catch (...) {
        report("placing for a descendant");
        *found = 0;
    }
}

extern "C" void swiftomniui_winui_scroller_offset(SwiftOmniUIObjectRef handle, double *offset) {
    try {
        auto scroller = borrow<controls::ScrollViewer>(handle);
        offset[0] = scroller.HorizontalOffset();
        offset[1] = scroller.VerticalOffset();
        offset[2] = scroller.ScrollableWidth();
        offset[3] = scroller.ScrollableHeight();
    } catch (...) {
        report("reading a scroller");
    }
}

extern "C" void swiftomniui_winui_scroller_viewport(
    SwiftOmniUIObjectRef handle, SwiftOmniUIObjectRef descendant, double *viewport
) {
    std::fill_n(viewport, 6, 0);
    try {
        auto scroller = borrow<controls::ScrollViewer>(handle);
        auto content = scroller.Content().try_as<xaml::UIElement>();
        if (!content) return;
        auto element = as<xaml::UIElement>(descendant);
        auto corner = element.TransformToVisual(content).TransformPoint({0, 0});
        viewport[0] = scroller.HorizontalOffset() - corner.X;
        viewport[1] = scroller.VerticalOffset() - corner.Y;
        viewport[2] = scroller.ViewportWidth();
        viewport[3] = scroller.ViewportHeight();
        auto parent = xaml::Media::VisualTreeHelper::GetParent(content).as<xaml::UIElement>();
        auto displayed = element.TransformToVisual(parent).TransformPoint({0, 0});
        viewport[4] = displayed.X;
        viewport[5] = displayed.Y;
    } catch (...) {
        report("reading a descendant's scroll viewport");
    }
}
