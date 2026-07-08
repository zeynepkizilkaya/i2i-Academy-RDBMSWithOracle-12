package com.zeynep.rdbmswithoracle.repository;

import com.zeynep.rdbmswithoracle.model.BookDto;

import java.util.List;

public interface BookRepository {

    void importBooks(String rawData);

    List<BookDto> getBooks();

}
