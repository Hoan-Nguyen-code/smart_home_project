
package com.smart_home_backend.controller;

import com.smart_home_backend.entity.Device;
import com.smart_home_backend.service.DeviceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import com.smart_home_backend.entity.Device;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.http.ResponseEntity;
import com.smart_home_backend.entity.Device;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.http.ResponseEntity;
@RestController
@RequestMapping("/api/devices")
public class DeviceController {

    private final DeviceService deviceService;

    public DeviceController(DeviceService deviceService) {
        this.deviceService = deviceService;
    }
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteDevice(@PathVariable Long id) {
        deviceService.deleteDevice(id);
        return ResponseEntity.noContent().build();
    }
    @PutMapping("/{id}")
    public ResponseEntity<Device> updateDevice(
            @PathVariable Long id,
            @RequestBody Device device
    ) {
        Device updatedDevice = deviceService.updateDevice(id, device);
        return ResponseEntity.ok(updatedDevice);
    }

    @PostMapping
    public ResponseEntity<Device> createDevice(@RequestBody Device device) {
        Device createdDevice = deviceService.createDevice(device);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(createdDevice);
    }

    // GET /api/devices
    @GetMapping
    public List<Device> getAllDevices() {
        return deviceService.getAllDevices();
    }

    // GET /api/devices/room/1
    @GetMapping("/room/{roomId}")
    public List<Device> getDevicesByRoomId(
            @PathVariable Long roomId
    ) {
        return deviceService.getDevicesByRoomId(roomId);
    }

    // PATCH /api/devices/1/status
    @PatchMapping("/{id}/status")
    public ResponseEntity<Device> updateDeviceStatus(
            @PathVariable Long id,
            @RequestBody Map<String, Boolean> request
    ) {
        Boolean status = request.get("status");

        Device updatedDevice =
                deviceService.updateDeviceStatus(id, status);

        return ResponseEntity.ok(updatedDevice);
    }
}
