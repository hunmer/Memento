package com.example.memento_widgets_example

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager
import android.graphics.Color
import android.graphics.drawable.ColorDrawable

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 额外设置透明背景和对话框窗口属性
        window.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        
        // 调整窗口参数，使对话框居中显示
        val params = window.attributes
        params.width = WindowManager.LayoutParams.WRAP_CONTENT
        params.height = WindowManager.LayoutParams.WRAP_CONTENT
        params.x = 0
        params.y = 0
        window.attributes = params
        
        // 设置对话框样式
        setTheme(R.style.TimerDialogTheme)
    }
}
