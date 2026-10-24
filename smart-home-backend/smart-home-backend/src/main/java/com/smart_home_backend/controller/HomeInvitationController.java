
package com.smart_home_backend.controller;

import com.smart_home_backend.dto.CreateInvitationRequest;
import com.smart_home_backend.dto.CreateInvitationResponse;
import com.smart_home_backend.dto.JoinHomeRequest;
import com.smart_home_backend.service.HomeInvitationService;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/home-invitations")
public class HomeInvitationController {

    private final HomeInvitationService homeInvitationService;

    public HomeInvitationController(
            HomeInvitationService homeInvitationService) {
        this.homeInvitationService = homeInvitationService;
    }

    @PostMapping
    public ResponseEntity<CreateInvitationResponse> createInvitation(
            @Valid @RequestBody CreateInvitationRequest request,
            Authentication authentication) {

        CreateInvitationResponse response =
                homeInvitationService.createInvitation(
                        request,
                        authentication.getName()
                );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @PostMapping("/join")
    public ResponseEntity<Map<String, String>> joinHome(
            @Valid @RequestBody JoinHomeRequest request,
            Authentication authentication) {

        homeInvitationService.joinHome(
                request.getCode(),
                authentication.getName()
        );

        return ResponseEntity.ok(
                Map.of("message", "Tham gia nhà thành công")
        );
    }
}
