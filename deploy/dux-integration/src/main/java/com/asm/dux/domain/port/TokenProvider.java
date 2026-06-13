package com.asm.dux.domain.port;

/**
 * Domain port — abstracts how an access token is obtained.
 * Infrastructure adapters (e.g. KeycloakTokenAdapter) implement this.
 * Dependency-Inversion: domain code never imports Spring or Keycloak classes.
 */
public interface TokenProvider {
    String getAccessToken();
}
