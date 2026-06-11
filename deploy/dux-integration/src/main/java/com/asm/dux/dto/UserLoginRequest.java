package com.asm.dux.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserLoginRequest {
    private String version = "Default";
    private boolean refresh = true;
    private String login;

    public UserLoginRequest(String login) {
        this.login = login;
    }
}
