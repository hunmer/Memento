直接写顶层 await 代码，不要再套 IIFE：
const result = await Memento.chat.testSync();
setResult(result);

如果确实要封装函数，记得把 Promise 传递给外层：
async function run() {
  const result = await Memento.chat.testSync();
  setResult(result);
}
await run();      // 或 `return run();`

任何新建的 async IIFE 都必须 await：
await (async () => {
  const result = await Memento.chat.testSync();
  setResult(result);
})();

只要最外层始终在等待最后一个 Promise，setResult 就会在调用完成后才被清理，自然不会再出现未定义错误。