import { MessageHandler } from './MessageHandler';
import { WebSocket } from 'ws';
import { WebSocketMessage } from '../WebSocketRouter';
import { LibraryServerDataSQLite } from '../LibraryServerDataSQLite';

export class CreateHandler extends MessageHandler {
  constructor(
    dbService: LibraryServerDataSQLite,
    ws: WebSocket,
    message: WebSocketMessage
  ) {
    super(dbService, ws, message);
  }

  async handle(): Promise<void> {
    try {
      const data = this.message.payload.data;
      let result;
      
      switch(this.message.payload.type) {
        case 'file':
          result = await this.dbService.createFile(data);
          break;
        case 'folder':
          result = await this.dbService.createFolder(data);
          break;
        case 'tag':
          result = await this.dbService.createTag(data);
          break;
        default:
          throw new Error(`Unsupported create type: ${this.message.payload.type}`);
      }

      this.sendResponse(typeof result === 'number' ? { id: result } : result);
    } catch (err) {
      this.sendError(err instanceof Error ? err.message : 'Create operation failed');
    }
  }
}