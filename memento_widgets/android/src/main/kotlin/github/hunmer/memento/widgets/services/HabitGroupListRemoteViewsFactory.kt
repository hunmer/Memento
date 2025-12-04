package github.hunmer.memento.widgets.services

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import github.hunmer.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import github.hunmer.memento.widgets.providers.HabitGroupListWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.io.InputStream

/**
 * 习惯分组列表的 RemoteViewsFactory
 * 负责创建和管理列表项
 */
class HabitGroupListRemoteViewsFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    companion object {
        private const val TAG = "HabitGroupListFactory"
        private const val PREF_KEY_SELECTED_GROUP = "habit_group_list_selected_group_"
    }

    private var groups: List<GroupItem> = emptyList()
    private var habits: List<HabitItem> = emptyList()
    private val appWidgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )
    private val listType: String = intent.getStringExtra("list_type") ?: "groups"

    data class GroupItem(
        val id: String,
        val name: String,
        val icon: String,
        val isSelected: Boolean = false
    )

    data class HabitItem(
        val id: String,
        val title: String,
        val icon: String?,
        val group: String?
    )

    override fun onCreate() {
        Log.d(TAG, "onCreate: appWidgetId=$appWidgetId, listType=$listType")
    }

    override fun onDataSetChanged() {
        Log.d(TAG, "onDataSetChanged: Loading data for listType=$listType, appWidgetId=$appWidgetId")
        if (listType == "groups") {
            groups = loadGroups()
            Log.d(TAG, "onDataSetChanged: Loaded ${groups.size} groups for widget $appWidgetId")
        } else {
            habits = loadHabits()
            Log.d(TAG, "onDataSetChanged: Loaded ${habits.size} habits for widget $appWidgetId")
        }
    }

    override fun onDestroy() {
        groups = emptyList()
        habits = emptyList()
    }

    override fun getCount(): Int {
        return if (listType == "groups") groups.size else habits.size
    }

    override fun getViewAt(position: Int): RemoteViews {
        return if (listType == "groups") {
            getGroupViewAt(position)
        } else {
            getHabitViewAt(position)
        }
    }

    /**
     * 获取分组项视图
     */
    private fun getGroupViewAt(position: Int): RemoteViews {
        if (position < 0 || position >= groups.size) {
            return RemoteViews(context.packageName, R.layout.widget_habit_group_item)
        }

        val group = groups[position]
        val views = RemoteViews(context.packageName, R.layout.widget_habit_group_item)

        // 设置分组图标 (从Flutter assets加载PNG)
        val iconBitmap = loadIconFromAssets(group.icon)
        if (iconBitmap != null) {
            views.setImageViewBitmap(R.id.group_icon, iconBitmap)
        } else {
            // 如果加载失败，显示默认图标
            views.setImageViewResource(R.id.group_icon, android.R.drawable.ic_menu_gallery)
        }

        // 设置分组名称
        views.setTextViewText(R.id.group_name, group.name)

        // 设置选中状态背景色
        if (group.isSelected) {
            views.setInt(R.id.group_item_container, "setBackgroundColor", 0xFF3A3A5C.toInt())
        } else {
            views.setInt(R.id.group_item_container, "setBackgroundColor", Color.TRANSPARENT)
        }

        // 设置点击 - 填充 Intent
        val fillIntent = Intent().apply {
            putExtra("group_id", group.id)
        }
        views.setOnClickFillInIntent(R.id.group_item_container, fillIntent)

        return views
    }

    /**
     * 获取习惯项视图
     */
    private fun getHabitViewAt(position: Int): RemoteViews {
        if (position < 0 || position >= habits.size) {
            return RemoteViews(context.packageName, R.layout.widget_habit_list_item)
        }

        val habit = habits[position]
        val views = RemoteViews(context.packageName, R.layout.widget_habit_list_item)

        // 设置习惯图标 (从Flutter assets加载PNG)
        val iconName = habit.icon ?: "star"
        val iconBitmap = loadIconFromAssets(iconName)
        if (iconBitmap != null) {
            views.setImageViewBitmap(R.id.habit_icon, iconBitmap)
        } else {
            // 如果加载失败，显示默认图标
            views.setImageViewResource(R.id.habit_icon, android.R.drawable.ic_menu_gallery)
        }

        // 设置习惯名称
        views.setTextViewText(R.id.habit_name, habit.title)

        // 设置习惯项点击 - 打开计时器
        val itemFillIntent = Intent().apply {
            putExtra("action", "open_timer")
            putExtra("habit_id", habit.id)
        }
        views.setOnClickFillInIntent(R.id.habit_item_container, itemFillIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    /**
     * 从 SharedPreferences 加载分组数据
     */
    private fun loadGroups(): List<GroupItem> {
        return try {
            val prefs = context.getSharedPreferences(
                BasePluginWidgetProvider.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            val jsonString = prefs.getString("habit_group_list_widget_data", null)

            if (jsonString.isNullOrEmpty()) {
                Log.w(TAG, "No group data found")
                return emptyList()
            }

            val json = JSONObject(jsonString)
            val groupsArray = json.optJSONArray("groups") ?: return emptyList()

            // 获取当前选中的分组
            val selectedGroupId = prefs.getString("$PREF_KEY_SELECTED_GROUP$appWidgetId", HabitGroupListWidgetProvider.GROUP_ALL)

            val result = mutableListOf<GroupItem>()

            // 添加内置分组：所有、未分组
            result.add(GroupItem(
                id = HabitGroupListWidgetProvider.GROUP_ALL,
                name = "所有",
                icon = "📋",
                isSelected = selectedGroupId == HabitGroupListWidgetProvider.GROUP_ALL
            ))
            result.add(GroupItem(
                id = HabitGroupListWidgetProvider.GROUP_UNGROUPED,
                name = "未分组",
                icon = "📁",
                isSelected = selectedGroupId == HabitGroupListWidgetProvider.GROUP_UNGROUPED
            ))

            // 添加用户定义的分组
            for (i in 0 until groupsArray.length()) {
                val groupJson = groupsArray.getJSONObject(i)
                val groupId = groupJson.optString("id", "")
                result.add(GroupItem(
                    id = groupId,
                    name = groupJson.optString("name", ""),
                    icon = groupJson.optString("icon", "📂"),
                    isSelected = selectedGroupId == groupId
                ))
            }

            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load groups", e)
            emptyList()
        }
    }

    /**
     * 从 SharedPreferences 加载习惯数据
     */
    private fun loadHabits(): List<HabitItem> {
        return try {
            val prefs = context.getSharedPreferences(
                BasePluginWidgetProvider.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            val jsonString = prefs.getString("habit_group_list_widget_data", null)

            if (jsonString.isNullOrEmpty()) {
                Log.w(TAG, "No habit data found")
                return emptyList()
            }

            val json = JSONObject(jsonString)
            val habitsArray = json.optJSONArray("habits") ?: return emptyList()

            // 获取当前选中的分组
            val selectedGroupId = prefs.getString("$PREF_KEY_SELECTED_GROUP$appWidgetId", HabitGroupListWidgetProvider.GROUP_ALL)

            val result = mutableListOf<HabitItem>()

            for (i in 0 until habitsArray.length()) {
                val habitJson = habitsArray.getJSONObject(i)
                val habitGroup = habitJson.optString("group", null)

                // 根据选中的分组过滤习惯
                val shouldInclude = when (selectedGroupId) {
                    HabitGroupListWidgetProvider.GROUP_ALL -> true
                    HabitGroupListWidgetProvider.GROUP_UNGROUPED -> habitGroup.isNullOrEmpty()
                    else -> habitGroup == selectedGroupId
                }

                if (shouldInclude) {
                    result.add(HabitItem(
                        id = habitJson.optString("id", ""),
                        title = habitJson.optString("title", ""),
                        icon = habitJson.optString("icon", null),
                        group = habitGroup
                    ))
                }
            }

            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load habits", e)
            emptyList()
        }
    }

    /**
     * 从Flutter assets加载图标PNG
     * @param iconName 图标名称 (不带.png后缀)
     * @return Bitmap对象，如果加载失败返回null
     */
    private fun loadIconFromAssets(iconName: String): android.graphics.Bitmap? {
        return try {
            // Flutter assets的路径前缀为 flutter_assets/
            val assetPath = "flutter_assets/assets/icons/material/$iconName.png"
            Log.d(TAG, "Loading icon: $assetPath")

            context.assets.open(assetPath).use { inputStream ->
                BitmapFactory.decodeStream(inputStream)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to load icon '$iconName': ${e.message}")
            null
        }
    }
}
