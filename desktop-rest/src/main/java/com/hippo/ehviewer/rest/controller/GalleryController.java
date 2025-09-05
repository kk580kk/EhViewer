package com.hippo.ehviewer.rest.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/gallery")
public class GalleryController {

  @GetMapping("/{gid}")
  public ResponseEntity<String> gallery(@PathVariable("gid") String gid) {
    // TODO integrate real gallery detail logic
    return ResponseEntity.ok("{\"gid\":\"" + gid + "\",\"title\":\"placeholder\"}");
  }
}