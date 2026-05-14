# Database Standards

> Database standards: PostgreSQL, naming, migrations, performance

**Compiled**: 2026-03-25 13:07
**Source**: evolv-coder-standards
**Domain Version**: 1.0.0

---

## Contents

- [Naming Conventions](#naming-conventions)
- [Schema Design](#schema-design)
- [Migrations](#migrations)
- [Performance](#performance)

---

<!-- Source: standards/database/naming-conventions.md (v1.0.0) -->

# PostgreSQL Naming Conventions

**Version**: 1.0.0
**Last Updated**: 2026-01-04
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
For many-to-many relationships, combine both table names (both plural):

```sql
-- Pattern: tables1_tables2
CREATE TABLE users_roles (
    user_id INTEGER REFERENCES users(id),
    role_id INTEGER REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE products_categories (
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
ALTER TABLE users_roles
ADD CONSTRAINT uq_users_roles_user_id_role_id
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

<!-- Source: standards/database/schema-design.md (v1.0.0) -->

# Database Schema Design Standard

**Version**: 1.0.0
**Last Updated**: 2025-12-30
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
| Primary keys | `SERIAL` / `BIGSERIAL` | `UUID` (unless distributed) |
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

from sqlalchemy import Column, Integer, DateTime, func
from sqlalchemy.orm import DeclarativeBase, declared_attr


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

    id = Column(Integer, primary_key=True, index=True)
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

    ORGANIZATIONS {
        int id PK
        string name
        timestamp created_at
        timestamp updated_at
    }

    USERS {
        int id PK
        string email UK
        string hashed_password
        string full_name
        boolean is_active
        int organization_id FK
        timestamp created_at
        timestamp updated_at
    }

    ROLES {
        int id PK
        string name UK
    }

    POSTS {
        int id PK
        string title
        text content
        int author_id FK
        timestamp created_at
        timestamp updated_at
    }

    PROJECTS {
        int id PK
        string name
        timestamp created_at
    }

    PROJECT_MEMBERS {
        int user_id PK,FK
        int project_id PK,FK
        string role
        timestamp joined_at
    }

    CATEGORIES {
        int id PK
        string name
        int parent_id FK
    }
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

<!-- Source: standards/database/migrations.md (v1.0.0) -->

# Database Migrations Standard

**Version**: 1.0.0
**Last Updated**: 2025-12-30
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
hooks = black
black.type = console_scripts
black.entrypoint = black
black.options = -q

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

**Version**: 1.0.0
**Last Updated**: 2025-12-30
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

<!-- Compilation Metadata
  domain: database-standards
  domain_version: 1.0.0
  compiled_at: 2026-03-25 13:07
  source: evolv-coder-standards
  files_compiled: 4/4
-->