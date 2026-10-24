package co.tryforma.app

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener
import kotlin.math.min

/**
 * Hosts Flutter behind the same launch as iOS: the lit Forma mark on ink
 * from the first frame the app can draw, held until Flutter's own first
 * frame — the identical mark, where the splash animation starts.
 *
 * On iOS the storyboard gives that for free. Android's own splash cannot:
 * before Android 12 it is a window background (no screen-relative sizing),
 * and from 12 on it is a system splash whose icon slot is a small masked
 * circle. So the themes keep the system splash to plain ink (res/values*),
 * and [LaunchMarkView] draws the mark the moment the window draws. On
 * Android 12+ the system then dissolves its ink over the mark with its
 * standard exit; no exit listener is set, because that route hands the
 * splash over through a copy attached to this window, which arrives late
 * and unpredictably and can hide the start of the animation.
 *
 * Two things stand between that view and the screen, and both are handled
 * here. FlutterActivity holds back the window's first draw until Flutter
 * has rendered, which would keep the ink-only system splash up for the
 * whole of Dart's startup: hence FlutterFragmentActivity, whose fragment
 * has a switch for that hold ([createFlutterFragment]). And Android 13+
 * holds a window's first frame until every SurfaceView in it has a buffer,
 * which for Flutter's is again its first frame: hence Flutter's view sits
 * out the first frame ([onStart]).
 */
class MainActivity : FlutterFragmentActivity(), FlutterUiDisplayListener {
    private var launchMark: LaunchMarkView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val mark = LaunchMarkView(this)
        addContentView(mark, ViewGroup.LayoutParams(MATCH_PARENT, MATCH_PARENT))
        launchMark = mark
    }

    override fun createFlutterFragment(): FlutterFragment =
        super.createFlutterFragment().apply {
            // FlutterFragment's own argument for the first-draw hold (the
            // builder's shouldDelayFirstAndroidViewDraw), which the activity
            // switches on for surface rendering. Off, so the window — and
            // the mark — draw before Flutter's first frame.
            arguments?.putBoolean("should_delay_first_android_view_draw", false)
        }

    override fun onStart() {
        super.onStart() // the fragment's FlutterView exists from here on
        val mark = launchMark ?: return
        val flutterView = findViewById<View>(FlutterFragment.FLUTTER_VIEW_ID) ?: return
        // Invisible, Flutter's SurfaceView has no surface yet, so the first
        // frame is the mark alone and goes straight to the screen. Flutter's
        // view comes back right behind it; the mark covers it until Flutter
        // draws. (Still laid out, so Flutter knows its size all along.)
        flutterView.visibility = View.INVISIBLE
        mark.afterFirstDraw = { flutterView.visibility = View.VISIBLE }
    }

    override fun onFlutterUiDisplayed() {
        // Flutter's first frame is the same lit mark in the same place, so
        // the handover is invisible.
        launchMark?.let { (it.parent as? ViewGroup)?.removeView(it) }
        launchMark = null
    }

    override fun onFlutterUiNoLongerDisplayed() {}
}

/**
 * The lit Forma mark on ink: frame 0 of FormaSplash
 * (lib/core/widgets/forma_splash.dart), drawn with the same geometry, the
 * same colours, the storyboard's size rule (53% of the width, capped so the
 * mark's height never passes 24% of the height) and the same centring. Any
 * change to the mark has to land in both.
 */
private class LaunchMarkView(context: Context) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = BLUE }

    /** Runs once, after the frame with this view's first draw is committed. */
    var afterFirstDraw: (() -> Unit)? = null

    init {
        setBackgroundColor(INK)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val markW = min(w * 0.53f, h * 0.24f * BOX_W / BOX_H)
        val markH = markW * BOX_H / BOX_W
        val k = markW / BOX_W

        canvas.save()
        canvas.translate((w - markW) / 2f, (h - markH) / 2f)
        canvas.scale(k, k)
        canvas.clipRect(0f, 0f, BOX_W, BOX_H)
        canvas.drawRect(374f, 175f, 960f, 305f, paint) // the link
        canvas.drawCircle(1118f, 240f, 236.5f, paint) // the lit node
        canvas.drawCircle(234f, 240f, 236.5f, paint) // the mastered disc
        canvas.restore()

        afterFirstDraw?.let { run ->
            afterFirstDraw = null
            post(run)
        }
    }

    private companion object {
        const val INK = 0xFF111016.toInt()
        const val BLUE = 0xFF3C7DFF.toInt()
        const val BOX_W = 1360f
        const val BOX_H = 480f
    }
}
