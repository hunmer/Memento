package github.hunmer.memento

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * 动态深度链接处理 Activity
 * 用于接收动态注册的 URL Scheme
 * 收到链接后转发到 MainActivity 处理
 */
class DynamicDeepLinkActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 转发 Intent 到 MainActivity
        val mainIntent = Intent(this, MainActivity::class.java).apply {
            action = intent.action
            data = intent.data
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            // 复制 extras
            intent.extras?.let { putExtras(it) }
        }

        startActivity(mainIntent)
        finish()
    }
}
