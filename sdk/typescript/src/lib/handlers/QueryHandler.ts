import { MessageHandler } from './MessageHandler';
import { WebSocket } from 'ws';
import { WebSocketMessage } from '../WebSocketRouter';
import { LibraryServerDataSQLite } from '../LibraryServerDataSQLite';

export class QueryHandler extends MessageHandler {
  constructor(
    dbService: LibraryServerDataSQLite,
    ws: WebSocket,
    message: WebSocketMessage
  ) {
    super(dbService, ws, message);
  }

  async handle(): Promise<void> {
    try {
      const query = this.message.payload.data.query;
      const result = await this.dbService.query(query);
      this.sendResponse(result);
    } catch (err) {
      this.sendError(err instanceof Error ? err.message : 'Query failed');
    }
  }
}