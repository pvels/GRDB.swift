import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

class BelongsToOptionalAssociationTests: GRDBTestCase {
    
    func testSingleColumnNoForeignKeyNoPrimaryKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentId"] = 1
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("id", .integer)
            }
            try db.create(table: "children") { t in
                t.column("parentId", .integer)
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parentId")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON ("parents"."rowid" = "children"."parentId")
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE (\"rowid\" = 1)")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parentId")], to: [Column("id")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON ("parents"."id" = "children"."parentId")
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
        }
    }
    
    func testSingleColumnNoForeignKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentId"] = 1
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("id", .integer).primaryKey()
            }
            try db.create(table: "children") { t in
                t.column("parentId", .integer)
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parentId")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON ("parents"."id" = "children"."parentId")
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parentId")], to: [Column("id")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON ("parents"."id" = "children"."parentId")
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
        }
    }
    
    func testSingleColumnSingleForeignKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentId"] = 1
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("id", .integer).primaryKey()
            }
            try db.create(table: "children") { t in
                t.column("parentId", .integer).references("parents")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(optional: Parent.self)
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON ("parents"."id" = "children"."parentId")
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parentId")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON ("parents"."id" = "children"."parentId")
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parentId")], to: [Column("id")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON ("parents"."id" = "children"."parentId")
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
        }
    }
    
    func testSingleColumnSeveralForeignKeys() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parent1Id"] = 1
                container["parent2Id"] = 2
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("id", .integer).primaryKey()
            }
            try db.create(table: "children") { t in
                t.column("parent1Id", .integer).references("parents")
                t.column("parent2Id", .integer).references("parents")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parent1Id")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON ("parents"."id" = "children"."parent1Id")
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parent1Id")], to: [Column("id")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON ("parents"."id" = "children"."parent1Id")
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 1)")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parent2Id")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON ("parents"."id" = "children"."parent2Id")
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 2)")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parent2Id")], to: [Column("id")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON ("parents"."id" = "children"."parent2Id")
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE (\"id\" = 2)")
            }
        }
    }
    
    func testCompoundColumnNoForeignKeyNoPrimaryKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentA"] = 1
                container["parentB"] = 2
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("a", .integer)
                t.column("b", .integer)
            }
            try db.create(table: "children") { t in
                t.column("parentA", .integer)
                t.column("parentB", .integer)
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parentA"), Column("parentB")], to: [Column("a"), Column("b")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON (("parents"."a" = "children"."parentA") AND ("parents"."b" = "children"."parentB"))
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
        }
    }
    
    func testCompoundColumnNoForeignKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentA"] = 1
                container["parentB"] = 2
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("a", .integer)
                t.column("b", .integer)
                t.primaryKey(["a", "b"])
            }
            try db.create(table: "children") { t in
                t.column("parentA", .integer)
                t.column("parentB", .integer)
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parentA"), Column("parentB")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON (("parents"."a" = "children"."parentA") AND ("parents"."b" = "children"."parentB"))
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parentA"), Column("parentB")], to: [Column("a"), Column("b")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON (("parents"."a" = "children"."parentA") AND ("parents"."b" = "children"."parentB"))
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
        }
    }
    
    func testCompoundColumnSingleForeignKey() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parentA"] = 1
                container["parentB"] = 2
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("a", .integer)
                t.column("b", .integer)
                t.primaryKey(["a", "b"])
            }
            try db.create(table: "children") { t in
                t.column("parentA", .integer)
                t.column("parentB", .integer)
                t.foreignKey(["parentA", "parentB"], references: "parents")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(optional: Parent.self)
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON (("parents"."a" = "children"."parentA") AND ("parents"."b" = "children"."parentB"))
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parentA"), Column("parentB")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON (("parents"."a" = "children"."parentA") AND ("parents"."b" = "children"."parentB"))
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parentA"), Column("parentB")], to: [Column("a"), Column("b")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON (("parents"."a" = "children"."parentA") AND ("parents"."b" = "children"."parentB"))
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
        }
    }
    
    func testCompoundColumnSeveralForeignKeys() throws {
        struct Child : TableMapping, MutablePersistable {
            static let databaseTableName = "children"
            func encode(to container: inout PersistenceContainer) {
                container["parent1A"] = 1
                container["parent1B"] = 2
                container["parent2A"] = 3
                container["parent2B"] = 4
            }
        }
        
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parents") { t in
                t.column("a", .integer)
                t.column("b", .integer)
                t.primaryKey(["a", "b"])
            }
            try db.create(table: "children") { t in
                t.column("parent1A", .integer)
                t.column("parent1B", .integer)
                t.column("parent2A", .integer)
                t.column("parent2B", .integer)
                t.foreignKey(["parent1A", "parent1B"], references: "parents")
                t.foreignKey(["parent2A", "parent2B"], references: "parents")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parent1A"), Column("parent1B")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON (("parents"."a" = "children"."parent1A") AND ("parents"."b" = "children"."parent1B"))
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parent1A"), Column("parent1B")], to: [Column("a"), Column("b")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON (("parents"."a" = "children"."parent1A") AND ("parents"."b" = "children"."parent1B"))
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 1) AND (\"b\" = 2))")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parent2A"), Column("parent2B")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON (("parents"."a" = "children"."parent2A") AND ("parents"."b" = "children"."parent2B"))
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 3) AND (\"b\" = 4))")
            }
            do {
                let association = Child.belongsTo(optional: Parent.self, using: ForeignKey([Column("parent2A"), Column("parent2B")], to: [Column("a"), Column("b")]))
                try assertEqualSQL(db, Child.all().including(association), """
                    SELECT "children".*, "parents".* \
                    FROM "children" \
                    LEFT JOIN "parents" ON (("parents"."a" = "children"."parent2A") AND ("parents"."b" = "children"."parent2B"))
                    """)
                try assertEqualSQL(db, Child().request(association), "SELECT * FROM \"parents\" WHERE ((\"a\" = 3) AND (\"b\" = 4))")
            }
        }
    }
    
    func testForeignKeyDefinitionFromColumn() {
        struct Parent : TableMapping {
            static let databaseTableName = "parents"
            enum Columns {
                static let id = Column("id")
            }
        }
        
        struct Child : TableMapping {
            static let databaseTableName = "children"
            enum Columns {
                static let parentId = Column("parentId")
            }
            enum ForeignKeys {
                static let parent1 = ForeignKey([Columns.parentId])
                static let parent2 = ForeignKey([Columns.parentId], to: [Parent.Columns.id])
            }
            static let parent1 = belongsTo(optional: Parent.self, using: ForeignKeys.parent1)
            static let parent2 = belongsTo(optional: Parent.self, using: ForeignKeys.parent2)
        }
    }
}
