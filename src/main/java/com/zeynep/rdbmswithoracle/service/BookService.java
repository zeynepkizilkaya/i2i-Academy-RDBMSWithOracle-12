package com.zeynep.rdbmswithoracle.service;

import com.zeynep.rdbmswithoracle.model.BookDto;
import com.zeynep.rdbmswithoracle.repository.BookRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BookService {

    private final BookRepository repository;

    public BookService(BookRepository repository) {
        this.repository = repository;
    }

    public void importBooks(String rawData) {
        repository.importBooks(rawData);
    }

    public List<BookDto> getBooks() {
        return repository.getBooks();
    }
}
