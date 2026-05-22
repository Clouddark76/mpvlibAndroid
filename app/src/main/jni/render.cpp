#include <jni.h>
#include <android/native_window.h>
#include <android/native_window_jni.h>

#include <mpv/client.h>

#include "jni_utils.h"
#include "log.h"
#include "globals.h"

extern "C" {
    jni_func(void, attachSurface, jobject surface_);
    jni_func(void, detachSurface);
};

static jobject surface;
static ANativeWindow *native_window;

jni_func(void, attachSurface, jobject surface_) {
    CHECK_MPV_INIT();

    if (surface) {
        detachSurface(env, obj);
    }

    surface = env->NewGlobalRef(surface_);
    if (!surface)
        die("invalid surface provided");

    native_window = ANativeWindow_fromSurface(env, surface);
    if (!native_window) {
        env->DeleteGlobalRef(surface);
        surface = NULL;
        die("failed to get native window from surface");
    }

    // Set frame rate if available (Android 11+)
    if (__builtin_available(android 30, *)) {
        // We don't know the exact frame rate here, but we can set a default or
        // let mpv handle it later. Setting it to 0.0f tells the system to use
        // the app's preferred rate or the video's rate once known.
        ANativeWindow_setFrameRate(native_window, 0.0f, ANATIVEWINDOW_FRAME_RATE_COMPATIBILITY_DEFAULT);
    }

    int64_t wid = reinterpret_cast<intptr_t>(native_window);
    int result = mpv_set_option(g_mpv, "wid", MPV_FORMAT_INT64, &wid);
    if (result < 0)
         ALOGE("mpv_set_option(wid) returned error %s", mpv_error_string(result));
}

jni_func(void, detachSurface) {
    CHECK_MPV_INIT();

    int64_t wid = 0;
    int result = mpv_set_option(g_mpv, "wid", MPV_FORMAT_INT64, &wid);
    if (result < 0)
         ALOGE("mpv_set_option(wid) returned error %s", mpv_error_string(result));

    if (native_window) {
        ANativeWindow_release(native_window);
        native_window = NULL;
    }

    if (surface) {
        env->DeleteGlobalRef(surface);
        surface = NULL;
    }
}
