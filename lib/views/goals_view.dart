// lib/views/goals_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants.dart';
import 'custom_header_priv.dart';

class GoalsView extends StatefulWidget {
  const GoalsView({Key? key}) : super(key: key);

  @override
  State<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showForm = false;

  List<dynamic> _goals = [];

  // Formulaire "Nouveau Projet"
  final _formKey       = GlobalKey<FormState>();
  final _titleCtrl     = TextEditingController();
  final _targetCtrl    = TextEditingController();
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // RÉCUPÉRATION DES OBJECTIFS (Extraction blindée)
  // ==========================================
  Future<void> _fetchGoals() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('goals.php');
      if (mounted && response != null) {
        setState(() {
          if (response is Map && response.containsKey('data') && response['data'] is List) {
            _goals = response['data'];
          } else {
            _goals = []; // Sécurisation pour éviter le NoSuchMethodError
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack("Erreur de chargement : ${e.toString()}", isError: true);
      }
    }
  }

  // ==========================================
  // ACTIONS API
  // ==========================================
  Future<void> _submitAddGoal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await ApiService().post('goals.php', {
        'action':        'add_goal',
        'title':         _titleCtrl.text.trim(),
        'target_amount': double.parse(_targetCtrl.text),
        'deadline':      _deadline != null ? _formatDate(_deadline!) : null,
      });
      if (mounted && response != null && response['success'] == true) {
        if (response['data'] != null) {
          setState(() => _goals.insert(0, response['data']));
        }
        _titleCtrl.clear();
        _targetCtrl.clear();
        setState(() { _deadline = null; _showForm = false; });
        _showSnack("Nouvel objectif d'épargne créé avec succès !");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitEditGoal({
    required int id,
    required String title,
    required double target,
    required DateTime? deadline,
  }) async {
    try {
      final response = await ApiService().post('goals.php', {
        'action':        'edit_goal',
        'goal_id':       id,
        'title':         title,
        'target_amount': target,
        'deadline':      deadline != null ? _formatDate(deadline) : null,
      });
      if (mounted && response != null && response['success'] == true) {
        final idx = _goals.indexWhere((g) => g['id'] == id);
        if (idx != -1) {
          setState(() {
            final current = (_goals[idx]['current_amount'] as num).toDouble();
            final percent = target > 0 ? (current / target * 100).clamp(0, 100).round() : 0;
            _goals[idx] = {
              ..._goals[idx],
              'title':          title,
              'target_amount':  target,
              'deadline':       deadline != null ? _formatDate(deadline) : null,
              'percent':        percent,
              'is_completed':   percent >= 100,
            };
          });
        }
        _showSnack("Objectif mis à jour avec succès.");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    }
  }

  Future<void> _submitDeleteGoal(int id) async {
    try {
      final response = await ApiService().post('goals.php', {
        'action':  'delete_goal',
        'goal_id': id,
      });
      if (mounted && response != null && response['success'] == true) {
        setState(() => _goals.removeWhere((g) => g['id'] == id));
        _showSnack("L'objectif a été supprimé définitivement.");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    }
  }

  Future<void> _submitContribute(int id, double amount) async {
    try {
      final response = await ApiService().post('goals.php', {
        'action':  'contribute',
        'goal_id': id,
        'amount':  amount,
      });
      if (mounted && response != null && response['success'] == true) {
        final data = response['data'];
        final idx  = _goals.indexWhere((g) => g['id'] == id);
        if (idx != -1 && data != null) {
          setState(() {
            _goals[idx] = {
              ..._goals[idx],
              'current_amount': data['current_amount'],
              'percent':        data['percent'],
              'is_completed':   data['is_completed'],
            };
          });
        }
        _showSnack(response['message'] ?? 'Cotisation enregistrée avec succès !');
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    }
  }

  // ==========================================
  // MODALES
  // ==========================================
  void _openEditModal(Map<String, dynamic> g) {
    final titleCtrl  = TextEditingController(text: g['title'] ?? '');
    final targetCtrl = TextEditingController(
        text: ((g['target_amount'] as num?) ?? 0).toStringAsFixed(0));
    DateTime? editDeadline;
    if (g['deadline'] != null && g['deadline'].toString().isNotEmpty) {
      try { editDeadline = DateTime.parse(g['deadline']); } catch (_) {}
    }
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: const Color(0x661A1A2E),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: _glassModalShell(
            title: "Modifier l'objectif",
            topBorderColor: AppColors.primary,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _modalLabel('Nom du projet'),
                const SizedBox(height: 6),
                _glassInput(
                  controller: titleCtrl,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.backgroundDark),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _modalLabel('Cible (FCFA)'),
                      const SizedBox(height: 6),
                      _glassInput(
                        controller: targetCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.backgroundDark),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          return (n == null || n <= 0) ? 'Invalide' : null;
                        },
                      ),
                    ],
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _modalLabel('Date limite'),
                      const SizedBox(height: 6),
                      _datePicker(
                        date: editDeadline,
                        onPicked: (d) => setModal(() => editDeadline = d),
                        context: ctx,
                      ),
                    ],
                  )),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.of(ctx).pop();
                      await _submitEditGoal(
                        id:       g['id'] as int,
                        title:    titleCtrl.text.trim(),
                        target:   double.parse(targetCtrl.text),
                        deadline: editDeadline,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.backgroundDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Text('Sauvegarder',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _openDeleteModal(int id) {
    showDialog(
      context: context,
      barrierColor: const Color(0x661A1A2E),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: _glassModalShell(
          topBorderColor: AppColors.danger,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: Color(0xFFFFE4E6), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, size: 32, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            const Text("Supprimer l'objectif ?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
            const SizedBox(height: 8),
            const Text(
              "Cette action supprimera le suivi de cet objectif définitivement.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: const Text('Annuler',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _submitDeleteGoal(id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: AppColors.danger.withOpacity(0.3),
                  ),
                  child: const Text('Supprimer',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================
  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _formatDateLong(String raw) {
    const mois = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    if (raw.length < 10) return raw;
    final d = int.tryParse(raw.substring(8, 10)) ?? 0;
    final m = int.tryParse(raw.substring(5, 7)) ?? 0;
    final y = raw.substring(0, 4);
    return '$d ${mois[m]} $y';
  }

  String _formatCurrency(num value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ==========================================
  // BUILD PRINCIPAL
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      extendBody: true,
      bottomNavigationBar: const CustomHeaderPriv(currentRoute: '/app/goals'),
      body: Stack(
        children: [
          _buildAnimatedMesh(),

          RefreshIndicator(
            onRefresh: _fetchGoals,
            color: AppColors.primary,
            backgroundColor: Colors.white,
            edgeOffset: 40,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  _buildHeader(),
                  const SizedBox(height: 20),

                  if (_showForm) ...[
                    _buildFormCard(),
                    const SizedBox(height: 24),
                  ],

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (_goals.isEmpty)
                    _buildEmptyState()
                  else
                    ..._goals.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildGoalCard(g),
                        )),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPOSANT : HEADER
  // ==========================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Objectifs d'Épargne",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.backgroundDark,
                      letterSpacing: -0.5)),
              SizedBox(height: 4),
              Text('Planifiez et financez vos projets.',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _showForm = !_showForm),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.backgroundDark.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(
              _showForm ? Icons.close_rounded : Icons.add_rounded,
              color: Colors.white, size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // COMPOSANT : FORMULAIRE NOUVEAU PROJET
  // ==========================================
  Widget _buildFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
            boxShadow: [BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.08),
                blurRadius: 30, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lancer un projet',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.backgroundDark)),
              const SizedBox(height: 18),

              Form(
                key: _formKey,
                child: Column(children: [
                  _fieldLabel('Nom du projet'),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: _titleCtrl,
                    hintText: 'Ex: Achat Nouveau PC',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Montant Cible'),
                        const SizedBox(height: 6),
                        _glassInput(
                          controller: _targetCtrl,
                          hintText: '0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffix: const Text('FCFA',
                              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.backgroundDark),
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            return (n == null || n <= 0) ? 'Invalide' : null;
                          },
                        ),
                      ],
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Date limite (Optionnel)'),
                        const SizedBox(height: 6),
                        _datePicker(
                          date: _deadline,
                          onPicked: (d) => setState(() => _deadline = d),
                          context: context,
                        ),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAddGoal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18, width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Créer l'objectif",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // COMPOSANT : CARTE OBJECTIF
  // ==========================================
  Widget _buildGoalCard(Map<String, dynamic> g) {
    final int    id            = g['id'] is int ? g['id'] : int.tryParse(g['id'].toString()) ?? 0;
    final String title         = g['title'] ?? '';
    final double targetAmount  = (g['target_amount']  as num?)?.toDouble() ?? 0;
    final double currentAmount = (g['current_amount'] as num?)?.toDouble() ?? 0;
    final int    percent       = (g['percent'] as num?)?.toInt() ?? 0;
    final bool   isCompleted   = g['is_completed'] == true;
    final String? deadline     = g['deadline']?.toString();

    final contributeCtrl = TextEditingController();
    final contribKey = GlobalKey<FormState>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.9)),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.06),
                  blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre + actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.backgroundDark)),
                    ),
                    GestureDetector(
                      onTap: () => _openEditModal(g),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.edit_rounded, size: 15, color: AppColors.textSecondary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openDeleteModal(id),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFFD1FAE5) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCompleted ? 'ATTEINT 🎉' : 'EN COURS : $percent%',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: isCompleted ? const Color(0xFF047857) : AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),

                // Date limite
                Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      deadline != null && deadline.isNotEmpty
                          ? "Échéance : ${_formatDateLong(deadline)}"
                          : "Pas de date limite",
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // Montants
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatCurrency(currentAmount.toInt()),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isCompleted ? const Color(0xFF059669) : AppColors.primary)),
                    Text('/ ${_formatCurrency(targetAmount.toInt())} FCFA',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),

                // Barre de progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 10,
                    color: const Color(0xFFE2E8F0),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (percent / 100).clamp(0, 1),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCompleted
                                ? [const Color(0xFF34D399), const Color(0xFF14B8A6)]
                                : [const Color(0xFF818CF8), const Color(0xFFA855F7)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Divider(color: Colors.blueGrey.withOpacity(0.12), height: 1),
                const SizedBox(height: 14),

                // Zone cotisation ou "Objectif Financé"
                if (!isCompleted)
                  Form(
                    key: contribKey,
                    child: Row(children: [
                      Expanded(
                        child: _glassInput(
                          controller: contributeCtrl,
                          hintText: 'Montant',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.backgroundDark),
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            return (n == null || n <= 0) ? '...' : null;
                          },
                          dense: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          if (!contribKey.currentState!.validate()) return;
                          final amount = double.parse(contributeCtrl.text);
                          contributeCtrl.clear();
                          await _submitContribute(id, amount);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text('Cotiser',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ),
                      ),
                    ]),
                  )
                else
                  const Center(
                    child: Text('OBJECTIF FINANCÉ',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Color(0xFF059669))),
                  ),
              ],
            ),
          ),

          // Glow décoratif si complété
          if (isCompleted)
            Positioned(
              right: -40, top: -40,
              child: IgnorePointer(
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF34D399).withOpacity(0.15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
          ),
          child: Column(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: const Icon(Icons.bolt_rounded, color: Colors.black38, size: 30),
            ),
            const SizedBox(height: 16),
            const Text("Aucun objectif d'épargne",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
            const SizedBox(height: 4),
            const Text("Prenez de l'avance sur l'avenir en vous fixant un premier cap.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _showForm = true),
              child: const Text('Lancer un projet maintenant →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ]),
        ),
      ),
    );
  }

  // ==========================================
  // FOND ORBES (identique aux autres vues)
  // ==========================================
  Widget _buildAnimatedMesh() {
    return Positioned.fill(
      child: Stack(children: [
        Positioned(
          top: -100, left: -50,
          child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6B9D).withOpacity(0.08))),
        ),
        Positioned(
          top: 200, right: -100,
          child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD32A).withOpacity(0.05))),
        ),
        Positioned(
          bottom: -50, right: -50,
          child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D2FF).withOpacity(0.06))),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: Container(color: Colors.transparent),
        ),
      ]),
    );
  }

  // ==========================================
  // MODALE SHELL RÉUTILISABLE (CORRIGÉE)
  // ==========================================
  Widget _glassModalShell({
    required Widget child,
    String? title,
    Color? topBorderColor,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        // CORRECTION FATALE : Bordure stricte et uniforme pour éviter le crash (écran gris)
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 40,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // La touche de couleur est déplacée ici sous forme de petite barre design
        if (topBorderColor != null)
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: topBorderColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        if (title != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.backgroundDark)),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        child,
      ]),
    );
  }

  Widget _glassInput({
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
    TextStyle? style,
    bool dense = false,
  }) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboardType,
      validator:    validator,
      style: style ??
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.backgroundDark),
      decoration: InputDecoration(
        hintText:  hintText,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        suffix:    suffix,
        filled:    true,
        fillColor: Colors.white.withOpacity(0.8),
        isDense:   dense,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 12 : 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }

  Widget _datePicker({
    required DateTime? date,
    required void Function(DateTime) onPicked,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context:     context,
          initialDate: date ?? DateTime.now(),
          firstDate:   DateTime(2020),
          lastDate:    DateTime(2100),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              date != null
                  ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                  : 'Choisir...',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: date != null ? AppColors.backgroundDark : AppColors.textSecondary),
            ),
          ),
          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
        ]),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.8),
      );

  Widget _modalLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.8),
        ),
      );
}