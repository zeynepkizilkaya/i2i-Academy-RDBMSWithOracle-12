package com.zeynep.rdbmswithoracle.repository;

import com.zeynep.rdbmswithoracle.model.BookDto;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import java.sql.Clob;
import java.sql.Types;
import java.util.List;
import java.util.Map;

@Repository
public class BookRepositoryImpl implements BookRepository {

    private final JdbcTemplate jdbcTemplate;

    public BookRepositoryImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void importBooks(String rawData) {
        String xmlData = callClobFunction("PARSE_TO_XML", rawData);
        String jsonData = callClobFunction("PARSE_TO_JSON", rawData);

        jdbcTemplate.execute((ConnectionCallback<Void>) connection -> {
            try (var statement = connection.prepareCall("{ call BOOK_OPERATIONS.INSERT_BOOKS(?, ?) }")) {
                statement.setString(1, xmlData);
                statement.setString(2, jsonData);
                statement.execute();
            }
            return null;
        });
    }

    private String callClobFunction(String functionName, String rawData) {
        return jdbcTemplate.execute((ConnectionCallback<String>) connection -> {
            try (var statement = connection.prepareCall("{ ? = call BOOK_OPERATIONS." + functionName + "(?) }")) {
                statement.registerOutParameter(1, Types.CLOB);
                statement.setString(2, rawData);
                statement.execute();

                Clob clob = statement.getClob(1);
                return clob == null ? null : clob.getSubString(1, (int) clob.length());
            }
        });
    }

    @Override
    @SuppressWarnings("unchecked")
    public List<BookDto> getBooks() {

        SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTemplate)
                .withCatalogName("BOOK_OPERATIONS")
                .withProcedureName("GET_BOOKS")
                .withoutProcedureColumnMetaDataAccess()
                .returningResultSet(
                        "P_CURSOR",
                        bookRowMapper()
                )
                .declareParameters(new SqlOutParameter("P_CURSOR", Types.REF_CURSOR));

        Map<String, Object> result = jdbcCall.execute();

        return (List<BookDto>) result.get("P_CURSOR");
    }

    private RowMapper<BookDto> bookRowMapper() {

        return (rs, rowNum) -> new BookDto(
                rs.getLong("ID"),
                rs.getString("TITLE"),
                rs.getString("AUTHOR_NAME"),
                rs.getString("PUBLISHER_NAME"),
                rs.getString("ISBN"),
                rs.getInt("PUBLICATION_YEAR")
        );
    }
}
