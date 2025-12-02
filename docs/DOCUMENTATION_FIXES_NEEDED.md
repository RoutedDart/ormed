# Documentation Fixes Needed

This document tracks all methods/properties mentioned in documentation that don't actually exist in the codebase.

## Methods That DON'T Exist

### DataSource
- `DataSource.setDefault()` - Does not exist
  - Use: `ConnectionManager.instance.setDefaultConnection(name)` instead
- `DataSource.getByName()` - Does not exist  
  - Use: `ConnectionManager.instance.getConnection(name)` instead
- `ds.runMigrations()` - Does not exist
- `ds.migrate.reset()` - Does not exist
- `ds.migrate.run()` - Does not exist
- `ds.activeQueries` property - Does not exist
- `ds.isConnected` property - Does not exist

### DataSourceOptions
- `readReplicas` parameter - Does not exist
- `poolSize` parameter - Does not exist
- `maxIdleTime` parameter - Does not exist
- `connectionTimeout` parameter - Does not exist

### Query
- `.forceUsePrimary()` - Does not exist

### ConnectionManager
- `.allConnections()` - Does not exist
  - Possible alternative: Check actual ConnectionManager API

## Files Affected

1. **docs/getting-started.md** - ✅ FIXED
   - Removed `DataSource.setDefault()` 

2. **docs/multi-database.md** - ✅ PARTIALLY FIXED
   - Removed `DataSource.setDefault()` reference
   - Still has: readReplicas, forceUsePrimary, poolSize, allConnections, getByName, activeQueries, isConnected

3. **docs/testing.md**
   - Has: `runMigrations()`, `migrate.reset()`, `migrate.run()`

4. **docs/best_practices.md**
   - Has: `runMigrations()`

## Methods That DO Exist

### Model Static Helpers
✅ `Model.all<T>()` 
✅ `Model.find<T>(id)`
✅ `Model.findOrFail<T>(id)`
✅ `Model.findMany<T>(ids)`
✅ `Model.first<T>()`
✅ `Model.firstOrFail<T>()`
✅ `Model.count<T>()`
✅ `Model.exists<T>()`
✅ `Model.doesntExist<T>()`
✅ `Model.query<T>()`
✅ `Model.where<T>()`
✅ `Model.whereIn<T>()`
✅ `Model.orderBy<T>()`
✅ `Model.limit<T>()`
✅ `Model.destroy<T>(ids)`

### Model Instance Methods  
✅ `model.save()`
✅ `model.delete()`
✅ `model.fill()`
✅ `model.forceFill()`
✅ `model.fresh()`
✅ `model.refresh()`
✅ `model.getAttribute()`
✅ `model.setAttribute()`
✅ `model.getAttributes()`
✅ `model.setAttributes()`
✅ `model.hasAttribute()`
✅ `model.getOriginal()`
✅ `model.isDirty()`
✅ `model.getChanges()`
✅ `model.getDirty()`
✅ `model.syncOriginal()`
✅ `model.toRecord()`
✅ `model.toArray()`
✅ `model.toJson()`

### Model Relation Methods
✅ `model.load()`
✅ `model.loadMissing()`
✅ `model.relationLoaded()`
✅ `model.loadCount()`
✅ `model.loadSum()`
✅ `model.loadAvg()`
✅ `model.loadMax()`
✅ `model.loadMin()`
✅ `model.attach()`
✅ `model.detach()`
✅ `model.sync()`
✅ `model.associate()`
✅ `model.dissociate()`
✅ `model.setRelation()`
✅ `model.unsetRelation()`
✅ `model.getRelation()`

### Model Configuration
✅ `Model.preventLazyLoading()`
✅ `Model.allowLazyLoading()`
✅ `Model.bindConnectionResolver()`
✅ `Model.unbindConnectionResolver()`

### ConnectionManager
✅ `ConnectionManager.instance.setDefaultConnection(name)`
✅ `ConnectionManager.instance.getConnection(name)`

## Action Items

1. Remove or replace all non-existent methods from documentation
2. Consider implementing commonly expected methods like:
   - Migration runners on DataSource
   - Connection pooling configuration
   - Read replica support
   - `forceUsePrimary()` query method
3. Add "Not Yet Implemented" sections for planned features
