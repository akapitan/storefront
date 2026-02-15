Generate or update a jOOQ repository implementation for: $ARGUMENTS

## Instructions

You are creating a jOOQ-based repository implementation in this project's persistence layer. Follow every convention below precisely — they are derived from the existing codebase and must be matched exactly.

## Step 1: Identify the domain interface

Find the domain repository interface that needs a jOOQ implementation. It lives under:
`nbx-backend/src/main/java/com/versuni/nbx/backend/domain/model/<entity>/<Entity>Repository.java`

Read it to understand the contract (method signatures, return types, parameter types).

## Step 2: Identify the jOOQ-generated tables

Find the relevant generated table references under `org.jooq.generated.Tables`. Read the generated table class to know the exact column names and types. If unsure, search for existing usages in the `infrastructure/persistence/jooq/` package.

## Step 3: Create/update the implementation

The file goes in:
`nbx-backend/src/main/java/com/versuni/nbx/backend/infrastructure/persistence/jooq/Jooq<Entity>Repository.java`

### Mandatory class structure (in this exact order):

```java
package com.versuni.nbx.backend.infrastructure.persistence.jooq;

// imports: java.*, org.jooq.*, org.springframework.*, domain model classes
// ALWAYS use: import static org.jooq.generated.Tables.<TABLE_NAME>;

@Repository
class Jooq<Entity>Repository implements <Entity>Repository {

    // ── 1. Static computed fields (multisets, aggregations, JSONB expressions) ──
    // Only if the entity has nested collections or computed columns.
    // Example:
    //   private static final Field<List<Child>> childrenMultiset = multiset(...).convertFrom(...);

    // ── 2. SelectField array ──
    // Lists every column and computed field used in SELECT queries.
    private static final SelectField<?>[] selectFields = { TABLE.COL_A, TABLE.COL_B, ... };

    // ── 3. Static RecordMapper singleton ──
    private static final <Entity>RecordMapper recordMapper = new <Entity>RecordMapper();

    // ── 4. Static TypeReference classes (if needed for JSONB deserialization) ──
    // Example:
    //   private static final SomeTypeReference someTypeReference = new SomeTypeReference();

    // ── 5. DSLContext (constructor-injected) ──
    private final DSLContext dslContext;

    Jooq<Entity>Repository(DSLContext dslContext) {
        Objects.requireNonNull(dslContext, "dslContext must not be null");
        this.dslContext = dslContext;
    }

    // ── 6. Repository method implementations ──
    // Each method is annotated with @Override and the appropriate @Transactional variant.

    // ── 7. Private static inner RecordMapper class ──
    private static class <Entity>RecordMapper implements RecordMapper<Record, <Entity>> {
        @Override
        public <Entity> map(Record record) {
            <Entity>Record entityRecord = record.into(TABLE);
            return new <Entity>(...);
        }
    }

    // ── 8. Private static inner TypeReference classes (if JSONB generics are needed) ──
}
```

### Key conventions — NEVER deviate:

| Rule | Detail |
|------|--------|
| **Visibility** | Class is **package-private** (no `public` keyword). Constructor is also package-private. |
| **Constructor** | Single `DSLContext` param with `Objects.requireNonNull` guard. No `@Autowired`. |
| **`selectFields`** | Always a `static final SelectField<?>[]`. Include every column and computed field. |
| **`recordMapper`** | Always a `private static final` singleton of an inner `RecordMapper` class. |
| **`@Transactional`** | Write methods: `@Transactional`. Read methods: `@Transactional(readOnly = true)`. |
| **Caching** | Use `@Cacheable(cacheNames = "...", key = "#paramName")` / `@CacheEvict` only when the domain interface documents caching intent, or when an existing repo already caches. |
| **Table imports** | Always `import static org.jooq.generated.Tables.TABLE_NAME;`. Never use qualified table refs inline. |
| **ID conversions** | UUID-based IDs: call `.toUuid()`. String-based IDs: call `.toString()`. Construct from DB: `EntityId.from(uuid)` or `EntityId.of(string)`. |
| **JSONB** | Use `JsonbHelper.serialize(obj)` and `JsonbHelper.deserialize(jsonb, Class/TypeReference)`. Define `TypeReference` subclasses as private static inner classes. |
| **Joins** | Chain in `.from(TABLE.join(...).on(...).leftJoin(...).on(...))`. |
| **Conditions** | Build `Condition` variables. Use `noCondition()` for dynamic WHERE. Use `.and()` / `.or()` chaining. |
| **Enum storage** | Store enums as strings via `.name()`. Read back via `Enum.valueOf(record.getString())`. |
| **Multisets** | Use `multiset(select(...).from(...).where(...)).convertFrom(...)` for nested collections. Declare as `private static final Field<List<...>>`. |

