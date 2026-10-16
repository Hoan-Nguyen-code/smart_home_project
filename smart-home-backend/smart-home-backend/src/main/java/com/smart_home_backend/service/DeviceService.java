
package com.smart_home_backend.service;

import com.smart_home_backend.entity.Device;
import com.smart_home_backend.repository.DeviceRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
@Service
public class DeviceService {

    private final DeviceRepository deviceRepository;

    public void deleteDevice(Long id) {
        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy thiết bị có ID: " + id
                ));

        deviceRepository.delete(device);
    }

    public Device updateDevice(Long id, Device updatedDevice) {
        Device existingDevice = deviceRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy thiết bị có ID: " + id
                ));

        existingDevice.setName(updatedDevice.getName());
        existingDevice.setType(updatedDevice.getType());
        existingDevice.setRoomId(updatedDevice.getRoomId());
        existingDevice.setNodeId(updatedDevice.getNodeId());
        existingDevice.setMqttChannel(updatedDevice.getMqttChannel());

        return deviceRepository.save(existingDevice);
    }

    public Device createDevice(Device device) {
        if (device.getId() != null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Không được truyền ID khi tạo thiết bị"
            );
        }

        device.setId(null);
        return deviceRepository.save(device);
    }

    public DeviceService(DeviceRepository deviceRepository) {
        this.deviceRepository = deviceRepository;
    }

    // Lấy tất cả thiết bị
    public List<Device> getAllDevices() {
        return deviceRepository.findAll();
    }

    // Lấy thiết bị theo phòng
    public List<Device> getDevicesByRoomId(Long roomId) {
        return deviceRepository.findByRoomId(roomId);
    }

    // Bật/tắt thiết bị
    public Device updateDeviceStatus(Long id, Boolean status) {
        if (status == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Trạng thái thiết bị không được để trống"
            );
        }

        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy thiết bị với ID: " + id
                ));

        device.setStatus(status);

        return deviceRepository.save(device);
    }
}
