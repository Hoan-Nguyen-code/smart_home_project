
package com.smart_home_backend.repository;

import com.smart_home_backend.entity.HomeMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HomeMemberRepository
        extends JpaRepository<HomeMember, Long> {

    boolean existsByUserIdAndHomeId(Long userId, Long homeId);

    boolean existsByUserId(Long userId);

    List<HomeMember> findByUserId(Long userId);
}
