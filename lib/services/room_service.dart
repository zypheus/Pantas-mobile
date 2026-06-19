import 'package:intl/intl.dart';

import '../core/cache/memory_cache_store.dart';
import '../core/network/api_client.dart';
import '../models/room.dart';
import '../models/room_reservation.dart';
import '../models/user.dart';

class RoomService {
  static final RoomService _instance = RoomService._internal();

  factory RoomService() => _instance;

  RoomService._internal();

  final ApiClient _apiClient = ApiClient();
  final MemoryCacheStore _cache = MemoryCacheStore.instance;
  String? lastMessage;

  static const _roomsTtl = Duration(minutes: 15);
  static const _availabilityTtl = Duration(minutes: 1);
  static const _reservationsTtl = Duration(minutes: 2);
  static const _reservationDetailsTtl = Duration(minutes: 2);
  static const _dashboardTtl = Duration(minutes: 1);

  Future<RoomDashboard> getDashboard({
    DateTime? date,
    String? roomId,
    bool refresh = false,
  }) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date ?? DateTime.now());
    final queryParameters = {'date': dateKey, 'room_id': roomId}
      ..removeWhere((_, value) => value == null || value == '');

    return _cache.getOrFetch<RoomDashboard>(
      _cacheKey('rooms:dashboard', queryParameters),
      ttl: _dashboardTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get(
          '/rooms/dashboard',
          queryParameters: queryParameters,
        );
        final data = _asMap(response['data']);
        final rooms = data['rooms'];
        final reservations = data['reservations'];

        return RoomDashboard(
          currentUser: User.fromApiJson(_asMap(data['current_user'])),
          rooms: rooms is List
              ? rooms
                    .map((item) => Room.fromJson(_asMap(item)))
                    .toList(growable: false)
              : const [],
          reservations: reservations is List
              ? reservations
                    .map((item) => RoomReservation.fromJson(_asMap(item)))
                    .toList(growable: false)
              : const [],
          availability: RoomAvailability.fromJson(_asMap(data['availability'])),
        );
      },
    );
  }

  Future<List<Room>> getRooms({bool refresh = false}) async {
    return _cache.getOrFetch<List<Room>>(
      'rooms:list',
      ttl: _roomsTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get('/rooms');
        final data = response['data'];
        if (data is! List) return const [];

        return data
            .map((item) => Room.fromJson(_asMap(item)))
            .toList(growable: false);
      },
    );
  }

  Future<RoomAvailability> getAvailability(
    String roomId,
    DateTime date, {
    bool refresh = false,
  }) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    return _cache.getOrFetch<RoomAvailability>(
      'rooms:availability:$roomId:$dateKey',
      ttl: _availabilityTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get(
          '/rooms/availability',
          queryParameters: {'room_id': roomId, 'date': dateKey},
        );

        return RoomAvailability.fromJson(_asMap(response['data']));
      },
    );
  }

  Future<RoomReservation> submitRoomReservation({
    required String roomId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required int numberOfStudents,
    required List<String> studentNames,
    String? notes,
  }) async {
    final start = _splitTime(startTime);
    final end = _splitTime(endTime);
    final response = await _apiClient.post(
      '/rooms/reservations',
      body: {
        'room_id': int.tryParse(roomId) ?? roomId,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'start_time': start.time,
        'start_ampm': start.ampm,
        'end_time': end.time,
        'end_ampm': end.ampm,
        'number_of_students': numberOfStudents,
        'student_names': studentNames,
        'notes': notes,
      }..removeWhere((_, value) => value == null),
    );

    lastMessage = response['message']?.toString();
    invalidateReservationCaches();
    _cache.invalidateByPrefix('rooms:availability:$roomId:');

    return RoomReservation.fromJson(_asMap(response['data']));
  }

  Future<List<RoomReservation>> getUserReservations({
    bool refresh = false,
  }) async {
    return _cache.getOrFetch<List<RoomReservation>>(
      'rooms:reservations:user',
      ttl: _reservationsTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get('/rooms/reservations');
        final data = response['data'];
        if (data is! List) return const [];

        return data
            .map((item) => RoomReservation.fromJson(_asMap(item)))
            .toList(growable: false);
      },
    );
  }

  Future<RoomReservation> getReservationDetails(
    String id, {
    bool refresh = false,
  }) async {
    return _cache.getOrFetch<RoomReservation>(
      'rooms:reservation:$id',
      ttl: _reservationDetailsTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get('/rooms/reservations/$id');
        return RoomReservation.fromJson(_asMap(response['data']));
      },
    );
  }

  Future<RoomReservation> cancelReservation(String id) async {
    final response = await _apiClient.delete('/rooms/reservations/$id');
    lastMessage = response['message']?.toString();
    invalidateReservationCaches();
    _cache.remove('rooms:reservation:$id');

    return RoomReservation.fromJson(_asMap(response['data']));
  }

  Future<List<String>> getAvailableRooms(
    DateTime date, {
    bool refresh = false,
  }) async {
    final rooms = await getRooms(refresh: refresh);
    return rooms.map((room) => room.name).toList(growable: false);
  }

  Future<List<String>> getAvailableTimeSlots(
    String room,
    DateTime date, {
    bool refresh = false,
  }) async {
    final rooms = await getRooms();
    final selected = rooms.where((item) => item.name == room).firstOrNull;
    if (selected == null) return const [];

    final availability = await getAvailability(
      selected.id,
      date,
      refresh: refresh,
    );
    return defaultTimeSlots
        .where((slot) => !availability.isBooked(slot.start24, slot.end24))
        .map((slot) => slot.label)
        .toList(growable: false);
  }

  Future<bool> submitReservation(
    String room,
    DateTime date,
    String startTime,
    String endTime,
  ) async {
    final rooms = await getRooms();
    final selected = rooms.where((item) => item.name == room).firstOrNull;
    if (selected == null) return false;

    await submitRoomReservation(
      roomId: selected.id,
      date: date,
      startTime: startTime,
      endTime: endTime,
      numberOfStudents: 1,
      studentNames: const ['Jane Doe'],
    );
    return true;
  }

  void invalidateReservationCaches() {
    _cache.invalidateByPrefix('rooms:reservations:');
    _cache.invalidateByPrefix('rooms:reservation:');
    _cache.invalidateByPrefix('rooms:availability:');
    _cache.invalidateByPrefix('rooms:dashboard:');
  }

  void invalidateRoomCaches() {
    _cache.invalidateByPrefix('rooms:');
  }

  TimeParts _splitTime(String value) {
    final parsed = DateFormat('h:mm a').parse(value);
    return TimeParts(
      time: DateFormat('h:mm').format(parsed),
      ampm: DateFormat('a').format(parsed),
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  String _cacheKey(String prefix, Map<String, dynamic> values) {
    final entries = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final query = entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    return '$prefix:$query';
  }
}

class RoomDashboard {
  final User currentUser;
  final List<Room> rooms;
  final List<RoomReservation> reservations;
  final RoomAvailability availability;

  const RoomDashboard({
    required this.currentUser,
    required this.rooms,
    required this.reservations,
    required this.availability,
  });
}

class RoomAvailability {
  final String roomId;
  final DateTime date;
  final List<BookedRoomSlot> bookedSlots;

  const RoomAvailability({
    required this.roomId,
    required this.date,
    required this.bookedSlots,
  });

  factory RoomAvailability.fromJson(Map<String, dynamic> json) {
    final bookedSlots = json['booked_slots'];

    return RoomAvailability(
      roomId: json['room_id']?.toString() ?? '',
      date:
          DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      bookedSlots: bookedSlots is List
          ? bookedSlots
                .map((item) => BookedRoomSlot.fromJson(_asMap(item)))
                .toList(growable: false)
          : const [],
    );
  }

  bool isBooked(String startTime, String endTime) {
    final start = _minutes(startTime);
    final end = _minutes(endTime);

    return bookedSlots.any((slot) {
      final bookedStart = _minutes(slot.startTime);
      final bookedEnd = _minutes(slot.endTime);
      return start < bookedEnd && end > bookedStart;
    });
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}

class BookedRoomSlot {
  final String reservationId;
  final String startTime;
  final String endTime;
  final String status;

  const BookedRoomSlot({
    required this.reservationId,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory BookedRoomSlot.fromJson(Map<String, dynamic> json) {
    return BookedRoomSlot(
      reservationId: json['reservation_id']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class RoomTimeSlot {
  final String label;
  final String startLabel;
  final String endLabel;
  final String start24;
  final String end24;

  const RoomTimeSlot({
    required this.label,
    required this.startLabel,
    required this.endLabel,
    required this.start24,
    required this.end24,
  });
}

class TimeParts {
  final String time;
  final String ampm;

  const TimeParts({required this.time, required this.ampm});
}

const defaultTimeSlots = [
  RoomTimeSlot(
    label: '9:00 AM - 10:00 AM',
    startLabel: '9:00 AM',
    endLabel: '10:00 AM',
    start24: '09:00:00',
    end24: '10:00:00',
  ),
  RoomTimeSlot(
    label: '10:00 AM - 11:00 AM',
    startLabel: '10:00 AM',
    endLabel: '11:00 AM',
    start24: '10:00:00',
    end24: '11:00:00',
  ),
  RoomTimeSlot(
    label: '11:00 AM - 12:00 PM',
    startLabel: '11:00 AM',
    endLabel: '12:00 PM',
    start24: '11:00:00',
    end24: '12:00:00',
  ),
  RoomTimeSlot(
    label: '1:00 PM - 2:00 PM',
    startLabel: '1:00 PM',
    endLabel: '2:00 PM',
    start24: '13:00:00',
    end24: '14:00:00',
  ),
  RoomTimeSlot(
    label: '2:00 PM - 3:00 PM',
    startLabel: '2:00 PM',
    endLabel: '3:00 PM',
    start24: '14:00:00',
    end24: '15:00:00',
  ),
  RoomTimeSlot(
    label: '3:00 PM - 4:00 PM',
    startLabel: '3:00 PM',
    endLabel: '4:00 PM',
    start24: '15:00:00',
    end24: '16:00:00',
  ),
  RoomTimeSlot(
    label: '4:00 PM - 5:00 PM',
    startLabel: '4:00 PM',
    endLabel: '5:00 PM',
    start24: '16:00:00',
    end24: '17:00:00',
  ),
];

int _minutes(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return 0;
  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  return (hours * 60) + minutes;
}
