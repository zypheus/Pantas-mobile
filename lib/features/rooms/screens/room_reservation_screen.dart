import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/room.dart';
import '../../../models/room_reservation.dart';
import '../../../services/room_service.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../rooms/widgets/time_slot_chip.dart';

class RoomReservationScreen extends StatefulWidget {
  const RoomReservationScreen({super.key});

  @override
  State<RoomReservationScreen> createState() => _RoomReservationScreenState();
}

class _RoomReservationScreenState extends State<RoomReservationScreen> {
  final _roomService = RoomService();
  DateTime selectedDate = DateTime.now();
  Room? selectedRoom;
  RoomTimeSlot? selectedSlot;
  RoomAvailability? _availability;
  List<Room> _rooms = const [];
  List<RoomReservation> _reservations = const [];
  bool _isLoading = true;
  bool _isLoadingAvailability = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  final int studentCount = 1;
  final List<String> studentNames = const ['Jane Doe'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _roomService.getRooms(),
        _roomService.getUserReservations(),
      ]);
      final rooms = results[0] as List<Room>;

      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _reservations = results[1] as List<RoomReservation>;
        selectedRoom = rooms.isEmpty ? null : rooms.first;
        _isLoading = false;
      });
      await _loadAvailability();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.validationSummary;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load rooms.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAvailability() async {
    final room = selectedRoom;
    if (room == null) return;

    setState(() {
      _isLoadingAvailability = true;
      selectedSlot = null;
    });

    try {
      final availability = await _roomService.getAvailability(
        room.id,
        selectedDate,
      );
      if (!mounted) return;
      setState(() {
        _availability = availability;
        _isLoadingAvailability = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availability = null;
        _isLoadingAvailability = false;
      });
    }
  }

  Future<void> _submitReservation() async {
    final room = selectedRoom;
    final slot = selectedSlot;
    if (room == null || slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a room and available time slot.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reservation = await _roomService.submitRoomReservation(
        roomId: room.id,
        date: selectedDate,
        startTime: slot.startLabel,
        endTime: slot.endLabel,
        numberOfStudents: studentCount,
        studentNames: studentNames,
        notes: 'Submitted from mobile app.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _roomService.lastMessage ?? 'Room reservation submitted.',
          ),
        ),
      );
      context.go('/room_reservation_details?id=${reservation.id}');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.validationSummary)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit reservation.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Reservation')),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildError()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Choose a room',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRoomList(),
                    const SizedBox(height: 24),
                    const Text(
                      'Select date',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDatePicker(context),
                    const SizedBox(height: 24),
                    const Text(
                      'Choose a time slot',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSlots(),
                    const SizedBox(height: 24),
                    _buildStudentsCard(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text(
                        _isSubmitting ? 'Submitting...' : 'Submit Reservation',
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildReservationsList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.meeting_room_outlined,
              size: 42,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomList() {
    if (_rooms.isEmpty) {
      return const Text(
        'No rooms available.',
        style: TextStyle(color: AppColors.textMuted),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _rooms.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final room = _rooms[index];
          final isSelected = selectedRoom?.id == room.id;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedRoom = room;
              });
              _loadAvailability();
            },
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    room.description.isEmpty
                        ? 'Library room'
                        : room.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  StatusBadge(
                    label: 'Capacity ${room.capacity}',
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (picked != null) {
          setState(() {
            selectedDate = picked;
          });
          _loadAvailability();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
            const Icon(Icons.calendar_today, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (_isLoadingAvailability) {
      return const Center(child: CircularProgressIndicator());
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: defaultTimeSlots.map((slot) {
        final isBooked =
            _availability?.isBooked(slot.start24, slot.end24) ?? false;
        return TimeSlotChip(
          label: slot.label,
          selected: selectedSlot?.label == slot.label,
          enabled: !isBooked,
          onTap: () {
            setState(() {
              selectedSlot = slot;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildStudentsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Students',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.group, color: AppColors.primary),
                  SizedBox(width: 12),
                  Text(
                    '1 student selected',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: studentNames
                    .map(
                      (name) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          name,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReservationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Your reservations',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_reservations.isEmpty)
          const Text(
            'No reservations yet.',
            style: TextStyle(color: AppColors.textMuted),
          )
        else
          ..._reservations.take(3).map((reservation) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => context.go(
                  '/room_reservation_details?id=${reservation.id}',
                ),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.roomName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${DateFormat('MMM d, yyyy').format(reservation.reservationDate)} • ${_timeRange(reservation)}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: reservation.displayStatus,
                        color: _statusColor(reservation.status),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'approved' => AppColors.success,
      'rejected' || 'cancelled' => AppColors.danger,
      _ => AppColors.warning,
    };
  }

  String _timeRange(RoomReservation reservation) {
    return '${_formatApiTime(reservation.startTime)} - ${_formatApiTime(reservation.endTime)}';
  }

  String _formatApiTime(String value) {
    try {
      return DateFormat('h:mm a').format(DateFormat('HH:mm:ss').parse(value));
    } on FormatException {
      return value;
    }
  }
}
