import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/id_card_service.dart';

class DigitalIdScreen extends StatefulWidget {
  const DigitalIdScreen({super.key});

  @override
  State<DigitalIdScreen> createState() => _DigitalIdScreenState();
}

class _DigitalIdScreenState extends State<DigitalIdScreen> {
  final _idCardService = IdCardService();
  final _pageController = PageController();

  DigitalIdCard? _card;
  String? _error;
  bool _isLoading = true;
  bool _isSaving = false;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    final cached = !refresh ? _idCardService.peekCached() : null;

    setState(() {
      if (cached != null) {
        _card = cached;
        _isLoading = false;
        _error = null;
      } else {
        _isLoading = true;
        _error = null;
      }
    });

    try {
      final card = await _idCardService.getDigitalId(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _card = card;
        _isLoading = false;
        _error = null;
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        if (_card == null) {
          _error = exception.message;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_card == null) {
          _error = 'Unable to load your digital ID.';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCurrentSide() async {
    final card = _card;
    if (card == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo library permission is required to save.'),
            ),
          );
          return;
        }
      }

      final bytes = _pageIndex == 0 ? card.frontPng : card.backPng;
      final side = _pageIndex == 0 ? 'front' : 'back';
      final name =
          'pantas_id_${card.studentNumber.isEmpty ? 'student' : card.studentNumber}_$side';

      await Gal.putImageBytes(bytes, name: name);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ID $side to gallery.')),
      );
    } on GalException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.type.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save ID to gallery.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Digital ID'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : () => _load(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Regenerate ID',
          ),
          IconButton(
            onPressed: _isLoading || _card == null || _isSaving
                ? null
                : _saveCurrentSide,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Save to gallery',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Generating your library ID…',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _load(refresh: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final card = _card!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            children: [
              Text(
                card.fullName.isEmpty ? 'Library ID' : card.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (card.studentNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  card.studentNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _pageIndex = index),
            children: [
              _IdSideView(label: 'Front', bytes: card.frontPng),
              _IdSideView(label: 'Back', bytes: card.backPng),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(active: _pageIndex == 0),
                  const SizedBox(width: 8),
                  _Dot(active: _pageIndex == 1),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Swipe to view ${_pageIndex == 0 ? 'back' : 'front'} · Tap download to save',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveCurrentSide,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: Text(
                    _pageIndex == 0 ? 'Save front' : 'Save back',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdSideView extends StatelessWidget {
  final String label;
  final Uint8List bytes;

  const _IdSideView({required this.label, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 3,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: active ? 18 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
