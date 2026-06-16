import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

enum _Tab { student, faculty }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  _Tab _tab = _Tab.student;

  // ── Student fields ──────────────────────────────────────────────
  final _sFirstName = TextEditingController();
  final _sLastName = TextEditingController();
  final _sMiddle = TextEditingController();
  final _sId = TextEditingController();
  DateTime? _sDob;
  String? _sCourse;
  String? _sYear;
  final _sMobile = TextEditingController();
  final _sAddress = TextEditingController();

  // ── Faculty fields ──────────────────────────────────────────────
  final _fFirstName = TextEditingController();
  final _fLastName = TextEditingController();
  final _fMiddle = TextEditingController();
  final _fEmployeeId = TextEditingController();
  final _fDesignation = TextEditingController();
  String? _fProgram;
  String? _fYearStart;
  DateTime? _fBirthday;
  final _fMobile = TextEditingController();
  final _fAddress = TextEditingController();

  // ── Emergency (per tab) ─────────────────────────────────────────
  final _sEPerson = TextEditingController();
  final _sERelation = TextEditingController();
  final _sENumber = TextEditingController();
  final _sEAddress = TextEditingController();

  final _fEPerson = TextEditingController();
  final _fERelation = TextEditingController();
  final _fENumber = TextEditingController();
  final _fEAddress = TextEditingController();

  // ── Signature points ────────────────────────────────────────────
  final List<Offset?> _sSig = [];
  final List<Offset?> _fSig = [];

  // ── Profile photo placeholder ───────────────────────────────────
  bool _sPhoto = false;
  bool _fPhoto = false;

  static const _courses = [
    'BSIT', 'BSCS', 'BSEd', 'BSBA', 'BSN', 'BSCRIM', 'BSA', 'BSHRM',
  ];
  static const _years = [
    '1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year',
  ];

  static const _programs = [
    'College of Education', 'College of Engineering', 'College of Business',
    'College of Nursing', 'College of Criminal Justice', 'College of IT',
    'College of Arts & Sciences', 'Library Services', 'Administrative Staff',
  ];

  static List<String> get _startYears {
    final now = DateTime.now().year;
    return List.generate(now - 1979, (i) => '${now - i}');
  }

  @override
  void dispose() {
    for (final c in [
      _sFirstName, _sLastName, _sMiddle, _sId, _sMobile, _sAddress,
      _fFirstName, _fLastName, _fMiddle, _fEmployeeId, _fDesignation,
      _fMobile, _fAddress,
      _sEPerson, _sERelation, _sENumber, _sEAddress,
      _fEPerson, _fERelation, _fENumber, _fEAddress,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _sDob = picked);
  }

  Future<void> _pickFacultyBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1985),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fBirthday = picked);
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: size.height * 0.28,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),
          Positioned(
            top: size.height * 0.26,
            left: 0, right: 0, bottom: 0,
            child: const ColoredBox(color: AppColors.background),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildCard(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/d.png',
          width: 80,
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
            ),
            child: const Icon(Icons.library_books_rounded, size: 36, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Library Registration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fill in your details to register',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabSwitcher(),
          const SizedBox(height: 24),
          if (_tab == _Tab.student) _studentForm() else _facultyForm(),
        ],
      ),
    );
  }

  // ── Tab switcher ────────────────────────────────────────────────

  Widget _buildTabSwitcher() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tab_(label: 'Student', tab: _Tab.student),
            const SizedBox(width: 4),
            _tab_(label: 'Faculty & Staff', tab: _Tab.faculty),
          ],
        ),
      ),
    );
  }

  Widget _tab_({required String label, required _Tab tab}) {
    final active = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textMuted,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── Student form ─────────────────────────────────────────────────

  Widget _studentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Student Information'),
        const SizedBox(height: 12),
        _row([
          _field(_sFirstName, 'First Name', Icons.person_outline_rounded),
          _field(_sLastName, 'Last Name', Icons.person_outline_rounded),
        ]),
        const SizedBox(height: 12),
        _row([
          _field(_sMiddle, 'Middle Initial', Icons.sort_by_alpha_rounded),
          _field(_sId, 'ID Number', Icons.badge_outlined, type: TextInputType.number),
        ]),
        const SizedBox(height: 12),
        _row([
          _datePicker(),
          _dropdown(
            value: _sCourse,
            hint: 'Select Course',
            icon: Icons.school_outlined,
            items: _courses,
            onChanged: (v) => setState(() => _sCourse = v),
          ),
        ]),
        const SizedBox(height: 12),
        _row([
          _dropdown(
            value: _sYear,
            hint: 'Select Year',
            icon: Icons.calendar_today_outlined,
            items: _years,
            onChanged: (v) => setState(() => _sYear = v),
          ),
          _field(_sMobile, 'Mobile Number', Icons.phone_outlined, type: TextInputType.phone),
        ]),
        const SizedBox(height: 12),
        _field(_sAddress, 'Address', Icons.home_outlined),
        const SizedBox(height: 20),
        _section('Emergency Contact'),
        const SizedBox(height: 12),
        _row([
          _field(_sEPerson, 'Emergency Person', Icons.person_pin_outlined),
          _field(_sERelation, 'Relationship', Icons.people_outline_rounded),
        ]),
        const SizedBox(height: 12),
        _row([
          _field(_sENumber, 'Emergency Number', Icons.phone_in_talk_outlined, type: TextInputType.phone),
          _field(_sEAddress, 'Emergency Address', Icons.location_on_outlined),
        ]),
        const SizedBox(height: 20),
        _section('Profile Picture'),
        const SizedBox(height: 12),
        _photoPicker(
          hasPhoto: _sPhoto,
          onTap: () => setState(() => _sPhoto = !_sPhoto),
        ),
        const SizedBox(height: 20),
        _section('Signature'),
        const SizedBox(height: 4),
        Text('Draw your signature below',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.8))),
        const SizedBox(height: 10),
        _signaturePad(_sSig),
        const SizedBox(height: 8),
        _clearBtn(() => setState(() => _sSig.clear())),
        const SizedBox(height: 24),
        _submitBtn('Submit Student Registration', () => context.go('/home')),
        const SizedBox(height: 16),
        _signInLink(),
      ],
    );
  }

  // ── Faculty form ─────────────────────────────────────────────────

  Widget _facultyForm() {
    final birthdayLabel = _fBirthday == null
        ? 'dd/mm/yyyy'
        : '${_fBirthday!.day.toString().padLeft(2, '0')}/'
          '${_fBirthday!.month.toString().padLeft(2, '0')}/'
          '${_fBirthday!.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Faculty & Staff Information'),
        const SizedBox(height: 12),
        _row([
          _field(_fFirstName, 'First Name', Icons.person_outline_rounded),
          _field(_fLastName, 'Last Name', Icons.person_outline_rounded),
        ]),
        const SizedBox(height: 12),
        _row([
          _field(_fMiddle, 'Middle Initial', Icons.sort_by_alpha_rounded),
          _field(_fEmployeeId, 'ID Number', Icons.badge_outlined),
        ]),
        const SizedBox(height: 12),
        _field(
          _fDesignation,
          'Designation',
          Icons.work_outline_rounded,
          hint: 'e.g. Instructor I, Librarian',
        ),
        const SizedBox(height: 12),
        _dropdown(
          value: _fProgram,
          hint: 'Select Program',
          icon: Icons.school_outlined,
          items: _programs,
          onChanged: (v) => setState(() => _fProgram = v),
        ),
        const SizedBox(height: 12),
        _row([
          _dropdown(
            value: _fYearStart,
            hint: 'Year of start of work in this HEI',
            icon: Icons.work_history_outlined,
            items: _startYears,
            onChanged: (v) => setState(() => _fYearStart = v),
          ),
          GestureDetector(
            onTap: _pickFacultyBirthday,
            child: AbsorbPointer(
              child: TextField(
                readOnly: true,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: birthdayLabel,
                  labelStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.cake_outlined, size: 18),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  isDense: true,
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _field(
          _fMobile,
          'Mobile Number',
          Icons.phone_outlined,
          type: TextInputType.phone,
          hint: '09000000000',
        ),
        const SizedBox(height: 12),
        _multilineField(_fAddress, 'Address', Icons.home_outlined),
        const SizedBox(height: 20),
        _section('Formal picture (optional)'),
        const SizedBox(height: 12),
        _photoPicker(
          hasPhoto: _fPhoto,
          onTap: () => setState(() => _fPhoto = !_fPhoto),
        ),
        const SizedBox(height: 20),
        _section('Signature (optional)'),
        const SizedBox(height: 10),
        _signaturePad(_fSig),
        const SizedBox(height: 8),
        _clearBtn(() => setState(() => _fSig.clear())),
        const SizedBox(height: 20),
        _section('Emergency Contact Information'),
        const SizedBox(height: 12),
        _row([
          _field(_fEPerson, 'Contact person', Icons.person_pin_outlined),
          _field(_fERelation, 'Relationship', Icons.people_outline_rounded),
        ]),
        const SizedBox(height: 12),
        _row([
          _field(_fENumber, 'Contact number', Icons.phone_in_talk_outlined, type: TextInputType.phone),
          _field(_fEAddress, 'Emergency address', Icons.location_on_outlined),
        ]),
        const SizedBox(height: 24),
        _submitBtn('Submit Faculty & Staff Registration', () => context.go('/home')),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              'Back to home',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared widgets ───────────────────────────────────────────────

  Widget _section(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 10)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        isDense: true,
      ),
    );
  }

  Widget _multilineField(
    TextEditingController ctrl,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: ctrl,
      maxLines: 3,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Icon(icon, size: 18),
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        isDense: true,
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: value == null ? hint : null,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          hint: Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _datePicker() {
    final label = _sDob == null
        ? 'Date of Birth'
        : '${_sDob!.day.toString().padLeft(2, '0')}/'
          '${_sDob!.month.toString().padLeft(2, '0')}/'
          '${_sDob!.year}';
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: TextField(
          readOnly: true,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 12),
            prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _photoPicker({required bool hasPhoto, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: hasPhoto
            ? const Center(
                child: Icon(Icons.check_circle_outline_rounded, size: 36, color: AppColors.success),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, size: 28, color: AppColors.textMuted),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap to choose a photo',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _signaturePad(List<Offset?> points) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: GestureDetector(
          onPanUpdate: (d) => setState(() => points.add(d.localPosition)),
          onPanEnd: (_) => setState(() => points.add(null)),
          child: CustomPaint(
            painter: _SignaturePainter(points),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  Widget _clearBtn(VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.refresh_rounded, size: 16),
      label: const Text('Clear', style: TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: const BorderSide(color: AppColors.danger),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _submitBtn(String label, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _signInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? ',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Signature painter ──────────────────────────────────────────────

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
