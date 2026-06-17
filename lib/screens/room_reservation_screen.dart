import 'package:flutter/material.dart';
import '../services/room_service.dart';
import '../shared/widgets/skeleton_loading.dart';

class RoomReservationScreen extends StatefulWidget {
  const RoomReservationScreen({super.key});

  @override
  State<RoomReservationScreen> createState() => _RoomReservationScreenState();
}

class _RoomReservationScreenState extends State<RoomReservationScreen> {
  final _roomService = RoomService();
  DateTime _selectedDate = DateTime.now();
  String? _selectedRoom;
  String? _selectedStartTime;
  String? _selectedEndTime;
  List<String> _availableRooms = [];
  List<String> _availableTimeSlots = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableRooms();
  }

  Future<void> _loadAvailableRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rooms = await _roomService.getAvailableRooms(_selectedDate);
      if (mounted) {
        setState(() {
          _availableRooms = rooms;
          _selectedRoom = null;
          _availableTimeSlots = [];
          _selectedStartTime = null;
          _selectedEndTime = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load rooms')),
        );
      }
    }
  }

  Future<void> _loadAvailableTimeSlots(String room) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final slots =
          await _roomService.getAvailableTimeSlots(room, _selectedDate);
      if (mounted) {
        setState(() {
          _availableTimeSlots = slots;
          _selectedStartTime = null;
          _selectedEndTime = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load time slots')),
        );
      }
    }
  }

  Future<void> _submitReservation() async {
    if (_selectedRoom == null || _selectedStartTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _roomService.submitReservation(
        _selectedRoom!,
        _selectedDate,
        _selectedStartTime!,
        _selectedEndTime!,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation submitted successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit reservation')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred')),
        );
      }
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
      appBar: AppBar(
        title: const Text('Room Reservation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection
            Text(
              'Select Date',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                  _loadAvailableRooms();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate.toString().split(' ')[0],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Room Selection
            Text(
              'Select Room',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const SkeletonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(
                          height: 18,
                          width: 140,
                          margin: EdgeInsets.only(bottom: 12),
                        ),
                        SkeletonBox(
                          height: 44,
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 12),
                        ),
                        SkeletonBox(
                          height: 18,
                          width: 140,
                          margin: EdgeInsets.only(bottom: 12),
                        ),
                        SkeletonBox(
                          height: 44,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  )
                : _availableRooms.isEmpty
                    ? const Text('No rooms available for this date')
                    : DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Choose a room'),
                        value: _selectedRoom,
                        items: _availableRooms
                            .map((room) =>
                                DropdownMenuItem(value: room, child: Text(room)))
                            .toList(),
                        onChanged: (room) {
                          if (room != null) {
                            setState(() {
                              _selectedRoom = room;
                            });
                            _loadAvailableTimeSlots(room);
                          }
                        },
                      ),
            const SizedBox(height: 24),

            // Time Selection
            if (_selectedRoom != null) ...[
              Text(
                'Select Time',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time'),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Start'),
                          value: _selectedStartTime,
                          items: _availableTimeSlots
                              .map((time) => DropdownMenuItem(
                                    value: time,
                                    child: Text(time),
                                  ))
                              .toList(),
                          onChanged: (time) {
                            setState(() {
                              _selectedStartTime = time;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Time'),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('End'),
                          value: _selectedEndTime,
                          items: _availableTimeSlots
                              .map((time) => DropdownMenuItem(
                                    value: time,
                                    child: Text(time),
                                  ))
                              .toList(),
                          onChanged: (time) {
                            setState(() {
                              _selectedEndTime = time;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReservation,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Reservation'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
