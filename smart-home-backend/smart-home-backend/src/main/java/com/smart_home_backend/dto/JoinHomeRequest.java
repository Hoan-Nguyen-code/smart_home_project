
package com.smart_home_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class JoinHomeRequest {

    @NotBlank(message = "Mã mời không được để trống")
    @Size(max = 50, message = "Mã mời không được quá 50 ký tự")
    private String code;

    public JoinHomeRequest() {
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }
}
