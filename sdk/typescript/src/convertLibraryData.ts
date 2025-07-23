import { LibraryServerDataSQLite } from './LibraryServerDataSQLite';
import * as path from 'path';
import * as fs from 'fs';
import { Database } from 'sqlite3';

interface SourceFile {
  id: number;
  title: string;
  size: number;
  date: number;
  birthtime: number;
  link: string;
  md5: string;
}

interface SourceFolder {
  id: number;
  title: string;
  icon: string;
  desc: string;
  meta: string;
  parent: number;
  ctime: number;
}

interface SourceTag {
  id: number;
  title: string;
  icon: string;
  desc: string;
  meta: string;
  parent: number;
  ctime: number;
}

interface UrlMeta {
  fid: number;
  url: string;
}

interface DescMeta {
  fid: number;
  desc: string;
}

interface FolderMeta {
  fid: number;
  ids: string;
}

interface TagMeta {
  fid: number;
  ids: string;
}

export class LibraryDataConverter {
  constructor(private libraryData: LibraryServerDataSQLite) {}

  async convertAndInsertData(data: {
    files: SourceFile[];
    folders: SourceFolder[];
    tags: SourceTag[];
    urlMeta: UrlMeta[];
    descMeta: DescMeta[];
    foldersMeta: FolderMeta[];
    tagsMeta: TagMeta[];
  }, options: { maxItems?: number } = {}) {
    try {
      const maxItems = options.maxItems || Infinity;
      let processed = 0;
      const totalItems = Math.min(
        data.folders.length + data.tags.length + data.files.length,
        maxItems
      );

      // 转换并插入文件夹数据
      const folderMap = new Map<number, number>();
      for (const folder of data.folders) {
        if (processed >= maxItems) break;
        const existingFolder = await this.libraryData.getFolder(folder.id);
        if (existingFolder) {
          await this.libraryData.updateFolder(folder.id, {
            title: folder.title,
            parent_id: folder.parent || null,
          });
          folderMap.set(folder.id, folder.id);
        } else {
          const newFolderId = await this.libraryData.createFolder({
            id: folder.id,
            title: folder.title,
            parent_id: folder.parent || null,
          });
          folderMap.set(folder.id, newFolderId);
        }
        processed++;
        this.showProgress(processed, totalItems, 'folders');
      }

      // 转换并插入标签数据
      const tagMap = new Map<number, number>();
      for (const tag of data.tags) {
        if (processed >= maxItems) break;
        const existingTag = await this.libraryData.getTag(tag.id);
        if (existingTag) {
          await this.libraryData.updateTag(tag.id, {
            title: tag.title,
            parent_id: tag.parent || null,
          });
          tagMap.set(tag.id, tag.id);
        } else {
          const newTagId = await this.libraryData.createTag({
            id: tag.id,
            title: tag.title,
            parent_id: tag.parent || null,
          });
          tagMap.set(tag.id, newTagId);
        }
        processed++;
        this.showProgress(processed, totalItems, 'tags');
      }

      // 转换并插入文件数据
      const fileMap = new Map<number, number>();
      for (const file of data.files) {
        if (processed >= maxItems) break;
        const urlMeta = data.urlMeta.find(m => m.fid === file.id);
        const descMeta = data.descMeta.find(m => m.fid === file.id);
        const tags = this.getTagIdsForFile(file.id, data.tagsMeta, tagMap);
        const newFileId = await this.libraryData.createFile({
          name: file.title,
          created_at: file.birthtime || file.date,
          imported_at: Date.now(),
          size: file.size,
          hash: '', // 不保留hash
          notes: descMeta?.desc,
          folder_id: this.getFolderIdsForFile(file.id, data.foldersMeta, folderMap),
          reference: urlMeta?.url,
          path: this.generateFilePath(file.title, file.link, folderMap),
          tags: tags != null && tags.length ? JSON.stringify(tags) : null,
        });

        if (typeof newFileId === 'number') {
          fileMap.set(file.id, newFileId);
        }
        processed++;
        this.showProgress(processed, totalItems, 'files');
      }

      console.log(`\nData conversion completed (${processed}/${totalItems} items processed)`);
    } catch (error) {
      console.error('Error during data conversion:', error);
      throw error;
    }
  }

  private extractColorFromMeta(meta: string): number | null {
    if (!meta) return null;
    try {
      const metaObj = JSON.parse(meta);
      return metaObj.color || null;
    } catch {
      return null;
    }
  }

