package com.screengradient

import android.content.Context
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.view.View
import com.facebook.react.uimanager.BackgroundStyleApplicator
import com.facebook.react.views.view.ReactViewGroup

/**
 * Native view for `<GradientView>`.
 *
 * Draws the nearest [ScreenGradientHostView]'s gradient behind its children. The gradient is never
 * created in this view's coordinates: the host's shader (defined in host viewport coordinates) is
 * drawn with a local matrix equal to the inverse of this view's view→host transform, so each pixel
 * shows the host gradient color at its physical position inside the host.
 */
class GradientView(context: Context) : ReactViewGroup(context) {

  private var host: ScreenGradientHostView? = null

  private val paint = Paint(Paint.DITHER_FLAG)
  private val viewToHost = Matrix()
  private val hostToView = Matrix()
  private val scratch = Matrix()
  private var hasMatrix = false

  init {
    // ViewGroups skip onDraw by default.
    setWillNotDraw(false)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    attachToHost()
  }

  override fun onDetachedFromWindow() {
    detachFromHost()
    super.onDetachedFromWindow()
  }

  private fun attachToHost() {
    detachFromHost()
    var parent = parent
    while (parent != null) {
      if (parent is ScreenGradientHostView) {
        host = parent
        parent.register(this)
        hasMatrix = false
        updateHostMatrix(parent)
        return
      }
      parent = parent.parent
    }
    // Not inside a ScreenGradient: draw nothing (the JS layer warns in development).
  }

  private fun detachFromHost() {
    host?.unregister(this)
    host = null
    hasMatrix = false
  }

  internal fun onHostGradientChanged() {
    invalidate()
  }

  /** Called by the host before each frame is drawn. Invalidates only if the mapping changed. */
  internal fun updateHostMatrix(host: ScreenGradientHostView) {
    if (!host.computeViewToHost(this, scratch)) {
      return
    }
    if (hasMatrix && scratch == viewToHost) {
      return
    }
    viewToHost.set(scratch)
    hasMatrix = viewToHost.invert(hostToView)
    invalidate()
  }

  override fun onDraw(canvas: Canvas) {
    super.onDraw(canvas)
    val shader = host?.shader ?: return
    if (!hasMatrix) {
      return
    }
    shader.setLocalMatrix(hostToView)
    paint.shader = shader
    canvas.save()
    BackgroundStyleApplicator.clipToPaddingBox(this, canvas)
    canvas.drawPaint(paint)
    canvas.restore()
  }
}
