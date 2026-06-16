import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/room_reservation.dart';
import '../../../services/room_service.dart';
import '../../../shared/widgets/status_badge.dart';

class RoomReservationDetailsScreen extends StatefulWidget {
  final String? reservationId;

  const RoomReservationDetailsScreen({super.key, this.reservationId});

  @override
  State<RoomReservationDetailsScreen> createState() =>
      _RoomReservationDetailsScreenState();
}

class _RoomReservationDetailsScreenState
    extends State<RoomReservationDetailsScreen> {
  final _roomService = RoomService();
  RoomReservation? _reservation;
  bool _isLoading = true;
  bool _isCancelling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReservation();
  }

  Future<void> _loadReservation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reservation =
          widget.reservationId == null || widget.reservationId!.isEmpty
          ? await _loadMostRecentReservation()
          : await _roomService.getReservationDetails(widget.reservationId!);

      if (!mounted) return;
      setState(() {
        _reservation = reservation;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.validationSummary;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load reservation details.';
        _isLoading = false;
      });
    }
  }

  Future<RoomReservation?> _loadMostRecentReservation() async {
    final reservations = await _roomService.getUserReservations();
    return reservations.isEmpty ? null : reservations.first;
  }

  Future<void> _cancelReservation() async {
    final reservation = _reservation;
    if (reservation == null) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final updated = await _roomService.cancelReservation(reservation.id);
      if (!mounted) return;
      setState(() {
        _reservation = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _roomService.lastMessage ?? 'Room reservation cancelled.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.validationSummary)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to cancel reservation.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservation = _reservation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reservation Details')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildError()
            : reservation == null
            ? const Center(
                child: Text(
                  'No reservation found.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            : _buildDetails(reservation),
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
              Icons.event_busy_rounded,
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
              onPressed: _loadReservation,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(RoomReservation reservation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.roomName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Capacity ${reservation.roomCapacity}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat(
                        'MMMM d, yyyy',
                      ).format(reservation.reservationDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    StatusBadge(
                      label: reservation.displayStatus,
                      color: _statusColor(reservation.status),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _timeRange(reservation),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Participants',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: reservation.studentNames.isEmpty
                  ? const [Text('No participants listed.')]
                  : reservation.studentNames
                        .map(
                          (name) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(name),
                          ),
                        )
                        .toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Notes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              reservation.notes.isEmpty
                  ? 'Please review library room policies and arrive 10 minutes prior to check-in.'
                  : reservation.notes,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: reservation.canCancel && !_isCancelling
                ? _cancelReservation
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(_isCancelling ? 'Cancelling...' : 'Cancel Reservation'),
          ),
        ],
      ),
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
