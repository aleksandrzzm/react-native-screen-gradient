package com.screengradient

import android.content.Context
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Shader
import android.view.View
import android.view.ViewTreeObserver
import com.facebook.react.views.view.ReactViewGroup
import java.util.Collections
import java.util.WeakHashMap

/**
 * Native host for `<ScreenGradient>`.
 *
 * Owns the single logical gradient, defined in this view's own coordinate space (its viewport):
 * `start`/`end` are fractions of the host's width/height. Descendant [GradientView]s register
 * themselves here and draw a window into this gradient.
 *
 * Positioning is driven entirely by the native view tree: once per frame (only when a frame is
 * actually being drawn) [onPreDraw] recomputes each registered view's host→view matrix and
 * invalidates the views whose matrix changed (scroll, layout, transform).
 */
class ScreenGradientHostView(context: Context) :
  ReactViewGroup(context), ViewTreeObserver.OnPreDrawListener {

  private val gradientViews: MutableSet<GradientView> =
    Collections.newSetFromMap(WeakHashMap())

  private var colors: IntArray = IntArray(0)
  private var locations: FloatArray? = null
  private var startX = 0f
  private var startY = 0f
  private var endX = 0f
  private var endY = 1f

  /** Gradient in host coordinates, or null when there is nothing to draw. */
  var shader: Shader? = null
    private set

  private var observedTreeObserver: ViewTreeObserver? = null

  fun setColors(colors: IntArray) {
    this.colors = colors
    invalidateGradient()
  }

  fun setLocations(locations: FloatArray?) {
    this.locations = locations
    invalidateGradient()
  }

  fun setStart(x: Float, y: Float) {
    startX = x
    startY = y
    invalidateGradient()
  }

  fun setEnd(x: Float, y: Float) {
    endX = x
    endY = y
    invalidateGradient()
  }

  internal fun register(view: GradientView) {
    gradientViews.add(view)
  }

  internal fun unregister(view: GradientView) {
    gradientViews.remove(view)
  }

  private fun invalidateGradient() {
    shader = buildShader(width, height)
    for (view in gradientViews) {
      view.onHostGradientChanged()
    }
  }

  private fun buildShader(w: Int, h: Int): Shader? {
    if (w <= 0 || h <= 0 || colors.isEmpty()) {
      return null
    }
    // A single color is not a valid LinearGradient input; repeat it.
    val shaderColors = if (colors.size == 1) intArrayOf(colors[0], colors[0]) else colors
    val positions = locations?.takeIf { it.size == shaderColors.size }
    return LinearGradient(
      startX * w,
      startY * h,
      endX * w,
      endY * h,
      shaderColors,
      positions,
      Shader.TileMode.CLAMP,
    )
  }

  override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
    super.onSizeChanged(w, h, oldw, oldh)
    invalidateGradient()
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    attachTreeObserver()
  }

  override fun onDetachedFromWindow() {
    detachTreeObserver()
    super.onDetachedFromWindow()
  }

  private fun attachTreeObserver() {
    detachTreeObserver()
    val observer = viewTreeObserver
    observer.addOnPreDrawListener(this)
    observedTreeObserver = observer
  }

  private fun detachTreeObserver() {
    val observer = observedTreeObserver ?: return
    if (observer.isAlive) {
      observer.removeOnPreDrawListener(this)
    }
    observedTreeObserver = null
  }

  override fun onPreDraw(): Boolean {
    if (gradientViews.isEmpty()) {
      return true
    }
    for (view in gradientViews) {
      view.updateHostMatrix(this)
    }
    return true
  }

  /**
   * Computes the matrix that maps [view]'s local coordinates to this host's viewport coordinates,
   * by walking up the parent chain. Returns false if [view] is not a descendant.
   *
   * For every view `v` between [view] and the host, ViewGroup draws `v` as:
   * `translate(v.left, v.top) · v.matrix · translate(-v.scrollX, -v.scrollY)`, so the product of
   * those per-level transforms is exactly the mapping the renderer uses. ScrollView offsets enter
   * through the parent's scrollX/scrollY.
   */
  internal fun computeViewToHost(view: View, out: Matrix): Boolean {
    out.reset()
    var current: View = view
    while (current !== this) {
      out.postTranslate(-current.scrollX.toFloat(), -current.scrollY.toFloat())
      val m = current.matrix
      if (!m.isIdentity) {
        out.postConcat(m)
      }
      out.postTranslate(current.left.toFloat(), current.top.toFloat())
      current = current.parent as? View ?: return false
    }
    out.postTranslate(-scrollX.toFloat(), -scrollY.toFloat())
    return true
  }
}
