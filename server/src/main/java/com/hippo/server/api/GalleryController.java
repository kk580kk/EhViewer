package com.hippo.server.api;

import com.hippo.server.service.SessionService;
import io.javalin.http.Context;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class GalleryController {
    private final SessionService sessionService;

    public GalleryController(SessionService sessionService) {
        this.sessionService = sessionService;
    }

    public void list(Context ctx) {
        // Phase 1: return stubbed list to unblock UI
        String pageStr = ctx.queryParam("page");
        int page = pageStr != null ? Integer.parseInt(pageStr) : 1;
        List<Map<String, Object>> items = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            Map<String, Object> it = new HashMap<>();
            it.put("id", "gid-" + ((page - 1) * 10 + i + 1));
            it.put("title", "Sample Gallery " + ((page - 1) * 10 + i + 1));
            it.put("cover", "");
            items.add(it);
        }
        Map<String, Object> data = new HashMap<>();
        data.put("page", page);
        data.put("items", items);
        ctx.json(ApiResponse.ok(data));
    }
}

