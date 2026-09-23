package com.screengradient

import android.graphics.Color
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.ScreenGradientViewManagerInterface
import com.facebook.react.viewmanagers.ScreenGradientViewManagerDelegate

@ReactModule(name = ScreenGradientViewManager.NAME)
class ScreenGradientViewManager : SimpleViewManager<ScreenGradientView>(),
  ScreenGradientViewManagerInterface<ScreenGradientView> {
  private val mDelegate: ViewManagerDelegate<ScreenGradientView>

  init {
    mDelegate = ScreenGradientViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<ScreenGradientView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): ScreenGradientView {
    return ScreenGradientView(context)
  }

  @ReactProp(name = "color")
  override fun setColor(view: ScreenGradientView?, color: Int?) {
    view?.setBackgroundColor(color ?: Color.TRANSPARENT)
  }

  companion object {
    const val NAME = "ScreenGradientView"
  }
}
