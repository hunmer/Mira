import { MessageHandler } from './MessageHandler';
import { WebSocket } from 'ws';
import { WebSocketMessage } from '../WebSocketRouter';
import { LibraryServerDataSQLite } from '../LibraryServerDataSQLite';

export class UpdateHandler extends MessageHandler {
  constructor(
    dbService: LibraryServerDataSQLite,
    ws: WebSocket,
    message: WebSocketMessage
  ) {
    super(dbService, ws, message);
  }

  async handle(): Promise<void> {
    try {
      const { id, data } = this.message.payload.data;
      let result = false;
      
      switch(this.message.payload.type) {
        case 'file':
          result = await this.dbService.updateFile(id, data);
          break;
        case 'folder':
          result = await this.dbService.updateFolder(id, data);
          break;
        case 'tag':
          result = await this.dbService.updateTag(id, data);
          break;
        default:
          throw new Error(`Unsupported update type: ${this.message.payload.type}`);
      }

      this.sendResponse({ success: result });
    } catch (err) {
      this.sendError(err instanceof Error ? err.message : 'Update operation failed');
    }
  }
}