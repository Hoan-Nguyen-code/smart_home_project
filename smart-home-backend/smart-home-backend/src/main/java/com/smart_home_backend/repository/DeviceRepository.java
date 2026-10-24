
package com.smart_home_backend.repository;

import com.smart_home_backend.entity.Device;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface DeviceRepository extends JpaRepository<Device, Long> {

    // Lấy thiết bị theo phòng (giữ nguyên)
    List<Device> findByRoomId(Long roomId);

    // Lấy thiết bị thuộc các nhà mà USER đã tham gia
    @Query("""
            SELECT d
            FROM Device d, Room r
            WHERE d.roomId = r.id
              AND r.homeId IN :homeIds
            """)
    List<Device> findByHomeIds(
            @Param("homeIds") List<Long> homeIds
    );
}
