import { WebSocketServer } from './WebSocketServer';
import { HttpRouter } from './HttpRouter';
import express from 'express';
import http from 'http';
import { LibraryServerDataSQLite } from './LibraryServerDataSQLite';

// 创建Express应用
const app = express();
app.use(express.json());

// 创建HTTP路由
const httpRouter = new HttpRouter();
app.use('/api', httpRouter.getRouter());

// 创建HTTP服务器
const server = http.createServer(app);

// 创建WebSocket服务器
const wsServer = new WebSocketServer(8080);
wsServer.start('/ws');

// 启动HTTP服务器
const PORT = 3000;
server.listen(PORT, () => {
  console.log(`HTTP server running on port ${PORT}`);
});

// 示例：加载库
async function exampleUsage() {
  const dbConfig = {
    // 数据库配置
    path: './data/library.db',
    // 其他配置项...
  };

  try {
    const dbService = await wsServer.loadLibrary(dbConfig);
    console.log(`Library loaded: ${dbService.getLibraryId()}`);
  } catch (err) {
    console.error('Failed to load library:', err);
  }
}

// 处理退出
process.on('SIGINT', async () => {
  console.log('Shutting down servers...');
  await wsServer.stop();
  await httpRouter.close();
  server.close();
  process.exit();
});