import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/classroom.dart';
import '../../../services/faculty_classroom_service.dart';

class MyFoldersScreen extends StatefulWidget {
  const MyFoldersScreen({super.key});

  @override
  State<MyFoldersScreen> createState() => _MyFoldersScreenState();
}

class _MyFoldersScreenState extends State<MyFoldersScreen> {
  final _service = FacultyClassroomService();
  List<FacultyFolderSummary> _folders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final folders = await _service.getFolders();
      if (!mounted) return;
      setState(() {
        _folders = folders;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.validationSummary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load folders.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Folders'),
        backgroundColor: AppColors.navyBrand,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/faculty/create-folder');
          _load();
        },
        label: const Text('Create Folder'),
        icon: const Icon(Icons.create_new_folder_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text(_error!)),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  )
                : _folders.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          Center(child: Text('No folders yet.')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _folders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final folder = _folders[index];
                          return ListTile(
                            tileColor: AppColors.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: const Icon(Icons.folder_rounded),
                            title: Text(folder.name),
                            subtitle: Text(
                              '${folder.bookCount} books · shared to ${folder.classroomCount} rooms',
                            ),
                            onTap: () => context.push(
                              '/faculty/folders/details?id=${folder.id}',
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
