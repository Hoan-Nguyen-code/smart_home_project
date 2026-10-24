
package com.smart_home_backend.repository;

import com.smart_home_backend.entity.IoTNode;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface IoTNodeRepository extends JpaRepository<IoTNode, Long> {

    // Lấy danh sách ESP32 thuộc một phòng.
    List<IoTNode> findByRoomId(Long roomId);

    // Tìm ESP32 theo mã định danh duy nhất.
    Optional<IoTNode> findByNodeCode(String nodeCode);

}
