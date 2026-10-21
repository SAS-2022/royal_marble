# Room (used by WorkManager, which the background-location plugin uses) finds
# a database's generated `<Name>_Impl` class from the database class's name at
# runtime. R8 (AGP 9) renamed them, so the release bundle crashed on launch:
# "Failed to create an instance of class androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { *; }
-keepnames class * extends androidx.room.RoomDatabase
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