### Query method patterns:

**Return `Optional<T>`** → use `.fetchOptional(recordMapper)`
**Return `T` (nullable)** → use `.fetchOne(recordMapper)`
**Return `List<T>`** → use `.fetch(recordMapper)` with `.orderBy(TABLE.ID)`
**Return `boolean`** → use `this.dslContext.fetchExists(TABLE, condition)`
**Void write** → use `.execute()` at the end

**Insert:**
```java
this.dslContext.insertInto(TABLE)
    .columns(TABLE.COL_A, TABLE.COL_B)
    .values(entity.getA(), entity.getB())
    .execute();
```

**Upsert (on conflict update):**
```java
this.dslContext.insertInto(TABLE)
    .columns(...)
    .values(...)
    .onConflict(TABLE.UNIQUE_KEY).doUpdate()
        .set(TABLE.COL_A, newVal)
    .execute();
```

**Upsert (on conflict ignore):**
```java
.onConflictOnConstraint(Keys.CONSTRAINT_NAME).doNothing()
// or
.onDuplicateKeyIgnore()
```

**Update:**
```java
this.dslContext.update(TABLE)
    .set(TABLE.COL_A, newValue)
    .where(TABLE.ID.eq(id.toUuid()))
    .execute();
```

**Cross-table update (join via `.from()`):**
```java
this.dslContext.update(CHILD_TABLE)
    .set(CHILD_TABLE.COL, value)
    .from(PARENT_TABLE)
    .where(CHILD_TABLE.PARENT_ID.eq(PARENT_TABLE.ID)
        .and(PARENT_TABLE.ID.eq(parentId.toUuid())))
    .execute();
```

**Delete:**
```java
this.dslContext.deleteFrom(TABLE)
    .where(TABLE.ID.eq(id.toUuid()))
    .execute();
```

**Delete with returning:**
```java
this.dslContext.deleteFrom(TABLE)
    .where(condition)
    .returning(TABLE.COL_A, TABLE.COL_B)
    .fetch(recordMapper);
```

**Subquery in condition:**
```java
.where(TABLE.ID.in(
    select(OTHER.ID).from(OTHER).where(OTHER.FK.eq(value))))
```

### PostgreSQL-specific patterns:

**Array columns:**
```java
// Write: Java collection → SQL array
Integer[] values = list.stream().map(Enum::ordinal).toArray(Integer[]::new);
// Read: SQL array → Java collection
Stream.of(record.getArrayCol()).map(SomeType::from).toList();
```

**Array search (`= ANY`):**
```java
import static org.jooq.impl.DSL.any;
import static org.jooq.impl.DSL.val;
Condition condition = val(searchValue).eq(any(TABLE.ARRAY_COL));
```

**JSONB concat (`||`):**
```java
DslExtensions.jsonbConcat(field1, field2)
```

**JSONB get attribute (`->>'key'`):**
```java
DSL.jsonbGetAttribute(field, "key")
```

**JSONB aggregation:**
```java
jsonbObjectAgg(keyField, valueField).filterWhere(keyField.isNotNull())
```

## Step 4: Verify

After generating the code:
1. Confirm every method from the domain interface is implemented
2. Confirm `selectFields` includes all columns needed by the `RecordMapper`
3. Confirm all `@Transactional` annotations are correct (readOnly for queries)
4. Confirm ID conversions match the ID type (UUID vs String)
5. Confirm no `public` keyword on the class or constructor
