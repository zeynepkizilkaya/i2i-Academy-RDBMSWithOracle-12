# RDBMS With Oracle

This project was developed for the i2i Academy RDBMS with Oracle assignment.

## Technologies

- Java 21
- Spring Boot
- Oracle XE
- Flyway
- Docker
- Maven

## Project Description

The project manages book records using Oracle Database and Spring Boot.

During the project I:

- Created the database schema with Flyway
- Implemented PL/SQL package and procedures
- Added trigger for audit logs
- Developed REST APIs for importing and listing books
- Connected Spring Boot with Oracle XE using JDBC
- Containerized the application with Docker

## API Endpoints

### Import Books

```
POST /api/books/import
```

Imports book data into the database.

### Get Books

```
GET /api/books
```

Returns all books stored in the database.

## Run the Project

```bash
docker compose up --build
```

or

```bash
./mvnw spring-boot:run
```

## Notes

This project was created to practice:

- Oracle PL/SQL
- Flyway migrations
- Spring Boot JDBC
- REST API development
- Docker
