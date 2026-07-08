CREATE OR REPLACE PACKAGE BOOK_OPERATIONS AS

    FUNCTION PARSE_TO_XML(
        P_RAW_DATA IN CLOB
    ) RETURN CLOB;

    FUNCTION PARSE_TO_JSON(
        P_RAW_DATA IN CLOB
    ) RETURN CLOB;

    PROCEDURE INSERT_BOOKS(
        P_XML IN CLOB,
        P_JSON IN CLOB
    );

    PROCEDURE GET_BOOKS(
        P_CURSOR OUT SYS_REFCURSOR
    );

END BOOK_OPERATIONS;
/

CREATE OR REPLACE PACKAGE BODY BOOK_OPERATIONS AS

    FUNCTION XML_ESCAPE(P_VALUE IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN REPLACE(
               REPLACE(
               REPLACE(
               REPLACE(
               REPLACE(NVL(P_VALUE, ''), '&', '&amp;'),
                                      '<', '&lt;'),
                                      '>', '&gt;'),
                                      '"', '&quot;'),
                                      '''', '&apos;');
    END;

    FUNCTION JSON_ESCAPE(P_VALUE IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN REPLACE(
               REPLACE(
               REPLACE(
               REPLACE(NVL(P_VALUE, ''), '\', '\\'),
                                      '"', '\"'),
                                      CHR(13), ''),
                                      CHR(10), '\n');
    END;

    PROCEDURE READ_BOOK_RECORD(
        P_RECORD IN VARCHAR2,
        P_TITLE OUT VARCHAR2,
        P_AUTHOR_NAME OUT VARCHAR2,
        P_PUBLISHER_NAME OUT VARCHAR2,
        P_ISBN OUT VARCHAR2,
        P_PUBLICATION_YEAR OUT VARCHAR2
    ) IS
    BEGIN
        P_TITLE := TRIM(REGEXP_SUBSTR(P_RECORD, '[^|]+', 1, 1));
        P_AUTHOR_NAME := TRIM(REGEXP_SUBSTR(P_RECORD, '[^|]+', 1, 2));
        P_PUBLISHER_NAME := TRIM(REGEXP_SUBSTR(P_RECORD, '[^|]+', 1, 3));
        P_ISBN := TRIM(REGEXP_SUBSTR(P_RECORD, '[^|]+', 1, 4));
        P_PUBLICATION_YEAR := TRIM(REGEXP_SUBSTR(P_RECORD, '[^|]+', 1, 5));

        IF P_TITLE IS NULL OR P_AUTHOR_NAME IS NULL OR P_PUBLISHER_NAME IS NULL THEN
            RAISE_APPLICATION_ERROR(-20010, 'Each book must contain title, author, and publisher.');
        END IF;

        IF P_PUBLICATION_YEAR IS NOT NULL AND NOT REGEXP_LIKE(P_PUBLICATION_YEAR, '^[0-9]{4}$') THEN
            RAISE_APPLICATION_ERROR(-20011, 'Publication year must be a four digit number.');
        END IF;
    END;

    FUNCTION NORMALIZE_RAW_DATA(P_RAW_DATA IN CLOB) RETURN VARCHAR2 IS
        V_RAW VARCHAR2(32767);
    BEGIN
        IF P_RAW_DATA IS NULL OR DBMS_LOB.GETLENGTH(P_RAW_DATA) = 0 THEN
            RAISE_APPLICATION_ERROR(-20012, 'Raw book data cannot be empty.');
        END IF;

        V_RAW := DBMS_LOB.SUBSTR(P_RAW_DATA, 32767, 1);
        V_RAW := REPLACE(REPLACE(TRIM(V_RAW), CHR(13), ''), CHR(10), ';');

        IF V_RAW IS NULL THEN
            RAISE_APPLICATION_ERROR(-20012, 'Raw book data cannot be empty.');
        END IF;

        RETURN V_RAW;
    END;

    FUNCTION PARSE_TO_XML(P_RAW_DATA IN CLOB) RETURN CLOB IS
        V_RAW VARCHAR2(32767);
        V_RECORD VARCHAR2(4000);
        V_TITLE VARCHAR2(200);
        V_AUTHOR_NAME VARCHAR2(100);
        V_PUBLISHER_NAME VARCHAR2(100);
        V_ISBN VARCHAR2(20);
        V_PUBLICATION_YEAR VARCHAR2(4);
        V_INDEX NUMBER := 1;
        V_XML CLOB := '<books>';
    BEGIN
        V_RAW := NORMALIZE_RAW_DATA(P_RAW_DATA);

        LOOP
            V_RECORD := TRIM(REGEXP_SUBSTR(V_RAW, '[^;]+', 1, V_INDEX));
            EXIT WHEN V_RECORD IS NULL;

            READ_BOOK_RECORD(V_RECORD, V_TITLE, V_AUTHOR_NAME, V_PUBLISHER_NAME, V_ISBN, V_PUBLICATION_YEAR);

            V_XML := V_XML
                || '<book>'
                || '<title>' || XML_ESCAPE(V_TITLE) || '</title>'
                || '<authorName>' || XML_ESCAPE(V_AUTHOR_NAME) || '</authorName>'
                || '<publisherName>' || XML_ESCAPE(V_PUBLISHER_NAME) || '</publisherName>'
                || '<isbn>' || XML_ESCAPE(V_ISBN) || '</isbn>'
                || '<publicationYear>' || XML_ESCAPE(V_PUBLICATION_YEAR) || '</publicationYear>'
                || '</book>';

            V_INDEX := V_INDEX + 1;
        END LOOP;

        RETURN V_XML || '</books>';
    END;

    FUNCTION PARSE_TO_JSON(P_RAW_DATA IN CLOB) RETURN CLOB IS
        V_RAW VARCHAR2(32767);
        V_RECORD VARCHAR2(4000);
        V_TITLE VARCHAR2(200);
        V_AUTHOR_NAME VARCHAR2(100);
        V_PUBLISHER_NAME VARCHAR2(100);
        V_ISBN VARCHAR2(20);
        V_PUBLICATION_YEAR VARCHAR2(4);
        V_INDEX NUMBER := 1;
        V_JSON CLOB := '{"books":[';
    BEGIN
        V_RAW := NORMALIZE_RAW_DATA(P_RAW_DATA);

        LOOP
            V_RECORD := TRIM(REGEXP_SUBSTR(V_RAW, '[^;]+', 1, V_INDEX));
            EXIT WHEN V_RECORD IS NULL;

            READ_BOOK_RECORD(V_RECORD, V_TITLE, V_AUTHOR_NAME, V_PUBLISHER_NAME, V_ISBN, V_PUBLICATION_YEAR);

            IF V_INDEX > 1 THEN
                V_JSON := V_JSON || ',';
            END IF;

            V_JSON := V_JSON
                || '{"title":"' || JSON_ESCAPE(V_TITLE)
                || '","authorName":"' || JSON_ESCAPE(V_AUTHOR_NAME)
                || '","publisherName":"' || JSON_ESCAPE(V_PUBLISHER_NAME)
                || '","isbn":"' || JSON_ESCAPE(V_ISBN)
                || '","publicationYear":' || CASE WHEN V_PUBLICATION_YEAR IS NULL THEN 'null' ELSE V_PUBLICATION_YEAR END
                || '}';

            V_INDEX := V_INDEX + 1;
        END LOOP;

        RETURN V_JSON || ']}';
    END;

    PROCEDURE INSERT_BOOKS(
        P_XML IN CLOB,
        P_JSON IN CLOB
    ) IS
        V_XML_COUNT NUMBER;
        V_JSON_COUNT NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO V_XML_COUNT
        FROM XMLTABLE(
            '/books/book'
            PASSING XMLTYPE(P_XML)
            COLUMNS TITLE VARCHAR2(200) PATH 'title'
        );

        SELECT COUNT(*)
        INTO V_JSON_COUNT
        FROM JSON_TABLE(
            P_JSON,
            '$.books[*]'
            COLUMNS TITLE VARCHAR2(200) PATH '$.title'
        );

        IF V_XML_COUNT = 0 OR V_XML_COUNT <> V_JSON_COUNT THEN
            RAISE_APPLICATION_ERROR(-20013, 'XML and JSON inputs are empty or inconsistent.');
        END IF;

        MERGE INTO AUTHORS A
        USING (
            SELECT DISTINCT AUTHOR_NAME
            FROM XMLTABLE(
                '/books/book'
                PASSING XMLTYPE(P_XML)
                COLUMNS AUTHOR_NAME VARCHAR2(100) PATH 'authorName'
            )
        ) X
        ON (LOWER(A.NAME) = LOWER(X.AUTHOR_NAME))
        WHEN NOT MATCHED THEN
            INSERT (NAME) VALUES (X.AUTHOR_NAME);

        MERGE INTO PUBLISHERS P
        USING (
            SELECT DISTINCT PUBLISHER_NAME
            FROM XMLTABLE(
                '/books/book'
                PASSING XMLTYPE(P_XML)
                COLUMNS PUBLISHER_NAME VARCHAR2(100) PATH 'publisherName'
            )
        ) X
        ON (LOWER(P.NAME) = LOWER(X.PUBLISHER_NAME))
        WHEN NOT MATCHED THEN
            INSERT (NAME) VALUES (X.PUBLISHER_NAME);

        INSERT INTO BOOKS (TITLE, AUTHOR_ID, PUBLISHER_ID, ISBN, PUBLICATION_YEAR)
        SELECT
            X.TITLE,
            A.ID,
            P.ID,
            X.ISBN,
            X.PUBLICATION_YEAR
        FROM XMLTABLE(
            '/books/book'
            PASSING XMLTYPE(P_XML)
            COLUMNS
                TITLE VARCHAR2(200) PATH 'title',
                AUTHOR_NAME VARCHAR2(100) PATH 'authorName',
                PUBLISHER_NAME VARCHAR2(100) PATH 'publisherName',
                ISBN VARCHAR2(20) PATH 'isbn',
                PUBLICATION_YEAR NUMBER PATH 'publicationYear'
        ) X
        JOIN AUTHORS A ON LOWER(A.NAME) = LOWER(X.AUTHOR_NAME)
        JOIN PUBLISHERS P ON LOWER(P.NAME) = LOWER(X.PUBLISHER_NAME);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'Book import failed: ' || SQLERRM);
    END;

    PROCEDURE GET_BOOKS(
        P_CURSOR OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN P_CURSOR FOR
            SELECT
                B.ID,
                B.TITLE,
                A.NAME AS AUTHOR_NAME,
                P.NAME AS PUBLISHER_NAME,
                B.ISBN,
                B.PUBLICATION_YEAR
            FROM BOOKS B
            JOIN AUTHORS A ON B.AUTHOR_ID = A.ID
            JOIN PUBLISHERS P ON B.PUBLISHER_ID = P.ID
            ORDER BY B.ID;
    END;

END BOOK_OPERATIONS;
/
