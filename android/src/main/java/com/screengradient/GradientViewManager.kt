package com.screengradient

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.views.view.ReactViewGroup
import com.facebook.react.views.view.ReactViewManager

/** Extends [ReactViewManager] so GradientView supports every regular View prop and children. */
@ReactModule(name = GradientViewManager.NAME)
class GradientViewManager : ReactViewManager() {

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): ReactViewGroup = GradientView(context)

  companion object {
    const val NAME = "RNScreenGradientView"
  }
}
