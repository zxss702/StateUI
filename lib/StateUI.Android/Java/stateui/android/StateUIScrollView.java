// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

package stateui.android;

import android.content.Context;
import android.view.MotionEvent;
import android.widget.ScrollView;

/**
 * A `ScrollView` the host can hush: `isScrollDisabled` turns the user's drag off while the program's own
 * `scrollTo` still moves it, and a touch it does not answer goes to whatever stands under it.
 */
final class StateUIScrollView extends ScrollView {
    private boolean scrollable = true;

    StateUIScrollView(Context context) {
        super(context);
    }

    void setScrollable(boolean can) {
        scrollable = can;
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent event) {
        return scrollable && super.onInterceptTouchEvent(event);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        return scrollable && super.onTouchEvent(event);
    }
}
