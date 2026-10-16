
package com.smart_home_backend.repository;

import com.smart_home_backend.entity.Device;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DeviceRepository extends JpaRepository<Device, Long> {

    List<Device> findByRoomId(Long roomId);

}
