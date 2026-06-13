package com.asm.dux.domain.port;

/**
 * Domain port — abstracts user lookup in the DUX ERP system.
 */
public interface UserGateway {
    String getUserByLogin(String login);
}
