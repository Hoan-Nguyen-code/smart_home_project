
package com.smart_home_backend.config;

import com.smart_home_backend.service.CustomUserDetailsService;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(
            CustomUserDetailsService userDetailsService,
            PasswordEncoder passwordEncoder
    ) {
        DaoAuthenticationProvider provider =
                new DaoAuthenticationProvider(userDetailsService);

        provider.setPasswordEncoder(passwordEncoder);

        return new ProviderManager(provider);
    }

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            JwtAuthenticationFilter jwtAuthenticationFilter
    ) throws Exception {

        http
                .csrf(csrf -> csrf.disable())

                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )

                .formLogin(form -> form.disable())
                .httpBasic(basic -> basic.disable())

                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint((request, response, e) ->
                                response.sendError(
                                        HttpStatus.UNAUTHORIZED.value(),
                                        "Unauthorized"
                                )
                        )
                        .accessDeniedHandler((request, response, e) ->
                                response.sendError(
                                        HttpStatus.FORBIDDEN.value(),
                                        "Forbidden"
                                )
                        )
                )


                .authorizeHttpRequests(auth -> auth
                        .dispatcherTypeMatchers(
                                jakarta.servlet.DispatcherType.ERROR
                        ).permitAll()

                        // Cho phép đăng nhập không cần JWT
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/auth/login"
                        ).permitAll()

                        // Chỉ ADMIN được thêm, sửa, xóa phòng
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/rooms",
                                "/api/rooms/**"
                        ).hasRole("ADMIN")

                        .requestMatchers(
                                HttpMethod.PUT,
                                "/api/rooms/**"
                        ).hasRole("ADMIN")

                        .requestMatchers(
                                HttpMethod.DELETE,
                                "/api/rooms/**"
                        ).hasRole("ADMIN")

                        // Chỉ ADMIN được thêm, sửa, xóa thiết bị
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/devices",
                                "/api/devices/**"
                        ).hasRole("ADMIN")

                        .requestMatchers(
                                HttpMethod.PUT,
                                "/api/devices/**"
                        ).hasRole("ADMIN")

                        .requestMatchers(
                                HttpMethod.DELETE,
                                "/api/devices/**"
                        ).hasRole("ADMIN")

                        // ADMIN và USER đều được điều khiển thiết bị
                        .requestMatchers(
                                HttpMethod.PATCH,
                                "/api/devices/*/status"
                        ).hasAnyRole("ADMIN", "USER")

                        // ADMIN và USER đều được xem phòng, thiết bị
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/rooms",
                                "/api/rooms/**",
                                "/api/devices",
                                "/api/devices/**"
                        ).hasAnyRole("ADMIN", "USER")

                        // Những API chưa khai báo quyền vẫn cần đăng nhập
                        .anyRequest().authenticated()
                )


                .addFilterBefore(
                        jwtAuthenticationFilter,
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }
}
