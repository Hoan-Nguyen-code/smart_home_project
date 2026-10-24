
package com.smart_home_backend.controller;

import com.smart_home_backend.entity.Device;
import com.smart_home_backend.service.DeviceService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/devices")
public class DeviceController {

    private final DeviceService deviceService;

    public DeviceController(DeviceService deviceService) {
        this.deviceService = deviceService;
    }

    // ADMIN xóa thiết bị
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteDevice(
            @PathVariable Long id
    ) {
        deviceService.deleteDevice(id);

        return ResponseEntity.noContent().build();
    }

    // ADMIN cập nhật thiết bị
    @PutMapping("/{id}")
    public ResponseEntity<Device> updateDevice(
            @PathVariable Long id,
            @RequestBody Device device
    ) {
        Device updatedDevice =
                deviceService.updateDevice(id, device);

        return ResponseEntity.ok(updatedDevice);
    }

    // ADMIN tạo thiết bị
    @PostMapping
    public ResponseEntity<Device> createDevice(
            @RequestBody Device device
    ) {
        Device createdDevice =
                deviceService.createDevice(device);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(createdDevice);
    }

    // Lấy danh sách thiết bị theo quyền tài khoản
    @GetMapping
    public List<Device> getAllDevices(
            Authentication authentication
    ) {
        String email = authentication.getName();

        return deviceService.getAllDevices(email);
    }

    // Lấy thiết bị theo phòng và kiểm tra quyền
    @GetMapping("/room/{roomId}")
    public List<Device> getDevicesByRoomId(
            @PathVariable Long roomId,
            Authentication authentication
    ) {
        String email = authentication.getName();

        return deviceService.getDevicesByRoomId(
                roomId,
                email
        );
    }

    // Bật/tắt thiết bị sau khi kiểm tra quyền
    @PatchMapping("/{id}/status")
    public ResponseEntity<Device> updateDeviceStatus(
            @PathVariable Long id,
            @RequestBody Map<String, Boolean> request,
            Authentication authentication
    ) {
        Boolean status = request.get("status");

        String email = authentication.getName();

        Device updatedDevice =
                deviceService.updateDeviceStatus(
                        id,
                        status,
                        email
                );

        return ResponseEntity.ok(updatedDevice);
    }
}
