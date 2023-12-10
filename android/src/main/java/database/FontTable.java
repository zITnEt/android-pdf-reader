package database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import java.io.File;

public class FontTable extends SQLiteOpenHelper {
    private static final int DATABASE_VERSION = 1;

    public FontTable(Context context) {
        super(context, "fonts", null, DATABASE_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        // Define your table creation SQL statements here
        db.execSQL("CREATE TABLE IF NOT EXISTS fonts (" +
                "_id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "filePath TEXT, "+
                "lastUsed INTEGER)");
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        db.execSQL("DROP TABLE IF EXISTS DATABASE_NAME");
        onCreate(db);
    }

    public void insert(String filePath){
        SQLiteDatabase database = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("filePath", filePath);
        values.put("lastUsed", System.currentTimeMillis());
        database.insert("fonts", null, values);
        delete(database);
        database.close();
    }

    public void delete(SQLiteDatabase database){
        String query = "SELECT COUNT(*) FROM fonts";
        Cursor cursor = database.rawQuery(query, null);

        int rowCount = 0; // Initialize the row count to 0

        if (cursor.moveToFirst()) {
            rowCount = cursor.getInt(0);
        }
        cursor.close();

        if (rowCount < 25){
            return;
        }

        int toBeRemoved = 0;
        String[] projection = {"_id", "filePath", "lastUsed"};
        Cursor cursor1 = database.query(
                "fonts",    // Table name
                projection,           // Columns to retrieve
                null,                 // Selection (WHERE clause), null retrieves all rows
                null,                 // Selection arguments
                null,                 // Group by clause, null means no grouping
                null,                 // Having clause, null means no filtering
                null          // Sort order
        );

        String toBeRemovedFilePath = "";
        int toBeRemovedId = 0;
        long toBeRemovedLastUsed = 0;

        try {
            while (cursor1.moveToNext()) {
                long id = cursor1.getLong(cursor1.getColumnIndexOrThrow("_id"));
                String filePath = cursor1.getString(cursor1.getColumnIndexOrThrow("filePath"));
                long lastUsed = cursor1.getLong(cursor1.getColumnIndexOrThrow("lastUsed"));

                if (id == 1){
                    toBeRemovedId = 1;
                    toBeRemovedLastUsed = lastUsed;
                    toBeRemovedFilePath = filePath;
                }
                else{
                    if (lastUsed < toBeRemovedLastUsed){
                        toBeRemovedLastUsed = lastUsed;
                        toBeRemovedFilePath = filePath;
                        toBeRemovedId = (int)id;
                    }
                }
            }

            String selection = "_id = ?"; // The WHERE clause
            String[] selectionArgs = { String.valueOf(toBeRemovedId) }; // The value to replace ? in the selection
            database.delete("fonts", selection, selectionArgs);
            File tobeRemovedFile = new File(toBeRemovedFilePath);
            tobeRemovedFile.delete();
        } finally {
            cursor.close();
        }

    }
}
