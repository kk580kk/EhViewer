package com.hippo.server;

import com.hippo.server.api.AuthController;
import com.hippo.server.api.GalleryController;
import com.hippo.server.api.ApiResponse;
import com.hippo.server.service.SessionService;
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

        SessionService sessionService = new SessionService();
        AuthController auth = new AuthController(sessionService);
        GalleryController galleries = new GalleryController(sessionService);

        app.get("/api/health", Main::healthHandler);
        app.post("/api/login", auth::login);
        app.get("/api/galleries", galleries::list);
    }

    private static void healthHandler(Context ctx) {
        ctx.json(ApiResponse.ok(Map.of("status", "ok")));
    }
}

