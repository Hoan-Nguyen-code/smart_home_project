
package com.smart_home_backend.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public class CreateInvitationRequest {

    @NotNull(message = "ID nhà không được để trống")
    @Positive(message = "ID nhà phải lớn hơn 0")
    private Long homeId;

    public CreateInvitationRequest() {
    }

    public Long getHomeId() {
        return homeId;
    }

    public void setHomeId(Long homeId) {
        this.homeId = homeId;
    }
}
