package com.screengradient

import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.views.view.ReactViewGroup
import com.facebook.react.views.view.ReactViewManager

@ReactModule(name = GradientMaskSvgManager.NAME)
class GradientMaskSvgManager : ReactViewManager() {

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): ReactViewGroup =
    GradientMaskSvgView(context)

  @ReactProp(name = "hostName")
  fun setHostName(view: ReactViewGroup, value: String?) {
    (view as? GradientMaskSvgView)?.hostName = value ?: GradientHostView.DEFAULT_HOST_NAME
  }

  @ReactProp(name = "pathData")
  fun setPathData(view: ReactViewGroup, value: ReadableArray?) {
    (view as? GradientMaskSvgView)?.setPathData(value?.toFloatArray() ?: FloatArray(0))
  }

  @ReactProp(name = "viewBox")
  fun setViewBox(view: ReactViewGroup, value: ReadableArray?) {
    (view as? GradientMaskSvgView)?.setViewBox(value?.toFloatArray())
  }

  companion object {
    const val NAME = "RNGradientMaskSvg"
  }
}
