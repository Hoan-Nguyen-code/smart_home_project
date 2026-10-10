
package com.smart_home_backend.repository;

import com.smart_home_backend.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoomRepository extends JpaRepository<Room, Long> {

    boolean existsByHomeIdAndName(Long homeId, String name);

}
