
package com.smart_home_backend.service;

import com.smart_home_backend.entity.Home;
import com.smart_home_backend.entity.HomeMember;
import com.smart_home_backend.entity.User;
import com.smart_home_backend.repository.HomeMemberRepository;
import com.smart_home_backend.repository.HomeRepository;
import com.smart_home_backend.repository.UserRepository;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class HomeService {

    private final HomeRepository homeRepository;
    private final HomeMemberRepository homeMemberRepository;
    private final UserRepository userRepository;

    public HomeService(
            HomeRepository homeRepository,
            HomeMemberRepository homeMemberRepository,
            UserRepository userRepository
    ) {
        this.homeRepository = homeRepository;
        this.homeMemberRepository = homeMemberRepository;
        this.userRepository = userRepository;
    }

    public List<Home> getMyHomes(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy tài khoản"
                ));

        // ADMIN có quyền xem tất cả nhà trong hệ thống.
        if ("ADMIN".equals(user.getRole())) {
            return homeRepository.findAll();
        }

        // USER chỉ xem những nhà đã tham gia.
        List<Long> homeIds = homeMemberRepository
                .findByUserId(user.getId())
                .stream()
                .map(HomeMember::getHomeId)
                .toList();

        if (homeIds.isEmpty()) {
            return List.of();
        }

        return homeRepository.findAllById(homeIds);
    }
}
