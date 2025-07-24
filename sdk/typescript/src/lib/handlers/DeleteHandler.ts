import { MessageHandler } from '../WebSocketRouter';
import { WebSocket } from 'ws';
import { WebSocketMessage } from '../WebSocketRouter';
import { LibraryServerDataSQLite } from '../LibraryServerDataSQLite';

export class DeleteHandler extends MessageHandler {
  constructor(
    dbService: LibraryServerDataSQLite,
    ws: WebSocket,
    message: WebSocketMessage
  ) {
    super(dbService, ws, message);
  }

  async handle(): Promise<void> {
    try {
      const { id, options } = this.message.payload.data;
      let result = false;
      
      switch(this.message.payload.type) {
        case 'file':
          result = await this.dbService.deleteFile(id, options);
          break;
        case 'folder':
          result = await this.dbService.deleteFolder(id);
          break;
        case 'tag':
          result = await this.dbService.deleteTag(id);
          break;
        default:
          throw new Error(`Unsupported delete type: ${this.message.payload.type}`);
      }

      this.sendResponse({ success: result });
    } catch (err) {
      this.sendError(err instanceof Error ? err.message : 'Delete operation failed');
    }
  }
}