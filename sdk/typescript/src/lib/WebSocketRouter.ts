import { LibraryServerDataSQLite } from './LibraryServerDataSQLite';
import { WebSocket } from 'ws';
import { MessageHandler } from './handlers/MessageHandler';
import { FileHandler } from './handlers/FileHandler';
import { TagHandler } from './handlers/TagHandler';
import { FolderHandler } from './handlers/FolderHandler';
import { LibraryHandler } from './handlers/LibraryHandler';

export interface WebSocketMessage {
  action: string;
  requestId: string;
  libraryId: string;
  payload: {
    type: string;
    data: Record<string, any>;
  };
}

export class WebSocketRouter {
  static async route(
    dbService: LibraryServerDataSQLite,
    ws: WebSocket,
    message: WebSocketMessage
  ): Promise<MessageHandler | null> {
    const { payload } = message;

    // 根据资源类型路由到不同的处理器
    switch (payload.type) {
      case 'file':
        return new FileHandler(dbService, ws, message);
      case 'tag':
        return new TagHandler(dbService, ws, message);
      case 'folder':
        return new FolderHandler(dbService, ws, message);
      case 'library':
        return new LibraryHandler(dbService, ws, message);
      default:
        return null;
    }
  }
}