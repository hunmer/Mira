import { LibraryServerDataSQLite } from '../LibraryServerDataSQLite';
import { WebSocket } from 'ws';
import { WebSocketMessage } from '../WebSocketRouter';
import { response } from 'express';

export abstract class MessageHandler {
  constructor(
    protected dbService: LibraryServerDataSQLite,
    protected ws: WebSocket,
    protected message: WebSocketMessage
  ) {}

  abstract handle(): Promise<void>;

  protected sendResponse(data: Record<string, any>): void {
    const response = JSON.stringify({
      ...this.message,
      payload: {
        ...this.message.payload,
        data
      }
    })
    console.log({response});
    this.ws.send(response);
  }

  protected sendError(error: string): void {
    const response = JSON.stringify({
      ...this.message,
      status: 'error',
      error
    });
    console.log({response})
    this.ws.send(response);
  }
}