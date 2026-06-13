package com.asm.dux.domain.usecase;

import com.asm.dux.domain.port.UserGateway;
import org.springframework.stereotype.Component;

/**
 * Application use-case: retrieve a DUX user by their login name.
 * Depends only on the {@link UserGateway} port — no HTTP, no Spring web types.
 */
@Component
public class GetUserByLoginUseCase {

    private final UserGateway userGateway;

    public GetUserByLoginUseCase(UserGateway userGateway) {
        this.userGateway = userGateway;
    }

    public String execute(String login) {
        return userGateway.getUserByLogin(login);
    }
}
