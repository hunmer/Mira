import { LibraryServerDataSQLite } from '../LibraryServerDataSQLite';
import { WebSocket } from 'ws';
import { WebSocketMessage } from '../WebSocketRouter';

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