import { MessageHandler } from './MessageHandler';
import { WebSocket } from 'ws';
import { WebSocketMessage } from '../WebSocketRouter';
import { LibraryServerDataSQLite } from '../LibraryServerDataSQLite';

export class TagHandler extends MessageHandler {
  constructor(
    dbService: LibraryServerDataSQLite,
    ws: WebSocket,
    message: WebSocketMessage
  ) {
    super(dbService, ws, message);
  }

  async handle(): Promise<void> {
    try {
      const { action, payload } = this.message;
      const { data } = payload;
      
      let result;
      switch(action) {
        case 'query':
          result = await this.dbService.queryTag(data.query);
          break;
        case 'create':
          result = await this.dbService.createTag(data);
          break;
        case 'update':
          result = await this.dbService.updateTag(data.id, data);
          break;
        case 'delete':
          result = await this.dbService.deleteTag(data.id);
          break;
        default:
          throw new Error(`Unsupported tag action: ${action}`);
      }

      this.sendResponse({data: result});
    } catch (err) {
      this.sendError(err instanceof Error ? err.message : 'Tag operation failed');
    }
  }
}