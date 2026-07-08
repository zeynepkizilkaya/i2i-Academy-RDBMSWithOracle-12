package com.zeynep.rdbmswithoracle.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class BookDto {

    private Long id;
    private String title;
    private String authorName;
    private String publisherName;
    private String isbn;
    private Integer publicationYear;

}