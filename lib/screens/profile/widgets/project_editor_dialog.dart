import 'package:flutter/material.dart';
import '../../../models/models.dart';

class ProjectEditorDialog extends StatefulWidget {
  final Project? project;

  const ProjectEditorDialog({super.key, this.project});

  @override
  State<ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<ProjectEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _stackController;
  late TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project?.title ?? '');
    _descController = TextEditingController(
      text: widget.project?.description ?? '',
    );
    _stackController = TextEditingController(text: widget.project?.stack ?? '');
    _linkController = TextEditingController(text: widget.project?.link ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _stackController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.project == null ? 'Add Project' : 'Edit Project'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Project Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stackController,
                decoration: const InputDecoration(
                  labelText: 'Tech Stack (e.g., Flutter, Firebase)',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Stack is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Project Link (Optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newProject = Project(
                title: _titleController.text,
                description: _descController.text,
                stack: _stackController.text,
                link: _linkController.text.isNotEmpty
                    ? _linkController.text
                    : null,
              );
              Navigator.pop(context, newProject);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
