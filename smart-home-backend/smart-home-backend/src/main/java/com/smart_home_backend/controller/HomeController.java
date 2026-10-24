
package com.smart_home_backend.controller;

import com.smart_home_backend.entity.Home;
import com.smart_home_backend.service.HomeService;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/homes")
public class HomeController {

    private final HomeService homeService;

    public HomeController(HomeService homeService) {
        this.homeService = homeService;
    }

    @GetMapping("/my")
    public ResponseEntity<List<Home>> getMyHomes(
            Authentication authentication
    ) {
        List<Home> homes = homeService.getMyHomes(
                authentication.getName()
        );

        return ResponseEntity.ok(homes);
    }
}
