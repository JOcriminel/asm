package com.asm.dux.controller;

import com.asm.dux.service.DuxUserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClientException;

@RestController
@RequestMapping("/api/dux")
public class DuxController {

    private final DuxUserService userService;

    public DuxController(DuxUserService userService) {
        this.userService = userService;
    }

    @GetMapping("/user")
    public ResponseEntity<String> user(
            @RequestParam(defaultValue = "admin") String login) {

        try {
            String result = userService.getUserByLogin(login);
            return ResponseEntity.ok(result);

        } catch (RestClientException e) {
            // HTTP call failed (timeout, connection refused, 4xx/5xx from remote)
            String msg = """            
                    {"error": "DUX API call failed", "detail": "%s"}
                    """.formatted(e.getMessage().replace("\"", "'"));
            return ResponseEntity.status(502).body(msg);

        } catch (Exception e) {
            // Any other unexpected error
            String msg = """
                    {"error": "Internal error", "detail": "%s"}
                    """.formatted(e.getMessage().replace("\"", "'"));
            return ResponseEntity.status(500).body(msg);
        }
    }
}