import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/room.dart';
import '../../../models/room_reservation.dart';
import '../../../models/user.dart';
import '../../../services/room_service.dart';
import '../../../services/user_service.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../rooms/widgets/time_slot_chip.dart';

class RoomReservationScreen extends StatefulWidget {
  const RoomReservationScreen({super.key});

  @override
  State<RoomReservationScreen> createState() => _RoomReservationScreenState();
}

class _RoomReservationScreenState extends State<RoomReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomService = RoomService();
  final _userService = UserService();
  final _notesController = TextEditingController();
  final List<TextEditingController> _studentNameControllers = [];
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
  int _studentCount = 1;

  @override
  void initState() {
    super.initState();
    _syncStudentNameControllers();
    _loadInitialData();
  }

  @override
  void dispose() {
    for (final controller in _studentNameControllers) {
      controller.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _roomService.getRooms(refresh: refresh),
        _roomService.getUserReservations(refresh: refresh),
        _userService.getCurrentUser(refresh: refresh),
      ]);
      final rooms = results[0] as List<Room>;
      final currentUser = results[2] as User?;

      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _reservations = results[1] as List<RoomReservation>;
        selectedRoom = rooms.isEmpty ? null : rooms.first;
        _prefillPrimaryStudentName(currentUser?.name);
        _clampStudentCountToSelectedRoom();
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

  Future<void> _loadAvailability({bool refresh = false}) async {
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
        refresh: refresh,
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

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_studentCount > room.capacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This room only allows up to ${room.capacity} students.',
          ),
        ),
      );
      return;
    }

    final studentNames = _studentNameControllers
        .take(_studentCount)
        .map((controller) => controller.text.trim())
        .toList(growable: false);

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reservation = await _roomService.submitRoomReservation(
        roomId: room.id,
        date: selectedDate,
        startTime: slot.startLabel,
        endTime: slot.endLabel,
        numberOfStudents: _studentCount,
        studentNames: studentNames,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _roomService.lastMessage ?? 'Room reservation submitted.',
          ),
        ),
      );
      await context.push('/room_reservation_details?id=${reservation.id}');
      await _loadInitialData(refresh: true);
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
            ? SkeletonPage(
                children: [
                  SkeletonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(
                          height: 18,
                          width: 180,
                          margin: EdgeInsets.only(bottom: 16),
                        ),
                        SkeletonBox(
                          height: 180,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(20),
                          margin: EdgeInsets.only(bottom: 20),
                        ),
                        SkeletonLine(width: double.infinity),
                        SizedBox(height: 12),
                        SkeletonLine(width: 220),
                        SizedBox(height: 24),
                        SkeletonBox(
                          height: 18,
                          width: 140,
                          margin: EdgeInsets.only(bottom: 12),
                        ),
                        SkeletonBox(height: 18, width: double.infinity),
                        SizedBox(height: 24),
                        SkeletonBox(
                          height: 18,
                          width: 140,
                          margin: EdgeInsets.only(bottom: 12),
                        ),
                        SkeletonBox(height: 18, width: double.infinity),
                      ],
                    ),
                  ),
                ],
              )
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
              onPressed: () => _loadInitialData(refresh: true),
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
                _clampStudentCountToSelectedRoom();
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
      return const SkeletonList(
        itemCount: 3,
        itemHeight: 44,
        spacing: 12,
        padding: EdgeInsets.zero,
      );
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
    return Form(
      key: _formKey,
      child: Column(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$_studentCount ${_studentCount == 1 ? 'student' : 'students'} selected',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove student',
                      onPressed: _studentCount > 1
                          ? () => _setStudentCount(_studentCount - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.primary,
                    ),
                    IconButton(
                      tooltip: 'Add student',
                      onPressed: _canAddStudent
                          ? () => _setStudentCount(_studentCount + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(
                    _studentCount,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _studentNameControllers[index],
                        textInputAction: index == _studentCount - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Student ${index + 1} name',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter student ${index + 1} name.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Purpose or request details',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canAddStudent {
    final roomCapacity = selectedRoom?.capacity ?? 20;
    return _studentCount < roomCapacity && _studentCount < 20;
  }

  void _setStudentCount(int value) {
    setState(() {
      _studentCount = value.clamp(1, selectedRoom?.capacity ?? 20);
      _syncStudentNameControllers();
    });
  }

  void _syncStudentNameControllers() {
    while (_studentNameControllers.length < _studentCount) {
      _studentNameControllers.add(TextEditingController());
    }

    while (_studentNameControllers.length > _studentCount) {
      _studentNameControllers.removeLast().dispose();
    }
  }

  void _prefillPrimaryStudentName(String? name) {
    if (name == null || name.trim().isEmpty) return;
    if (_studentNameControllers.isEmpty) {
      _syncStudentNameControllers();
    }
    final firstController = _studentNameControllers.first;
    if (firstController.text.trim().isEmpty) {
      firstController.text = name.trim();
    }
  }

  void _clampStudentCountToSelectedRoom() {
    final capacity = selectedRoom?.capacity;
    if (capacity == null || capacity <= 0 || _studentCount <= capacity) return;
    _studentCount = capacity;
    _syncStudentNameControllers();
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
