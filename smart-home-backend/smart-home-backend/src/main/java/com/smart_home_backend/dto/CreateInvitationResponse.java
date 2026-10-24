
package com.smart_home_backend.dto;

import java.time.LocalDateTime;

public class CreateInvitationResponse {

    private Long id;
    private Long homeId;
    private String code;
    private LocalDateTime expiresAt;

    public CreateInvitationResponse() {
    }

    public CreateInvitationResponse(
            Long id,
            Long homeId,
            String code,
            LocalDateTime expiresAt) {

        this.id = id;
        this.homeId = homeId;
        this.code = code;
        this.expiresAt = expiresAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getHomeId() {
        return homeId;
    }

    public void setHomeId(Long homeId) {
        this.homeId = homeId;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }
}
