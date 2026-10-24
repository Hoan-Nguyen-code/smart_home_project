
package com.smart_home_backend.repository;

import com.smart_home_backend.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RoomRepository extends JpaRepository<Room, Long> {

    // Kiểm tra tên phòng đã tồn tại trong nhà
    boolean existsByHomeIdAndName(Long homeId, String name);

    // Lấy danh sách phòng thuộc một nhà
    List<Room> findByHomeId(Long homeId);

    // Lấy danh sách phòng thuộc các nhà USER đã tham gia
    List<Room> findByHomeIdIn(List<Long> homeIds);
}
