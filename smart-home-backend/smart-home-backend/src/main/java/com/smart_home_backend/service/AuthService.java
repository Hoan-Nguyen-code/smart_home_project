
package com.smart_home_backend.service;

import com.smart_home_backend.dto.LoginRequest;
import com.smart_home_backend.dto.LoginResponse;
import com.smart_home_backend.dto.RegisterRequest;
import com.smart_home_backend.dto.RegisterResponse;
import com.smart_home_backend.entity.User;
import com.smart_home_backend.repository.UserRepository;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.Locale;

@Service
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    public AuthService(
            AuthenticationManager authenticationManager,
            UserRepository userRepository,
            JwtService jwtService,
            PasswordEncoder passwordEncoder
    ) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.passwordEncoder = passwordEncoder;
    }

    public LoginResponse login(LoginRequest request) {

        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getEmail(),
                            request.getPassword()
                    )
            );
        } catch (AuthenticationException e) {
            throw new BadCredentialsException(
                    "Email hoặc mật khẩu không chính xác"
            );
        }

        User user = userRepository
                .findByEmail(request.getEmail())
                .orElseThrow(() ->
                        new BadCredentialsException(
                                "Email hoặc mật khẩu không chính xác"
                        )
                );

        String token = jwtService.generateToken(user.getEmail());

        return new LoginResponse(
                token,
                user.getEmail(),
                user.getRole()
        );
    }

    public RegisterResponse register(RegisterRequest request) {

        String fullName = request.getFullName().trim();
        String email = request.getEmail()
                .trim()
                .toLowerCase(Locale.ROOT);

        String password = request.getPassword();

        // BCrypt chỉ xử lý tối đa 72 byte mật khẩu.
        if (password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new IllegalArgumentException(
                    "Mật khẩu không được vượt quá 72 byte UTF-8"
            );
        }

        // Kiểm tra email đã được đăng ký chưa.
        if (userRepository.findByEmail(email).isPresent()) {
            throw new IllegalArgumentException(
                    "Email đã được sử dụng"
            );
        }

        User user = new User();
        user.setFullName(fullName);
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(password));

        // Không nhận role từ phía client.
        user.setRole("USER");

        try {
            User savedUser = userRepository.saveAndFlush(user);

            return new RegisterResponse(
                    savedUser.getId(),
                    savedUser.getFullName(),
                    savedUser.getEmail(),
                    savedUser.getRole()
            );
        } catch (DataIntegrityViolationException e) {
            throw new IllegalArgumentException(
                    "Không thể đăng ký: email đã tồn tại hoặc dữ liệu không hợp lệ"
            );
        }
    }
}
