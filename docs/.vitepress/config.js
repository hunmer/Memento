import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Memento 使用指南',
  description: 'Memento 个人助手应用使用说明',
  lang: 'zh-CN',
  lastUpdated: true,
  ignoreDeadLinks: true,
  themeConfig: {
    logo: '/icon.png',
    nav: [
      { text: '首页', link: '/' },
      { text: '快速安装', link: '/guide/installation' },
      { text: '插件中心', link: '/plugins' }
    ],
    sidebar: {
      '/guide/': [
        {
          text: '使用指南',
          items: [
            { text: '快速安装', link: '/guide/installation' }
          ]
        }
      ],
      '/plugins/': [
        {
          text: '插件中心',
          items: [
            { text: '插件总览', link: '/plugins' },
            {
              text: '核心插件',
              collapsed: true,
              items: [
                { text: 'Chat 聊天', link: '/plugins/chat' },
                { text: 'OpenAI 助手', link: '/plugins/openai' },
                { text: 'Diary 日记', link: '/plugins/diary' },
                { text: 'Notes 笔记', link: '/plugins/notes' },
                { text: 'Activity 活动', link: '/plugins/activity' }
              ]
            },
            {
              text: '生活管理',
              collapsed: true,
              items: [
                { text: 'Goods 物品', link: '/plugins/goods' },
                { text: 'Bill 账单', link: '/plugins/bill' },
                { text: 'Checkin 签到', link: '/plugins/checkin' }
              ]
            },
            {
              text: '其他插件',
              collapsed: true,
              items: [
                { text: 'Calendar 日历', link: '/plugins/calendar' },
                { text: 'Day 纪念日', link: '/plugins/day' },
                { text: 'Todo 任务', link: '/plugins/todo' },
                { text: 'Tracker 目标追踪', link: '/plugins/tracker' },
                { text: 'Contact 联系人', link: '/plugins/contact' },
                { text: 'Timer 计时器', link: '/plugins/timer' },
                { text: 'Store 物品兑换', link: '/plugins/store' },
                { text: 'Nodes 节点', link: '/plugins/nodes' },
                { text: 'Calendar Album 相册', link: '/plugins/calendar_album' },
                { text: 'Habits 习惯管理', link: '/plugins/habits' },
                { text: 'Database 数据库', link: '/plugins/database' }
              ]
            }
          ]
        }
      ]
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/hunmer/Memento' }
    ],
    editLink: {
      pattern: 'https://github.com/hunmer/Memento/edit/master/docs/:path',
      text: '在 GitHub 上编辑此页'
    },
    docFooter: {
      prev: '上一页',
      next: '下一页'
    },
    outline: {
      label: '页面导航',
      level: 'deep'
    },
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025 Memento'
    },
    search: {
      provider: 'local'
    }
  }
})
