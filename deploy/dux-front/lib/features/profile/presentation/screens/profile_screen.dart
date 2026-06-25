import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_members_provider.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/core/widgets/section_header.dart';
import 'package:dux_front/core/widgets/primary_button.dart';
import 'package:dux_front/core/widgets/app_text_field.dart';
import 'package:dux_front/core/widgets/loading_skeleton.dart';
import 'package:dux_front/core/widgets/error_state_widget.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/station/presentation/controllers/station_controller.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _obscurePassword = true;

  Future<void> _pickAndUploadProfilePicture(
    BuildContext context,
    WidgetRef ref,
    TimetreeMember? currentMember,
  ) async {
    if (currentMember == null || currentMember.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez patienter pendant le chargement de votre compte Dux Calender.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null) {
        final file = result.files.single;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await io.File(file.path!).readAsBytes();
        }
        if (bytes != null) {
          final base64String = base64Encode(bytes);
          await ref.read(timetreeMembersProvider.notifier).updateMember(
            id: currentMember.id,
            username: currentMember.username,
            fullName: currentMember.fullName,
            email: currentMember.email,
            role: currentMember.role,
            profilePicture: base64String,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo de profil mise à jour avec succès.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String fieldName) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fieldName copié dans le presse-papiers'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final state = ref.read(profileControllerProvider);
    if (state.profile == null) return;

    final profile = state.profile!;
    final nameController = TextEditingController(text: profile.fullName);
    final emailController = TextEditingController(text: profile.email);
    final phoneController = TextEditingController(text: profile.phone);
    final locationController = TextEditingController(text: profile.location);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xl)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSpacing.l,
            right: AppSpacing.l,
            top: AppSpacing.l,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  AppSpacing.gapL,
                  Text(
                    'Modifier les informations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.gapL,
                  AppTextField(
                    controller: nameController,
                    labelText: 'Nom et prénom',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                  ),
                  AppSpacing.gapL,
                  AppTextField(
                    controller: emailController,
                    labelText: 'Mail / Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                  ),
                  AppSpacing.gapL,
                  AppTextField(
                    controller: phoneController,
                    labelText: 'Téléphone',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                  ),
                  AppSpacing.gapL,
                  AppTextField(
                    controller: locationController,
                    labelText: 'Cellule / Localisation',
                    prefixIcon: Icons.location_on_outlined,
                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                  ),
                  AppSpacing.gapXl,
                  Consumer(
                    builder: (context, ref, _) {
                      final isSaving = ref.watch(profileControllerProvider.select((s) => s.isSaving));
                      return PrimaryButton(
                        text: 'Enregistrer',
                        isLoading: isSaving,
                        onPressed: () async {
                          if (formKey.currentState?.validate() ?? false) {
                            final success = await ref.read(profileControllerProvider.notifier).updateProfile(
                                  fullName: nameController.text,
                                  email: emailController.text,
                                  phone: phoneController.text,
                                  location: locationController.text,
                                );
                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profil mis à jour localement'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                  AppSpacing.gapXl,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(profileControllerProvider);
    final stationState = ref.watch(stationControllerProvider);
    final membersAsync = ref.watch(timetreeMembersProvider);
    final currentMember = state.profile == null
        ? null
        : membersAsync.when(
            data: (list) => list.firstWhere(
              (m) => m.username.toLowerCase() == state.profile!.userId.toLowerCase(),
              orElse: () => const TimetreeMember(id: '', username: '', fullName: '', email: '', role: ''),
            ),
            loading: () => null,
            error: (_, __) => null,
          );

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Profil Utilisateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Se déconnecter',
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          if (state.isLoading && state.profile == null) {
            return _buildLoadingState();
          }

          if (state.error != null && state.profile == null) {
            return ErrorStateWidget(
              description: state.error!,
              onRetry: () => ref.read(profileControllerProvider.notifier).fetchProfile(),
            );
          }

          final profile = state.profile!;
          final formattedJoined = DateFormat('dd MMMM yyyy, HH:mm').format(profile.joinedDate);
          final stationName = stationState.station?.name ?? (stationState.isLoading ? 'Chargement...' : profile.station);

          Widget content = RefreshIndicator(
            onRefresh: () => ref.read(profileControllerProvider.notifier).fetchProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Block
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.tertiary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppBorderRadius.roundedL,
                      boxShadow: AppShadows.softShadow(context),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                backgroundImage: currentMember?.profilePicture != null && currentMember!.profilePicture!.isNotEmpty
                                    ? MemoryImage(base64Decode(currentMember.profilePicture!))
                                    : null,
                                child: currentMember?.profilePicture != null && currentMember!.profilePicture!.isNotEmpty
                                    ? null
                                    : Text(
                                        profile.fullName.trim().isNotEmpty
                                            ? profile.fullName.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).join().toUpperCase()
                                            : 'U',
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () => _pickAndUploadProfilePicture(context, ref, currentMember),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapL,
                        Text(
                          profile.fullName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapXs,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            profile.role,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        AppSpacing.gapM,
                        Chip(
                          avatar: const Icon(Icons.business_rounded, size: 16, color: Colors.white),
                          label: Text(
                            stationName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          side: BorderSide.none,
                          shape: const StadiumBorder(),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapL,

                  // Identifiants & Sécurité Card
                  SectionHeader(
                    title: 'Identifiants & Rôle',
                    actionLabel: 'Modifier',
                    onActionPressed: () => _showEditProfileSheet(context),
                  ),
                  InfoCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.person_rounded,
                          label: 'Nom et prénom',
                          value: profile.fullName,
                          onCopy: () => _copyToClipboard(profile.fullName, 'Nom et prénom'),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.account_box_rounded,
                          label: 'Login / Nom d\'utilisateur',
                          value: profile.userId,
                          onCopy: () => _copyToClipboard(profile.userId, 'Login'),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.lock_rounded,
                          label: 'Mot de passe',
                          value: profile.motDePasse.isNotEmpty
                              ? profile.motDePasse
                              : 'Non disponible',
                          obscureText: profile.motDePasse.isNotEmpty
                              ? _obscurePassword
                              : false,
                          trailing: profile.motDePasse.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                )
                              : null,
                          onCopy: profile.motDePasse.isNotEmpty
                              ? () => _copyToClipboard(profile.motDePasse, 'Mot de passe')
                              : null,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.verified_user_rounded,
                          label: 'Type Utilisateur',
                          value: profile.role,
                          onCopy: () => _copyToClipboard(profile.role, 'Type Utilisateur'),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapL,

                  // Coordonnées Card
                  SectionHeader(title: 'Coordonnées & Code'),
                  InfoCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.email_rounded,
                          label: 'Mail / Courriel',
                          value: profile.email,
                          onCopy: () => _copyToClipboard(profile.email, 'Mail'),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.phone_rounded,
                          label: 'Téléphone',
                          value: profile.phone.isNotEmpty ? profile.phone : 'Non spécifié',
                          onCopy: profile.phone.isNotEmpty ? () => _copyToClipboard(profile.phone, 'Téléphone') : null,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.badge_rounded,
                          label: 'Code Utilisateur',
                          value: profile.employeeId,
                          onCopy: () => _copyToClipboard(profile.employeeId, 'Code Utilisateur'),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapL,

                  // Organisation & Affectation Card
                  SectionHeader(title: 'Affectation & Métadonnées'),
                  InfoCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.business_rounded,
                          label: 'Nom de la Station',
                          value: stationName,
                          onCopy: () => _copyToClipboard(stationName, 'Nom de la Station'),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.grid_view_rounded,
                          label: 'Cellule',
                          value: profile.cellule.isNotEmpty ? profile.cellule : 'Non spécifiée',
                          onCopy: profile.cellule.isNotEmpty ? () => _copyToClipboard(profile.cellule, 'Cellule') : null,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.person_add_rounded,
                          label: 'Créateur',
                          value: profile.createur.isNotEmpty ? profile.createur : 'Non spécifié',
                          onCopy: profile.createur.isNotEmpty ? () => _copyToClipboard(profile.createur, 'Créateur') : null,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date création',
                          value: formattedJoined,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapL,

                  // (Theme Settings Card removed)
                  AppSpacing.gapXxl,
                ],
              ),
            ),
          );

          if (isWide) {
            return Center(
              child: SizedBox(
                width: 600,
                child: content,
              ),
            );
          }

          return content;
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool obscureText = false,
    Widget? trailing,
    VoidCallback? onCopy,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          AppSpacing.gapM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  obscureText ? '••••••••' : value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
          if (onCopy != null) ...[
            AppSpacing.gapS,
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: onCopy,
              tooltip: 'Copier',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        children: [
          const Center(child: LoadingSkeleton.circular(size: 100)),
          AppSpacing.gapL,
          const LoadingSkeleton(height: 20, width: 150),
          AppSpacing.gapS,
          const LoadingSkeleton(height: 16, width: 100),
          AppSpacing.gapL,
          const LoadingSkeleton(height: 150, width: double.infinity),
          AppSpacing.gapL,
          const LoadingSkeleton(height: 150, width: double.infinity),
        ],
      ),
    );
  }
}
