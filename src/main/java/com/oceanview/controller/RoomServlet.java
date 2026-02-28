package com.oceanview.controller;

import com.oceanview.model.Room;
import com.oceanview.service.RoomService;
import com.oceanview.util.Constants;
import com.oceanview.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Room Servlet
 * Handles room operations
 * URL Mapping: /room (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class RoomServlet extends HttpServlet {
    
    private static final Logger logger = LoggerFactory.getLogger(RoomServlet.class);
    private RoomService roomService;
    
    @Override
    public void init() throws ServletException {
        roomService = new RoomService();
        logger.info("RoomServlet initialized");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        String servletPath = request.getServletPath();
        boolean isAdminPath = servletPath.startsWith("/admin");
        
        if (action == null) {
            action = "list";
        }
        
        switch (action) {
            case "view":
                viewRoom(request, response);
                break;
            case "list":
                listRooms(request, response, isAdminPath);
                break;
            case "search":
                searchRooms(request, response);
                break;
            case "available":
                getAvailableRooms(request, response);
                break;
            case "add":
                showAddForm(request, response);
                break;
            case "edit":
                showEditForm(request, response);
                break;
            case "delete":
                deleteRoom(request, response);
                break;
            case "updateStatus":
                updateRoomStatus(request, response);
                break;
            default:
                listRooms(request, response, isAdminPath);
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if ("create".equals(action)) {
            createRoom(request, response);
        } else if ("update".equals(action)) {
            updateRoom(request, response);
        } else if ("updateStatus".equals(action)) {
            updateRoomStatus(request, response);
        } else {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid action");
        }
    }
    
    /**
     * Create a new room
     */
    private void createRoom(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            // Get parameters
            String roomNumber = request.getParameter("roomNumber");
            String roomTypeStr = request.getParameter("roomType");
            String floorStr = request.getParameter("floor");
            String capacityStr = request.getParameter("capacity");
            String priceStr = request.getParameter("pricePerNight");
            String description = request.getParameter("description");
            String amenities = request.getParameter("amenities");
            String imageUrl = request.getParameter("imageUrl");
            
            // Validate input
            if (ValidationUtil.isEmpty(roomNumber) || ValidationUtil.isEmpty(roomTypeStr) ||
                !ValidationUtil.isValidInteger(floorStr) || !ValidationUtil.isValidInteger(capacityStr) ||
                !ValidationUtil.isValidDouble(priceStr)) {
                
                request.setAttribute(Constants.ATTR_ERROR, "Invalid input parameters");
                request.getRequestDispatcher("/views/admin/room-form.jsp").forward(request, response);
                return;
            }
            
            // Create room object
            String sizeStr = request.getParameter("size");
            String statusStr = request.getParameter("status");
            
            Room room = new Room();
            room.setRoomNumber(roomNumber.trim());
            room.setRoomType(Room.RoomType.valueOf(roomTypeStr));
            room.setFloor(Integer.parseInt(floorStr));
            room.setCapacity(Integer.parseInt(capacityStr));
            room.setPricePerNight(new BigDecimal(priceStr));
            if (sizeStr != null && !sizeStr.isEmpty() && ValidationUtil.isValidInteger(sizeStr)) {
                room.setSize(Integer.parseInt(sizeStr));
            }
            room.setDescription(description);
            room.setAmenities(amenities);
            // Auto-assign default image by room type if admin left the field blank
            if (imageUrl != null && !imageUrl.trim().isEmpty()) {
                room.setImageUrl(imageUrl.trim());
            } else {
                room.setImageUrl(RoomService.getDefaultImageUrl(room.getRoomType()));
            }
            if (statusStr != null && !statusStr.isEmpty()) {
                try { room.setStatus(Room.RoomStatus.valueOf(statusStr)); }
                catch (IllegalArgumentException e) { room.setStatus(Room.RoomStatus.AVAILABLE); }
            } else {
                room.setStatus(Room.RoomStatus.AVAILABLE);
            }
            
            int roomId = roomService.createRoom(room);
            
            HttpSession session = request.getSession();
            if (roomId > 0) {
                session.setAttribute(Constants.ATTR_SUCCESS, "Room created successfully!");
                response.sendRedirect(request.getContextPath() + "/room?action=view&id=" + roomId);
            } else {
                String errorMsg = roomId == -1 ? "Room number already exists" : "Failed to create room";
                request.setAttribute(Constants.ATTR_ERROR, errorMsg);
                request.getRequestDispatcher("/views/admin/room-form.jsp").forward(request, response);
            }
            
        } catch (Exception e) {
            logger.error("Error creating room", e);
            request.setAttribute(Constants.ATTR_ERROR, "Failed to create room");
            request.getRequestDispatcher("/views/admin/room-form.jsp").forward(request, response);
        }
    }
    
    /**
     * Update existing room
     */
    private void updateRoom(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            String roomIdStr = request.getParameter("roomId");
            
            if (!ValidationUtil.isValidInteger(roomIdStr)) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid room ID");
                return;
            }
            
            int roomId = Integer.parseInt(roomIdStr);
            Optional<Room> roomOpt = roomService.getRoomById(roomId);
            
            if (roomOpt.isEmpty()) {
                request.setAttribute(Constants.ATTR_ERROR, "Room not found");
                request.getRequestDispatcher("/views/admin/rooms.jsp").forward(request, response);
                return;
            }
            
            Room room = roomOpt.get();
            
            // Update room properties
            room.setRoomNumber(request.getParameter("roomNumber"));
            room.setRoomType(Room.RoomType.valueOf(request.getParameter("roomType")));
            room.setFloor(Integer.parseInt(request.getParameter("floor")));
            room.setCapacity(Integer.parseInt(request.getParameter("capacity")));
            room.setPricePerNight(new BigDecimal(request.getParameter("pricePerNight")));
            String sizeStr = request.getParameter("size");
            if (sizeStr != null && !sizeStr.isEmpty() && ValidationUtil.isValidInteger(sizeStr)) {
                room.setSize(Integer.parseInt(sizeStr));
            }
            room.setDescription(request.getParameter("description"));
            room.setAmenities(request.getParameter("amenities"));
            // Auto-assign default image by room type if admin left the field blank
            String imageUrlUpd = request.getParameter("imageUrl");
            if (imageUrlUpd != null && !imageUrlUpd.trim().isEmpty()) {
                room.setImageUrl(imageUrlUpd.trim());
            } else {
                room.setImageUrl(RoomService.getDefaultImageUrl(room.getRoomType()));
            }
            String statusStr = request.getParameter("status");
            if (statusStr != null && !statusStr.isEmpty()) {
                try { room.setStatus(Room.RoomStatus.valueOf(statusStr)); }
                catch (IllegalArgumentException ignore) {}
            }
            
            boolean success = roomService.updateRoom(room);
            
            HttpSession session = request.getSession();
            if (success) {
                session.setAttribute(Constants.ATTR_SUCCESS, "Room updated successfully!");
                response.sendRedirect(request.getContextPath() + "/room?action=view&id=" + roomId);
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Failed to update room");
                request.getRequestDispatcher("/views/admin/room-form.jsp").forward(request, response);
            }
            
        } catch (Exception e) {
            logger.error("Error updating room", e);
            request.setAttribute(Constants.ATTR_ERROR, "Failed to update room");
            request.getRequestDispatcher("/views/admin/room-form.jsp").forward(request, response);
        }
    }
    
    /**
     * View room details
     */
    private void viewRoom(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String idStr = request.getParameter("id");
        
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid room ID");
            return;
        }
        
        int roomId = Integer.parseInt(idStr);
        Optional<Room> roomOpt = roomService.getRoomById(roomId);
        
        if (roomOpt.isPresent()) {
            request.setAttribute("room", roomOpt.get());
            request.getRequestDispatcher("/views/rooms/room-details.jsp").forward(request, response);
        } else {
            request.setAttribute(Constants.ATTR_ERROR, "Room not found");
            request.getRequestDispatcher("/views/rooms/list.jsp").forward(request, response);
        }
    }
    
    /**
     * List all rooms - supports filtering by type, dates, guests
     */
    private void listRooms(HttpServletRequest request, HttpServletResponse response, boolean isAdminPath)
            throws ServletException, IOException {

        String checkInStr  = request.getParameter("checkIn");
        String checkOutStr = request.getParameter("checkOut");
        String roomTypeStr = request.getParameter("roomType");
        String guestsStr   = request.getParameter("guests");

        List<Room> rooms;
        LocalDate checkIn  = null;
        LocalDate checkOut = null;

        try {
            if (checkInStr != null && !checkInStr.isEmpty()
                    && checkOutStr != null && !checkOutStr.isEmpty()) {
                checkIn  = LocalDate.parse(checkInStr);
                checkOut = LocalDate.parse(checkOutStr);

                if (roomTypeStr != null && !roomTypeStr.isEmpty()) {
                    try {
                        Room.RoomType roomType = Room.RoomType.valueOf(roomTypeStr.toUpperCase());
                        rooms = roomService.searchAvailableRoomsByType(roomType, checkIn, checkOut);
                    } catch (IllegalArgumentException e) {
                        rooms = roomService.searchAvailableRooms(checkIn, checkOut);
                    }
                } else {
                    rooms = roomService.searchAvailableRooms(checkIn, checkOut);
                }

                // Client-side guest filter hint (capacity) — pass through
                if (guestsStr != null && !guestsStr.isEmpty()) {
                    request.setAttribute("minGuests", guestsStr);
                }

            } else {
                // No dates: show all rooms, but still filter by type if chosen
                if (roomTypeStr != null && !roomTypeStr.isEmpty()) {
                    try {
                        Room.RoomType roomType = Room.RoomType.valueOf(roomTypeStr.toUpperCase());
                        rooms = roomService.getRoomsByType(roomType);
                    } catch (IllegalArgumentException e) {
                        rooms = roomService.getAllRooms();
                    }
                } else {
                    rooms = roomService.getAllRooms();
                }
            }
        } catch (Exception e) {
            logger.error("Error listing rooms", e);
            rooms = roomService.getAllRooms();
        }

        request.setAttribute("rooms", rooms);
        request.setAttribute("checkIn",  checkIn);
        request.setAttribute("checkOut", checkOut);
        request.setAttribute("selectedType",   roomTypeStr);
        request.setAttribute("selectedGuests", guestsStr);

        if (isAdminPath) {
            request.getRequestDispatcher("/views/admin/rooms.jsp").forward(request, response);
        } else {
            request.getRequestDispatcher("/views/guest/rooms.jsp").forward(request, response);
        }
    }

    /**
     * Search available rooms (action=search, used by search form with checkInDate/checkOutDate params)
     */
    private void searchRooms(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String checkInStr  = request.getParameter("checkInDate");
        String checkOutStr = request.getParameter("checkOutDate");
        String roomTypeStr = request.getParameter("roomType");

        // Fall back to the shorter param names used by the rooms filter form
        if (checkInStr == null || checkInStr.isEmpty()) checkInStr  = request.getParameter("checkIn");
        if (checkOutStr == null || checkOutStr.isEmpty()) checkOutStr = request.getParameter("checkOut");

        try {
            LocalDate checkIn  = LocalDate.parse(checkInStr);
            LocalDate checkOut = LocalDate.parse(checkOutStr);

            List<Room> rooms;
            if (roomTypeStr != null && !roomTypeStr.isEmpty()) {
                try {
                    Room.RoomType roomType = Room.RoomType.valueOf(roomTypeStr.toUpperCase());
                    rooms = roomService.searchAvailableRoomsByType(roomType, checkIn, checkOut);
                } catch (IllegalArgumentException e) {
                    rooms = roomService.searchAvailableRooms(checkIn, checkOut);
                }
            } else {
                rooms = roomService.searchAvailableRooms(checkIn, checkOut);
            }

            request.setAttribute("rooms",    rooms);
            request.setAttribute("checkIn",  checkIn);
            request.setAttribute("checkOut", checkOut);
            request.setAttribute("selectedType", roomTypeStr);
            request.getRequestDispatcher("/views/guest/rooms.jsp").forward(request, response);

        } catch (Exception e) {
            logger.error("Error searching rooms", e);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid search parameters. Please enter valid dates.");
            List<Room> rooms = roomService.getAllRooms();
            request.setAttribute("rooms", rooms);
            request.getRequestDispatcher("/views/guest/rooms.jsp").forward(request, response);
        }
    }
    
    /**
     * Get available rooms
     */
    private void getAvailableRooms(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        List<Room> rooms = roomService.getAvailableRooms();
        request.setAttribute("rooms", rooms);
        request.getRequestDispatcher("/views/rooms/available.jsp").forward(request, response);
    }
    
    /**
     * Show add room form
     */
    private void showAddForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        request.getRequestDispatcher("/views/admin/room-form.jsp").forward(request, response);
    }
    
    /**
     * Show edit room form
     */
    private void showEditForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String idStr = request.getParameter("id");
        
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid room ID");
            return;
        }
        
        int roomId = Integer.parseInt(idStr);
        Optional<Room> roomOpt = roomService.getRoomById(roomId);
        
        if (roomOpt.isPresent()) {
            request.setAttribute("room", roomOpt.get());
            request.getRequestDispatcher("/views/admin/room-form.jsp").forward(request, response);
        } else {
            request.setAttribute(Constants.ATTR_ERROR, "Room not found");
            request.getRequestDispatcher("/views/admin/rooms.jsp").forward(request, response);
        }
    }
    
    /**
     * Update room status only (quick status change)
     */
    private void updateRoomStatus(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String idStr = request.getParameter("id");
        String statusStr = request.getParameter("status");

        if (!ValidationUtil.isValidInteger(idStr) || statusStr == null || statusStr.isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid parameters");
            return;
        }

        try {
            int roomId = Integer.parseInt(idStr);
            Room.RoomStatus newStatus = Room.RoomStatus.valueOf(statusStr.toUpperCase());
            boolean success = roomService.updateRoomStatus(roomId, newStatus);

            HttpSession session = request.getSession();
            if (success) {
                session.setAttribute(Constants.ATTR_SUCCESS, "Room status updated to " + newStatus.name());
            } else {
                session.setAttribute(Constants.ATTR_ERROR, "Failed to update room status");
            }
        } catch (IllegalArgumentException e) {
            request.getSession().setAttribute(Constants.ATTR_ERROR, "Invalid status value");
        }

        response.sendRedirect(request.getContextPath() + "/admin/rooms");
    }

    /**
     * Delete room
     */
    private void deleteRoom(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String idStr = request.getParameter("id");
        
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid room ID");
            return;
        }
        
        int roomId = Integer.parseInt(idStr);
        boolean success = roomService.deleteRoom(roomId);
        
        HttpSession session = request.getSession();
        if (success) {
            session.setAttribute(Constants.ATTR_SUCCESS, "Room deleted successfully!");
        } else {
            session.setAttribute(Constants.ATTR_ERROR, "Failed to delete room");
        }
        
        response.sendRedirect(request.getContextPath() + "/admin/rooms");
    }
}