  private extractFolderIdFromLink(link: string, folderMap: Map<number, number>): number | null {
    // 假设link格式为"folder:123"或类似
    const match = link.match(/folder:(\d+)/);
    if (match && match[1]) {
      const sourceFolderId = parseInt(match[1]);
      return folderMap.get(sourceFolderId) || null;
    }
    return null;
  }

  private generateFilePath(title: string, link: string, folderMap: Map<number, number>): string | null {
    if (!link) return null;
    // 如果link不为空，直接使用link作为path
    return link;
  }

  private getFolderIdsForFile(
    fileId: number, 
    foldersMeta: FolderMeta[],
    folderMap: Map<number, number>
  ): number | null {
    const meta = foldersMeta.find(m => m.fid === fileId);
    if (!meta?.ids) return null;
    
    const ids = meta.ids.split('|')
      .filter(id => id !== '')
      .map(id => folderMap.get(parseInt(id)))
      .filter(id => id !== undefined) as number[];
      
    return ids.length > 0 ? ids[0] : null;
  }

  private getTagIdsForFile(
    fileId: number,
    tagsMeta: TagMeta[],
    tagMap: Map<number, number>
  ): string[] | null {
    const meta = tagsMeta.find(m => m.fid === fileId);
    if (!meta?.ids) return null;
    
    return meta.ids.split('|')
      .filter(id => id !== '')
      .map(id => tagMap.get(parseInt(id)))
      .filter(id => id !== undefined)
      .map(id => id!.toString());
  }

  // 从SQLite源数据库读取数据的函数
  public async readFromSourceDb(dbPath: string): Promise<{
    files: SourceFile[];
    folders: SourceFolder[];
    tags: SourceTag[];
    urlMeta: UrlMeta[];
    descMeta: DescMeta[];
    foldersMeta: FolderMeta[];
    tagsMeta: TagMeta[];
  }> {
    const db = new Database(dbPath);
    
    const [files, folders, tags, urlMeta, descMeta, foldersMeta, tagsMeta] = await Promise.all([
      this.queryAll<SourceFile>(db, 'SELECT * FROM files'),
      this.queryAll<SourceFolder>(db, 'SELECT * FROM folders'),
      this.queryAll<SourceTag>(db, 'SELECT * FROM tags'),
      this.queryAll<UrlMeta>(db, 'SELECT * FROM url_meta'),
      this.queryAll<DescMeta>(db, 'SELECT * FROM desc_meta'),
      this.queryAll<FolderMeta>(db, 'SELECT * FROM folders_meta'),
      this.queryAll<TagMeta>(db, 'SELECT * FROM tags_meta')
    ]);

    db.close();
    return { files, folders, tags, urlMeta, descMeta, foldersMeta, tagsMeta };
  }

  private showProgress(current: number, total: number, type: string) {
    const percent = Math.floor((current / total) * 100);
    process.stdout.write(
      `\rProcessing ${type}: ${current}/${total} (${percent}%)` + 
      (percent === 100 ? '\n' : '')
    );
  }

  private queryAll<T>(db: Database, sql: string): Promise<T[]> {
    return new Promise((resolve, reject) => {
      db.all(sql, [], (err, rows) => {
        if (err) reject(err);
        else resolve(rows as T[]);
      });
    });
  }
}

// 使用示例
async function main(sourceDbPath: string, targetDir: string) {
  if (!sourceDbPath || !targetDir) {
    console.error('Usage: node convertLibraryData.js <sourceDbFile> <targetDir>');
    process.exit(1);
  }

  if (!fs.existsSync(sourceDbPath)) {
    console.error(`Source database not found: ${sourceDbPath}`);
    process.exit(1);
  }

  // 确保目标目录存在
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }

  const config = {
    id: 'library-1',
    customFields: {
      path: targetDir,
    }
  };
  
  const libraryData = new LibraryServerDataSQLite({} as any, config);
  await libraryData.initialize();
  const converter = new LibraryDataConverter(libraryData);
  
  try {
    console.log('Reading data from source database...');
    const sourceData = await converter.readFromSourceDb(sourceDbPath);
    
    console.log(`Found ${sourceData.files.length} files, ${sourceData.folders.length} folders, ${sourceData.tags.length} tags`);
    console.log('Converting and inserting data...');
    await converter.convertAndInsertData(sourceData, { maxItems: undefined }); // 测试时可限制最大转换条数
    console.log(`Data conversion completed successfully. Database saved to: ${targetDir}`);
  } catch (error) {
    console.error('Data conversion failed:', error);
    process.exit(1);
  } finally {
    await libraryData.close();
  }
}

// 如果是直接执行此文件而不是被导入
if (require.main === module) {
  const args = process.argv.slice(2);
  main(args[0], args[1]).catch(console.error);
}
