package com.zeynep.rdbmswithoracle.controller;

import com.zeynep.rdbmswithoracle.model.BookDto;
import com.zeynep.rdbmswithoracle.service.BookService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/books")
public class BookController {

    private final BookService service;

    public BookController(BookService service) {
        this.service = service;
    }

    @PostMapping(value = "/import", consumes = MediaType.TEXT_PLAIN_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public String importBooks(@RequestBody String rawData) {

        service.importBooks(rawData);

        return "Books imported successfully";
    }

    @GetMapping
    public List<BookDto> getBooks() {
        return service.getBooks();
    }
}
