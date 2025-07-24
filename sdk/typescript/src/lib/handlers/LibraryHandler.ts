import { MessageHandler } from './MessageHandler';
import { WebSocket } from 'ws';
import { WebSocketMessage } from '../WebSocketRouter';
import { LibraryServerDataSQLite } from '../LibraryServerDataSQLite';

export class LibraryHandler extends MessageHandler {
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
        case 'create':
          result = await this.dbService.createLibrary(data);
          break;
        case 'close':
          result = await this.dbService.closeLibrary();
          break;
        default:
          throw new Error(`Unsupported library action: ${action}`);
      }

      this.sendResponse({});
    } catch (err) {
      this.sendError(err instanceof Error ? err.message : 'Library operation failed');
    }
  }
}
