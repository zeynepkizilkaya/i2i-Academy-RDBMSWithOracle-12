# RDBMS With Oracle

Spring Boot and Oracle XE homework project for practicing relational database design, Flyway migrations, PL/SQL packages, triggers, JDBC calls, and REST endpoints.

## Theoretical Summary

Relational databases store normalized, schema-based data with SQL, ACID transactions, joins, and strong consistency, while non-relational databases usually optimize flexible documents, key-value access, graph models, or horizontal scale. In-memory data grids such as Apache Ignite are useful for very fast distributed access, but traditional relational databases are still needed for durable storage, transactional integrity, constraints, complex querying, and long-term operational reliability. PL/SQL is Oracle's procedural extension to SQL, so it adds variables, functions, procedures, packages, cursors, and exception handling to normal SQL statements. Stored procedures and packages keep database logic close to the data, reduce round trips, centralize validation, and make complex operations reusable. Connection pools such as HikariCP reuse existing database connections instead of creating a new expensive connection for every request, and migration tools such as Flyway keep schema and PL/SQL changes versioned, repeatable, and consistent across environments.

## Data Format

`POST /api/books/import` accepts a raw delimited text body.

Each book uses this format:

```text
title|author|publisher|isbn|publicationYear
```

Multiple books can be separated with semicolons or new lines:

```text
Clean Code|Robert C. Martin|Prentice Hall|9780132350884|2008;Effective Java|Joshua Bloch|Addison-Wesley|9780134685991|2018
```

## Run With Docker

```bash
docker compose up --build
```

The compose file starts Oracle XE and the Spring Boot application on the same Docker network.

## API Examples

Import books:

```bash
curl -X POST http://localhost:8080/api/books/import \
  -H "Content-Type: text/plain" \
  --data "Clean Code|Robert C. Martin|Prentice Hall|9780132350884|2008;Effective Java|Joshua Bloch|Addison-Wesley|9780134685991|2018"
```

Fetch books:

```bash
curl http://localhost:8080/api/books
```

## Database Features

- Flyway creates `AUTHORS`, `PUBLISHERS`, `BOOKS`, and `AUDIT_LOGS`.
- A row-level trigger writes an audit record whenever a book is inserted.
- `BOOK_OPERATIONS.PARSE_TO_XML` converts raw delimited text to XML.
- `BOOK_OPERATIONS.PARSE_TO_JSON` converts raw delimited text to JSON.
- `BOOK_OPERATIONS.INSERT_BOOKS` parses XML and JSON with Oracle XML/JSON features and inserts normalized records.
- `BOOK_OPERATIONS.GET_BOOKS` returns all book records through a cursor.
