package com.hippo.server;

import io.javalin.Javalin;
import io.javalin.http.Context;

import java.util.HashMap;
import java.util.Map;

public class Main {
    public static void main(String[] args) {
        int port = 8080;
        Javalin app = Javalin.create(config -> {
            config.http.defaultContentType = "application/json";
            config.showJavalinBanner = false;
        }).start(port);

        app.get("/api/health", Main::healthHandler);
    }

    private static void healthHandler(Context ctx) {
        Map<String, Object> body = new HashMap<>();
        body.put("status", "ok");
        ctx.json(body);
    }
}

