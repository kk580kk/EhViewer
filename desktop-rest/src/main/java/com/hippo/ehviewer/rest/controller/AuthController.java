package com.hippo.ehviewer.rest.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

  @PostMapping("/login")
  public ResponseEntity<String> login(@RequestBody String cookie) {
    // TODO integrate real authentication logic
    return ResponseEntity.ok("{\"status\":\"ok\",\"user\":\"demo\"}");
  }

  @GetMapping("/me")
  public ResponseEntity<String> me() {
    // TODO return real user info
    return ResponseEntity.ok("{\"username\":\"demo\",\"gp\":0,\"credit\":0}");
  }
}