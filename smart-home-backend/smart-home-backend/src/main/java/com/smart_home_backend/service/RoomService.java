
package com.smart_home_backend.service;
import org.springframework.dao.DataIntegrityViolationException;
import com.smart_home_backend.entity.Room;
import com.smart_home_backend.repository.RoomRepository;
import org.springframework.stereotype.Service;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;

@Service
public class RoomService {

    private final RoomRepository roomRepository;

    public RoomService(RoomRepository roomRepository) {
        this.roomRepository = roomRepository;
    }

    public List<Room> getAllRooms() {
        return roomRepository.findAll();
    }
    public Room getRoomById(Long id) {
        return roomRepository.findById(id)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(
                        org.springframework.http.HttpStatus.NOT_FOUND,
                        "Không tìm thấy phòng với ID: " + id
                ));
    }


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



    public Room updateRoom(Long id, Room roomDetails) {

        Room room = getRoomById(id);

        String newName = roomDetails.getName();

        // Chỉ kiểm tra trùng khi tên phòng thay đổi
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



    public void deleteRoom(Long id) {

        Room room = getRoomById(id);

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


}
