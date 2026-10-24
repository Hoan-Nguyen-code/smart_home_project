
package com.smart_home_backend.service;

import com.smart_home_backend.entity.HomeMember;
import com.smart_home_backend.entity.IoTNode;
import com.smart_home_backend.entity.Room;
import com.smart_home_backend.entity.User;
import com.smart_home_backend.repository.HomeMemberRepository;
import com.smart_home_backend.repository.IoTNodeRepository;
import com.smart_home_backend.repository.RoomRepository;
import com.smart_home_backend.repository.UserRepository;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class IoTNodeService {

    private final IoTNodeRepository ioTNodeRepository;
    private final RoomRepository roomRepository;
    private final HomeMemberRepository homeMemberRepository;
    private final UserRepository userRepository;

    public IoTNodeService(
            IoTNodeRepository ioTNodeRepository,
            RoomRepository roomRepository,
            HomeMemberRepository homeMemberRepository,
            UserRepository userRepository
    ) {
        this.ioTNodeRepository = ioTNodeRepository;
        this.roomRepository = roomRepository;
        this.homeMemberRepository = homeMemberRepository;
        this.userRepository = userRepository;
    }

    // Lấy thông tin người dùng từ email trong JWT.
    private User getCurrentUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy tài khoản"
                ));
    }

    // Kiểm tra USER có quyền truy cập phòng hay không.
    private void checkRoomAccess(Long roomId, User user) {
        if ("ADMIN".equals(user.getRole())) {
            return;
        }

        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy phòng"
                ));

        boolean hasAccess = homeMemberRepository
                .existsByUserIdAndHomeId(
                        user.getId(),
                        room.getHomeId()
                );

        if (!hasAccess) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Bạn không có quyền truy cập ESP32 của phòng này"
            );
        }
    }

    // ADMIN xem tất cả, USER chỉ xem ESP32 thuộc nhà đã tham gia.
    public List<IoTNode> getAllNodes(String email) {
        User user = getCurrentUser(email);

        if ("ADMIN".equals(user.getRole())) {
            return ioTNodeRepository.findAll();
        }

        List<Long> homeIds = homeMemberRepository
                .findByUserId(user.getId())
                .stream()
                .map(HomeMember::getHomeId)
                .toList();

        if (homeIds.isEmpty()) {
            return List.of();
        }

        return ioTNodeRepository.findAll()
                .stream()
                .filter(node -> roomRepository.findById(node.getRoomId())
                        .map(room -> homeIds.contains(room.getHomeId()))
                        .orElse(false))
                .toList();
    }

    // Lấy thông tin một ESP32 theo ID.
    public IoTNode getNodeById(Long id, String email) {
        User user = getCurrentUser(email);

        IoTNode node = ioTNodeRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy ESP32"
                ));

        checkRoomAccess(node.getRoomId(), user);

        return node;
    }

    // Lấy danh sách ESP32 thuộc một phòng.
    public List<IoTNode> getNodesByRoomId(Long roomId, String email) {
        User user = getCurrentUser(email);

        // Kiểm tra phòng tồn tại trước.
        if (!roomRepository.existsById(roomId)) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Không tìm thấy phòng"
            );
        }

        checkRoomAccess(roomId, user);

        return ioTNodeRepository.findByRoomId(roomId);
    }
}
