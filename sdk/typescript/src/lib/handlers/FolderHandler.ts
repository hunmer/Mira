import { MessageHandler } from './MessageHandler';
import { WebSocket } from 'ws';
import { WebSocketMessage } from '../WebSocketRouter';
import { LibraryServerDataSQLite } from '../LibraryServerDataSQLite';

export class FolderHandler extends MessageHandler {
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
          result = await this.dbService.queryFolder(data.query);
          break;
        case 'create':
          result = await this.dbService.createFolder(data);
          break;
        case 'update':
          result = await this.dbService.updateFolder(data.id, data);
          break;
        case 'delete':
          result = await this.dbService.deleteFolder(data.id);
          break;
        default:
          throw new Error(`Unsupported folder action: ${action}`);
      }

      this.sendResponse({data: result});
    } catch (err) {
      this.sendError(err instanceof Error ? err.message : 'Folder operation failed');
    }
  }
}