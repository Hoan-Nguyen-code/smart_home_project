
package com.smart_home_backend.service;

import com.smart_home_backend.dto.CreateInvitationRequest;
import com.smart_home_backend.dto.CreateInvitationResponse;
import com.smart_home_backend.entity.HomeInvitation;
import com.smart_home_backend.entity.HomeMember;
import com.smart_home_backend.entity.User;
import com.smart_home_backend.repository.HomeInvitationRepository;
import com.smart_home_backend.repository.HomeMemberRepository;
import com.smart_home_backend.repository.HomeRepository;
import com.smart_home_backend.repository.UserRepository;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Optional;

@Service
public class HomeInvitationService {

    private static final String CODE_CHARACTERS =
            "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

    private static final int CODE_LENGTH = 12;

    private final SecureRandom secureRandom = new SecureRandom();

    private final HomeRepository homeRepository;
    private final HomeMemberRepository homeMemberRepository;
    private final HomeInvitationRepository homeInvitationRepository;
    private final UserRepository userRepository;

    public HomeInvitationService(
            HomeRepository homeRepository,
            HomeMemberRepository homeMemberRepository,
            HomeInvitationRepository homeInvitationRepository,
            UserRepository userRepository) {

        this.homeRepository = homeRepository;
        this.homeMemberRepository = homeMemberRepository;
        this.homeInvitationRepository = homeInvitationRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public CreateInvitationResponse createInvitation(
            CreateInvitationRequest request,
            String adminEmail) {

        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Không tìm thấy tài khoản ADMIN"
                ));

        if (!"ADMIN".equals(admin.getRole())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Chỉ ADMIN mới được tạo mã mời"
            );
        }

        Long homeId = request.getHomeId();

        if (!homeRepository.existsById(homeId)) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Không tìm thấy ngôi nhà"
            );
        }

        String code = generateUniqueCode();

        LocalDateTime expiresAt =
                LocalDateTime.now(ZoneOffset.UTC).plusHours(24);

        HomeInvitation invitation = new HomeInvitation();
        invitation.setHomeId(homeId);
        invitation.setCreatedBy(admin.getId());
        invitation.setCode(code);
        invitation.setExpiresAt(expiresAt);

        HomeInvitation saved =
                homeInvitationRepository.save(invitation);

        return new CreateInvitationResponse(
                saved.getId(),
                saved.getHomeId(),
                saved.getCode(),
                saved.getExpiresAt()
        );
    }

    @Transactional
    public void joinHome(String rawCode, String userEmail) {

        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Không tìm thấy tài khoản"
                ));

        if (!"USER".equals(user.getRole())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Chỉ USER mới sử dụng mã mời"
            );
        }

        if (rawCode == null || rawCode.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Mã mời không được để trống"
            );
        }

        String code = rawCode.trim().toUpperCase();

        HomeInvitation invitation =
                homeInvitationRepository.findByCodeForUpdate(code)
                        .orElseThrow(() -> new ResponseStatusException(
                                HttpStatus.NOT_FOUND,
                                "Mã mời không tồn tại"
                        ));

        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);

        if (invitation.getUsedAt() != null) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Mã mời đã được sử dụng"
            );
        }

        if (!invitation.getExpiresAt().isAfter(now)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Mã mời đã hết hạn"
            );
        }

        Long homeId = invitation.getHomeId();

        if (homeMemberRepository.existsByUserIdAndHomeId(
                user.getId(), homeId)) {

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Bạn đã là thành viên của ngôi nhà này"
            );
        }

        HomeMember member = new HomeMember();
        member.setUserId(user.getId());
        member.setHomeId(homeId);
        member.setJoinedAt(now);

        homeMemberRepository.save(member);

        invitation.setUsedAt(now);
        homeInvitationRepository.save(invitation);
    }

    private String generateUniqueCode() {

        for (int attempt = 0; attempt < 10; attempt++) {
            StringBuilder builder = new StringBuilder(CODE_LENGTH);

            for (int i = 0; i < CODE_LENGTH; i++) {
                int index = secureRandom.nextInt(
                        CODE_CHARACTERS.length()
                );
                builder.append(CODE_CHARACTERS.charAt(index));
            }

            String code = builder.toString();

            if (!homeInvitationRepository.existsByCode(code)) {
                return code;
            }
        }

        throw new ResponseStatusException(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "Không thể tạo mã mời. Vui lòng thử lại"
        );
    }
}
