import { LibraryServerDataSQLite } from './LibraryServerDataSQLite';

export class LibraryService {
  private dbService: LibraryServerDataSQLite;

  constructor(dbService: LibraryServerDataSQLite) {
    this.dbService = dbService;
  }

  async connectLibrary(config: Record<string, any>): Promise<Record<string, any>> {
    return {
      id: this.dbService.getLibraryId(),
      status: 'connected',
      config
    };
  }
}