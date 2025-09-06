package com.hippo.server.api;

import com.hippo.server.service.SessionService;
import io.javalin.http.Context;

import java.util.Map;

public class AuthController {
    private final SessionService sessionService;

    public AuthController(SessionService sessionService) {
        this.sessionService = sessionService;
    }

    public void login(Context ctx) {
        // For phase 1, accept cookies from client and store in CookieJar
        Map<String, String> body = ctx.bodyAsClass(Map.class);
        String cookieHeader = body == null ? null : body.get("cookie");
        if (cookieHeader == null || cookieHeader.isEmpty()) {
            ctx.json(ApiResponse.error(2001, "cookie required"));
            return;
        }
        // No-op: CookieJar will be populated on first request to domain; here we just echo back
        ctx.json(ApiResponse.ok(Map.of("session", "accepted")));
    }
}

