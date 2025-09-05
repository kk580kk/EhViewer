package com.hippo.ehviewer.rest.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class SearchController {

  @GetMapping("/search")
  public ResponseEntity<String> search(@RequestParam("kw") String keyword, @RequestParam(value = "page", defaultValue = "0") int page) {
    // TODO integrate real search logic
    return ResponseEntity.ok("{\"keyword\":\"" + keyword + "\",\"page\":" + page + "}");
  }
}