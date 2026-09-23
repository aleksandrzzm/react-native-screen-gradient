package com.screengradient

import android.content.Context
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path

/**
 * Native view for `<GradientMaskSvg>`: fills / strokes SVG paths with the host gradient.
 *
 * Paths arrive pre-normalized from JS (see src/svg/encodePaths.ts): absolute moveTo / lineTo /
 * cubicTo / close only. They are transformed into view coordinates once per prop or size change;
 * the gradient positioning is inherited from [GradientView].
 */
class GradientMaskSvgView(context: Context) : GradientView(context) {

  private class MaskPath(
    val source: Path,
    val fill: Boolean,
    val stroke: Boolean,
    val strokeWidth: Float,
    val cap: Paint.Cap,
    val join: Paint.Join,
    val miterLimit: Float,
  ) {
    val scaled = Path()
  }

  private var paths: List<MaskPath> = emptyList()
  private var viewBox: FloatArray? = null
  private var scale = 1f
  private val viewBoxMatrix = Matrix()

  init {
    paint.isAntiAlias = true
  }

  fun setPathData(data: FloatArray) {
    paths = decode(data)
    updateScaledPaths()
  }

  fun setViewBox(value: FloatArray?) {
    viewBox = value?.takeIf { it.size == 4 && it[2] > 0f && it[3] > 0f }
    updateScaledPaths()
  }

  override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
    super.onSizeChanged(w, h, oldw, oldh)
    updateScaledPaths()
  }

  /** viewBox → view bounds, SVG default preserveAspectRatio="xMidYMid meet". */
  private fun updateScaledPaths() {
    viewBoxMatrix.reset()
    scale = 1f
    val box = viewBox
    if (box != null && width > 0 && height > 0) {
      scale = minOf(width / box[2], height / box[3])
      viewBoxMatrix.setTranslate(-box[0], -box[1])
      viewBoxMatrix.postScale(scale, scale)
      viewBoxMatrix.postTranslate((width - box[2] * scale) / 2f, (height - box[3] * scale) / 2f)
    }
    for (path in paths) {
      path.source.transform(viewBoxMatrix, path.scaled)
    }
    invalidate()
  }

  override fun drawGradient(canvas: Canvas, paint: Paint) {
    canvas.save()
    canvas.clipRect(0f, 0f, width.toFloat(), height.toFloat())
    for (path in paths) {
      if (path.fill) {
        paint.style = Paint.Style.FILL
        canvas.drawPath(path.scaled, paint)
      }
      if (path.stroke) {
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = path.strokeWidth * scale
        paint.strokeCap = path.cap
        paint.strokeJoin = path.join
        paint.strokeMiter = path.miterLimit
        canvas.drawPath(path.scaled, paint)
      }
    }
    canvas.restore()
  }

  private companion object {
    const val HEADER_LENGTH = 6
    const val FLAG_FILL = 1
    const val FLAG_EVEN_ODD = 2
    const val FLAG_STROKE = 4

    const val MOVE = 0
    const val LINE = 1
    const val CUBIC = 2
    const val CLOSE = 3

    val CAPS = arrayOf(Paint.Cap.BUTT, Paint.Cap.ROUND, Paint.Cap.SQUARE)
    val JOINS = arrayOf(Paint.Join.MITER, Paint.Join.ROUND, Paint.Join.BEVEL)

    fun decode(data: FloatArray): List<MaskPath> {
      val result = ArrayList<MaskPath>()
      var i = 0
      while (i + HEADER_LENGTH <= data.size) {
        val flags = data[i].toInt()
        val strokeWidth = data[i + 1]
        val cap = CAPS.getOrElse(data[i + 2].toInt()) { Paint.Cap.BUTT }
        val join = JOINS.getOrElse(data[i + 3].toInt()) { Paint.Join.MITER }
        val miterLimit = data[i + 4]
        val end = minOf(data.size, i + HEADER_LENGTH + data[i + 5].toInt())
        i += HEADER_LENGTH

        val path = Path()
        path.fillType =
          if (flags and FLAG_EVEN_ODD != 0) Path.FillType.EVEN_ODD else Path.FillType.WINDING
        while (i < end) {
          when (data[i].toInt()) {
            MOVE -> if (i + 3 <= end) { path.moveTo(data[i + 1], data[i + 2]); i += 3 } else i = end
            LINE -> if (i + 3 <= end) { path.lineTo(data[i + 1], data[i + 2]); i += 3 } else i = end
            CUBIC -> if (i + 7 <= end) {
              path.cubicTo(data[i + 1], data[i + 2], data[i + 3], data[i + 4], data[i + 5], data[i + 6])
              i += 7
            } else i = end
            CLOSE -> { path.close(); i += 1 }
            else -> i = end
          }
        }
        i = end
        result.add(
          MaskPath(
            source = path,
            fill = flags and FLAG_FILL != 0,
            stroke = flags and FLAG_STROKE != 0,
            strokeWidth = strokeWidth,
            cap = cap,
            join = join,
            miterLimit = miterLimit,
          )
        )
      }
      return result
    }
  }
}
