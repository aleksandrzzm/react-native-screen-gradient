package com.screengradient

import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.views.view.ReactViewGroup
import com.facebook.react.views.view.ReactViewManager

/**
 * Extends [ReactViewManager] so the host supports every regular View prop (overflow, borders,
 * removeClippedSubviews, ...). Custom props go through @ReactProp setters.
 */
@ReactModule(name = GradientHostManager.NAME)
class GradientHostManager : ReactViewManager() {

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): ReactViewGroup =
    GradientHostView(context)

  @ReactProp(name = "host")
  fun setHost(view: ReactViewGroup, value: String?) {
    val host = view as? GradientHostView ?: return
    host.hostName = value ?: GradientHostView.DEFAULT_HOST_NAME
  }

  @ReactProp(name = "colors")
  fun setColors(view: ReactViewGroup, value: ReadableArray?) {
    val host = view as? GradientHostView ?: return
    if (value == null) {
      host.setColors(IntArray(0))
      return
    }
    val colors = IntArray(value.size()) { i ->
      when (value.getType(i)) {
        ReadableType.Map -> ColorPropConverter.getColor(value.getMap(i), view.context) ?: 0
        ReadableType.Number -> value.getDouble(i).toLong().toInt()
        else -> 0
      }
    }
    host.setColors(colors)
  }

  @ReactProp(name = "locations")
  fun setLocations(view: ReactViewGroup, value: ReadableArray?) {
    val host = view as? GradientHostView ?: return
    host.setLocations(value?.toFloatArray())
  }

  @ReactProp(name = "start")
  fun setStart(view: ReactViewGroup, value: ReadableMap?) {
    val host = view as? GradientHostView ?: return
    host.setStart(value.floatOr("x", 0f), value.floatOr("y", 0f))
  }

  @ReactProp(name = "end")
  fun setEnd(view: ReactViewGroup, value: ReadableMap?) {
    val host = view as? GradientHostView ?: return
    host.setEnd(value.floatOr("x", 0f), value.floatOr("y", 1f))
  }

  private fun ReadableMap?.floatOr(key: String, fallback: Float): Float =
    if (this != null && hasKey(key) && !isNull(key)) getDouble(key).toFloat() else fallback

  companion object {
    const val NAME = "RNGradientHost"
  }
}

internal fun ReadableArray.toFloatArray(): FloatArray = FloatArray(size()) { getDouble(it).toFloat() }
