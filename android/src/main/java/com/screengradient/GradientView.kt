package com.screengradient

import android.content.Context
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import com.facebook.react.uimanager.BackgroundStyleApplicator
import com.facebook.react.views.view.ReactViewGroup

/**
 * Native view for `<GradientView>`.
 *
 * Draws the nearest matching [GradientHostView]'s gradient behind its children. The gradient is
 * never created in this view's coordinates: the host's shader (defined in host coordinates) is
 * drawn with a local matrix equal to the inverse of this view's view→host transform, so each pixel
 * shows the host gradient color at its physical position inside the host.
 */
open class GradientView(context: Context) : ReactViewGroup(context) {

  private var host: GradientHostView? = null

  /** Nearest ancestor [GradientHostView] with this name is used. */
  var hostName: String = GradientHostView.DEFAULT_HOST_NAME
    set(value) {
      if (field == value) {
        return
      }
      field = value
      if (isAttachedToWindow) {
        reattachToHost()
      }
    }

  protected val paint = Paint(Paint.DITHER_FLAG)
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
    reattachToHost()
  }

  override fun onDetachedFromWindow() {
    detachFromHost()
    super.onDetachedFromWindow()
  }

  internal fun reattachToHost() {
    detachFromHost()
    var parent = parent
    while (parent != null) {
      if (parent is GradientHostView && parent.hostName == hostName) {
        host = parent
        parent.register(this)
        updateHostMatrix(parent)
        return
      }
      parent = parent.parent
    }
    // No matching GradientHost: draw nothing (the JS layer warns in development).
    invalidate()
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
  internal fun updateHostMatrix(host: GradientHostView) {
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
    drawGradient(canvas, paint)
  }

  /** Draws [paint] (carrying the host shader, already positioned) in view coordinates. */
  protected open fun drawGradient(canvas: Canvas, paint: Paint) {
    canvas.save()
    BackgroundStyleApplicator.clipToPaddingBox(this, canvas)
    canvas.drawPaint(paint)
    canvas.restore()
  }
}
