package com.example.floating_ball_plugin

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.Toast
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel

class FloatingBallService : Service() {

    companion object {
        var isRunning = false
        private var positionSink: EventChannel.EventSink? = null
        private var buttonSink: EventChannel.EventSink? = null
        @Volatile
        private var instance: FloatingBallService? = null

        fun setPositionSink(sink: EventChannel.EventSink?) {
            positionSink = sink
        }

        fun setButtonSink(sink: EventChannel.EventSink?) {
            buttonSink = sink
        }

        fun sendPosition(x: Int, y: Int) {
            positionSink?.success(mapOf("x" to x, "y" to y))
        }

        /// 更新配置（静态方法，供插件主类调用）
        fun updateConfig(config: HashMap<String, Any>) {
            instance?.updateConfigInternal(config)
        }

        /// 从字节数据更新图片（静态方法，供插件主类调用）
        fun updateImageFromBytes(imageBytes: ByteArray) {
            instance?.updateImageInternal(imageBytes)
        }
    }

    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View
    private var params: WindowManager.LayoutParams? = null
    private var screenWidth: Int = 0
    private var screenHeight: Int = 0
    private var isExpanded = false
    private val expandedButtons = mutableListOf<View>()

    // 配置参数
    private var iconName: String? = null
    private var ballSize: Int = 100
    private var startX: Int = 0
    private var startY: Int = 0
    private var snapThreshold: Int = 50
    private var buttonData: List<Map<String, Any>>? = null // 按钮数据数组
    private var customImageBytes: ByteArray? = null // 持久化存储自定义图片

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        isRunning = true
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        // 获取屏幕尺寸
        val displayMetrics = resources.displayMetrics
        screenWidth = displayMetrics.widthPixels
        screenHeight = displayMetrics.heightPixels
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        isRunning = false
        if (::floatingView.isInitialized && floatingView.isAttachedToWindow) {
            windowManager.removeView(floatingView)
        }
        closeExpandedButtons()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            val config = it.getSerializableExtra("config") as? HashMap<String, Any>
            config?.let { cfg ->
                iconName = cfg["iconName"] as? String
                ballSize = (cfg["size"] as? Double)?.toInt() ?: 100
                startX = (cfg["startX"] as? Double)?.toInt() ?: (screenWidth - ballSize)
                startY = (cfg["startY"] as? Double)?.toInt() ?: (screenHeight / 2)
                snapThreshold = (cfg["snapThreshold"] as? Double)?.toInt() ?: 50
                // 获取按钮数据数组
                buttonData = cfg["buttonData"] as? List<Map<String, Any>>
            }
        }

        // 只有在视图未初始化时才创建
        if (!::floatingView.isInitialized) {
            initFloatingView()
        }
        return START_STICKY
    }

    private fun initFloatingView() {
        // 创建悬浮球视图
        floatingView = ImageView(this).apply {
            // 优先使用自定义图片
            customImageBytes?.let { bytes ->
                try {
                    val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                    if (bitmap != null) {
                        setImageBitmap(bitmap)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    // 还原到默认图标
                    setDefaultIcon()
                }
            } ?: run {
                // 没有自定义图片，使用默认图标
                setDefaultIcon()
            }
            setOnTouchListener(touchListener)
        }

        // 悬浮球参数
        params = WindowManager.LayoutParams(
            ballSize,
            ballSize,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = startX
            y = startY
        }

        windowManager.addView(floatingView, params)
    }

    /// 设置默认图标
    private fun ImageView.setDefaultIcon() {
        val iconResId = iconName?.let { name ->
            resources.getIdentifier(name, "drawable", packageName)
        } ?: android.R.drawable.ic_menu_add
        setImageDrawable(ContextCompat.getDrawable(this@FloatingBallService, iconResId))
    }

    private var initialX: Int = 0
    private var initialY: Int = 0
    private var initialTouchX: Float = 0f
    private var initialTouchY: Float = 0f
    private var hasMoved = false // 标记是否发生移动

    private val touchListener = View.OnTouchListener { v, event ->
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                initialX = params!!.x
                initialY = params!!.y
                initialTouchX = event.rawX
                initialTouchY = event.rawY
                hasMoved = false
            }
            MotionEvent.ACTION_MOVE -> {
                params!!.x = initialX + (event.rawX - initialTouchX).toInt()
                params!!.y = initialY + (event.rawY - initialTouchY).toInt()
                windowManager.updateViewLayout(floatingView, params)

                // 发送位置更新
                sendPosition(params!!.x, params!!.y)

                // 检查是否发生了实质性移动
                val deltaX = event.rawX - initialTouchX
                val deltaY = event.rawY - initialTouchY
                val distance = Math.sqrt((deltaX * deltaX + deltaY * deltaY).toDouble())

                if (distance > 10 && !hasMoved) {
                    hasMoved = true
                    // 如果正在展开，移动时关闭展开
                    if (isExpanded) {
                        closeExpandedButtons()
                        isExpanded = false
                    }
                }
            }
            MotionEvent.ACTION_UP -> {
                // 检查是否需要自动吸附
                checkAndSnapToEdge()

                // 判断是否为点击（移动距离小且之前没有移动）
                if (!hasMoved && Math.abs(event.rawX - initialTouchX) < 10 && Math.abs(event.rawY - initialTouchY) < 10) {
                    toggleExpand()
                }
                hasMoved = false
            }
        }
        true
    }

    /// 检查是否需要吸附到边缘
    private fun checkAndSnapToEdge() {
        val leftDistance = params!!.x
        val rightDistance = screenWidth - params!!.x - ballSize

        // 检查是否靠近左边缘
        if (leftDistance <= snapThreshold) {
            params!!.x = 0
            windowManager.updateViewLayout(floatingView, params)
            sendPosition(params!!.x, params!!.y)
            return
        }

        // 检查是否靠近右边缘
        if (rightDistance <= snapThreshold) {
            params!!.x = screenWidth - ballSize
            windowManager.updateViewLayout(floatingView, params)
            sendPosition(params!!.x, params!!.y)
        }
    }

    // 展开/关闭多个按钮
    private fun toggleExpand() {
        if (isExpanded) {
            closeExpandedButtons()
        } else {
            showExpandedButtons()
        }
        isExpanded = !isExpanded
    }

    // 根据位置和可用空间展示多个按钮（圆形布局）
    private fun showExpandedButtons() {
        val ballX = params!!.x
        val ballY = params!!.y

        // 计算可用空间
        val availableLeft = ballX
        val availableRight = screenWidth - ballX - ballSize
        val availableTop = ballY
        val availableBottom = screenHeight - ballY - ballSize

        // 菜单参数
        val menuRadius = 200  // 菜单半径
        val buttonSize = ballSize

        // 决定布局：全圆或半圆
        var startAngle = 0f
        var endAngle = 360f
        var isHalfCircle = false

        val spaceThreshold = menuRadius - 20  // 边缘阈值

        when {
            availableLeft < spaceThreshold -> {
                // 左边缘：向右半圆
                startAngle = 270f
                endAngle = 90f
                isHalfCircle = true
            }
            availableRight < spaceThreshold -> {
                // 右边缘：向左半圆
                startAngle = 90f
                endAngle = 270f
                isHalfCircle = true
            }
            availableTop < spaceThreshold -> {
                // 上边缘：向下半圆
                startAngle = 180f
                endAngle = 360f
                isHalfCircle = true
            }
            availableBottom < spaceThreshold -> {
                // 下边缘：向上半圆
                startAngle = 0f
                endAngle = 180f
                isHalfCircle = true
            }
        }

        // 调整半径如果空间不足
        var adjustedRadius = menuRadius
        val minSpace = listOf(availableLeft, availableRight, availableTop, availableBottom).min() - 20
        if (minSpace < menuRadius && minSpace > 0) {
            adjustedRadius = minSpace.toInt()
        }

        // 获取按钮数组，如果没有则使用默认按钮
        val buttons = buttonData ?: listOf(
            mapOf("title" to "按钮1", "icon" to "ic_menu_info_details"),
            mapOf("title" to "按钮2", "icon" to "ic_menu_info_details"),
            mapOf("title" to "按钮3", "icon" to "ic_menu_info_details")
        )

        val buttonCount = buttons.size

        // 计算角度
        val angleStep = if (isHalfCircle) {
            (endAngle - startAngle) / buttonCount
        } else {
            360f / buttonCount
        }

        // 创建圆形布局的按钮
        buttons.forEachIndexed { index, button ->
            val angle = startAngle + (index * angleStep)
            val radians = Math.toRadians(angle.toDouble())

            // 计算按钮位置
            val buttonX = ballX + (adjustedRadius * Math.cos(radians)).toInt()
            val buttonY = ballY + (adjustedRadius * Math.sin(radians)).toInt()

            // 获取按钮图标和标题
            val buttonIcon = button["icon"] as? String ?: "ic_menu_info_details"
            val buttonTitle = button["title"] as? String ?: "按钮${index + 1}"
            val buttonData = button["data"] as? Map<String, Any>

            // 从资源中获取图标
            val iconResId = resources.getIdentifier(buttonIcon, "drawable", packageName)

            val buttonView = ImageView(this).apply {
                setImageDrawable(
                    ContextCompat.getDrawable(
                        this@FloatingBallService,
                        if (iconResId != 0) iconResId else android.R.drawable.ic_menu_info_details
                    )
                )
                setOnClickListener {
                    // 通过EventChannel回传按钮点击事件
                    val event = hashMapOf<String, Any>(
                        "index" to index,
                        "title" to buttonTitle,
                        "data" to (buttonData ?: hashMapOf<String, Any>())
                    )
                    buttonSink?.success(event)
                    toggleExpand()
                }
                // 设置内容描述（无障碍）
                contentDescription = buttonTitle
            }

            val buttonParams = WindowManager.LayoutParams(
                buttonSize,
                buttonSize,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = buttonX
                y = buttonY
            }

            windowManager.addView(buttonView, buttonParams)
            expandedButtons.add(buttonView)
        }
    }

    private fun closeExpandedButtons() {
        expandedButtons.forEach { windowManager.removeView(it) }
        expandedButtons.clear()
    }

    /// 内部配置更新方法
    private fun updateConfigInternal(config: HashMap<String, Any>) {
        if (!::floatingView.isInitialized || !floatingView.isAttachedToWindow) {
            return
        }

        var needsButtonRecreation = false

        // 更新配置参数
        config["size"]?.let {
            val newSize = (it as? Double)?.toInt() ?: ballSize
            if (newSize != ballSize) {
                ballSize = newSize
                // 更新窗口大小
                params?.let { p ->
                    p.width = ballSize
                    p.height = ballSize
                    windowManager.updateViewLayout(floatingView, p)
                }
            }
        }

        config["snapThreshold"]?.let {
            snapThreshold = (it as? Double)?.toInt() ?: snapThreshold
        }

        // 更新图标
        config["iconName"]?.let { newIconName ->
            val iconNameStr = newIconName as? String
            if (iconNameStr != null && iconNameStr != iconName) {
                iconName = iconNameStr
                val iconResId = iconName?.let { name ->
                    resources.getIdentifier(name, "drawable", packageName)
                } ?: android.R.drawable.ic_menu_add

                (floatingView as? ImageView)?.setImageDrawable(
                    ContextCompat.getDrawable(this, iconResId)
                )
            }
        }

        // 更新按钮数据
        config["buttonData"]?.let { newButtonData ->
            val buttons = newButtonData as? List<Map<String, Any>>
            if (buttons != null && buttons != buttonData) {
                buttonData = buttons
                needsButtonRecreation = true
            }
        }

        // 如果按钮数据改变了，重新创建按钮
        if (needsButtonRecreation) {
            // 关闭现有按钮
            closeExpandedButtons()
            // 如果之前是展开状态，重新展开
            if (isExpanded) {
                showExpandedButtons()
            }
        }
    }

    /// 内部图片更新方法
    private fun updateImageInternal(imageBytes: ByteArray) {
        // 保存图片数据以供重启后恢复
        customImageBytes = imageBytes

        if (!::floatingView.isInitialized || !floatingView.isAttachedToWindow) {
            return
        }

        try {
            // 将字节数据转换为 Bitmap
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            if (bitmap != null) {
                // 设置到 ImageView
                (floatingView as? ImageView)?.setImageBitmap(bitmap)
                // 更新窗口布局
                params?.let { p ->
                    windowManager.updateViewLayout(floatingView, p)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
