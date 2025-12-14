/**
 * PureRead WebView 卡片预加载脚本
 *
 * 此文件在 QuickJS 引擎中执行，而非在 WebView 页面中
 * 通过调用 memento.registerTool() 注册特定于 PureRead 的自定义 JavaScript 工具
 * 注册的工具可以被 Agent Chat 直接调用，无需打开 WebView 页面
 *
 * 注意：Dart 端会在执行此脚本前验证 memento.registerTool 已存在
 * 因此无需在此脚本中轮询等待
 */

// 工具注册函数
function registerTools() {
  console.log('[Preload] 开始注册 PureRead 工具...');

  // ==================== 书籍管理工具 ====================

  // 注册保存书籍工具
  memento.registerTool({
    id: 'book_save',
    name: '保存书籍',
    description: '将新书籍保存到 PureRead 存储',
    parameters: [
      {
        name: 'title',
        type: 'string',
        optional: false,
        description: '书籍标题'
      },
      {
        name: 'author',
        type: 'string',
        optional: false,
        description: '作者名称'
      },
      {
        name: 'totalPages',
        type: 'number',
        optional: false,
        description: '总页数'
      },
      {
        name: 'genres',
        type: 'string',
        optional: true,
        description: '类型标签，多个用逗号分隔（如：Fiction,Sci-Fi）'
      },
      {
        name: 'description',
        type: 'string',
        optional: true,
        description: '书籍描述'
      },
      {
        name: 'status',
        type: 'string',
        optional: true,
        description: '阅读状态：TO_READ, READING, FINISHED, PAUSED（默认：TO_READ）'
      },
      {
        name: 'coverImage',
        type: 'string',
        optional: true,
        description: '封面图片 Base64 或 URL'
      }
    ],
    examples: [
      {
        code: `const result = await memento.tools.book_save({
  title: '三体',
  author: '刘慈欣',
  totalPages: 302,
  genres: 'Sci-Fi,Fiction',
  description: '地球往事三部曲第一部',
  status: 'READING'
});
setResult(result);`,
        comment: '保存新书籍《三体》'
      },
      {
        code: `const result = await memento.tools.book_save({
  title: 'Clean Code',
  author: 'Robert C. Martin',
  totalPages: 464,
  genres: 'Tech,Non-Fiction'
});
setResult(result);`,
        comment: '添加技术书籍'
      }
    ],
    code: `
      // 读取现有卡片数据
      const cardData = await memento.storage.readCardData('pureread');
      const data = cardData || { books: [], updatedAt: new Date().toISOString() };

      // 生成唯一 ID
      const id = String(Date.now());
      const now = new Date().toISOString();

      // 处理类型标签
      const genres = params.genres ? params.genres.split(',').map(g => g.trim()) : [];

      // 添加新书籍
      data.books.push({
        id: id,
        title: params.title,
        author: params.author,
        totalPages: params.totalPages,
        genres: genres,
        description: params.description || '',
        status: params.status || 'TO_READ',
        coverImage: params.coverImage || '',
        createdDate: now,
        logs: [],
        isArchived: false
      });
      data.updatedAt = now;

      // 保存回文件
      await memento.storage.writeCardData('pureread', data);

      return {
        success: true,
        id: id,
        bookCount: data.books.length,
        message: '书籍保存成功'
      };
    `,
    cardId: 'pureread'
  });

  // 注册列出书籍工具
  memento.registerTool({
    id: 'book_list',
    name: '列出书籍',
    description: '获取所有保存的书籍',
    parameters: [
      {
        name: 'status',
        type: 'string',
        optional: true,
        description: '按状态筛选：TO_READ, READING, FINISHED, PAUSED'
      },
      {
        name: 'includeArchived',
        type: 'boolean',
        optional: true,
        description: '是否包含已归档的书籍（默认：false）'
      }
    ],
    examples: [
      {
        code: `const result = await memento.tools.book_list();
setResult(result);`,
        comment: '获取所有书籍'
      },
      {
        code: `const result = await memento.tools.book_list({ status: 'READING' });
setResult('正在阅读的书籍数: ' + result.books.length);`,
        comment: '获取正在阅读的书籍'
      },
      {
        code: `const result = await memento.tools.book_list({ includeArchived: true });
setResult(result);`,
        comment: '获取包括已归档的所有书籍'
      }
    ],
    code: `
      // 从文件读取卡片数据
      const cardData = await memento.storage.readCardData('pureread');

      if (!cardData || !cardData.books) {
        return {
          success: true,
          books: [],
          total: 0
        };
      }

      let books = cardData.books;

      // 默认不包含已归档的书籍
      if (!params.includeArchived) {
        books = books.filter(b => !b.isArchived);
      }

      // 如果指定了状态，进行筛选
      if (params.status) {
        books = books.filter(b => b.status === params.status);
      }

      return {
        success: true,
        books: books,
        total: books.length
      };
    `,
    cardId: 'pureread'
  });

  // 注册搜索书籍工具
  memento.registerTool({
    id: 'book_search',
    name: '搜索书籍',
    description: '根据标题、作者或类型搜索书籍',
    parameters: [
      {
        name: 'query',
        type: 'string',
        optional: false,
        description: '搜索关键词'
      }
    ],
    examples: [
      {
        code: `const result = await memento.tools.book_search({ query: '三体' });
setResult(result);`,
        comment: '搜索包含 "三体" 的书籍'
      },
      {
        code: `const result = await memento.tools.book_search({ query: 'Martin' });
setResult(result);`,
        comment: '搜索作者名包含 "Martin" 的书籍'
      }
    ],
    code: `
      // 从文件读取卡片数据
      const cardData = await memento.storage.readCardData('pureread');

      if (!cardData || !cardData.books) {
        return { success: true, books: [], total: 0 };
      }

      const query = (params.query || '').toLowerCase();

      const filtered = cardData.books.filter(b =>
        !b.isArchived && (
          (b.title && b.title.toLowerCase().includes(query)) ||
          (b.author && b.author.toLowerCase().includes(query)) ||
          (b.description && b.description.toLowerCase().includes(query)) ||
          (b.genres && b.genres.some(g => g.toLowerCase().includes(query)))
        )
      );

      return {
        success: true,
        books: filtered,
        total: filtered.length
      };
    `,
    cardId: 'pureread'
  });

  // 注册更新书籍工具
  memento.registerTool({
    id: 'book_update',
    name: '更新书籍',
    description: '更新现有书籍的信息',
    parameters: [
      {
        name: 'id',
        type: 'string',
        optional: false,
        description: '书籍 ID'
      },
      {
        name: 'title',
        type: 'string',
        optional: true,
        description: '书籍标题'
      },
      {
        name: 'author',
        type: 'string',
        optional: true,
        description: '作者名称'
      },
      {
        name: 'totalPages',
        type: 'number',
        optional: true,
        description: '总页数'
      },
      {
        name: 'genres',
        type: 'string',
        optional: true,
        description: '类型标签，多个用逗号分隔'
      },
      {
        name: 'description',
        type: 'string',
        optional: true,
        description: '书籍描述'
      },
      {
        name: 'status',
        type: 'string',
        optional: true,
        description: '阅读状态'
      },
      {
        name: 'isArchived',
        type: 'boolean',
        optional: true,
        description: '是否归档'
      }
    ],
    examples: [
      {
        code: `const result = await memento.tools.book_update({
  id: '1234567890',
  status: 'FINISHED'
});
setResult(result);`,
        comment: '将书籍标记为已完成'
      }
    ],
    code: `
      const cardData = await memento.storage.readCardData('pureread');

      if (!cardData || !cardData.books) {
        return { success: false, message: '数据不存在' };
      }

      const bookIndex = cardData.books.findIndex(b => b.id === params.id);
      if (bookIndex === -1) {
        return { success: false, message: '书籍不存在' };
      }

      const book = cardData.books[bookIndex];

      // 更新字段
      if (params.title !== undefined) book.title = params.title;
      if (params.author !== undefined) book.author = params.author;
      if (params.totalPages !== undefined) book.totalPages = params.totalPages;
      if (params.genres !== undefined) {
        book.genres = params.genres.split(',').map(g => g.trim());
      }
      if (params.description !== undefined) book.description = params.description;
      if (params.status !== undefined) book.status = params.status;
      if (params.isArchived !== undefined) book.isArchived = params.isArchived;

      cardData.updatedAt = new Date().toISOString();

      await memento.storage.writeCardData('pureread', cardData);

      return {
        success: true,
        message: '书籍更新成功',
        book: book
      };
    `,
    cardId: 'pureread'
  });

  // 注册删除书籍工具
  memento.registerTool({
    id: 'book_delete',
    name: '删除书籍',
    description: '从 PureRead 中删除书籍',
    parameters: [
      {
        name: 'id',
        type: 'string',
        optional: false,
        description: '书籍 ID'
      }
    ],
    examples: [
      {
        code: `const result = await memento.tools.book_delete({ id: '1234567890' });
setResult(result);`,
        comment: '删除指定书籍'
      }
    ],
    code: `
      const cardData = await memento.storage.readCardData('pureread');

      if (!cardData || !cardData.books) {
        return { success: false, message: '数据不存在' };
      }

      const bookIndex = cardData.books.findIndex(b => b.id === params.id);
      if (bookIndex === -1) {
        return { success: false, message: '书籍不存在' };
      }

      cardData.books.splice(bookIndex, 1);
      cardData.updatedAt = new Date().toISOString();

      await memento.storage.writeCardData('pureread', cardData);

      return {
        success: true,
        message: '书籍删除成功',
        remainingCount: cardData.books.length
      };
    `,
    cardId: 'pureread'
  });

  // ==================== 阅读记录管理工具 ====================

  // 注册添加阅读记录工具
  memento.registerTool({
    id: 'log_add',
    name: '添加阅读记录',
    description: '为书籍添加新的阅读记录',
    parameters: [
      {
        name: 'bookId',
        type: 'string',
        optional: false,
        description: '书籍 ID'
      },
      {
        name: 'pagesRead',
        type: 'number',
        optional: false,
        description: '本次阅读的页数'
      },
      {
        name: 'note',
        type: 'string',
        optional: true,
        description: '阅读笔记'
      },
      {
        name: 'date',
        type: 'string',
        optional: true,
        description: '阅读日期（ISO 格式，默认为当前时间）'
      }
    ],
    examples: [
      {
        code: `const result = await memento.tools.log_add({
  bookId: '1234567890',
  pagesRead: 50,
  note: '今天读到了三体人回应地球信号的部分，非常震撼！'
});
setResult(result);`,
        comment: '添加阅读记录'
      }
    ],
    code: `
      const cardData = await memento.storage.readCardData('pureread');

      if (!cardData || !cardData.books) {
        return { success: false, message: '数据不存在' };
      }

      const book = cardData.books.find(b => b.id === params.bookId);
      if (!book) {
        return { success: false, message: '书籍不存在' };
      }

      const logId = String(Date.now());
      const now = params.date || new Date().toISOString();

      const log = {
        id: logId,
        date: now,
        pagesRead: params.pagesRead,
        note: params.note || ''
      };

      if (!book.logs) {
        book.logs = [];
      }
      book.logs.push(log);

      cardData.updatedAt = new Date().toISOString();

      await memento.storage.writeCardData('pureread', cardData);

      // 计算总阅读页数
      const totalRead = book.logs.reduce((sum, l) => sum + l.pagesRead, 0);

      return {
        success: true,
        message: '阅读记录添加成功',
        logId: logId,
        totalLogsCount: book.logs.length,
        totalPagesRead: totalRead,
        progress: ((totalRead / book.totalPages) * 100).toFixed(2) + '%'
      };
    `,
    cardId: 'pureread'
  });

  // 注册列出阅读记录工具
  memento.registerTool({
    id: 'log_list',
    name: '列出阅读记录',
    description: '获取指定书籍的所有阅读记录',
    parameters: [
      {
        name: 'bookId',
        type: 'string',
        optional: false,
        description: '书籍 ID'
      }
    ],
    examples: [
      {
        code: `const result = await memento.tools.log_list({ bookId: '1234567890' });
setResult(result);`,
        comment: '获取书籍的所有阅读记录'
      }
    ],
    code: `
      const cardData = await memento.storage.readCardData('pureread');

      if (!cardData || !cardData.books) {
        return { success: false, message: '数据不存在' };
      }

      const book = cardData.books.find(b => b.id === params.bookId);
      if (!book) {
        return { success: false, message: '书籍不存在' };
      }

      const logs = book.logs || [];
      const totalRead = logs.reduce((sum, l) => sum + l.pagesRead, 0);

      return {
        success: true,
        logs: logs,
        totalLogsCount: logs.length,
        totalPagesRead: totalRead,
        progress: ((totalRead / book.totalPages) * 100).toFixed(2) + '%'
      };
    `,
    cardId: 'pureread'
  });

  // 注册删除阅读记录工具
  memento.registerTool({
    id: 'log_delete',
    name: '删除阅读记录',
    description: '删除指定的阅读记录',
    parameters: [
      {
        name: 'bookId',
        type: 'string',
        optional: false,
        description: '书籍 ID'
      },
      {
        name: 'logId',
        type: 'string',
        optional: false,
        description: '阅读记录 ID'
      }
    ],
    examples: [
      {
        code: `const result = await memento.tools.log_delete({
  bookId: '1234567890',
  logId: '9876543210'
});
setResult(result);`,
        comment: '删除指定的阅读记录'
      }
    ],
    code: `
      const cardData = await memento.storage.readCardData('pureread');

      if (!cardData || !cardData.books) {
        return { success: false, message: '数据不存在' };
      }

      const book = cardData.books.find(b => b.id === params.bookId);
      if (!book) {
        return { success: false, message: '书籍不存在' };
      }

      if (!book.logs) {
        return { success: false, message: '没有阅读记录' };
      }

      const logIndex = book.logs.findIndex(l => l.id === params.logId);
      if (logIndex === -1) {
        return { success: false, message: '阅读记录不存在' };
      }

      book.logs.splice(logIndex, 1);
      cardData.updatedAt = new Date().toISOString();

      await memento.storage.writeCardData('pureread', cardData);

      return {
        success: true,
        message: '阅读记录删除成功',
        remainingLogsCount: book.logs.length
      };
    `,
    cardId: 'pureread'
  });

  console.log('[Preload] ✓ PureRead 工具注册完成');
  return true;
}

// 直接执行工具注册（Dart 端已确保 memento.registerTool 存在）
(function() {
  try {
    console.log('[Preload] 开始执行工具注册...');
    if (registerTools()) {
      console.log('[Preload] ✓ 所有工具注册成功');
    } else {
      console.log('[Preload] ✗ 工具注册失败');
    }
  } catch (error) {
    console.error('[Preload] 工具注册过程出错:', error.message);
  }
})();
