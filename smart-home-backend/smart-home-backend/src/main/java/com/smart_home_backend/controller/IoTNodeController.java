
package com.smart_home_backend.controller;

import com.smart_home_backend.entity.IoTNode;
import com.smart_home_backend.service.IoTNodeService;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/iot-nodes")
public class IoTNodeController {

    private final IoTNodeService ioTNodeService;

    public IoTNodeController(IoTNodeService ioTNodeService) {
        this.ioTNodeService = ioTNodeService;
    }

    // ADMIN xem tất cả; USER chỉ xem ESP32 thuộc nhà đã tham gia.
    @GetMapping
    public ResponseEntity<List<IoTNode>> getAllNodes(
            Authentication authentication
    ) {
        return ResponseEntity.ok(
                ioTNodeService.getAllNodes(authentication.getName())
        );
    }

    // Xem thông tin một ESP32 theo ID.
    @GetMapping("/{id}")
    public ResponseEntity<IoTNode> getNodeById(
            @PathVariable Long id,
            Authentication authentication
    ) {
        return ResponseEntity.ok(
                ioTNodeService.getNodeById(
                        id,
                        authentication.getName()
                )
        );
    }

    // Xem các ESP32 thuộc một phòng.
    @GetMapping("/room/{roomId}")
    public ResponseEntity<List<IoTNode>> getNodesByRoomId(
            @PathVariable Long roomId,
            Authentication authentication
    ) {
        return ResponseEntity.ok(
                ioTNodeService.getNodesByRoomId(
                        roomId,
                        authentication.getName()
                )
        );
    }
}
