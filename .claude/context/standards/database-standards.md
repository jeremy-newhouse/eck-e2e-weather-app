# Database Standards

> Database standards: PostgreSQL, Neo4j, TimescaleDB, naming, schema design, migrations, multi-tenancy, performance

**Compiled**: 2026-06-01 20:55
**Source**: evolv-coder-standards
**Domain Version**: 1.4.3

---

## Contents

- [Readme](#readme)
- [Naming Conventions](#naming-conventions)
- [Schema Design](#schema-design)
- [Migrations](#migrations)
- [Performance](#performance)
- [Multi Tenancy](#multi-tenancy)
- [Neo4J](#neo4j)
- [Timescaledb](#timescaledb)

---

<!-- Source: standards/database/README.md (v1.4.3) -->

# Database Standards

**Status**: Active

## Overview
This directory contains all standards related to PostgreSQL database design, migrations, and query optimization.

## Stack Components
- **Database**: PostgreSQL 16+ (prod runs `timescale/timescaledb-ha:pg16`)
- **Time-series / vector**: TimescaleDB + pgvector (prod image `timescale/timescaledb-ha:pg16`)
- **Graph**: Neo4j 5.26 LTS (+ APOC)
- **ORM**: SQLAlchemy 2.0+ (async)
- **Migration Tool**: Alembic
- **In-DB scheduler**: pg_cron (bundled in the prod image)
- **Connection Pooling**: PgBouncer (production)
- **Monitoring**: pg_stat_statements

## Standards in This Section

### 📄 [naming-conventions.md](./naming-conventions.md)
PostgreSQL naming standards:
- Table names (plural, snake_case)
- Column names (snake_case)
- Foreign keys (_id suffix)
- Indexes and constraints
- Functions and triggers

### 📄 [migrations.md](./migrations.md)
Database migration patterns with Alembic:
- Migration file organization
- Auto-generation vs manual migrations
- Data migrations
- Rollback strategies
- Production deployment patterns

### 📄 [schema-design.md](./schema-design.md)
PostgreSQL schema design best practices:
- Table design principles
- Relationship patterns (one-to-many, many-to-many)
- JSONB usage patterns
- Indexing strategies
- Soft delete and audit patterns

### 📄 [performance.md](./performance.md)
Database performance optimization:
- Query analysis with EXPLAIN ANALYZE
- Indexing strategies (B-tree, GIN, partial)
- N+1 query prevention
- Connection pooling configuration
- Table partitioning
- Materialized views and caching

### 📄 [multi-tenancy.md](./multi-tenancy.md)
Tenant isolation patterns:
- Strategy selection (row-level default, schema-per-tenant, database-per-tenant)
- PostgreSQL Row-Level Security policies
- SQLAlchemy session-level tenant scoping
- Cross-tenant access semantics (403 vs 404)
- Migration and testing rules

### 📄 [timescaledb.md](./timescaledb.md)
TimescaleDB time-series standard:
- Hypertables and chunk-interval sizing
- Continuous aggregates and refresh policies
- Compression and retention policies
- pg_cron vs Celery-beat scheduling

### 📄 [neo4j.md](./neo4j.md)
Neo4j graph database standard:
- Async driver and connection lifecycle
- Parameterized Cypher (injection safety)
- Versioned graph migrations and APOC scope
- Testcontainers integration testing

## Quick Reference

### Table Naming
```sql
-- Tables: plural, snake_case
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_roles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    role_id INTEGER REFERENCES roles(id)
);
```

### Column Naming
```sql
-- Columns: snake_case
-- Timestamps: _at suffix
-- Booleans: is_ or has_ prefix
-- Foreign keys: _id suffix

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total_amount DECIMAL(10, 2),
    is_completed BOOLEAN DEFAULT FALSE,
    has_shipped BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP
);
```

### Index Naming
```sql
-- Pattern: idx_table_column(s)
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Unique constraints: unq_table_column(s)
ALTER TABLE users ADD CONSTRAINT unq_users_email UNIQUE(email);
```

## Migration Patterns

### Creating Migration
```bash
# Generate migration
alembic revision --autogenerate -m "add users table"

# Manual migration
alembic revision -m "add custom index"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

### Migration Template
```python
"""add users table

Revision ID: ${revision_id}
Revises: ${revises}
Create Date: ${create_date}

"""
from alembic import op
import sqlalchemy as sa

def upgrade() -> None:
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(255), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_users_email', 'users', ['email'])

def downgrade() -> None:
    op.drop_index('idx_users_email', 'users')
    op.drop_table('users')
```

## SQLAlchemy Models

### Base Model Pattern

For the canonical Base/TimestampMixin pattern, see [Schema Design](schema-design.md).

## Performance Guidelines

### Index Strategy
```sql
-- Index foreign keys
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- Index columns used in WHERE clauses
CREATE INDEX idx_users_email ON users(email);

-- Composite indexes for multiple columns
CREATE INDEX idx_orders_user_id_created_at ON orders(user_id, created_at);

-- Partial indexes for filtered queries
CREATE INDEX idx_orders_pending ON orders(status) WHERE status = 'pending';
```

### Query Optimization
```python
# Avoid N+1 queries - use eager loading
from sqlalchemy.orm import joinedload

users = await db.execute(
    select(User).options(joinedload(User.orders))
)

# Use bulk operations
await db.execute(
    insert(User),
    [
        {"email": "user1@example.com"},
        {"email": "user2@example.com"},
    ]
)
```

## Common Patterns

### Soft Deletes
```python
class SoftDeleteMixin:
    deleted_at = Column(DateTime, nullable=True)
    is_deleted = Column(Boolean, default=False, nullable=False)

    @property
    def is_active(self):
        return not self.is_deleted
```

### Audit Trail
```python
class AuditMixin:
    created_by = Column(Integer, ForeignKey('users.id'))
    updated_by = Column(Integer, ForeignKey('users.id'))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
```

### JSON Fields
```python
from sqlalchemy.dialects.postgresql import JSONB, UUID as PG_UUID

class Event(Base):
    __tablename__ = 'events'

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payload = Column(JSONB, nullable=False)
    metadata = Column(JSONB, default={})
```

## Best Practices

### ✅ DO
- Use snake_case for all identifiers
- Add indexes on foreign keys
- Use appropriate data types
- Include created_at/updated_at timestamps
- Write reversible migrations
- Test migrations on staging first
- Use connection pooling

### ❌ DON'T
- Use reserved keywords as names
- Create tables without primary keys
- Store large blobs in main tables
- Use SELECT * in production
- Skip foreign key constraints
- Ignore query performance
- Mix naming conventions

---

*For ORM implementation, see [Backend/tech-stack.md](../backend/tech-stack.md)*

---

<!-- Source: standards/database/naming-conventions.md (v1.1.0) -->

# PostgreSQL Naming Conventions

**Status**: Active

## Overview
Consistent naming conventions are critical for database maintainability, readability, and team collaboration. This guide establishes PostgreSQL naming standards following industry best practices.

## Core Principles

1. **Use lowercase with underscores** (snake_case) - PostgreSQL is case-insensitive but converts unquoted identifiers to lowercase
2. **Be descriptive but concise** - Names should be self-documenting
3. **Be consistent** - Follow the same patterns throughout your schema
4. **Avoid reserved keywords** - Don't use SQL reserved words as identifiers
5. **Use plural names for tables** - Tables are collections of entities

## General Rules

### Character Set
- Use only lowercase letters (a-z)
- Use numbers (0-9) - but not as the first character
- Use underscores (_) as word separators
- Avoid special characters, spaces, or hyphens
- Maximum length: 63 characters (PostgreSQL limit)

### Naming Pattern
```
component_type_descriptor
```

**Examples:**
- `users_profile_idx`
- `orders_created_at_idx`
- `fk_orders_customer_id`

## Table Names

### Convention
- **Plural nouns** - tables represent collections of entities
- Descriptive of the entities they contain
- Use snake_case for multi-word names

```sql
-- Good
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    total_amount DECIMAL(10, 2)
);

CREATE TABLE customer_addresses (
    id SERIAL PRIMARY KEY,
    street_address TEXT
);

-- Avoid
CREATE TABLE Users (...)  -- Capital letters
CREATE TABLE user (...)  -- Singular
CREATE TABLE customer-address (...)  -- Hyphens
```

### Junction/Join Tables
For many-to-many relationships, use singular-plural (`entity_related_entities`):

```sql
-- Pattern: singular_plural
CREATE TABLE user_roles (
    user_id INTEGER REFERENCES users(id),
    role_id INTEGER REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE product_categories (
    product_id INTEGER REFERENCES products(id),
    category_id INTEGER REFERENCES categories(id),
    PRIMARY KEY (product_id, category_id)
);
```

## Column Names

### Convention
- Use snake_case
- Be descriptive and specific
- Avoid abbreviations unless widely understood
- Don't prefix with table name (redundant)

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE
);

-- Avoid
CREATE TABLE users (
    userId INT,  -- Camel case
    user_email VARCHAR(255),  -- Redundant prefix
    fname VARCHAR(100),  -- Unclear abbreviation
    DOB DATE  -- All caps
);
```

### Primary Keys
- Use `id` as the primary key column name
- Always use SERIAL, BIGSERIAL, or UUID type

```sql
-- Good
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255)
);

-- Alternative with UUID
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50)
);
```

### Foreign Keys
- Name foreign key columns as: `{singular_referenced_table}_id`
- Use singular form for clarity (references a single entity)
- Makes relationships immediately clear

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    shipping_address_id INTEGER REFERENCES addresses(id),
    created_at TIMESTAMP
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER
);
```

### Boolean Columns
- Prefix with `is_`, `has_`, or `can_`
- Makes the boolean nature clear

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    has_premium BOOLEAN DEFAULT FALSE,
    can_post_comments BOOLEAN DEFAULT TRUE
);
```

### Date/Time Columns
- Use descriptive names with time context
- Standard suffixes: `_at` for timestamps, `_date` for dates

```sql
CREATE TABLE subscriptions (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activated_at TIMESTAMP,
    expires_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    start_date DATE,
    end_date DATE
);
```

### Common Column Patterns

| Purpose | Pattern | Example |
|---------|---------|---------|
| Primary Key | `id` | `id` |
| Foreign Key | `{singular_table}_id` | `customer_id`, `product_id` |
| Created timestamp | `created_at` | `created_at` |
| Updated timestamp | `updated_at` | `updated_at` |
| Deleted timestamp (soft delete) | `deleted_at` | `deleted_at` |
| Boolean flag | `is_*`, `has_*`, `can_*` | `is_active`, `has_access` |
| Count | `*_count` | `view_count`, `order_count` |
| Amount/Total | `*_amount`, `*_total` | `total_amount`, `subtotal` |
| Status | `*_status` | `order_status`, `payment_status` |

## Constraint Names

### Primary Key Constraints
Pattern: `pk_{table_name}`

```sql
CREATE TABLE customers (
    id SERIAL,
    email VARCHAR(255),
    CONSTRAINT pk_customers PRIMARY KEY (id)
);
```

### Foreign Key Constraints
Pattern: `fk_{table}_{referenced_table}` or `fk_{table}_{column}`

```sql
-- Good - shows relationship clearly
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id) REFERENCES customers(id);

-- Also acceptable
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer_id
FOREIGN KEY (customer_id) REFERENCES customers(id);

-- For multiple FKs to same table
ALTER TABLE orders
ADD CONSTRAINT fk_orders_billing_address
FOREIGN KEY (billing_address_id) REFERENCES addresses(id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_shipping_address
FOREIGN KEY (shipping_address_id) REFERENCES addresses(id);
```

### Unique Constraints
Pattern: `uq_{table}_{column(s)}`

```sql
-- Single column
ALTER TABLE users
ADD CONSTRAINT uq_users_email UNIQUE (email);

-- Multiple columns
ALTER TABLE user_roles
ADD CONSTRAINT uq_user_roles_user_id_role_id
UNIQUE (user_id, role_id);

-- More readable for multiple columns
ALTER TABLE inventory
ADD CONSTRAINT uq_inventory_warehouse_product
UNIQUE (warehouse_id, product_id);
```

### Check Constraints
Pattern: `chk_{table}_{column}_{condition}`

```sql
ALTER TABLE products
ADD CONSTRAINT chk_products_price_positive
CHECK (price > 0);

ALTER TABLE users
ADD CONSTRAINT chk_users_age_range
CHECK (age >= 0 AND age <= 150);

ALTER TABLE orders
ADD CONSTRAINT chk_orders_quantity_positive
CHECK (quantity > 0);
```

### Default Constraints
Pattern: `df_{table}_{column}`

```sql
ALTER TABLE users
ADD CONSTRAINT df_users_created_at
DEFAULT CURRENT_TIMESTAMP FOR created_at;

ALTER TABLE products
ADD CONSTRAINT df_products_is_active
DEFAULT TRUE FOR is_active;
```

## Index Names

### Convention
Pattern: `idx_{table}_{column(s)}_{type}`

Types:
- No suffix for standard B-tree indexes
- `_uniq` for unique indexes (though unique constraints are often preferred)
- `_gin` for GIN indexes
- `_gist` for GiST indexes
- `_partial` for partial indexes

```sql
-- Standard indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Composite indexes
CREATE INDEX idx_orders_customer_status
ON orders(customer_id, status);

CREATE INDEX idx_users_last_name_first_name
ON users(last_name, first_name);

-- GIN index for full-text search
CREATE INDEX idx_products_search_gin
ON products USING GIN(to_tsvector('english', description));

-- Partial index
CREATE INDEX idx_users_active_email_partial
ON users(email) WHERE is_active = TRUE;

-- Unique index (though UNIQUE constraint is often preferred)
CREATE UNIQUE INDEX idx_users_email_uniq ON users(email);
```

### Functional Indexes
Include the function name in the index name:

```sql
CREATE INDEX idx_users_email_lower
ON users(LOWER(email));

CREATE INDEX idx_orders_year_created
ON orders(EXTRACT(YEAR FROM created_at));
```

## View Names

### Convention
- Use `v_` or `vw_` prefix (optional but helpful)
- Or use `_view` suffix
- Descriptive of the data/purpose

```sql
-- With prefix
CREATE VIEW v_active_users AS
SELECT * FROM users WHERE is_active = TRUE;

CREATE VIEW vw_order_summary AS
SELECT
    o.id,
    o.order_number,
    c.email,
    SUM(oi.quantity * oi.price) as total
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id, o.order_number, c.email;

-- With suffix
CREATE VIEW customer_orders_view AS
SELECT * FROM customers c
JOIN orders o ON c.id = o.customer_id;

-- No prefix/suffix (also acceptable)
CREATE VIEW active_subscriptions AS
SELECT * FROM subscriptions
WHERE status = 'active' AND expires_at > CURRENT_TIMESTAMP;
```

## Materialized View Names

### Convention
- Use `mv_` or `mat_` prefix
- Or use `_mat` suffix

```sql
CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT
    DATE(created_at) as sale_date,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue
FROM orders
GROUP BY DATE(created_at);

CREATE MATERIALIZED VIEW mat_user_statistics AS
SELECT
    user_id,
    COUNT(*) as total_orders,
    SUM(total_amount) as lifetime_value
FROM orders
GROUP BY user_id;
```

## Function Names

### Convention
- Use verb-noun pattern
- snake_case
- Be descriptive of what the function does

```sql
-- Getter functions
CREATE FUNCTION get_user_by_email(user_email VARCHAR)
RETURNS TABLE(id INT, email VARCHAR, first_name VARCHAR) AS $$
    SELECT id, email, first_name FROM users WHERE email = user_email;
$$ LANGUAGE sql;

-- Calculator functions
CREATE FUNCTION calculate_order_total(order_id_param INT)
RETURNS DECIMAL AS $$
    SELECT SUM(quantity * price)
    FROM order_items
    WHERE order_id = order_id_param;
$$ LANGUAGE sql;

-- Boolean check functions
CREATE FUNCTION is_email_available(email_param VARCHAR)
RETURNS BOOLEAN AS $$
    SELECT NOT EXISTS(SELECT 1 FROM users WHERE email = email_param);
$$ LANGUAGE sql;

-- Update functions
CREATE FUNCTION update_user_last_login(user_id_param INT)
RETURNS VOID AS $$
    UPDATE users
    SET last_login_at = CURRENT_TIMESTAMP
    WHERE id = user_id_param;
$$ LANGUAGE sql;
```

## Trigger Names

### Convention
Pattern: `tr_{table}_{action}_{timing}`

Actions: `insert`, `update`, `delete`
Timing: `before`, `after`

```sql
-- Update timestamp trigger
CREATE TRIGGER tr_users_update_updated_at_before
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Audit log trigger
CREATE TRIGGER tr_orders_insert_audit_after
AFTER INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION log_order_creation();

-- Validation trigger
CREATE TRIGGER tr_order_items_validate_before
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION validate_order_item();
```

## Sequence Names

### Convention
Pattern: `{table}_{column}_seq` (automatically created with SERIAL)

```sql
-- Automatically created
CREATE TABLE customers (
    id SERIAL PRIMARY KEY  -- Creates customers_id_seq
);

-- Manual creation
CREATE SEQUENCE order_number_seq
START WITH 1000
INCREMENT BY 1;

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_number INTEGER DEFAULT nextval('order_number_seq')
);
```

## Schema Names

### Convention
- Use snake_case
- Organize by domain or purpose
- Common patterns: domain-based or environment-based

```sql
-- Domain-based schemas
CREATE SCHEMA sales;
CREATE SCHEMA inventory;
CREATE SCHEMA customer_service;
CREATE SCHEMA analytics;

-- Function-based schemas
CREATE SCHEMA audit;
CREATE SCHEMA reporting;
CREATE SCHEMA staging;

-- Examples with tables
CREATE TABLE sales.orders (
    id SERIAL PRIMARY KEY,
    total_amount DECIMAL(10, 2)
);

CREATE TABLE inventory.products (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(50)
);
```

## Enum Types

### Convention
- Suffix with `_type` or `_status` or `_enum`
- Use snake_case

```sql
-- Status enums
CREATE TYPE order_status_enum AS ENUM (
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled'
);

CREATE TYPE payment_status_enum AS ENUM (
    'unpaid',
    'paid',
    'refunded',
    'failed'
);

-- Type enums
CREATE TYPE user_role_type AS ENUM (
    'admin',
    'manager',
    'user',
    'guest'
);

-- Usage
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    status order_status_enum DEFAULT 'pending',
    payment_status payment_status_enum DEFAULT 'unpaid'
);
```

## Reserved Words to Avoid

### Common SQL Reserved Keywords
Avoid using these as table or column names without quotes:
- `users` (generally safe in PostgreSQL)
- `orders` (generally safe in PostgreSQL)
- `group`
- `table`
- `column`
- `index`
- `select`
- `where`
- `from`
- `join`
- `timestamp`
- `date`
- `time`

**Note:** `users` and `orders` are not reserved words in PostgreSQL and are commonly used.

## Alembic Migration Naming

### Convention for Alembic Revisions
Pattern: `{date}_{short_description}`

```bash
# Alembic revision message format
alembic revision -m "create_users_table"
alembic revision -m "add_email_verification_to_users"
alembic revision -m "create_orders_and_order_items_tables"
alembic revision -m "add_index_on_users_email"
```

### Migration File Content
```python
"""create_users_table

Revision ID: a1b2c3d4e5f6
Revises:
Create Date: 2025-11-10 10:30:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = 'a1b2c3d4e5f6'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id', name='pk_users'),
        sa.UniqueConstraint('email', name='uq_users_email')
    )
    op.create_index('idx_users_email', 'users', ['email'])

def downgrade():
    op.drop_index('idx_users_email', table_name='users')
    op.drop_table('users')
```

## Complete Example Schema

```sql
-- Create schema
CREATE SCHEMA ecommerce;

-- Create enum types
CREATE TYPE order_status_enum AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled');
CREATE TYPE payment_method_enum AS ENUM ('credit_card', 'debit_card', 'paypal', 'bank_transfer');

-- Customers table
CREATE TABLE customers (
    id SERIAL,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_customers PRIMARY KEY (id),
    CONSTRAINT uq_customers_email UNIQUE (email)
);

-- Addresses table
CREATE TABLE addresses (
    id SERIAL,
    customer_id INTEGER NOT NULL,
    street_address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_addresses PRIMARY KEY (id),
    CONSTRAINT fk_addresses_customers FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

-- Products table
CREATE TABLE products (
    id SERIAL,
    sku VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_products PRIMARY KEY (id),
    CONSTRAINT uq_products_sku UNIQUE (sku),
    CONSTRAINT chk_products_price_positive CHECK (price > 0),
    CONSTRAINT chk_products_stock_non_negative CHECK (stock_quantity >= 0)
);

-- Orders table
CREATE TABLE orders (
    id SERIAL,
    order_number VARCHAR(50) NOT NULL,
    customer_id INTEGER NOT NULL,
    billing_address_id INTEGER NOT NULL,
    shipping_address_id INTEGER NOT NULL,
    status order_status_enum DEFAULT 'pending',
    payment_method payment_method_enum,
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    shipping_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    CONSTRAINT pk_orders PRIMARY KEY (id),
    CONSTRAINT uq_orders_order_number UNIQUE (order_number),
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id) REFERENCES customers(id),
    CONSTRAINT fk_orders_billing_address FOREIGN KEY (billing_address_id) REFERENCES addresses(id),
    CONSTRAINT fk_orders_shipping_address FOREIGN KEY (shipping_address_id) REFERENCES addresses(id),
    CONSTRAINT chk_orders_total_positive CHECK (total_amount > 0)
);

-- Order items table
CREATE TABLE order_items (
    id SERIAL,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (id),
    CONSTRAINT fk_order_items_orders FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_products FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT chk_order_items_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_order_items_unit_price_positive CHECK (unit_price > 0)
);

-- Create indexes
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_addresses_customer_id ON addresses(customer_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_is_active ON products(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables
CREATE TRIGGER tr_customers_update_updated_at_before
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_products_update_updated_at_before
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_orders_update_updated_at_before
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

## Quick Reference Checklist

- [ ] Use snake_case for all identifiers
- [ ] Use plural table names
- [ ] Name foreign keys as `{singular_table}_id`
- [ ] Prefix boolean columns with `is_`, `has_`, or `can_`
- [ ] Use `created_at` and `updated_at` for timestamps
- [ ] Name constraints with appropriate prefixes: `pk_`, `fk_`, `uq_`, `chk_`
- [ ] Name indexes as `idx_{table}_{column(s)}`
- [ ] Use descriptive names that convey purpose
- [ ] Avoid abbreviations unless universally understood
- [ ] Be consistent across your entire schema

## Tools for Validation

- **pg_dump**: Review schema structure
- **psql \d commands**: Inspect tables and constraints
- **Linting tools**: Use SQL linters like sqlfluff
- **ER Diagram tools**: Visualize and validate relationships

## References

- [PostgreSQL Naming Conventions](https://www.postgresql.org/docs/current/sql-syntax-lexical.html)
- [PostgreSQL Best Practices](https://wiki.postgresql.org/wiki/Don't_Do_This)
- [SQL Style Guide](https://www.sqlstyle.guide/)

---

*Last updated: November 2025*

---

<!-- Source: standards/database/schema-design.md (v1.2.0) -->

# Database Schema Design Standard

**Status**: Active

## Purpose

This standard defines best practices for designing PostgreSQL database schemas with SQLAlchemy 2.0+, ensuring scalability, maintainability, and performance.

## Scope

- Table design principles
- Relationship patterns
- Data types and constraints
- Indexing strategies
- Advanced PostgreSQL features

---

## Design Principles

### 1. Normalize First, Denormalize for Performance

Start with normalized schema (3NF), then strategically denormalize based on query patterns:

```sql
-- Normalized (3NF)
users (id, email, name)
addresses (id, user_id, street, city, state, zip)

-- Denormalized for read performance (if needed)
users (id, email, name, primary_address_city, primary_address_state)
```

### 2. Use Appropriate Data Types

| Data | Preferred Type | Avoid |
|------|---------------|-------|
| Primary keys | `UUID` (v4, `gen_random_uuid()`) | `SERIAL` for user-facing tables |
| UUIDs | `UUID` native type | `VARCHAR(36)` |
| Money | `NUMERIC(19,4)` | `FLOAT`, `REAL` |
| Timestamps | `TIMESTAMPTZ` | `TIMESTAMP` (without TZ) |
| JSON data | `JSONB` | `JSON`, `TEXT` |
| Boolean | `BOOLEAN` | `INTEGER`, `CHAR(1)` |
| Enums | `VARCHAR` or PostgreSQL `ENUM` | Magic numbers |
| Text | `TEXT` | `VARCHAR` (without limit) |

### 3. Always Include Audit Columns

```python
from sqlalchemy import Column, DateTime, func
from sqlalchemy.orm import declared_attr


class TimestampMixin:
    """Mixin for created_at and updated_at timestamps."""

    @declared_attr
    def created_at(cls):
        return Column(
            DateTime(timezone=True),
            server_default=func.now(),
            nullable=False
        )

    @declared_attr
    def updated_at(cls):
        return Column(
            DateTime(timezone=True),
            server_default=func.now(),
            onupdate=func.now(),
            nullable=False
        )
```

---

## Table Design Patterns

### Base Model Pattern

```python
"""Base model with common functionality."""

from sqlalchemy import Column, DateTime, func
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import DeclarativeBase, declared_attr

import uuid


class Base(DeclarativeBase):
    """Base class for all models."""

    @declared_attr.directive
    def __tablename__(cls) -> str:
        """Generate table name from class name."""
        # Convert CamelCase to snake_case and pluralize
        import re
        name = re.sub(r'(?<!^)(?=[A-Z])', '_', cls.__name__).lower()
        return f"{name}s"


class BaseModel(Base):
    """Abstract base model with common columns."""

    __abstract__ = True

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )
```

### Standard Entity Model

```python
"""User model example."""

from sqlalchemy import Column, String, Boolean, Integer, ForeignKey
from sqlalchemy.orm import relationship

from app.db.base import BaseModel


class User(BaseModel):
    """User account model."""

    __tablename__ = "users"

    # Core fields
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=True)

    # Status flags
    is_active = Column(Boolean, default=True, nullable=False)
    is_superuser = Column(Boolean, default=False, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)

    # Foreign keys
    organization_id = Column(
        Integer,
        ForeignKey("organizations.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    # Relationships
    organization = relationship("Organization", back_populates="users")
    posts = relationship("Post", back_populates="author", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<User(id={self.id}, email={self.email})>"
```

---

## Relationship Patterns

### One-to-Many

```python
class Organization(BaseModel):
    """Organization with many users."""

    __tablename__ = "organizations"

    name = Column(String(255), nullable=False)

    # One organization has many users
    users = relationship(
        "User",
        back_populates="organization",
        lazy="selectin"  # Eager load by default
    )


class User(BaseModel):
    """User belongs to organization."""

    __tablename__ = "users"

    organization_id = Column(
        Integer,
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=True,
        index=True
    )

    # Many users belong to one organization
    organization = relationship("Organization", back_populates="users")
```

### Many-to-Many

```python
from sqlalchemy import Table, Column, Integer, ForeignKey

# Association table
user_roles = Table(
    "user_roles",
    Base.metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("role_id", Integer, ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True),
)


class User(BaseModel):
    """User with many roles."""

    __tablename__ = "users"

    roles = relationship(
        "Role",
        secondary=user_roles,
        back_populates="users",
        lazy="selectin"
    )


class Role(BaseModel):
    """Role assigned to many users."""

    __tablename__ = "roles"

    name = Column(String(50), unique=True, nullable=False)

    users = relationship(
        "User",
        secondary=user_roles,
        back_populates="roles"
    )
```

### Many-to-Many with Extra Data

```python
class ProjectMember(BaseModel):
    """Association model with extra attributes."""

    __tablename__ = "project_members"

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True
    )
    project_id = Column(
        Integer,
        ForeignKey("projects.id", ondelete="CASCADE"),
        primary_key=True
    )

    # Extra attributes
    role = Column(String(50), nullable=False, default="member")
    joined_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="project_memberships")
    project = relationship("Project", back_populates="members")


class User(BaseModel):
    __tablename__ = "users"

    project_memberships = relationship(
        "ProjectMember",
        back_populates="user",
        cascade="all, delete-orphan"
    )


class Project(BaseModel):
    __tablename__ = "projects"

    members = relationship(
        "ProjectMember",
        back_populates="project",
        cascade="all, delete-orphan"
    )
```

### Self-Referential (Tree/Hierarchy)

```python
class Category(BaseModel):
    """Hierarchical category structure."""

    __tablename__ = "categories"

    name = Column(String(255), nullable=False)
    parent_id = Column(
        Integer,
        ForeignKey("categories.id", ondelete="CASCADE"),
        nullable=True,
        index=True
    )

    # Self-referential relationships
    parent = relationship(
        "Category",
        remote_side="Category.id",
        back_populates="children"
    )
    children = relationship(
        "Category",
        back_populates="parent",
        cascade="all, delete-orphan"
    )
```

---

## JSONB Patterns

### When to Use JSONB

✅ **Good use cases:**
- Configuration/settings that vary per record
- Metadata with unknown structure
- Audit logs with varying attributes
- API response caching
- Feature flags per entity

❌ **Avoid JSONB for:**
- Data that needs foreign key constraints
- Frequently queried/filtered fields
- Data requiring complex joins
- Primary business entities

### JSONB Column Definition

```python
from sqlalchemy import Column
from sqlalchemy.dialects.postgresql import JSONB


class User(BaseModel):
    """User with JSONB preferences."""

    __tablename__ = "users"

    # Structured data - regular columns
    email = Column(String(255), nullable=False)

    # Semi-structured data - JSONB
    preferences = Column(
        JSONB,
        nullable=False,
        server_default='{}'
    )
    metadata = Column(JSONB, nullable=True)
```

### JSONB Indexing

```python
from sqlalchemy import Index


class Product(BaseModel):
    """Product with JSONB attributes."""

    __tablename__ = "products"

    name = Column(String(255), nullable=False)
    attributes = Column(JSONB, nullable=False, server_default='{}')

    __table_args__ = (
        # GIN index for general JSONB queries
        Index(
            "ix_products_attributes_gin",
            "attributes",
            postgresql_using="gin"
        ),
        # Specific path index for common queries
        Index(
            "ix_products_attributes_category",
            attributes["category"].astext
        ),
    )
```

### JSONB Queries

```python
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import JSONB

# Query JSONB field
stmt = select(Product).where(
    Product.attributes["category"].astext == "electronics"
)

# Check key exists
stmt = select(Product).where(
    Product.attributes.has_key("color")
)

# Contains value
stmt = select(Product).where(
    Product.attributes.contains({"color": "red"})
)

# Path query
stmt = select(Product).where(
    Product.attributes[("specs", "weight")].astext.cast(Float) < 5.0
)
```

---

## Soft Delete Pattern

### Implementation

```python
from sqlalchemy import Column, DateTime, Boolean, event
from sqlalchemy.orm import declared_attr, Query


class SoftDeleteMixin:
    """Mixin for soft delete functionality."""

    @declared_attr
    def deleted_at(cls):
        return Column(DateTime(timezone=True), nullable=True, index=True)

    @declared_attr
    def is_deleted(cls):
        return Column(Boolean, default=False, nullable=False, index=True)

    def soft_delete(self):
        """Mark record as deleted."""
        self.is_deleted = True
        self.deleted_at = func.now()

    def restore(self):
        """Restore soft-deleted record."""
        self.is_deleted = False
        self.deleted_at = None


class User(BaseModel, SoftDeleteMixin):
    """User with soft delete."""

    __tablename__ = "users"

    email = Column(String(255), nullable=False)
```

### Querying with Soft Delete

```python
from sqlalchemy import select

# Exclude soft-deleted by default
stmt = select(User).where(User.is_deleted == False)  # noqa: E712

# Include soft-deleted
stmt = select(User)

# Only soft-deleted
stmt = select(User).where(User.is_deleted == True)  # noqa: E712
```

---

## Indexing Strategies

### Index Types and When to Use

| Index Type | Use Case | Example |
|------------|----------|---------|
| B-tree (default) | Equality, range queries | `email`, `created_at` |
| Hash | Equality only | `status` (rarely used) |
| GIN | JSONB, arrays, full-text | `attributes`, `tags` |
| GiST | Geometric, full-text | `location`, `search_vector` |
| BRIN | Large sequential data | `created_at` on append-only tables |

### Index Definition

```python
from sqlalchemy import Index


class User(BaseModel):
    """User with various indexes."""

    __tablename__ = "users"

    email = Column(String(255), nullable=False)
    status = Column(String(50), nullable=False)
    organization_id = Column(Integer, ForeignKey("organizations.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        # Single column index
        Index("ix_users_email", "email", unique=True),

        # Composite index (order matters!)
        Index("ix_users_org_status", "organization_id", "status"),

        # Partial index (only active users)
        Index(
            "ix_users_email_active",
            "email",
            postgresql_where=text("status = 'active'")
        ),

        # Expression index
        Index(
            "ix_users_email_lower",
            func.lower(email)
        ),
    )
```

### Index Guidelines

1. **Index foreign keys** - Always index FK columns
2. **Index WHERE clause columns** - Columns frequently filtered
3. **Index ORDER BY columns** - Columns used for sorting
4. **Composite index order** - Most selective column first
5. **Avoid over-indexing** - Each index slows writes

---

## Constraints

### Check Constraints

```python
from sqlalchemy import CheckConstraint


class Order(BaseModel):
    """Order with constraints."""

    __tablename__ = "orders"

    quantity = Column(Integer, nullable=False)
    unit_price = Column(Numeric(10, 2), nullable=False)
    status = Column(String(50), nullable=False)

    __table_args__ = (
        CheckConstraint("quantity > 0", name="ck_orders_quantity_positive"),
        CheckConstraint("unit_price >= 0", name="ck_orders_price_non_negative"),
        CheckConstraint(
            "status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')",
            name="ck_orders_valid_status"
        ),
    )
```

### Unique Constraints

```python
from sqlalchemy import UniqueConstraint


class ProjectMember(BaseModel):
    """Unique constraint example."""

    __tablename__ = "project_members"

    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    project_id = Column(Integer, ForeignKey("projects.id"), nullable=False)

    __table_args__ = (
        # Composite unique constraint
        UniqueConstraint("user_id", "project_id", name="uq_project_members_user_project"),
    )
```

### Foreign Key Actions

```python
from sqlalchemy import ForeignKey

# CASCADE - Delete child when parent deleted
user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))

# SET NULL - Set to NULL when parent deleted
organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="SET NULL"))

# RESTRICT - Prevent parent deletion if children exist
department_id = Column(Integer, ForeignKey("departments.id", ondelete="RESTRICT"))

# SET DEFAULT - Set to default value when parent deleted
status_id = Column(Integer, ForeignKey("statuses.id", ondelete="SET DEFAULT"), server_default="1")
```

---

## PostgreSQL-Specific Features

### Enum Types

```python
from sqlalchemy import Enum
import enum


class UserStatus(str, enum.Enum):
    """User status enum."""
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    PENDING = "pending"


class User(BaseModel):
    """User with enum status."""

    __tablename__ = "users"

    # Option 1: Native PostgreSQL enum
    status = Column(
        Enum(UserStatus, name="user_status", create_type=True),
        nullable=False,
        default=UserStatus.PENDING
    )

    # Option 2: String column with check constraint (simpler migrations)
    # status = Column(String(50), nullable=False, default="pending")
```

### Array Columns

```python
from sqlalchemy.dialects.postgresql import ARRAY


class User(BaseModel):
    """User with array columns."""

    __tablename__ = "users"

    tags = Column(ARRAY(String(50)), nullable=False, server_default='{}')
    permissions = Column(ARRAY(String(100)), nullable=False, server_default='{}')

    __table_args__ = (
        # GIN index for array queries
        Index("ix_users_tags_gin", "tags", postgresql_using="gin"),
    )
```

### Full-Text Search

```python
from sqlalchemy import Column, Index, func
from sqlalchemy.dialects.postgresql import TSVECTOR


class Article(BaseModel):
    """Article with full-text search."""

    __tablename__ = "articles"

    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)

    # Generated search vector column
    search_vector = Column(
        TSVECTOR,
        Computed(
            "to_tsvector('english', coalesce(title, '') || ' ' || coalesce(content, ''))",
            persisted=True
        )
    )

    __table_args__ = (
        Index("ix_articles_search", "search_vector", postgresql_using="gin"),
    )
```

---

## Entity-Relationship Diagram Example

```mermaid
erDiagram
    ORGANIZATIONS ||--o{ USERS : "has many"
    USERS ||--o{ POSTS : "authors"
    USERS }o--o{ ROLES : "has many"
    USERS ||--o{ PROJECT_MEMBERS : "participates"
    PROJECTS ||--o{ PROJECT_MEMBERS : "has"
    CATEGORIES ||--o{ CATEGORIES : "parent of"
```

---

## Anti-Patterns to Avoid

### ❌ Entity-Attribute-Value (EAV)

```sql
-- DON'T: EAV pattern
CREATE TABLE attributes (
    entity_id INT,
    attribute_name VARCHAR(255),
    attribute_value TEXT
);

-- DO: Use JSONB or proper columns
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    attributes JSONB
);
```

### ❌ Polymorphic Associations Without Discriminator

```python
# DON'T: Ambiguous foreign key
class Comment(BaseModel):
    commentable_id = Column(Integer)  # Could be post, article, or video
    commentable_type = Column(String)  # Required but often forgotten

# DO: Explicit relationships or separate tables
class PostComment(BaseModel):
    post_id = Column(Integer, ForeignKey("posts.id"))

class ArticleComment(BaseModel):
    article_id = Column(Integer, ForeignKey("articles.id"))
```

### ❌ Over-Normalization

```python
# DON'T: Separate table for single value
class UserEmail(BaseModel):
    user_id = Column(Integer, ForeignKey("users.id"))
    email = Column(String(255))  # Only ever one per user

# DO: Column on main table
class User(BaseModel):
    email = Column(String(255), unique=True)
```

---

## Related Patterns

For implementation approaches and code examples:

- [Schema Patterns](../../patterns/database/schema-patterns.md) - Base models, relationships, JSONB, soft delete, indexing
- [Database Examples](../../examples/database/) - Filled implementations

## Related Standards

- [Database Naming Conventions](./naming-conventions.md)
- [Database Migrations](./migrations.md)
- [Backend Tech Stack](../backend/tech-stack.md)
- [Backend Python Standards](../backend/python.md)

---

*Well-designed schemas are the foundation of performant, maintainable applications.*

---

<!-- Source: standards/database/migrations.md (v1.0.3) -->

# Database Migrations Standard

**Status**: Active

## Purpose

This standard defines patterns and best practices for database migrations using Alembic with SQLAlchemy 2.0+ and PostgreSQL 16+.

## Scope

- Migration file organization
- Auto-generation vs manual migrations
- Data migrations
- Rollback strategies
- Production deployment patterns

---

## Migration Tool: Alembic

### Installation and Setup

```bash
# Install with uv
uv add alembic

# Initialize Alembic
alembic init alembic
```

### Directory Structure

```
project/
├── alembic/
│   ├── versions/              # Migration files
│   │   ├── 001_initial_schema.py
│   │   ├── 002_add_users_table.py
│   │   └── 003_add_user_email_index.py
│   ├── env.py                 # Alembic environment configuration
│   ├── script.py.mako         # Migration template
│   └── README                  # Alembic documentation
├── alembic.ini                # Alembic configuration
└── app/
    └── models/                # SQLAlchemy models
```

### Configuration (alembic.ini)

```ini
[alembic]
script_location = alembic
prepend_sys_path = .
version_path_separator = os

# Use async driver
sqlalchemy.url = postgresql+asyncpg://user:password@localhost/dbname

[post_write_hooks]
hooks = ruff_format
ruff_format.type = exec
ruff_format.executable = ruff
ruff_format.options = format REVISION_SCRIPT_FILENAME

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
```

### Environment Configuration (env.py)

```python
"""Alembic environment configuration for async SQLAlchemy."""

import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from app.core.config import settings
from app.db.base import Base
from app.models import *  # noqa: Import all models for autogenerate

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def get_url() -> str:
    """Get database URL from settings."""
    return settings.DATABASE_URL


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = get_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    """Run migrations with connection."""
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Run migrations in async mode."""
    configuration = config.get_section(config.config_ini_section, {})
    configuration["sqlalchemy.url"] = get_url()

    connectable = async_engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

---

## Migration File Naming

### Convention

```
{revision}_{description}.py

Examples:
001_initial_schema.py
002_create_users_table.py
003_add_email_index_to_users.py
004_add_organization_id_to_users.py
005_migrate_legacy_roles_data.py
```

### Naming Rules

| Type | Prefix | Example |
|------|--------|---------|
| Schema creation | `create_` | `create_users_table` |
| Column addition | `add_` | `add_email_to_users` |
| Column removal | `remove_` | `remove_legacy_field` |
| Index creation | `add_index_` | `add_index_on_users_email` |
| Data migration | `migrate_` | `migrate_user_roles_data` |
| Constraint | `add_constraint_` | `add_constraint_users_email_unique` |

---

## Auto-Generation vs Manual Migrations

### When to Use Auto-Generation

✅ **Use autogenerate for:**
- Adding new tables
- Adding/removing columns
- Adding/removing indexes
- Adding/removing foreign keys
- Changing column types (with caution)

```bash
# Generate migration from model changes
alembic revision --autogenerate -m "add_users_table"
```

### When to Write Manual Migrations

✅ **Write manual migrations for:**
- Data migrations (transforming existing data)
- Complex schema changes
- Renaming columns/tables (autogenerate detects as drop+add)
- Custom SQL operations
- Stored procedures/functions
- Triggers

```bash
# Create empty migration for manual editing
alembic revision -m "migrate_legacy_data"
```

### Autogenerate Limitations

Alembic autogenerate **cannot detect**:
- Table or column renames (appears as drop + create)
- Changes to column order
- Anonymous constraints
- Some CHECK constraints
- Stored procedures, triggers, functions

---

## Migration Patterns

### Basic Table Creation

```python
"""Create users table.

Revision ID: 001
Revises:
Create Date: 2025-12-30 10:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("full_name", sa.String(255), nullable=True),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("is_superuser", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email"),
    )
    op.create_index("ix_users_email", "users", ["email"])


def downgrade() -> None:
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
```

### Adding Columns

```python
"""Add organization_id to users.

Revision ID: 004
Revises: 003
"""

from alembic import op
import sqlalchemy as sa


def upgrade() -> None:
    # Add column as nullable first
    op.add_column(
        "users",
        sa.Column("organization_id", sa.Integer(), nullable=True)
    )

    # Add foreign key constraint
    op.create_foreign_key(
        "fk_users_organization_id",
        "users",
        "organizations",
        ["organization_id"],
        ["id"],
        ondelete="SET NULL"
    )

    # Add index for foreign key
    op.create_index("ix_users_organization_id", "users", ["organization_id"])


def downgrade() -> None:
    op.drop_index("ix_users_organization_id", table_name="users")
    op.drop_constraint("fk_users_organization_id", "users", type_="foreignkey")
    op.drop_column("users", "organization_id")
```

### Renaming Columns (Manual Required)

```python
"""Rename user name column.

Revision ID: 005
Revises: 004
"""

from alembic import op


def upgrade() -> None:
    # Rename column - must be done manually
    op.alter_column(
        "users",
        "full_name",
        new_column_name="display_name"
    )


def downgrade() -> None:
    op.alter_column(
        "users",
        "display_name",
        new_column_name="full_name"
    )
```

### Data Migration

```python
"""Migrate legacy role data.

Revision ID: 006
Revises: 005
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import table, column


def upgrade() -> None:
    # Define table reference for data operations
    users = table(
        "users",
        column("id", sa.Integer),
        column("role", sa.String),
        column("is_admin", sa.Boolean),
    )

    # Migrate data: set role based on is_admin flag
    op.execute(
        users.update()
        .where(users.c.is_admin == True)  # noqa: E712
        .values(role="admin")
    )

    op.execute(
        users.update()
        .where(users.c.is_admin == False)  # noqa: E712
        .values(role="user")
    )

    # After data migration, make column non-nullable
    op.alter_column(
        "users",
        "role",
        nullable=False,
        server_default="user"
    )


def downgrade() -> None:
    op.alter_column(
        "users",
        "role",
        nullable=True,
        server_default=None
    )
```

### Batch Operations for SQLite Compatibility

```python
"""Add constraint with batch mode.

Useful for SQLite or complex alterations.
"""

from alembic import op
import sqlalchemy as sa


def upgrade() -> None:
    # Batch mode recreates table - use for SQLite
    with op.batch_alter_table("users") as batch_op:
        batch_op.add_column(sa.Column("phone", sa.String(20)))
        batch_op.alter_column("email", nullable=False)
        batch_op.create_unique_constraint("uq_users_phone", ["phone"])


def downgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_constraint("uq_users_phone", type_="unique")
        batch_op.alter_column("email", nullable=True)
        batch_op.drop_column("phone")
```

---

## Rollback Strategies

### Development Rollback

```bash
# Downgrade one revision
alembic downgrade -1

# Downgrade to specific revision
alembic downgrade 003

# Downgrade to base (empty database)
alembic downgrade base

# Show current revision
alembic current

# Show migration history
alembic history --verbose
```

### Production Rollback Principles

1. **Always test rollbacks** in staging before production
2. **Data migrations may be irreversible** - plan accordingly
3. **Use transactions** - migrations run in transactions by default
4. **Have a backup** before running migrations

### Irreversible Migrations

```python
"""Drop legacy columns - IRREVERSIBLE.

Revision ID: 010
"""

from alembic import op
import sqlalchemy as sa


def upgrade() -> None:
    # WARNING: This migration drops data and cannot be fully reversed
    op.drop_column("users", "legacy_field")


def downgrade() -> None:
    # Cannot restore data - only recreate column structure
    op.add_column(
        "users",
        sa.Column("legacy_field", sa.String(255), nullable=True)
    )
    # NOTE: Original data is lost
```

---

## Production Deployment

### Pre-Deployment Checklist

- [ ] Migrations tested in staging environment
- [ ] Rollback procedure tested
- [ ] Database backup completed
- [ ] Maintenance window scheduled (if needed)
- [ ] Team notified of deployment

### Deployment Commands

```bash
# Check current state
alembic current

# Show pending migrations
alembic history --indicate-current

# Run all pending migrations
alembic upgrade head

# Run migrations to specific version
alembic upgrade 005
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Run database migrations
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
  run: |
    uv run alembic upgrade head
```

### Zero-Downtime Migrations

For zero-downtime deployments, follow this pattern:

1. **Add new columns as nullable** (backward compatible)
2. **Deploy new code** that writes to both old and new columns
3. **Backfill data** to new columns
4. **Deploy code** that reads from new columns
5. **Add constraints** (NOT NULL, etc.)
6. **Remove old columns** (cleanup migration)

```python
# Step 1: Add nullable column
def upgrade() -> None:
    op.add_column("users", sa.Column("new_email", sa.String(255), nullable=True))

# Step 3: Backfill (separate migration)
def upgrade() -> None:
    op.execute("UPDATE users SET new_email = email WHERE new_email IS NULL")

# Step 5: Add constraint (separate migration)
def upgrade() -> None:
    op.alter_column("users", "new_email", nullable=False)
    op.create_unique_constraint("uq_users_new_email", "users", ["new_email"])

# Step 6: Remove old column (separate migration)
def upgrade() -> None:
    op.drop_column("users", "email")
    op.alter_column("users", "new_email", new_column_name="email")
```

---

## Migration Testing

### Unit Testing Migrations

```python
"""Test migrations up and down."""

import pytest
from alembic import command
from alembic.config import Config


@pytest.fixture
def alembic_config():
    """Get Alembic configuration."""
    config = Config("alembic.ini")
    return config


def test_migrations_up_down(alembic_config, test_database):
    """Test that all migrations can be applied and rolled back."""
    # Upgrade to head
    command.upgrade(alembic_config, "head")

    # Downgrade to base
    command.downgrade(alembic_config, "base")

    # Upgrade again to verify clean state
    command.upgrade(alembic_config, "head")


def test_migration_idempotency(alembic_config, test_database):
    """Test that running upgrade multiple times is safe."""
    command.upgrade(alembic_config, "head")
    command.upgrade(alembic_config, "head")  # Should be no-op
```

---

## Common Issues and Solutions

### Issue: Autogenerate Detects False Changes

```python
# In env.py, add compare filters
def include_object(object, name, type_, reflected, compare_to):
    """Filter objects from autogenerate."""
    # Ignore specific tables
    if type_ == "table" and name in ["alembic_version", "spatial_ref_sys"]:
        return False
    return True

context.configure(
    # ...
    include_object=include_object,
)
```

### Issue: Circular Dependencies

```python
# Use depends_on for explicit ordering
depends_on: Union[str, Sequence[str], None] = ("002", "003")
```

### Issue: Long-Running Migrations

```python
# Add lock timeout for safety
def upgrade() -> None:
    op.execute("SET lock_timeout = '10s'")
    # ... migration operations
```

---

## Related Standards

- [Database Naming Conventions](./naming-conventions.md)
- [Database Schema Design](./schema-design.md)
- [Backend Tech Stack](../backend/tech-stack.md)
- [CI/CD Workflows](../devops/ci-cd.md)

---

*Properly managed migrations ensure database changes are trackable, reversible, and safely deployable to production.*

---

<!-- Source: standards/database/performance.md (v1.0.0) -->

# Database Performance Standards

**Status**: Active

## Overview

This document establishes standards for PostgreSQL database performance optimization, including indexing strategies, query optimization, and performance monitoring.

## Quick Reference

| Optimization | When to Apply | Impact |
|--------------|---------------|--------|
| B-tree index | Equality, range queries | High |
| Covering index | Frequently accessed columns | Medium |
| Partial index | Subset of rows queried | Medium |
| Connection pooling | High concurrency | High |
| Query optimization | Slow queries (>100ms) | High |

## Query Analysis

### Using EXPLAIN ANALYZE

Always analyze slow queries with `EXPLAIN ANALYZE`:

```sql
-- Basic analysis
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE user_id = 123
  AND created_at > '2024-01-01';

-- With buffers and timing
EXPLAIN (ANALYZE, BUFFERS, TIMING, FORMAT TEXT)
SELECT o.*, u.email
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.status = 'pending';
```

### Reading EXPLAIN Output

```sql
-- Example output
Nested Loop  (cost=0.43..16.49 rows=1 width=100) (actual time=0.025..0.027 rows=1 loops=1)
  ->  Index Scan using orders_user_id_idx on orders o  (cost=0.29..8.31 rows=1 width=50) (actual time=0.015..0.016 rows=1 loops=1)
        Index Cond: (user_id = 123)
  ->  Index Scan using users_pkey on users u  (cost=0.14..8.16 rows=1 width=50) (actual time=0.008..0.008 rows=1 loops=1)
        Index Cond: (id = o.user_id)
Planning Time: 0.150 ms
Execution Time: 0.050 ms
```

Key metrics to check:
- **Seq Scan** on large tables = needs index
- **actual rows** >> **rows** = outdated statistics
- **loops** > 1 with high count = N+1 problem
- **Execution Time** > 100ms = needs optimization

### Identifying Problem Queries

```sql
-- Find slowest queries (requires pg_stat_statements)
SELECT
    calls,
    round(total_exec_time::numeric, 2) as total_ms,
    round(mean_exec_time::numeric, 2) as mean_ms,
    round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 2) as percentage,
    substring(query, 1, 100) as query_preview
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Find queries with high I/O
SELECT
    query,
    shared_blks_hit,
    shared_blks_read,
    round(100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0), 2) as cache_hit_ratio
FROM pg_stat_statements
WHERE shared_blks_read > 1000
ORDER BY shared_blks_read DESC
LIMIT 10;
```

## Indexing Strategies

### B-Tree Indexes (Default)

Use for equality and range queries:

```sql
-- Single column index
CREATE INDEX idx_users_email ON users(email);

-- Composite index (order matters!)
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);

-- Unique index
CREATE UNIQUE INDEX idx_users_email_unique ON users(email);
```

### Index Column Order

For composite indexes, order columns by:
1. Equality conditions first (`WHERE status = 'active'`)
2. Range conditions second (`WHERE created_at > '2024-01-01'`)
3. Sort columns last (`ORDER BY name`)

```sql
-- Query pattern
SELECT * FROM orders
WHERE user_id = 123
  AND status = 'pending'
  AND created_at > '2024-01-01'
ORDER BY created_at DESC;

-- Optimal index
CREATE INDEX idx_orders_lookup
ON orders(user_id, status, created_at DESC);
```

### Covering Indexes

Include frequently accessed columns to avoid table lookups:

```sql
-- Instead of fetching from table
CREATE INDEX idx_orders_user
ON orders(user_id)
INCLUDE (status, total_amount, created_at);

-- Query can be satisfied entirely from index
SELECT status, total_amount, created_at
FROM orders
WHERE user_id = 123;
```

### Partial Indexes

Index only relevant rows:

```sql
-- Only index active users
CREATE INDEX idx_users_email_active
ON users(email)
WHERE is_active = true;

-- Only index recent orders
CREATE INDEX idx_orders_pending
ON orders(created_at DESC)
WHERE status = 'pending';
```

### GIN Indexes for Arrays/JSONB

```sql
-- JSONB containment queries
CREATE INDEX idx_users_metadata
ON users USING GIN(metadata jsonb_path_ops);

-- Query
SELECT * FROM users
WHERE metadata @> '{"role": "admin"}';

-- Array contains
CREATE INDEX idx_posts_tags
ON posts USING GIN(tags);

-- Query
SELECT * FROM posts
WHERE tags @> ARRAY['python', 'fastapi'];
```

### Index Maintenance

```sql
-- Check index usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- Find unused indexes
SELECT
    schemaname || '.' || relname AS table,
    indexrelname AS index,
    pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
    idx_scan as index_scans
FROM pg_stat_user_indexes ui
JOIN pg_index i ON ui.indexrelid = i.indexrelid
WHERE NOT indisunique
  AND idx_scan < 50
  AND pg_relation_size(i.indexrelid) > 1024 * 1024
ORDER BY pg_relation_size(i.indexrelid) DESC;

-- Rebuild bloated indexes
REINDEX INDEX CONCURRENTLY idx_orders_user_created;
```

## Query Optimization

### N+1 Query Prevention

**Problem:**
```python
# Bad - N+1 queries
users = await db.execute(select(User))
for user in users.scalars():
    orders = await db.execute(
        select(Order).where(Order.user_id == user.id)
    )  # N additional queries!
```

**Solution - Eager Loading:**
```python
# Good - Single query with join
from sqlalchemy.orm import selectinload, joinedload

# For one-to-many: selectinload (separate IN query)
stmt = select(User).options(selectinload(User.orders))
result = await db.execute(stmt)

# For many-to-one: joinedload (single JOIN)
stmt = select(Order).options(joinedload(Order.user))
result = await db.execute(stmt)
```

### Pagination Optimization

**Offset-based (avoid for large offsets):**
```sql
-- Slow for large offsets
SELECT * FROM orders
ORDER BY created_at DESC
LIMIT 20 OFFSET 10000;  -- Scans 10020 rows!
```

**Cursor-based (preferred):**
```sql
-- Fast - uses index
SELECT * FROM orders
WHERE created_at < '2024-01-15T10:30:00'
ORDER BY created_at DESC
LIMIT 20;
```

**Implementation:**
```python
from datetime import datetime
from typing import Optional

async def get_orders_paginated(
    db: AsyncSession,
    cursor: Optional[datetime] = None,
    limit: int = 20
) -> list[Order]:
    """Cursor-based pagination for orders."""
    stmt = select(Order).order_by(Order.created_at.desc()).limit(limit)

    if cursor:
        stmt = stmt.where(Order.created_at < cursor)

    result = await db.execute(stmt)
    return list(result.scalars())


# Next page cursor is last item's created_at
orders = await get_orders_paginated(db, cursor=last_order.created_at)
```

### Batch Operations

```python
# Bad - Individual inserts
for item in items:
    db.add(Order(**item))
    await db.commit()  # N commits!

# Good - Batch insert
from sqlalchemy.dialects.postgresql import insert

stmt = insert(Order).values(items)
await db.execute(stmt)
await db.commit()  # Single commit

# Good - Bulk update
stmt = (
    update(Order)
    .where(Order.id.in_([1, 2, 3, 4, 5]))
    .values(status="shipped")
)
await db.execute(stmt)
```

### Avoiding SELECT *

```python
# Bad - fetches all columns
stmt = select(User)

# Good - fetch only needed columns
stmt = select(User.id, User.email, User.name)

# Or use load_only
from sqlalchemy.orm import load_only

stmt = select(User).options(load_only(User.id, User.email, User.name))
```

## Connection Pooling

### SQLAlchemy Async Pool Configuration

```python
from sqlalchemy.ext.asyncio import create_async_engine

engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,           # Base pool size
    max_overflow=10,        # Additional connections allowed
    pool_timeout=30,        # Wait time for connection
    pool_recycle=1800,      # Recycle connections after 30 min
    pool_pre_ping=True,     # Verify connection before use
    echo=False,             # Disable SQL logging in production
)
```

### Monitoring Pool Health

```python
from sqlalchemy import event
from sqlalchemy.pool import Pool
import logging

logger = logging.getLogger(__name__)

@event.listens_for(Pool, "checkout")
def receive_checkout(dbapi_connection, connection_record, connection_proxy):
    """Log connection checkout for monitoring."""
    logger.debug(f"Connection checked out: {id(dbapi_connection)}")

@event.listens_for(Pool, "checkin")
def receive_checkin(dbapi_connection, connection_record):
    """Log connection checkin for monitoring."""
    logger.debug(f"Connection checked in: {id(dbapi_connection)}")

# Expose pool stats as metrics
def get_pool_stats(engine) -> dict:
    pool = engine.pool
    return {
        "pool_size": pool.size(),
        "checked_out": pool.checkedout(),
        "overflow": pool.overflow(),
        "checked_in": pool.checkedin(),
    }
```

### PgBouncer for High Concurrency

```ini
; pgbouncer.ini
[databases]
myapp = host=localhost port=5432 dbname=myapp

[pgbouncer]
listen_port = 6432
listen_addr = 0.0.0.0

; Pool mode
pool_mode = transaction  ; Best for web apps

; Connection limits
max_client_conn = 1000
default_pool_size = 25
min_pool_size = 5
reserve_pool_size = 5

; Timeouts
server_idle_timeout = 600
client_idle_timeout = 0
```

## Table Partitioning

### Range Partitioning (Time-Based)

```sql
-- Create partitioned table
CREATE TABLE events (
    id BIGSERIAL,
    event_type VARCHAR(50),
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL
) PARTITION BY RANGE (created_at);

-- Create monthly partitions
CREATE TABLE events_2024_01 PARTITION OF events
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE events_2024_02 PARTITION OF events
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Automate partition creation with pg_partman
CREATE EXTENSION pg_partman;

SELECT partman.create_parent(
    p_parent_table := 'public.events',
    p_control := 'created_at',
    p_type := 'native',
    p_interval := 'monthly',
    p_premake := 3
);
```

### Partition Maintenance

```sql
-- Drop old partitions
DROP TABLE events_2023_01;

-- Detach partition for archival
ALTER TABLE events DETACH PARTITION events_2023_12;

-- Move to archive schema
ALTER TABLE events_2023_12 SET SCHEMA archive;
```

## Statistics and Maintenance

### ANALYZE for Query Planner

```sql
-- Analyze single table
ANALYZE users;

-- Analyze entire database
ANALYZE;

-- Check table statistics
SELECT
    schemaname,
    relname,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

### VACUUM Configuration

```sql
-- Check autovacuum settings
SHOW autovacuum;
SHOW autovacuum_vacuum_scale_factor;
SHOW autovacuum_analyze_scale_factor;

-- Tune for high-update tables
ALTER TABLE orders SET (
    autovacuum_vacuum_scale_factor = 0.05,
    autovacuum_analyze_scale_factor = 0.02
);
```

### Table Bloat Detection

```sql
-- Check table bloat
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname || '.' || tablename)) as table_size,
    pg_size_pretty(pg_indexes_size(schemaname || '.' || tablename)) as index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC;
```

## Caching Strategies

### Application-Level Caching

```python
from redis import Redis
from functools import wraps
import json
import hashlib

redis = Redis(host='localhost', port=6379, db=0)

def cached(ttl: int = 300):
    """Cache function results in Redis."""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Generate cache key
            key_data = f"{func.__name__}:{args}:{kwargs}"
            cache_key = hashlib.sha256(key_data.encode()).hexdigest()

            # Try cache
            cached_result = await redis.get(cache_key)
            if cached_result:
                return json.loads(cached_result)

            # Execute and cache
            result = await func(*args, **kwargs)
            await redis.setex(
                cache_key,
                ttl,
                json.dumps(result, default=str)
            )

            return result
        return wrapper
    return decorator


@cached(ttl=60)
async def get_user_stats(user_id: int) -> dict:
    """Get user statistics (cached for 60s)."""
    # Expensive query
    result = await db.execute(...)
    return result
```

### Materialized Views

```sql
-- Create materialized view for expensive aggregations
CREATE MATERIALIZED VIEW monthly_sales_summary AS
SELECT
    date_trunc('month', created_at) as month,
    product_id,
    SUM(quantity) as total_quantity,
    SUM(total_amount) as total_revenue,
    COUNT(*) as order_count
FROM orders
WHERE status = 'completed'
GROUP BY 1, 2;

-- Create index on materialized view
CREATE INDEX idx_monthly_sales_product
ON monthly_sales_summary(product_id, month DESC);

-- Refresh (blocking)
REFRESH MATERIALIZED VIEW monthly_sales_summary;

-- Refresh concurrently (requires unique index)
CREATE UNIQUE INDEX idx_monthly_sales_unique
ON monthly_sales_summary(month, product_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_sales_summary;
```

## Performance Monitoring

### Key Metrics to Monitor

```sql
-- Database size
SELECT pg_size_pretty(pg_database_size(current_database()));

-- Table sizes
SELECT
    relname as table_name,
    pg_size_pretty(pg_total_relation_size(relid)) as total_size,
    pg_size_pretty(pg_relation_size(relid)) as data_size,
    pg_size_pretty(pg_indexes_size(relid)) as index_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- Cache hit ratio (should be > 99%)
SELECT
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as cache_hit_ratio
FROM pg_statio_user_tables;

-- Index hit ratio (should be > 95%)
SELECT
    sum(idx_blks_hit) / (sum(idx_blks_hit) + sum(idx_blks_read)) as index_hit_ratio
FROM pg_statio_user_indexes;

-- Active connections
SELECT
    state,
    count(*)
FROM pg_stat_activity
GROUP BY state;

-- Long-running queries
SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query,
    state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes'
  AND state != 'idle';
```

### Prometheus Metrics

```yaml
# postgres_exporter queries
pg_stat_user_tables:
  query: |
    SELECT schemaname, relname,
           seq_scan, seq_tup_read,
           idx_scan, idx_tup_fetch,
           n_tup_ins, n_tup_upd, n_tup_del,
           n_live_tup, n_dead_tup
    FROM pg_stat_user_tables
  metrics:
    - schemaname:
        usage: "LABEL"
    - relname:
        usage: "LABEL"
    - seq_scan:
        usage: "COUNTER"
    - idx_scan:
        usage: "COUNTER"
```

## Best Practices Checklist

### Before Deployment

- [ ] All foreign keys have indexes
- [ ] Queries use appropriate indexes (verified with EXPLAIN)
- [ ] No N+1 queries in common paths
- [ ] Pagination uses cursor-based approach for large datasets
- [ ] Connection pool properly sized
- [ ] Statistics are up to date

### Ongoing Maintenance

- [ ] Monitor slow query log weekly
- [ ] Check for unused indexes monthly
- [ ] Review table bloat monthly
- [ ] Validate cache hit ratios
- [ ] Audit connection pool usage

## References

- [PostgreSQL EXPLAIN Documentation](https://www.postgresql.org/docs/current/sql-explain.html)
- [PostgreSQL Index Types](https://www.postgresql.org/docs/current/indexes-types.html)
- [SQLAlchemy Performance](https://docs.sqlalchemy.org/en/20/faq/performance.html)
- [Use The Index, Luke](https://use-the-index-luke.com/)

---

*For schema design standards, see [schema-design.md](./schema-design.md). For migration patterns, see [migrations.md](./migrations.md).*

---

<!-- Source: standards/database/multi-tenancy.md (v1.0.1) -->

# Multi-Tenancy Isolation Standard

**Status**: Active

## Overview

Multi-tenant applications serve multiple customers (tenants) from a single
deployment. The most common — and most dangerous — failure mode is a
single missing `WHERE tenant_id = :tid` clause that leaks data between
tenants. This standard mandates the isolation strategy and the layered
defenses that make such leaks structurally impossible rather than relying
on developer discipline.

This standard applies to every backend application that holds data for
more than one customer. If the system serves a single organization with
no tenant boundary, this standard does not apply.

## Strategy Selection

Three canonical strategies exist. Pick exactly one as the default and
document deviations explicitly.

| Strategy | Isolation | Ops complexity | Query overhead | Blast radius of bug | When to choose |
|---|---|---|---|---|---|
| **Row-level** (single shared DB, `tenant_id` column on every row) | Logical | Low | Low (indexed predicate) | One bad query → all tenants | **Default.** SaaS with many small/medium tenants and no regulatory hard-isolation requirement. |
| **Schema-per-tenant** (one DB, one PostgreSQL schema per tenant) | Stronger logical | Medium (per-tenant migrations) | Low | One bad `search_path` → one tenant | Tenants with custom data models, mid-size enterprise SaaS. |
| **Database-per-tenant** (one PostgreSQL database per tenant) | Physical | High (N migrations, N backups, N pools) | None | Catastrophic failure contained to one tenant | Regulated data (HIPAA/PCI), large enterprise customers, contractual hard-isolation. |

**Default mandate:** row-level isolation. The remainder of this standard
specifies the row-level pattern in normative detail. Schema- and
database-per-tenant deployments inherit the same defense-in-depth
principles and are documented as escape hatches in §Escape Hatches below.

## Row-Level Isolation — Required Pattern

The row-level pattern uses three layers, each of which independently
enforces tenant scope. A bug in one layer must not allow cross-tenant
reads or writes.

### Layer 1 — Schema

Every tenant-scoped table MUST have a non-null `tenant_id UUID` foreign
key to the `tenants` table, indexed on `(tenant_id, ...)` for the most
common query patterns.

```python
from sqlalchemy import ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[uuid.UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, default=uuid4
    )

    # Tenant FK — required, non-null, indexed.
    tenant_id: Mapped[uuid.UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    # ... other columns ...

    __table_args__ = (
        # Composite index keyed on tenant_id first
        Index("ix_orders_tenant_status", "tenant_id", "status"),
    )
```

Rules:

1. `tenant_id` is `nullable=False`. Never store global-tenant rows in
   tenant-scoped tables.
2. `ondelete="RESTRICT"` — deleting a tenant must require explicit
   account-closure tooling, never cascade-delete a live tenant.
3. The first column of any composite index on a tenant-scoped table is
   `tenant_id`. The query planner needs the predicate available cheaply.
4. The `tenants` table itself is NOT tenant-scoped (it is the registry).
   Treat it as global; access is restricted to admin / control-plane code.

### Layer 2 — PostgreSQL Row-Level Security

Every tenant-scoped table MUST enable RLS and define policies for
`SELECT`, `INSERT`, `UPDATE`, and `DELETE` keyed on a session-local
`app.tenant_id` setting.

```sql
-- alembic migration
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders FORCE ROW LEVEL SECURITY;  -- applies to table owner too

CREATE POLICY orders_tenant_isolation ON orders
  USING (tenant_id = current_setting('app.tenant_id')::uuid)
  WITH CHECK (tenant_id = current_setting('app.tenant_id')::uuid);
```

Rules:

1. `FORCE ROW LEVEL SECURITY` — without this, the table owner (often the
   migration user) bypasses RLS, defeating the layer.
2. Use `current_setting('app.tenant_id')::uuid` — the setting is set
   per-transaction by Layer 3. Do NOT rely on `current_user`; the
   application connects as a single role.
3. Both `USING` (read filter) and `WITH CHECK` (write filter) clauses
   are required so an `UPDATE` cannot move a row into another tenant.
4. Privileged maintenance code (analytics jobs, support tooling) that
   legitimately spans tenants connects with a separate role that has
   `BYPASSRLS` and is audited. Application code MUST NOT use that role.

### Layer 3 — Per-Request Tenant Scoping

A FastAPI middleware reads the active tenant from the JWT, anchors it to
`request.state.tenant_id` (parallel to `request.state.request_id` from
[request-middleware.md](../backend/request-middleware.md)), and runs
`SET LOCAL app.tenant_id` on the SQLAlchemy session at the start of each
request.

```python
# app/middleware/tenancy.py
from typing import Awaitable, Callable

from fastapi import Request, Response
from sqlalchemy import text
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.auth import extract_tenant_id_from_token
from app.core.exceptions import UnauthorizedException
from app.db.session import async_session_factory


class TenancyMiddleware(BaseHTTPMiddleware):
    """Set app.tenant_id on the DB session for the lifetime of the request."""

    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]],
    ) -> Response:
        # Public routes do not require a tenant scope.
        if request.url.path.startswith(("/api/public", "/healthz", "/readyz")):
            return await call_next(request)

        tenant_id = extract_tenant_id_from_token(request)
        if tenant_id is None:
            raise UnauthorizedException("Missing tenant claim")

        request.state.tenant_id = tenant_id

        async with async_session_factory() as session:
            # SET LOCAL is scoped to the current transaction; bind the
            # session to the request so downstream code reuses it.
            await session.execute(
                text("SET LOCAL app.tenant_id = :tid"),
                {"tid": str(tenant_id)},
            )
            request.state.db = session
            return await call_next(request)
```

Rules:

1. The middleware runs after authentication. The tenant claim MUST come
   from a verified JWT, never from a request header or query parameter
   that the client controls.
2. `SET LOCAL` (not `SET`) — the value resets at end of transaction, so
   a connection returned to the pool cannot leak tenant scope to the
   next request.
3. `request.state.tenant_id` is the canonical name for downstream
   handlers and observability. Log it on every request alongside
   `request_id` (see [observability.md](../architecture/observability.md)).
4. The `CurrentUser` returned by `get_current_user` MUST also expose
   `tenant_id` (see [auth-guard.md](../backend/auth-guard.md)) so
   handlers and dependencies can use it without re-decoding the JWT.

### Layer 4 — Application-Layer Defense in Depth

Even with RLS, application queries SHOULD include an explicit
`WHERE tenant_id = :tid` clause. RLS is the safety net; the explicit
filter is the visible contract.

```python
# Explicit filter — preferred shape
async def list_orders_for_user(
    db: AsyncSession,
    *,
    tenant_id: uuid.UUID,
    user_id: uuid.UUID,
) -> list[Order]:
    stmt = (
        select(Order)
        .where(Order.tenant_id == tenant_id)
        .where(Order.created_by_id == user_id)
    )
    return list((await db.scalars(stmt)).all())
```

For codebases with many query sites, a SQLAlchemy ORM event hook MAY
inject the predicate automatically. If used, the hook MUST be tested
against every tenant-scoped table; opaque enforcement is acceptable only
when paired with explicit tests that prove it fires.

## Cross-Tenant Access Attempts

When a request authenticated as tenant A attempts to read or mutate a
resource belonging to tenant B (e.g., by guessing a UUID), the response
MUST be `403 Forbidden` with the RFC 9457 problem type
`/problems/forbidden`. This is the same response as a within-tenant
authorization failure — do NOT return `404 Not Found` to obscure
existence (existence is already obscured by the unguessable UUID; see
[F-024 PK strategy](../database/schema-design.md)).

```python
from app.core.exceptions import ForbiddenException

async def get_order(order_id: uuid.UUID, current_user: CurrentUser) -> Order:
    order = await order_crud.get(db, id=order_id)
    if order is None or order.tenant_id != current_user.tenant_id:
        raise ForbiddenException("Order not found in this tenant")
    return order
```

The `ForbiddenException` shape is defined in
[error-handling.md](../backend/error-handling.md). Both the not-found
and the cross-tenant case map to 403 because exposing the difference
is itself a side-channel leak.

## Migrations

Alembic migrations that create a tenant-scoped table MUST include the
RLS policy in the same revision. Splitting them across revisions opens
a window during which the table exists without isolation.

```python
# alembic/versions/2026_05_19_add_orders.py
def upgrade() -> None:
    op.create_table(
        "orders",
        sa.Column("id", PG_UUID(as_uuid=True), primary_key=True),
        sa.Column("tenant_id", PG_UUID(as_uuid=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["tenant_id"], ["tenants.id"], ondelete="RESTRICT"
        ),
        # ... other columns ...
    )
    op.create_index("ix_orders_tenant_id", "orders", ["tenant_id"])

    op.execute("ALTER TABLE orders ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE orders FORCE ROW LEVEL SECURITY")
    op.execute(
        "CREATE POLICY orders_tenant_isolation ON orders "
        "USING (tenant_id = current_setting('app.tenant_id')::uuid) "
        "WITH CHECK (tenant_id = current_setting('app.tenant_id')::uuid)"
    )
```

A migration review check (CI guardrail) MUST refuse a migration that
creates a tenant-scoped table without the matching RLS policy. The
review can grep the diff for `nullable=False` on a `tenant_id` column
and require a `CREATE POLICY` in the same revision.

## Testing

Every API integration test MUST run with at least two tenants and assert
no cross-bleed. The minimum test for any new tenant-scoped endpoint:

```python
# tests/integration/test_orders.py
async def test_order_endpoint_isolates_tenants(
    client_factory,
    seeded_orders_two_tenants,
) -> None:
    """A GET /orders as tenant A returns ONLY tenant A's orders."""
    tenant_a, tenant_b, orders_a, orders_b = seeded_orders_two_tenants

    async with client_factory(tenant=tenant_a) as client:
        response = await client.get("/orders")
        assert response.status_code == 200
        ids = {o["id"] for o in response.json()["items"]}
        assert ids == {str(o.id) for o in orders_a}
        assert not any(str(o.id) in ids for o in orders_b)


async def test_order_get_by_id_rejects_cross_tenant(
    client_factory,
    seeded_orders_two_tenants,
) -> None:
    """Tenant A asking for tenant B's order ID gets 403, not 200 or 404."""
    tenant_a, _, _, orders_b = seeded_orders_two_tenants
    cross_id = orders_b[0].id

    async with client_factory(tenant=tenant_a) as client:
        response = await client.get(f"/orders/{cross_id}")
        assert response.status_code == 403
        assert response.json()["type"] == "/problems/forbidden"
```

The `client_factory(tenant=...)` fixture is responsible for issuing a
JWT with the requested tenant claim. See
[testing.md](../backend/testing.md) for the test fixture pattern.

## Observability

Every log line and trace span emitted during a request MUST carry
`tenant_id` as a structured field, alongside `request_id` from
[request-middleware.md](../backend/request-middleware.md). This makes
cross-tenant data-leak postmortems possible (a single grep on
`tenant_id=<victim>` shows every operation that touched the victim
tenant during the incident window).

Do NOT log the full tenant name or any tenant-identifying string —
`tenant_id` is the canonical, structured key.

## Escape Hatches

### Schema-per-tenant

Use a per-request `SET search_path = tenant_<id>, public` in place of
`SET LOCAL app.tenant_id`. Migrations apply to a template schema and
are replayed per-tenant. Cross-tenant queries (analytics) require the
control-plane role.

### Database-per-tenant

The application maintains a registry of per-tenant connection strings;
the middleware swaps the SQLAlchemy engine based on the tenant claim.
RLS becomes redundant within each database. This is the costliest
strategy operationally; choose it only when contracts or regulation
require it.

### Hybrid

A single product MAY use row-level for the long tail of small tenants
and database-per-tenant for a small set of large tenants under
hard-isolation contracts. The strategy choice MUST be a property of the
tenant record (`tenants.isolation_strategy`), and the middleware
selects accordingly. Do not let the choice become implicit.

## Anti-Patterns

```python
# BAD — relies on the developer remembering the predicate every time
async def list_orders(db: AsyncSession) -> list[Order]:
    return list((await db.scalars(select(Order))).all())
```

Without the explicit `WHERE tenant_id = :tid` AND without RLS engaged,
this returns every tenant's orders. Even with RLS, the missing filter
is a code-review smell — the contract should be visible at the call
site.

```python
# BAD — tenant_id from a request header the client controls
tenant_id = request.headers.get("X-Tenant-ID")
```

Tenant scope MUST come from a verified JWT claim, never from a
client-controlled header or query parameter. Anything else is a CSRF
vector for cross-tenant access.

```python
# BAD — cross-tenant 404 instead of 403
order = await order_crud.get(db, id=order_id)
if order is None:
    raise NotFoundException("Order not found")
if order.tenant_id != current_user.tenant_id:
    raise NotFoundException("Order not found")  # WRONG
```

Both branches return the same response shape (existence is hidden by
unguessable UUIDs), but the contract is `403 Forbidden` —
[error-contract.md](../architecture/error-contract.md) reserves 404
for "not authoritative for this resource," and 403 for "not authorized
for this resource."

## Rules

1. **Pick one default strategy.** Row-level is the default unless
   regulation, contract, or scale forces an escape hatch.
2. **Tenant-scoped tables have a non-null indexed `tenant_id`.**
3. **PostgreSQL RLS is enabled with FORCE on every tenant-scoped table.**
4. **`SET LOCAL app.tenant_id` per request** in middleware; never `SET`.
5. **`CurrentUser.tenant_id` is non-null** for any authenticated route;
   public routes bypass tenancy explicitly.
6. **Every query is reviewable**: prefer explicit `WHERE tenant_id`
   over invisible event hooks. If hooks are used, prove them with tests.
7. **Cross-tenant access → `ForbiddenException` (403, /problems/forbidden).**
   Not 404.
8. **Migrations colocate table creation and RLS policy.** No window
   without isolation.
9. **Every integration test runs at least two tenants.**
10. **`tenant_id` is logged with `request_id` on every request.**

---

## Related Standards

- [Database Schema Design](./schema-design.md) — UUID primary keys,
  tenant_id column shape.
- [Backend Auth Guard](../backend/auth-guard.md) — `CurrentUser.tenant_id`.
- [Backend Error Handling](../backend/error-handling.md) —
  `ForbiddenException` shape.
- [Architecture Authentication](../architecture/authentication.md) —
  multi-tenant authentication (org membership). This standard governs
  data isolation; that standard governs identity resolution.
- [Architecture Security](../architecture/security.md) — adjacent
  controls.
- [Request Middleware](../backend/request-middleware.md) —
  `request.state.request_id` precedent for `request.state.tenant_id`.
- [Observability](../architecture/observability.md) — structured logging.

---

_Multi-tenancy bugs are silent and catastrophic. Defense in depth
across schema, RLS, request scope, and explicit query predicates is
the difference between a near-miss and a breach._

---

<!-- Source: standards/database/neo4j.md (v1.0.1) -->

# Neo4j Standard

**Status**: Active

## Purpose

Rules for using Neo4j as the graph database in a polyglot stack: how the
async driver is wired and pooled, why all Cypher MUST be parameterized
(Cypher injection is the graph analog of SQL injection), how schema and
seed data are migrated, which APOC surface is sanctioned, and how queries
are tested against a real engine. Postgres remains the relational system
of record; Neo4j is for relationship- and traversal-heavy data only.

## Scope

- Driver version, connection lifecycle, and pooling
- Parameterized Cypher and dynamic-label allow-lists (injection safety)
- Managed transactions and retry semantics
- Constraints, indexes, and versioned graph migrations
- APOC scope (APOC Core only) and forbidden dynamic-Cypher procedures
- Integration testing against a real Neo4j engine via testcontainers
- When to reach for the graph, and Neo4j ops/security baseline

---

## Driver & connection lifecycle

- Use the official Python **`neo4j` driver `>=6`**. The driver is versioned
  independently of the server: the 6.x driver supports Neo4j **5.26 LTS** and
  the current **CalVer** server lines (**2025.x / 2026.x**). Neo4j databases
  moved to calendar versioning in 2025 — **5.26 is the last semver LTS, and
  there is no Neo4j "6" server**; pin the engine to **5.26 LTS** (or a current
  2025.x / 2026.x release), never a nonexistent "6". Use the **async** API —
  the org is async end to end (SQLAlchemy 2.0 async / asyncpg / FastAPI).
- **One `Driver` instance per process.** The driver owns a connection
  pool; construct it once at application startup and `await driver.close()`
  at shutdown. NEVER create a driver per request — that defeats pooling and
  exhausts connections.
- Open a **session per unit of work** and let it close promptly. Sessions
  are cheap and NOT thread/task-safe; do not share one across concurrent
  tasks.
- Driver URI, scheme, and credentials come from config / the secrets
  manager — NEVER hardcoded. See [`../architecture/security.md`](../architecture/security.md).

```python
# startup: one driver for the whole process
from neo4j import AsyncGraphDatabase

driver = AsyncGraphDatabase.driver(
    settings.NEO4J_URI,                      # neo4j+s://… from config
    auth=(settings.NEO4J_USER, settings.NEO4J_PASSWORD),
    max_connection_pool_size=settings.NEO4J_POOL_SIZE,
    connection_timeout=15.0,                 # seconds, fail fast
    connection_acquisition_timeout=30.0,
)

# per unit of work
async with driver.session(database="neo4j") as session:
    ...

# shutdown
await driver.close()
```

- **Scheme selects routing and encryption:**

| Scheme | Use when |
|---|---|
| `neo4j://` / `neo4j+s://` | cluster — routes reads/writes across members; `+s` = TLS |
| `bolt://` / `bolt+s://` | a single instance only (no routing); `+s` = TLS |

  Use a `neo4j://` scheme for clusters so routing works; reserve `bolt://`
  for a single instance. Prefer the `+s` (TLS) variant; configure
  encryption explicitly rather than relying on a default.

## Parameterized Cypher (injection safety)

This is the headline security rule for this standard.

- **NEVER build Cypher by string-interpolating user input.** Concatenating
  or f-stringing untrusted values into a query string is **Cypher
  injection** — the graph analog of SQL injection.
- **ALWAYS pass values as query parameters** (`$param`) via the driver's
  parameter map. Parameters are never parsed as Cypher, so they cannot
  alter query structure — and they let the server cache the query plan.

```python
# BAD — Cypher injection: user input becomes query text
email = request_email  # e.g.  "x'}) DETACH DELETE n //"
await session.run(
    f"MATCH (u:User {{email: '{email}'}}) RETURN u"   # NEVER do this
)

# GOOD — value passed as a parameter, never parsed as Cypher
await session.run(
    "MATCH (u:User {email: $email}) RETURN u",
    email=request_email,
)
```

- **Labels and relationship types CANNOT be parameterized in Cypher.** When
  they must be dynamic, validate the value against a server-side
  **allow-list** of known labels/types and only then splice the *validated*
  constant into the query — NEVER interpolate the raw user value.

```python
ALLOWED_LABELS = {"User", "Account", "Document"}   # server-side constant

def node_count_query(label: str) -> str:
    if label not in ALLOWED_LABELS:
        raise ValueError(f"unknown label: {label!r}")
    return f"MATCH (n:{label}) RETURN count(n) AS n"   # label now trusted
```

## Managed transactions & retry

- Prefer **managed transactions**: `session.execute_read(...)` /
  `session.execute_write(...)` with a transaction function. They
  **auto-retry on transient errors** (e.g. a cluster leader switch,
  deadlock) — `session.run(...)` / explicit `begin_transaction()` do not.
- A transaction function MUST be **idempotent and side-effect-free outside
  the transaction**: it can be invoked more than once by the retry logic,
  so do not send emails, enqueue jobs, or mutate external state inside it.
- **Do not run writes in a read transaction** (`execute_read`). Route writes
  through `execute_write` so they reach the cluster leader.
- Keep transactions **short** and **consume results inside the transaction
  scope** — materialize the rows you need before the function returns; a
  result cursor is not valid once its transaction closes.

```python
async def get_friends(tx, user_id: str) -> list[str]:
    result = await tx.run(
        "MATCH (u:User {id: $id})-[:FRIEND]->(f:User) RETURN f.id AS id",
        id=user_id,
    )
    return [r["id"] async for r in result]          # consumed inside tx

async with driver.session(database="neo4j") as session:
    friends = await session.execute_read(get_friends, user_id)
```

## Constraints & indexes

- Declare **uniqueness constraints** and **node-key constraints** for
  identifying properties, and create **indexes** on properties used for
  lookups or `MATCH` anchors. Constraints both enforce integrity and back a
  supporting index.
- Constraints and indexes are **schema** — create them in a **migration**
  (next section), NEVER ad hoc at runtime from application code.

```cypher
// in a reviewed migration, not at app startup
CREATE CONSTRAINT user_id_unique IF NOT EXISTS
  FOR (u:User) REQUIRE u.id IS UNIQUE;

CREATE INDEX user_email_idx IF NOT EXISTS
  FOR (u:User) ON (u.email);
```

- Use `IF NOT EXISTS` so a migration is safe to re-apply. Naming follows
  [`./naming-conventions.md`](./naming-conventions.md).

## Schema & graph migrations

- The graph schema — constraints, indexes, seed/reference data, and
  structural reshapes — MUST be **versioned, reviewed, and applied by a
  migration runner** (e.g. a Cypher migration tool such as
  `neo4j-migrations`). It MUST NOT be auto-mutated on application startup in
  production.
- This mirrors the relational philosophy in [`./migrations.md`](./migrations.md):
  migrations are **versioned**, **reviewed**, **reversible where possible**,
  and **tested on staging before production**. Data reshapes that drop data
  are irreversible — flag them explicitly, as relational migrations do.
- Migrations run as a **deploy step**, separate from the app process, with
  the same gating as relational migrations. See
  [`./schema-design.md`](./schema-design.md) for modeling the schema a
  migration creates.
- Treat structural changes that affect lookup paths as a
  [`./performance.md`](./performance.md) concern — add the supporting index
  in the same migration that introduces the access pattern.

## APOC scope

- Use **APOC Core only** (bundled with the server); pin the APOC version to
  the **server's release line** — APOC Core tracks the database version
  (`5.26.x` for 5.26 LTS, or the matching 2025.x / 2026.x build). Do not
  install APOC Extended / Full in production.
- **NEVER pass untrusted input into dynamic-Cypher procedures** —
  `apoc.cypher.run*`, `apoc.cypher.doIt`, and `apoc.cypher.runMany` execute
  a Cypher string and re-open exactly the injection hole that parameters
  close. If dynamic Cypher is unavoidable, the query body MUST be a trusted
  server-side constant and all runtime values MUST be passed in the
  procedure's parameter map.
- **Document the sanctioned APOC procedures** for the project (e.g.
  read-only graph utilities, path expansion, collection/map helpers).
  Procedures that execute arbitrary code or reach the filesystem/network
  with user-controlled arguments (`apoc.load.*`, `apoc.export.*`,
  `apoc.periodic.submit` with dynamic Cypher) are **out of scope** unless an
  ADR records the need and the inputs are fully trusted.

## Testing

- **Integration-test query correctness against a real Neo4j engine** via
  testcontainers (`testcontainers[neo4j]`, `Neo4jContainer`). Spin up the
  engine, seed a graph, run the **real Cypher**, and assert on results.
- **Do NOT mock the driver for query-correctness tests.** A mock cannot
  validate Cypher syntax, constraint behavior, or traversal semantics, so it
  proves nothing about the query. Mocks are acceptable only to isolate
  unrelated units, never to stand in for the database under test.
- This is the graph equivalent of the relational posture: tests run against
  a real engine, not a substitute. The async test toolchain (`pytest`,
  `pytest-asyncio`) is defined in [`../backend/tech-stack.md`](../backend/tech-stack.md).

```python
import pytest
from neo4j import AsyncGraphDatabase
from testcontainers.neo4j import Neo4jContainer

@pytest.fixture(scope="session")
def neo4j_url():
    with Neo4jContainer("neo4j:5.26") as container:
        yield container.get_connection_url()

@pytest.mark.asyncio
async def test_friend_traversal(neo4j_url):
    async with AsyncGraphDatabase.driver(neo4j_url) as driver:
        async with driver.session(database="neo4j") as s:
            await s.run(
                "CREATE (a:User {id:$a})-[:FRIEND]->(b:User {id:$b})",
                a="1", b="2",
            )
            result = await s.run(
                "MATCH (:User {id:$a})-[:FRIEND]->(f) RETURN f.id AS id",
                a="1",
            )
            ids = [r["id"] async for r in result]
    assert ids == ["2"]
```

## Modeling & operations

- **Reach for the graph** when the workload is relationship-centric: deep or
  **variable-length traversals**, shortest-path / reachability, and queries
  whose cost in relational terms is many recursive self-joins. For
  set-oriented, tabular, or transactional data, stay relational.
- **Keep the system of record explicit.** Polyglot persistence is
  sanctioned — Neo4j runs **alongside** Postgres (TimescaleDB + pgvector)
  and Redis. Postgres is the relational system of record; the graph holds
  relationship/traversal data and references back to it. See
  [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  and the time-series sibling [`./timescaledb.md`](./timescaledb.md). When
  the same entity lives in both stores, document which store owns each field.
- **Security & ops baseline** — see [`../architecture/security.md`](../architecture/security.md):
  - Connect as a **least-privilege Neo4j user** scoped to the database and
    operations the service needs; do not use an admin account at runtime.
  - **Require TLS on Bolt** (`+s` / `+ssc` schemes). NEVER expose the Bolt
    or HTTP ports publicly — keep Neo4j on a private network.
  - Secrets (URI, credentials) come from the **secrets manager**, never from
    source or images.
  - Emit query latency/error metrics and propagate request context per
    [`../architecture/observability.md`](../architecture/observability.md)
    and [`../backend/request-middleware.md`](../backend/request-middleware.md);
    never log raw credentials or full parameter maps that may carry PII.

---

## Related Standards

- [Database Migrations](./migrations.md) — versioned, reviewed, staged migrations
- [Schema Design](./schema-design.md) — modeling the graph schema
- [Database Performance](./performance.md) — indexing access patterns
- [Naming Conventions](./naming-conventions.md) — constraint/index/label naming
- [TimescaleDB](./timescaledb.md) — time-series sibling in the polyglot stack
- [Database Standards Overview](./README.md)
- [Security](../architecture/security.md) — least privilege, TLS, secrets
- [Reference Architecture](../architecture/reference-architecture.md) — polyglot persistence
- [Observability](../architecture/observability.md) — query metrics and tracing
- [Backend Tech Stack](../backend/tech-stack.md) — async + test toolchain
- [Request Middleware](../backend/request-middleware.md) — request context propagation
- [RAG & Vector Stores](../ai/rag-vector-stores.md) — sibling persistence standard

---

<!-- Source: standards/database/timescaledb.md (v1.0.0) -->

# TimescaleDB Standard

**Status**: Active

## Purpose

Rules for time-series data on PostgreSQL via the **TimescaleDB** extension:
how time-series tables become hypertables, how rollups are precomputed with
continuous aggregates, how aged data is compressed and retired, and when an
in-database `pg_cron` job is correct versus an application-level Celery-beat
task.

TimescaleDB is a **Postgres extension**, not a separate engine, so **every
existing database standard still applies** — naming
([`./naming-conventions.md`](./naming-conventions.md)), schema design
([`./schema-design.md`](./schema-design.md)), query/index discipline
([`./performance.md`](./performance.md)), and migrations
([`./migrations.md`](./migrations.md)). This standard adds only the
time-series-specific rules on top.

## Scope

- Blessed image and version parity
- Converting tables to hypertables and sizing chunks
- Indexing hypertables for time-series access
- Continuous aggregates (CAGGs) for rollups
- Columnar compression on aged chunks
- Data retention and its governance constraints
- `pg_cron` (in-database) vs Celery-beat (application) scheduling
- pgvector coexistence in the same image
- Where this DDL lives (migrations) and how it is tested

---

## Image and version

- The **blessed production database image is
  `timescale/timescaledb-ha:pg16`**, which bundles **TimescaleDB +
  pgvector + pg_cron** in a single image on **PostgreSQL 16**. Do not pull
  TimescaleDB as a separate sidecar or run a vanilla `postgres` image in
  prod. See
  [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md).
- **dev, CI, and test MUST run the same major (pg16) and the same image**
  so hypertable, policy, and compression behavior is identical across
  environments. See [`../devops/docker.md`](../devops/docker.md). Testing
  Timescale features against stock `postgres` gives false confidence — the
  extension is absent.
- **Enable the extension in a migration, never ad hoc.** The first
  Timescale migration runs:

```sql
CREATE EXTENSION IF NOT EXISTS timescaledb;
-- only when the feature is actually used in that database:
CREATE EXTENSION IF NOT EXISTS vector;     -- pgvector
CREATE EXTENSION IF NOT EXISTS pg_cron;    -- in-DB scheduler
```

- `CREATE EXTENSION` is schema. It MUST live in version-controlled Alembic
  migrations and MUST NOT be applied by hand on a running database.

---

## Hypertables

- A **hypertable** is a regular table partitioned transparently into
  time-based **chunks**. Convert a time-series table immediately after
  creating it; the **partitioning column is the time column** (a
  `TIMESTAMPTZ`).

```python
# inside an Alembic migration upgrade()
op.create_table(
    "events",
    sa.Column("time", sa.DateTime(timezone=True), nullable=False),
    sa.Column("device_id", sa.Integer(), nullable=False),
    sa.Column("value", sa.Float(), nullable=False),
)
# new-style dimension builder (preferred)
op.execute("SELECT create_hypertable('events', by_range('time'));")
# classic form is equivalent:
# op.execute("SELECT create_hypertable('events', 'time');")
```

- **Create hypertables in an Alembic migration via `op.execute` raw SQL** —
  never at application runtime, never lazily on first write.
- A hypertable's time column **cannot be a serial/auto-increment surrogate
  key** standing in for time — partition on real event time.

### Chunk-interval sizing

- **Size a chunk to hold roughly the recent working set.** Rule of thumb:
  the **active (recently written/queried) chunks across all hypertables
  SHOULD fit in ≈ ≤25% of available RAM**, so indexes for the hot range stay
  resident.
- **Default to a ~7-day interval and tune by ingest rate.** High-volume
  ingest → smaller intervals (hours/days); sparse ingest → larger. Set it
  explicitly rather than relying on the install default:

```sql
SELECT set_chunk_time_interval('events', INTERVAL '1 day');
```

- **Add space (hash) partitioning only with a documented reason** (e.g.
  multi-node distribution). A second partitioning dimension adds planning
  cost; do not add it speculatively.

---

## Indexing hypertables

- Indexes on a hypertable are created on **every chunk**, so each redundant
  index multiplies storage and write cost. **Index deliberately.**
- Build composite indexes **time-descending**, leading with the column you
  filter/group by — typically the compression `segmentby` column:

```sql
CREATE INDEX ix_events_device_time ON events (device_id, time DESC);
```

- `(segmentby_col, time DESC)` matches both the common query shape
  ("latest rows for this device") and the compression layout below, so the
  same index serves reads on compressed and uncompressed chunks.
- **Avoid redundant indexes.** Do not keep both `(time)` and
  `(device_id, time DESC)` if the composite already serves the time-range
  scans. Follow the general index rules in
  [`./performance.md`](./performance.md).

---

## Continuous aggregates (CAGGs)

- Precompute rollups (per-minute/hour/day summaries) as a **materialized
  view declared `WITH (timescaledb.continuous)`** rather than aggregating the
  raw hypertable on every read.

```sql
CREATE MATERIALIZED VIEW events_hourly
WITH (timescaledb.continuous) AS
SELECT time_bucket(INTERVAL '1 hour', time) AS bucket,
       device_id,
       avg(value)  AS avg_value,
       max(value)  AS max_value
FROM events
GROUP BY bucket, device_id
WITH NO DATA;
```

- **Attach a refresh policy** so the aggregate stays current; tune the
  offsets to your latency tolerance and ingest lag:

```sql
SELECT add_continuous_aggregate_policy('events_hourly',
    start_offset => INTERVAL '3 days',
    end_offset   => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');
```

- **Query the CAGG for rollups, not the raw hypertable.** A dashboard
  reading a month of hourly averages MUST hit `events_hourly`, not scan raw
  `events`.
- **Real-time aggregation** (enabled by default) transparently unions the
  materialized buckets with not-yet-materialized recent raw rows, so reads
  see fresh data between refreshes. Keep `end_offset` ≥ your acceptable
  staleness if you disable it.
- CAGG definitions and their policies **are schema and live in migrations.**

---

## Compression

- **Enable native columnar compression on aged chunks** to cut storage and
  speed up large analytical scans. Configure it on the table, then schedule
  it with a policy:

```sql
ALTER TABLE events SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id',
    timescaledb.compress_orderby   = 'time DESC'
);
SELECT add_compression_policy('events', INTERVAL '7 days');
```

- **Choose `segmentby` to match your filter columns** (e.g. `device_id`) and
  `orderby` to match your sort (`time DESC`); these directly determine
  compressed-scan performance. Mismatched settings force decompression.
- **Compressed chunks are read-mostly.** Design ingest so writes land in the
  recent, uncompressed window and **you do not routinely UPDATE/DELETE
  inside compressed chunks** — mutating compressed data is expensive and
  partly defeats the format. Backfill into compressed ranges is an explicit,
  reviewed operation, not a hot path.
- Pick the compression cutoff (`INTERVAL '7 days'` above) to sit safely
  **outside the active write window** so live ingest is never compressing.

---

## Retention

- **Drop aged-out chunks with a retention policy** rather than `DELETE` on a
  large table:

```sql
SELECT add_retention_policy('events', INTERVAL '90 days');
```

- **Retention is a deliberate, documented decision per hypertable.** Record
  the chosen window and its rationale (cost, query relevance, legal basis) —
  it MUST NOT be a silent default.
- **Retention MUST honor data-governance / GDPR requirements.** Do not drop
  data a regulation requires you to keep (e.g. financial/audit records under
  a statutory retention period), and do not retain personal data past its
  lawful window. Reconcile every retention window with
  [`../architecture/gdpr-data-rights.md`](../architecture/gdpr-data-rights.md).
- Retention and erasure are different mechanisms: a retention policy ages
  out **whole chunks by time**; per-subject erasure (RTBF) is a targeted
  delete and is governed by the GDPR standard above, not by this policy.

---

## Scheduling: pg_cron vs Celery-beat (decision note)

The prod image bundles **`pg_cron`**, an **in-database, SQL-only** scheduler.
The platform also runs **Celery-beat** for **application-level** periodic
tasks (see [`../backend/background-jobs.md`](../backend/background-jobs.md)).
These solve different problems and **a given job belongs in exactly one of
them.**

| Dimension | `pg_cron` (in-DB) | Celery-beat (app) |
|---|---|---|
| Runs | SQL only (`cron.schedule(...)`) | Python tasks |
| Lives with | the database | the application deployment |
| External I/O | no | yes (HTTP, queues, S3, third-party APIs) |
| App context (secrets, ORM, observability) | no | yes |
| Survives app redeploy / scale-to-zero | yes | no (needs running workers) |
| Use for | data-local maintenance, in-DB rollups, vacuum/analyze helpers, ad-hoc SQL housekeeping | business logic, anything calling external services, app-layer retries/metrics |

- **Decision rule:** SQL-only **and** data-local **and** must-run-without-the-app
  → **`pg_cron`**. Needs application logic, external I/O, or app context
  (secrets, app-layer retries, app observability) → **Celery-beat**.
- **Never schedule the same job in both schedulers** — duplicate runs cause
  double-processing and contention.
- **Prefer Timescale's built-in policy API over hand-rolled `pg_cron` for
  Timescale concerns.** Retention, compression, and CAGG refresh are
  themselves background jobs run by the **Timescale job scheduler**; use
  `add_retention_policy` / `add_compression_policy` /
  `add_continuous_aggregate_policy` rather than reimplementing them as cron
  jobs. Reserve raw `pg_cron` for housekeeping those policies do not cover
  (e.g. a periodic `ANALYZE`, a bespoke in-DB cleanup query).

```sql
-- pg_cron is appropriate here: SQL-only, data-local, app-independent
SELECT cron.schedule('nightly-analyze-events', '17 3 * * *',
                     $$ANALYZE events;$$);
```

- **Manage `pg_cron` schedules as migrations** — `cron.schedule(...)` /
  `cron.unschedule(...)` are versioned in Alembic, reviewed, and reproducible.
  Do **not** create or edit cron jobs ad hoc via `psql`; an unversioned
  schedule cannot be reproduced in another environment.

---

## pgvector coexistence

- The blessed image also bundles **pgvector**, so embedding/vector tables
  live in the **same database** as hypertables — but they are **separate
  tables**. Vector search and time-series ingest have different access
  patterns and lifecycles.
- **Do NOT make embedding tables hypertables.** Embeddings are not
  partitioned by event time and gain nothing from chunking; making them
  hypertables only adds overhead.
- For all vector/embedding rules (index type, distance metric, embedding
  pinning, retrieval-time authorization), follow
  [`../ai/rag-vector-stores.md`](../ai/rag-vector-stores.md).

---

## Migrations

- **All TimescaleDB DDL is schema and MUST live in Alembic migrations** as
  raw SQL via `op.execute(...)`: extension creation, hypertable conversion,
  chunk-interval settings, CAGG definitions and policies, compression
  settings and policies, retention policies, and `pg_cron` schedules.
- Migrations MUST be **reviewed and tested on staging before production**,
  per [`./migrations.md`](./migrations.md). Provide a `downgrade()` where
  reversible (`remove_retention_policy`, `remove_compression_policy`,
  `remove_continuous_aggregate_policy`, `cron.unschedule`, `DROP MATERIALIZED
  VIEW`); where dropping data is irreversible, mark it explicitly as the
  migrations standard requires.
- Never reach for ad-hoc `psql` to apply any of the above on a live
  database — it bypasses review and drifts environments out of sync.

---

## Testing

- **Integration-test against the `timescale/timescaledb-ha:pg16` image**
  (e.g. via testcontainers), **not** a vanilla `postgres` container, so
  hypertable creation, CAGG refresh, compression, and retention behavior is
  actually exercised. Against stock `postgres` the extension is missing and
  `create_hypertable` / policy calls fail or no-op — the tests would prove
  nothing.
- Pin the **same major (pg16)** in the test image as dev/CI/prod so behavior
  matches what ships.
- Cover, at minimum: a table converts to a hypertable and writes land in the
  expected chunk; a CAGG materializes and a query reads from it; a
  compression policy compresses a backdated chunk; a retention policy drops
  an aged chunk.

---

## Related Standards

- [Database Migrations](./migrations.md) — where all Timescale DDL lives
- [Database Performance](./performance.md) — index/query discipline
- [Database Schema Design](./schema-design.md) — table/column design
- [Database Naming Conventions](./naming-conventions.md) — naming rules
- [Neo4j](./neo4j.md) — sibling datastore standard
- [Database Standards Index](./README.md)
- [Background Jobs](../backend/background-jobs.md) — Celery-beat scheduling
- [Backend Tech Stack](../backend/tech-stack.md)
- [RAG & Vector Stores](../ai/rag-vector-stores.md) — pgvector usage rules
- [Reference Architecture](../architecture/reference-architecture.md) — blessed image
- [GDPR Data Rights](../architecture/gdpr-data-rights.md) — retention/erasure constraints
- [Security](../architecture/security.md) — access-control baseline
- [Docker](../devops/docker.md) — dev/CI image parity

---

<!-- Compilation Metadata
  domain: database-standards
  domain_version: 1.4.3
  compiled_at: 2026-06-01 20:55
  source: evolv-coder-standards
  files_compiled: 8/8
-->