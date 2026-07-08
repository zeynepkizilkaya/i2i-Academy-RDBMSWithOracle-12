CREATE TABLE AUTHORS (
                         ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                         NAME VARCHAR2(100) NOT NULL
);

CREATE TABLE PUBLISHERS (
                            ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                            NAME VARCHAR2(100) NOT NULL
);

CREATE TABLE BOOKS (
                       ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                       TITLE VARCHAR2(200) NOT NULL,
                       AUTHOR_ID NUMBER NOT NULL,
                       PUBLISHER_ID NUMBER NOT NULL,
                       ISBN VARCHAR2(20),
                       PUBLICATION_YEAR NUMBER,

                       CONSTRAINT FK_BOOK_AUTHOR
                           FOREIGN KEY (AUTHOR_ID)
                               REFERENCES AUTHORS(ID),

                       CONSTRAINT FK_BOOK_PUBLISHER
                           FOREIGN KEY (PUBLISHER_ID)
                               REFERENCES PUBLISHERS(ID)
);

CREATE TABLE AUDIT_LOGS (
                            ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                            TABLE_NAME VARCHAR2(100),
                            ACTION_TYPE VARCHAR2(20),
                            LOG_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                            DB_USER VARCHAR2(100)
);