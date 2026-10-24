
package com.smart_home_backend.controller;

import com.smart_home_backend.entity.Room;
import com.smart_home_backend.service.RoomService;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/rooms")
public class RoomController {

    private final RoomService roomService;

    public RoomController(RoomService roomService) {
        this.roomService = roomService;
    }

    // Lấy danh sách phòng theo quyền tài khoản
    @GetMapping
    public List<Room> getAllRooms(Authentication authentication) {

        String email = authentication.getName();

        return roomService.getAllRooms(email);
    }

    // Xem chi tiết phòng theo quyền tài khoản
    @GetMapping("/{id}")
    public Room getRoomById(
            @PathVariable Long id,
            Authentication authentication
    ) {

        String email = authentication.getName();

        return roomService.getRoomById(id, email);
    }

    // ADMIN tạo phòng
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Room createRoom(@Valid @RequestBody Room room) {

        return roomService.createRoom(room);
    }

    // ADMIN cập nhật phòng
    @PutMapping("/{id}")
    public Room updateRoom(
            @PathVariable Long id,
            @Valid @RequestBody Room roomDetails
    ) {

        return roomService.updateRoom(id, roomDetails);
    }

    // ADMIN xóa phòng
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRoom(@PathVariable Long id) {

        roomService.deleteRoom(id);

        return ResponseEntity.noContent().build();
    }
}
