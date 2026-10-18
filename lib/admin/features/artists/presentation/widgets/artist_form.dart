import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:makeup_booking_app/core/config/app_config.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

import '../../../../app/admin_routes.dart';
import '../../../../core/domain/picked_image.dart';
import '../../../../core/theme/admin_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_card.dart';
import '../../data/firestore_admin_artist_repository.dart';
import '../../domain/artist_draft.dart';
import '../provider/admin_artist_providers.dart';
import 'profile_photo_field.dart';
import 'services_editor.dart';

/// The add/edit artist form. Pass [initial] to edit.
class ArtistForm extends ConsumerStatefulWidget {
  final ArtistEditorData? initial;

  const ArtistForm({super.key, this.initial});

  @override
  ConsumerState<ArtistForm> createState() => _ArtistFormState();
}

class _ArtistFormState extends ConsumerState<ArtistForm> {
  static const double _maxContentWidth = 920;
  static const double _wideBreakpoint = 720;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  late final TextEditingController _contactPhone;
  late final TextEditingController _instagram;
  late final TextEditingController _notes;
  late final TextEditingController _commissionPercent;
  late final TextEditingController _repeatCommissionPercent;
  late final ServicesEditorController _services;

  late Set<ServiceMode> _modes;
  late bool _isActive;
  PickedImage? _photo;

  // Errors for the fields that are not text inputs.
  String? _photoError;
  String? _modesError;
  String? _servicesError;

  bool get _isEditing => widget.initial != null;

