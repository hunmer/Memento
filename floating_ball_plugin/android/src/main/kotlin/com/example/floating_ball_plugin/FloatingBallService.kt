package com.example.floating_ball_plugin

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.Toast
import androidx.core.content.ContextCompat

class FloatingBallService : Service() {

    companion object {
        var isRunning = false
    }

    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View
    private var params: WindowManager.LayoutParams? = null
    private var screenWidth: Int = 0
    private var screenHeight: Int = 0
    private var isExpanded = false
    private val expandedButtons = mutableListOf<View>()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        // 获取屏幕尺寸
        val displayMetrics = resources.displayMetrics
        screenWidth = displayMetrics.widthPixels
        screenHeight = displayMetrics.heightPixels

        // 创建悬浮球视图（假设使用一个 ImageView，您可以替换为自定义布局）
        floatingView = ImageView(this).apply {
            setImageDrawable(ContextCompat.getDrawable(this@FloatingBallService, android.R.drawable.ic_menu_add)) // 替换为您的图标
            setOnTouchListener(touchListener)
        }

        // 悬浮球参数
        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = screenWidth - 100 // 初始位置：右侧中间
            y = screenHeight / 2
        }

        windowManager.addView(floatingView, params)
    }

    private val touchListener = View.OnTouchListener { v, event ->
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                initialX = params!!.x
                initialY = params!!.y
                initialTouchX = event.rawX
                initialTouchY = event.rawY
            }
            MotionEvent.ACTION_MOVE -> {
                params!!.x = initialX + (event.rawX - initialTouchX).toInt()
                params!!.y = initialY + (event.rawY - initialTouchY).toInt()
                windowManager.updateViewLayout(floatingView, params)
            }
            MotionEvent.ACTION_UP -> {
                // 自动吸附侧边
                val mid = screenWidth / 2
                val targetX = if (params!!.x < mid) 0 else screenWidth - floatingView.width
                params!!.x = targetX
                windowManager.updateViewLayout(floatingView, params)

                // 判断是否为点击（移动距离小）
                if (Math.abs(event.rawX - initialTouchX) < 10 && Math.abs(event.rawY - initialTouchY) < 10) {
                    toggleExpand()
                }
            }
        }
        true
    }

    private var initialX: Int = 0
    private var initialY: Int = 0
    private var initialTouchX: Float = 0f
    private var initialTouchY: Float = 0f

    // 展开/关闭多个按钮
    private fun toggleExpand() {
        if (isExpanded) {
            closeExpandedButtons()
        } else {
            showExpandedButtons()
        }
        isExpanded = !isExpanded
    }

    // 根据位置展示多个按钮
    private fun showExpandedButtons() {
        val ballX = params!!.x
        val ballY = params!!.y
        val buttonSize = 100 // 子按钮大小（dp），可调整
        val direction = if (ballX == 0) 1 else -1 // 左侧向右展开（1），右侧向左展开（-1）

        // 创建 3 个子按钮
        for (i in 1..3) {
            val buttonView = ImageView(this).apply {
                setImageDrawable(ContextCompat.getDrawable(this@FloatingBallService, android.R.drawable.ic_menu_info_details)) // 替换图标
                setOnClickListener {
                    Toast.makeText(this@FloatingBallService, "按钮 $i 被点击", Toast.LENGTH_SHORT).show()
                    toggleExpand() // 点击后关闭
                }
            }

            val buttonParams = WindowManager.LayoutParams(
                buttonSize,
                buttonSize,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = ballX + direction * i * buttonSize // 根据方向计算位置
                y = ballY
            }

            windowManager.addView(buttonView, buttonParams)
            expandedButtons.add(buttonView)
        }
    }

    private fun closeExpandedButtons() {
        expandedButtons.forEach { windowManager.removeView(it) }
        expandedButtons.clear()
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        if (floatingView.isAttachedToWindow) {
            windowManager.removeView(floatingView)
        }
        closeExpandedButtons()
    }
}
