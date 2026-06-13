package com.asm.dux.web;

import com.asm.dux.domain.usecase.GetUserByLoginUseCase;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for user-related endpoints.
 * Single responsibility: route HTTP → use-case → HTTP response.
 * All error handling is delegated to {@link com.asm.dux.exception.GlobalExceptionHandler}.
 */
@Slf4j
@RestController
@RequestMapping("/api/dux")
public class UserController {

    private final GetUserByLoginUseCase getUserByLoginUseCase;

    public UserController(GetUserByLoginUseCase getUserByLoginUseCase) {
        this.getUserByLoginUseCase = getUserByLoginUseCase;
    }

    @GetMapping("/user")
    public ResponseEntity<String> getUser(
            @RequestParam(defaultValue = "admin") String login) {
        log.info("GET /user - login={}", login);
        String result = getUserByLoginUseCase.execute(login);
        return ResponseEntity.ok(result);
    }
}
