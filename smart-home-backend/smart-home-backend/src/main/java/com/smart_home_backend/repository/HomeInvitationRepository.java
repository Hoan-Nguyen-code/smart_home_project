
package com.smart_home_backend.repository;

import com.smart_home_backend.entity.HomeInvitation;

import jakarta.persistence.LockModeType;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface HomeInvitationRepository
        extends JpaRepository<HomeInvitation, Long> {

    Optional<HomeInvitation> findByCode(String code);

    boolean existsByCode(String code);

    List<HomeInvitation> findByHomeId(Long homeId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
           SELECT i
           FROM HomeInvitation i
           WHERE i.code = :code
           """)
    Optional<HomeInvitation> findByCodeForUpdate(
            @Param("code") String code
    );
}
