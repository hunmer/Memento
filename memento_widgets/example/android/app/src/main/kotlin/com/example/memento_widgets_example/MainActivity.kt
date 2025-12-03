package github.hunmer.memento_widgets_example

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.content.Intent

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // 设置对话框主题 - 必须在 super.onCreate() 之前调用
        setTheme(R.style.TimerDialogTheme)

        super.onCreate(savedInstanceState)

        // 设置透明背景
        window.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))

        // 调整窗口参数，使对话框居中显示
        val params = window.attributes
        params.width = WindowManager.LayoutParams.WRAP_CONTENT
        params.height = WindowManager.LayoutParams.WRAP_CONTENT
        params.x = 0
        params.y = 0
        window.attributes = params

        // 处理小组件启动的应用外显示
        if (intent?.action == Intent.ACTION_VIEW) {
            // 小组件点击启动时的处理
            println("MainActivity: 小组件启动，显示计时器对话框")
        }
    }
}
