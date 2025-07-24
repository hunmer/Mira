import { LibraryServerDataSQLite } from './LibraryServerDataSQLite';
import { WebSocket } from 'ws';
import { QueryHandler } from './handlers/QueryHandler';
import { CreateHandler } from './handlers/CreateHandler';
import { UpdateHandler } from './handlers/UpdateHandler';
import { DeleteHandler } from './handlers/DeleteHandler';

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
    const { action } = message;

    // 根据action路由到不同的处理器
    switch (action) {
      case 'query':
        return new QueryHandler(dbService, ws, message);
      case 'update':
        return new UpdateHandler(dbService, ws, message);
      case 'delete':
        return new DeleteHandler(dbService, ws, message);
      case 'create':
        return new CreateHandler(dbService, ws, message);
      default:
        return null;
    }
  }
}

export abstract class MessageHandler {
  constructor(
    protected dbService: LibraryServerDataSQLite,
    protected ws: WebSocket,
    protected message: WebSocketMessage
  ) {}

  abstract handle(): Promise<void>;

  protected sendResponse(data: Record<string, any>): void {
    this.ws.send(JSON.stringify({
      ...this.message,
      payload: {
        ...this.message.payload,
        data
      }
    }));
  }

  protected sendError(error: string): void {
    this.ws.send(JSON.stringify({
      ...this.message,
      status: 'error',
      error
    }));
  }
}