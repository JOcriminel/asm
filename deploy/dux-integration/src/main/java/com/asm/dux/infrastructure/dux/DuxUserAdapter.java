package com.asm.dux.infrastructure.dux;

import com.asm.dux.domain.port.UserGateway;
import com.asm.dux.dto.UserLoginRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Infrastructure adapter: implements {@link UserGateway} by calling the DUX ERP user API.
 */
@Component
public class DuxUserAdapter implements UserGateway {

    private final DuxHttpClient httpClient;

    @Value("${dux.user-url}")
    private String userUrl;

    public DuxUserAdapter(DuxHttpClient httpClient) {
        this.httpClient = httpClient;
    }

    @Override
    public String getUserByLogin(String login) {
        return httpClient.post(userUrl, new UserLoginRequest(login));
    }
}
