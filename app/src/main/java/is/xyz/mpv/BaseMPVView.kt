package `is`.xyz.mpv

import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.view.SurfaceHolder
import android.view.SurfaceView
import `is`.xyz.mpv.MPVLib.MpvFormat
import `is`.xyz.mpv.MPVLib.observeProperty
import `is`.xyz.mpv.MPVLib.propBoolean
import `is`.xyz.mpv.MPVLib.propDouble
import `is`.xyz.mpv.MPVLib.propFloat
import `is`.xyz.mpv.MPVLib.propInt
import `is`.xyz.mpv.MPVLib.propLong
import `is`.xyz.mpv.MPVLib.propNode
import `is`.xyz.mpv.MPVLib.propString

// Contains only the essential code needed to get a picture on the screen

abstract class BaseMPVView(context: Context, attrs: AttributeSet) : SurfaceView(context, attrs), SurfaceHolder.Callback {
    /**
     * Initialize libmpv.
     *
     * Call this once before the view is shown.
     */
    fun initialize(configDir: String, cacheDir: String) {
        MPVLib.create(context)

        MPVLib.setOptionString("config", "yes")
        MPVLib.setOptionString("config-dir", configDir)
        for (opt in arrayOf("gpu-shader-cache-dir", "icc-cache-dir")) {
            MPVLib.setOptionString(opt, cacheDir)
        }
        try {
            android.system.Os.setenv("SSL_CERT_FILE", "$configDir/cacert.pem", true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set SSL_CERT_FILE", e)
        }
        initOptions()

        MPVLib.init()

        postInitOptions()
        MPVLib.setOptionString("force-window", "no")
        MPVLib.setOptionString("idle", "once")

        holder.addCallback(this)
        observeProperties()
        reobserveAllProperties()
    }

    /**
     * Deinitialize libmpv.
     *
     * Call this once before the view is destroyed.
     */
    fun destroy() {
        holder.removeCallback(this)
        clearAllProperties()
        MPVLib.destroy()
    }

    protected abstract fun initOptions()
    protected abstract fun postInitOptions()

    protected abstract fun observeProperties()

    private var filePath: String? = null

    /**
     * Set the first file to be played once the player is ready.
     */
    fun playFile(filePath: String) {
        this.filePath = filePath
    }

    private var voInUse: String = "gpu-next"
    private var hwdecInUse: String = "mediacodec-copy" // Default to "HW"

    /**
     * Sets the VO to use.
     * It is automatically disabled/enabled when the surface dis-/appears.
     */
    fun setVo(vo: String) {
        voInUse = vo
        MPVLib.setOptionString("vo", vo)
    }

    /**
     * Sets the hardware decoding mode.
     * @param mode "mediacodec" (HW+), "mediacodec-copy" (HW), or "no" (SW)
     */
    fun setHwdec(mode: String) {
        hwdecInUse = mode
        MPVLib.setOptionString("hwdec", mode)
    }

    /**
     * Configures the player for high-performance Vulkan rendering with zero-copy HW+.
     */
    fun enableVulkan(enabled: Boolean) {
        if (enabled) {
            setVo("gpu-next")
            MPVLib.setOptionString("gpu-api", "vulkan")
            MPVLib.setOptionString("gpu-context", "androidvk")
            // Enable zero-copy interop for HW+ (mediacodec)
            MPVLib.setOptionString("vd-lavc-dr", "yes")
            // Optimal Vulkan settings for Android
            MPVLib.setOptionString("vulkan-async-compute", "yes")
            MPVLib.setOptionString("vulkan-async-transfer", "yes")
            MPVLib.setOptionString("vulkan-queue-count", "1") // 1 is safest for mobile drivers
        } else {
            setVo("gpu")
            MPVLib.setOptionString("gpu-api", "opengl")
        }
    }

    // Surface callbacks

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        MPVLib.setPropertyString("android-surface-size", "${width}x$height")
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        Log.w(TAG, "attaching surface")
        MPVLib.attachSurface(holder.surface)
        MPVLib.setOptionString("force-window", "yes")

        if (filePath != null) {
            MPVLib.command("loadfile", filePath as String)
            filePath = null
        } else {
            MPVLib.setPropertyString("vo", voInUse)
        }
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        Log.w(TAG, "detaching surface")
        MPVLib.setPropertyString("vo", "null")
        MPVLib.setPropertyString("force-window", "no")
        MPVLib.detachSurface()
    }

    private fun reobserveAllProperties() {
        propBoolean.map.keys.forEach { observeProperty(it, MpvFormat.MPV_FORMAT_FLAG) }
        propString.map.keys.forEach { observeProperty(it, MpvFormat.MPV_FORMAT_STRING) }
        propDouble.map.keys.forEach { observeProperty(it, MpvFormat.MPV_FORMAT_DOUBLE) }
        propFloat.map.keys.forEach { observeProperty(it, MpvFormat.MPV_FORMAT_DOUBLE) }
        propLong.map.keys.forEach { observeProperty(it, MpvFormat.MPV_FORMAT_INT64) }
        propInt.map.keys.forEach { observeProperty(it, MpvFormat.MPV_FORMAT_INT64) }
        propNode.map.keys.forEach { observeProperty(it, MpvFormat.MPV_FORMAT_NODE) }
    }

    private fun clearAllProperties() {
        listOf(propInt, propBoolean, propDouble, propString, propFloat, propLong, propNode).forEach {
            it.map.clear()
        }
    }

    companion object {
        private const val TAG = "mpv"
    }
}
