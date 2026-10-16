
package com.smart_home_backend.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Entity
@Table(name = "devices")
public class Device {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "node_id", nullable = false)
    private Long nodeId;

    @NotBlank(message = "Tên thiết bị không được để trống")
    @Size(max = 100, message = "Tên thiết bị không được vượt quá 100 ký tự")
    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @NotBlank(message = "Loại thiết bị không được để trống")
    @Column(name = "type", nullable = false)
    private String type;

    @Column(name = "status", nullable = false)
    private Boolean status;

    @NotBlank(message = "Kênh MQTT không được để trống")
    @Column(name = "mqtt_channel", nullable = false)
    private String mqttChannel;

    public Device() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getRoomId() {
        return roomId;
    }

    public void setRoomId(Long roomId) {
        this.roomId = roomId;
    }

    public Long getNodeId() {
        return nodeId;
    }

    public void setNodeId(Long nodeId) {
        this.nodeId = nodeId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Boolean getStatus() {
        return status;
    }

    public void setStatus(Boolean status) {
        this.status = status;
    }

    public String getMqttChannel() {
        return mqttChannel;
    }

    public void setMqttChannel(String mqttChannel) {
        this.mqttChannel = mqttChannel;
    }
}