  /// 0.15 -> "15", 0.125 -> "12.5".
  static String _percentText(double fraction) {
    final percent = fraction * 100;
    return percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final artist = initial?.artist;
    final details = initial?.privateDetails ?? const ArtistPrivateDetails();
    final commission = initial?.commissionRate ?? AppConfig.commissionRate;
    final repeatCommission =
        initial?.repeatCommissionRate ?? AppConfig.repeatCommissionRate;

    _name = TextEditingController(text: artist?.name ?? '');
    _city = TextEditingController(text: artist?.city ?? '');
    _bio = TextEditingController(text: artist?.bio ?? '');
    _contactPhone = TextEditingController(text: details.contactPhone);
    _instagram = TextEditingController(text: details.instagram);
    _notes = TextEditingController(text: details.notes);
    _commissionPercent = TextEditingController(text: _percentText(commission));
    _repeatCommissionPercent =
        TextEditingController(text: _percentText(repeatCommission));
    _services = ServicesEditorController(artist?.services ?? const []);
    _modes = {...(artist?.serviceModes ?? ServiceMode.values)};
    _isActive = artist?.isActive ?? true;

    // A new artist starts with one empty service row.
    if (_services.isEmpty) _services.add();
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _city,
      _bio,
      _contactPhone,
      _instagram,
      _notes,
      _commissionPercent,
      _repeatCommissionPercent,
    ]) {
      controller.dispose();
    }
    _services.dispose();
    super.dispose();
  }

  /// Validates everything; returns false and shows the errors if anything is
  /// wrong.
  bool _validate() {
    final fieldsValid = _formKey.currentState!.validate();

    setState(() {
      _photoError = (_photo == null && !_isEditing)
          ? 'Add a profile photo'
          : null;
      _modesError = _modes.isEmpty ? 'Choose at least one option' : null;
      _servicesError = _services.isEmpty ? 'Add at least one service' : null;
    });

    final valid = fieldsValid &&
        _photoError == null &&
        _modesError == null &&
        _servicesError == null;

    if (!valid) {
      // The error may be off-screen on a long form, so say so and scroll to it.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealFirstError());
    }
    return valid;
  }

  /// Scrolls to the first text field that is showing a validation error.
  void _revealFirstError() {
    final root = _formKey.currentContext;
    if (root == null) return;

    var found = false;
    void visit(Element element) {
      if (found) return;
      if (element is StatefulElement &&
          element.state is FormFieldState &&
          (element.state as FormFieldState).hasError) {
        found = true;
        Scrollable.ensureVisible(
          element,
          alignment: 0.2,
          duration: const Duration(milliseconds: 250),
        );
        return;
      }
      element.visitChildren(visit);
    }

    (root as Element).visitChildren(visit);
  }

  ArtistDraft _buildDraft() {
    return ArtistDraft(
      name: _name.text,
      bio: _bio.text,
      city: _city.text,
      serviceModes: _modes,
      services: _services.toServices(),
      isActive: _isActive,
      commissionRate: double.parse(_commissionPercent.text.trim()) / 100,
      repeatCommissionRate:
          double.parse(_repeatCommissionPercent.text.trim()) / 100,
      privateDetails: ArtistPrivateDetails(
        contactPhone: _contactPhone.text,
        instagram: _instagram.text,
        notes: _notes.text,
      ),
    );
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final ok = await ref.read(artistAdminControllerProvider.notifier).save(
          artistId: widget.initial?.artist.id,
          draft: _buildDraft(),
          profilePhoto: _photo,
        );

    if (!ok || !mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Artist saved')));
    router.go(AdminRoutes.artists);
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(artistAdminControllerProvider);
    final saving = saveState.isLoading;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: _isEditing ? 'Edit artist' : 'Add artist',
                    subtitle: _isEditing
                        ? widget.initial!.artist.name
                        : 'Details customers will see in the app',
                    actions: [
                      OutlinedButton(
                        onPressed: saving
                            ? null
                            : () => context.go(AdminRoutes.artists),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: saving ? null : _save,
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                  if (saveState.hasError) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(
                      message: saveState.error is ArtistSaveFailure
                          ? saveState.error.toString()
                          : 'Please check your connection and try again.',
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildProfileSection(),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Services',
                    description: 'What the artist offers, with price and time.',
                    child: ServicesEditor(
                      controller: _services,
                      errorText: _servicesError,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildVisibilitySection(),
                  const SizedBox(height: 20),
                  _buildPrivateSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    final photo = ProfilePhotoField(
      existingUrl: widget.initial?.artist.imageUrl ?? '',
      picked: _photo,
      errorText: _photoError,
      onPicked: (image) => setState(() {
        _photo = image;
        _photoError = null;
      }),
    );

    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _twoColumns(
          TextFormField(
            controller: _name,
            validator: (v) =>
                Validators.required(v, 'Name') ??
                Validators.maxLength(v, 80) ??
                Validators.noContactDetails(v),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextFormField(
            controller: _city,
            validator: (v) =>
                Validators.required(v, 'City') ?? Validators.maxLength(v, 60),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'City'),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bio,
          validator: (v) =>
              Validators.maxLength(v, 500) ?? Validators.noContactDetails(v),
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'About',
            hintText: 'Style, experience, specialities',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Text('Where does the artist work?',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final mode in ServiceMode.values)
              FilterChip(
                label: Text(mode.label),
                selected: _modes.contains(mode),
                onSelected: (selected) => setState(() {
                  selected ? _modes.add(mode) : _modes.remove(mode);
                  _modesError = null;
                }),
              ),
          ],
        ),
        if (_modesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _modesError!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AdminColors.danger),
            ),
          ),
      ],
    );

    return SectionCard(
      title: 'Profile',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= _wideBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                photo,
                const SizedBox(width: 32),
                Expanded(child: fields),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [photo, const SizedBox(height: 24), fields],
          );
        },
      ),
    );
  }

  /// The repeat rate is a discount, so it may not exceed the first-booking rate.
  String? _validateRepeatCommission(String? value) {
    final error = Validators.number(value, min: 0, max: 60);
    if (error != null) return error;

    final first = double.tryParse(_commissionPercent.text.trim());
    if (first != null && double.parse(value!.trim()) > first) {
      return 'Must not be higher than the new-customer rate';
    }
    return null;
  }

  Widget _buildVisibilitySection() {
    return SectionCard(
      title: 'Visibility and commission',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Visible to customers'),
            subtitle: const Text('Turn off to hide the artist from the app.'),
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
          ),
          const SizedBox(height: 12),
          _twoColumns(
            TextFormField(
              controller: _commissionPercent,
              validator: (v) => Validators.number(v, min: 0, max: 60),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Commission, new customers',
                suffixText: '%',
                helperText: 'Platform share of a first booking',
              ),
            ),
            TextFormField(
              controller: _repeatCommissionPercent,
              validator: _validateRepeatCommission,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Commission, repeat customers',
                suffixText: '%',
                helperText: 'Lower, so regulars stay on the app',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateSection() {
    return SectionCard(
      title: 'Private details',
      description: 'Only admins can see this. It never reaches the app.',
      child: Column(
        children: [
          _twoColumns(
            TextFormField(
              controller: _contactPhone,
              validator: Validators.optionalIndianMobile,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Contact phone',
                prefixText: '+91 ',
                counterText: '',
              ),
            ),
            TextFormField(
              controller: _instagram,
              validator: Validators.optionalInstagram,
              decoration: const InputDecoration(
                labelText: 'Instagram',
                prefixText: '@',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notes,
            validator: (v) => Validators.maxLength(v, 1000),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Internal notes',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Two fields side by side on wide screens, stacked on narrow ones.
  Widget _twoColumns(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 480) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          );
        }
        return Column(children: [left, const SizedBox(height: 16), right]);
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AdminColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Couldn't save: $message",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AdminColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
