
package com.smart_home_backend.service;

import com.smart_home_backend.entity.HomeMember;
import com.smart_home_backend.entity.Room;
import com.smart_home_backend.entity.User;
import com.smart_home_backend.repository.HomeMemberRepository;
import com.smart_home_backend.repository.RoomRepository;
import com.smart_home_backend.repository.UserRepository;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class RoomService {

    private final RoomRepository roomRepository;
    private final HomeMemberRepository homeMemberRepository;
    private final UserRepository userRepository;

    public RoomService(
            RoomRepository roomRepository,
            HomeMemberRepository homeMemberRepository,
            UserRepository userRepository
    ) {
        this.roomRepository = roomRepository;
        this.homeMemberRepository = homeMemberRepository;
        this.userRepository = userRepository;
    }

    // Lấy danh sách phòng theo quyền tài khoản
    public List<Room> getAllRooms(String email) {

        User user = getCurrentUser(email);

        if ("ADMIN".equals(user.getRole())) {
            return roomRepository.findAll();
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

            return roomRepository.findByHomeIdIn(homeIds);
        }

        throw new ResponseStatusException(
                HttpStatus.FORBIDDEN,
                "Tài khoản không có quyền xem phòng"
        );
    }

    // Xem chi tiết phòng theo quyền tài khoản
    public Room getRoomById(Long id, String email) {

        User user = getCurrentUser(email);

        Room room = findRoomOrThrow(id);

        if ("ADMIN".equals(user.getRole())) {
            return room;
        }

        if ("USER".equals(user.getRole())) {

            boolean isMember = homeMemberRepository
                    .existsByUserIdAndHomeId(
                            user.getId(),
                            room.getHomeId()
                    );

            if (isMember) {
                return room;
            }
        }

        throw new ResponseStatusException(
                HttpStatus.FORBIDDEN,
                "Bạn không có quyền truy cập phòng này"
        );
    }

    // ADMIN tạo phòng
    public Room createRoom(Room room) {

        boolean exists = roomRepository.existsByHomeIdAndName(
                room.getHomeId(),
                room.getName()
        );

        if (exists) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Tên phòng đã tồn tại trong nhà này"
            );
        }

        room.setId(null);
        return roomRepository.save(room);
    }

    // ADMIN cập nhật phòng
    public Room updateRoom(Long id, Room roomDetails) {

        Room room = findRoomOrThrow(id);

        String newName = roomDetails.getName();

        if (!room.getName().equals(newName)) {

            boolean exists = roomRepository.existsByHomeIdAndName(
                    room.getHomeId(),
                    newName
            );

            if (exists) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Tên phòng đã tồn tại trong nhà này"
                );
            }
        }

        room.setName(newName);
        room.setDescription(roomDetails.getDescription());

        return roomRepository.save(room);
    }

    // ADMIN xóa phòng
    public void deleteRoom(Long id) {

        Room room = findRoomOrThrow(id);

        try {
            roomRepository.delete(room);
            roomRepository.flush();

        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Không thể xóa phòng vì đang có ESP32, thiết bị hoặc cảm biến liên kết"
            );
        }
    }

    // Hàm nội bộ tìm phòng theo ID
    private Room findRoomOrThrow(Long id) {

        return roomRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy phòng với ID: " + id
                ));
    }

    // Hàm nội bộ lấy tài khoản từ email trong JWT
    private User getCurrentUser(String email) {

        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Không tìm thấy tài khoản đăng nhập"
                ));
    }
}
