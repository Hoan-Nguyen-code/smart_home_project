
package com.smart_home_backend.service;

import com.smart_home_backend.entity.Device;
import com.smart_home_backend.entity.HomeMember;
import com.smart_home_backend.entity.Room;
import com.smart_home_backend.entity.User;

import com.smart_home_backend.repository.DeviceRepository;
import com.smart_home_backend.repository.HomeMemberRepository;
import com.smart_home_backend.repository.RoomRepository;
import com.smart_home_backend.repository.UserRepository;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class DeviceService {

    private final DeviceRepository deviceRepository;
    private final RoomRepository roomRepository;
    private final HomeMemberRepository homeMemberRepository;
    private final UserRepository userRepository;

    public DeviceService(
            DeviceRepository deviceRepository,
            RoomRepository roomRepository,
            HomeMemberRepository homeMemberRepository,
            UserRepository userRepository
    ) {
        this.deviceRepository = deviceRepository;
        this.roomRepository = roomRepository;
        this.homeMemberRepository = homeMemberRepository;
        this.userRepository = userRepository;
    }

    // Lấy danh sách thiết bị theo quyền tài khoản
    public List<Device> getAllDevices(String email) {

        User user = getCurrentUser(email);

        if ("ADMIN".equals(user.getRole())) {
            return deviceRepository.findAll();
        }

        if ("USER".equals(user.getRole())) {

            List<Long> homeIds = homeMemberRepository
                    .findByUserId(user.getId())
                    .stream()
                    .map(HomeMember::getHomeId)
                    .toList();

            if (homeIds.isEmpty()) {
                return List.of();
            }

            return deviceRepository.findByHomeIds(homeIds);
        }

        throw new ResponseStatusException(
                HttpStatus.FORBIDDEN,
                "Tài khoản không có quyền xem thiết bị"
        );
    }

    // Lấy thiết bị theo phòng và kiểm tra quyền truy cập
    public List<Device> getDevicesByRoomId(
            Long roomId,
            String email
    ) {
        User user = getCurrentUser(email);

        Room room = findRoomOrThrow(roomId);

        checkHomeAccess(user, room.getHomeId());

        return deviceRepository.findByRoomId(roomId);
    }

    // Bật/tắt thiết bị sau khi kiểm tra quyền
    public Device updateDeviceStatus(
            Long id,
            Boolean status,
            String email
    ) {
        if (status == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Trạng thái thiết bị không được để trống"
            );
        }

        User user = getCurrentUser(email);

        Device device = findDeviceOrThrow(id);

        Room room = findRoomOrThrow(device.getRoomId());

        checkHomeAccess(user, room.getHomeId());

        device.setStatus(status);

        return deviceRepository.save(device);
    }

    // ADMIN tạo thiết bị
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

    // ADMIN cập nhật thiết bị
    public Device updateDevice(
            Long id,
            Device updatedDevice
    ) {
        Device existingDevice = findDeviceOrThrow(id);

        existingDevice.setName(updatedDevice.getName());
        existingDevice.setType(updatedDevice.getType());
        existingDevice.setRoomId(updatedDevice.getRoomId());
        existingDevice.setNodeId(updatedDevice.getNodeId());
        existingDevice.setMqttChannel(
                updatedDevice.getMqttChannel()
        );

        return deviceRepository.save(existingDevice);
    }

    // ADMIN xóa thiết bị
    public void deleteDevice(Long id) {

        Device device = findDeviceOrThrow(id);

        deviceRepository.delete(device);
    }

    // Kiểm tra quyền truy cập nhà
    private void checkHomeAccess(User user, Long homeId) {

        if ("ADMIN".equals(user.getRole())) {
            return;
        }

        if ("USER".equals(user.getRole())) {

            boolean isMember = homeMemberRepository
                    .existsByUserIdAndHomeId(
                            user.getId(),
                            homeId
                    );

            if (isMember) {
                return;
            }
        }

        throw new ResponseStatusException(
                HttpStatus.FORBIDDEN,
                "Bạn không có quyền truy cập thiết bị thuộc nhà này"
        );
    }

    // Tìm thiết bị theo ID
    private Device findDeviceOrThrow(Long id) {

        return deviceRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy thiết bị với ID: " + id
                ));
    }

    // Tìm phòng theo ID
    private Room findRoomOrThrow(Long roomId) {

        return roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy phòng với ID: " + roomId
                ));
    }

    // Lấy tài khoản đang đăng nhập
    private User getCurrentUser(String email) {

        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Không tìm thấy tài khoản đăng nhập"
                ));
    }
}
