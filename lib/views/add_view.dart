// lib/views/add_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';
import 'custom_header_priv.dart';

class AddView extends StatefulWidget {
  const AddView({Key? key}) : super(key: key);

  @override
  State<AddView> createState() => _AddViewState();
}

class _AddViewState extends State<AddView> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<dynamic> _transactions = [];

  // Formulaire Ajouter
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'depense';
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // HELPER : extraction sécurisée de l'ID
  // ==========================================
  // CORRECTION : l'API peut renvoyer l'id en String ou en int selon le
  // contexte (MySQL/PHP via JSON). Un cast direct `as int` plantait
  // l'application si la valeur arrivait sous forme de String.
  int _extractId(Map<String, dynamic> t) {
    final raw = t['id'];
    if (raw is int) return raw;
    return int.parse(raw.toString());
  }

  // CORRECTION : nettoyage du montant via parsing numérique réel au lieu
  // de remplacements de texte (`replaceAll('.0', '')`), qui pouvait
  // corrompre des valeurs comme 1200.05 dans certains cas de figure.
  String _cleanAmountText(dynamic rawAmount) {
    final n = double.tryParse(rawAmount?.toString() ?? '') ?? 0;
    if (n == n.truncateToDouble()) {
      return n.toInt().toString();
    }
    return n.toString();
  }

  // ==========================================
  // RÉCUPÉRATION DE L'HISTORIQUE (Corrigée vers dashboard.php)
  // ==========================================
  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // CORRECTION ICI : On utilise dashboard.php qui est autorisé en GET
      // et qui renvoie nativement la liste des transactions récentes.
      final response = await ApiService().get('dashboard.php');

      if (mounted && response != null) {
        setState(() {
          // Extraction blindée identique à DashboardView
          Map<String, dynamic> dataMap = {};
          if (response is Map) {
            if (response.containsKey('data') && response['data'] is Map) {
              dataMap = Map<String, dynamic>.from(response['data']);
            } else {
              dataMap = Map<String, dynamic>.from(response);
            }
          }

          if (dataMap.containsKey('recent_transactions') &&
              dataMap['recent_transactions'] is List) {
            _transactions = dataMap['recent_transactions'];
          } else {
            _transactions = [];
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
  // ACTIONS API (Conservées sur add.php en POST)
  // ==========================================
  Future<void> _submitAdd() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await ApiService().post('add.php', {
        'action': 'add',
        'type': _type,
        'amount': double.parse(_amountCtrl.text),
        'description': _descCtrl.text.trim(),
        'transaction_date': _formatDate(_date),
      });
      if (mounted && response != null && response['success'] == true) {
        // Au lieu d'essayer d'injecter des données que l'API ne renvoie plus,
        // on rafraîchit simplement la liste depuis le serveur pour être synchro.
        await _fetchTransactions();

        _amountCtrl.clear();
        _descCtrl.clear();
        setState(() {
          _type = 'depense';
          _date = DateTime.now();
        });
        _showSnack("Opération ajoutée avec succès !");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitEdit({
    required int id,
    required String type,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    try {
      final response = await ApiService().post('add.php', {
        'action': 'edit',
        'transaction_id': id,
        'type': type,
        'amount': amount,
        'description': description,
        'transaction_date': _formatDate(date),
      });
      if (mounted && response != null && response['success'] == true) {
        final idx = _transactions.indexWhere((t) => _extractId(t) == id);
        if (idx != -1) {
          setState(() {
            _transactions[idx] = {
              ..._transactions[idx],
              'type': type,
              'amount': amount,
              'description': description,
              'transaction_date': _formatDate(date),
            };
          });
        }
        _showSnack("Opération modifiée avec succès.");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    }
  }

  Future<void> _submitDelete(int id) async {
    try {
      final response = await ApiService().post('add.php', {
        'action': 'delete',
        'transaction_id': id,
      });
      if (mounted && response != null && response['success'] == true) {
        setState(() => _transactions.removeWhere((t) => _extractId(t) == id));
        _showSnack("Opération supprimée définitivement.");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    }
  }

  Future<void> _submitResolveDebt(int id) async {
    try {
      final response = await ApiService().post('add.php', {
        'action': 'resolve_debt',
        'transaction_id': id,
      });
      if (mounted && response != null && response['success'] == true) {
        final idx = _transactions.indexWhere((t) => _extractId(t) == id);
        if (idx != -1) {
          setState(() {
            _transactions[idx] = {
              ..._transactions[idx],
              'type': 'depense',
              'description': '[Remboursé] ${_transactions[idx]['description']}',
              'transaction_date': _formatDate(DateTime.now()),
            };
          });
        }
        _showSnack(
          "Dette marquée comme remboursée. Le montant a été déduit de votre solde.",
        );
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    }
  }

  // ==========================================
  // MODALES
  // ==========================================
  // CORRECTION FATALE (écran gris plein écran après action) :
  // Avant, on faisait `Navigator.of(ctx).pop()` PUIS immédiatement
  // `await _submitEdit(...)` qui déclenchait un `setState()` sur AddView.
  // Le `pop()` lance une ANIMATION de fermeture du Dialog (barrier +
  // transition), elle ne se termine pas instantanément. Si le rebuild
  // de la page parente (avec ses BackdropFilter dans _buildAnimatedMesh
  // et _buildFormCard) arrivait pendant cette animation, l'Overlay du
  // barrier restait visuellement "coincé" en plein écran (gris), même si
  // l'action réseau avait réussi (le SnackBar vert s'affichait par-dessus).
  //
  // FIX : on attend la fermeture COMPLÈTE du dialog (await showDialog) et
  // on ne déclenche l'appel réseau + setState QU'APRÈS, une fois
  // l'animation terminée. Le bouton ne fait plus que Navigator.pop(ctx,
  // data) avec les données du formulaire, sans appel réseau direct.
  Future<void> _openEditModal(Map<String, dynamic> t) async {
    final amountCtrl = TextEditingController(
      text: _cleanAmountText(t['amount']),
    );
    final descCtrl = TextEditingController(text: t['description'] ?? '');
    String editType = (['depense', 'revenu', 'dette'].contains(t['type']))
        ? t['type']
        : 'depense';
    DateTime editDate;
    try {
      editDate = DateTime.parse(
        t['transaction_date'] ?? DateTime.now().toString(),
      );
    } catch (_) {
      editDate = DateTime.now();
    }
    final formKey = GlobalKey<FormState>();
    bool isSavingModal = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: const Color(0x661A1A2E),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: _glassModalShell(
            title: "Modifier l'opération",
            topBorderColor: AppColors.primary,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modalLabel('Montant'),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n <= 0) ? 'Montant invalide' : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _modalLabel('Type'),
                            const SizedBox(height: 6),
                            _glassDropdown(
                              value: editType,
                              onChanged: (v) => setModal(() => editType = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _modalLabel('Date'),
                            const SizedBox(height: 6),
                            _datePicker(
                              date: editDate,
                              onPicked: (d) => setModal(() => editDate = d),
                              context: ctx,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _modalLabel('Description'),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: descCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSavingModal
                          ? null
                          : () {
                              if (!formKey.currentState!.validate()) return;
                              setModal(() => isSavingModal = true);
                              Navigator.of(ctx).pop({
                                'id': _extractId(t),
                                'type': editType,
                                'amount': double.parse(amountCtrl.text),
                                'description': descCtrl.text.trim(),
                                'date': editDate,
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.backgroundDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: isSavingModal
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Sauvegarder',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Le dialog est maintenant COMPLÈTEMENT fermé (animation terminée).
    // On peut donc lancer l'appel réseau + setState sans risque de
    // collision avec l'overlay du barrier.
    if (result != null) {
      await _submitEdit(
        id: result['id'] as int,
        type: result['type'] as String,
        amount: result['amount'] as double,
        description: result['description'] as String,
        date: result['date'] as DateTime,
      );
    }
  }

  Future<void> _openDeleteModal(Map<String, dynamic> t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x661A1A2E),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: _glassModalShell(
          topBorderColor: AppColors.danger,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 32,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Supprimer l'opération ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Cette action est définitive et effacera cette trace de votre historique.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.danger.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Appel réseau déclenché APRÈS la fermeture complète du dialog.
    if (confirmed == true) {
      await _submitDelete(_extractId(t));
    }
  }

  Future<void> _openResolveModal(Map<String, dynamic> t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x661A1A2E),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: _glassModalShell(
          topBorderColor: const Color(0xFF10B981),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 32,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Terminer cette dette ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Elle sera convertie en dépense remboursée, ce qui déduira le montant de votre solde actuel.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF059669).withOpacity(0.3),
                      ),
                      child: const Text(
                        'Confirmer',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Appel réseau déclenché APRÈS la fermeture complète du dialog.
    if (confirmed == true) {
      await _submitResolveDebt(_extractId(t));
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================
  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _formatDateDisplay(String raw) {
    if (raw.length < 10) return raw;
    return '${raw.substring(8, 10)}/${raw.substring(5, 7)}/${raw.substring(0, 4)}';
  }

  String _formatCurrency(num value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==========================================
  // BUILD PRINCIPAL
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      extendBody: true,
      bottomNavigationBar: const CustomHeaderPriv(currentRoute: '/app/add'),
      body: Stack(
        children: [
          // Fond orbes identique au dashboard
          _buildAnimatedMesh(),

          RefreshIndicator(
            onRefresh: _fetchTransactions,
            color: AppColors.primary,
            backgroundColor: Colors.white,
            edgeOffset: 40,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // HEADER
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // FORMULAIRE AJOUTER
                  _buildFormCard(),
                  const SizedBox(height: 28),

                  // HISTORIQUE
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    _buildHistorySection(),

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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opérations',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.backgroundDark,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Gérez vos flux en temps réel.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/app/dashboard'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: AppColors.backgroundDark,
                ),
                SizedBox(width: 6),
                Text(
                  'Retour',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.backgroundDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // COMPOSANT : FORMULAIRE AJOUTER (glass card)
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
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Ajouter un flux',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Montant
                    _fieldLabel('Montant'),
                    const SizedBox(height: 6),
                    _glassInput(
                      controller: _amountCtrl,
                      hintText: '0',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      suffix: const Text(
                        'FCFA',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.backgroundDark,
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n <= 0)
                            ? 'Montant invalide'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Type + Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Type'),
                              const SizedBox(height: 6),
                              _glassDropdown(
                                value: _type,
                                onChanged: (v) => setState(() => _type = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Date'),
                              const SizedBox(height: 6),
                              _datePicker(
                                date: _date,
                                onPicked: (d) => setState(() => _date = d),
                                context: context,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _fieldLabel('Description'),
                    const SizedBox(height: 6),
                    _glassInput(
                      controller: _descCtrl,
                      hintText: 'Ex: Loyer, Salaire, Emprunt...',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Description requise'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Bouton submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.backgroundDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: AppColors.backgroundDark.withOpacity(
                            0.3,
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Enregistrer l'opération",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // COMPOSANT : HISTORIQUE
  // ==========================================
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique Récent',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.backgroundDark,
          ),
        ),
        const SizedBox(height: 16),

        if (_transactions.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            itemBuilder: (_, i) => _buildTransactionItem(_transactions[i]),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> t) {
    final String type = t['type'] ?? 'depense';
    final String description = t['description'] ?? 'Sans description';
    final int amount = int.tryParse(t['amount']?.toString() ?? '0') ?? 0;
    final String rawDate = t['transaction_date'] ?? '';

    Color badgeBg, badgeFg, amountColor;
    String sign, label;

    if (type == 'revenu') {
      badgeBg = const Color(0xFFD1FAE5);
      badgeFg = const Color(0xFF047857);
      amountColor = const Color(0xFF059669);
      sign = '+';
      label = 'Revenu';
    } else if (type == 'dette') {
      badgeBg = const Color(0xFFFEF3C7);
      badgeFg = const Color(0xFFB45309);
      amountColor = const Color(0xFFD97706);
      sign = '⚠ ';
      label = 'Dette';
    } else {
      badgeBg = const Color(0xFFFFE4E6);
      badgeFg = const Color(0xFFB91C1C);
      amountColor = AppColors.backgroundDark;
      sign = '-';
      label = 'Dépense';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ligne principale
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          color: badgeFg,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.backgroundDark,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateDisplay(rawDate),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${_formatCurrency(amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: amountColor,
                    ),
                  ),
                  const Text(
                    'FCFA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black26,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(color: Colors.blueGrey.withOpacity(0.1), height: 1),
          const SizedBox(height: 10),

          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Modifier
              _actionBtn(
                icon: Icons.edit_rounded,
                label: 'Modifier',
                bg: const Color(0xFFF1F5F9),
                fg: AppColors.textSecondary,
                onTap: () => _openEditModal(Map<String, dynamic>.from(t)),
              ),
              const SizedBox(width: 8),
              // Supprimer
              _actionBtn(
                icon: Icons.delete_outline_rounded,
                label: 'Supprimer',
                bg: const Color(0xFFF1F5F9),
                fg: AppColors.textSecondary,
                onTap: () => _openDeleteModal(Map<String, dynamic>.from(t)),
              ),
              if (type == 'dette') ...[
                const SizedBox(width: 8),
                // Terminer (dette)
                _actionBtn(
                  icon: Icons.check_rounded,
                  label: 'Terminer',
                  bg: const Color(0xFFD1FAE5),
                  fg: const Color(0xFF047857),
                  showLabel: true,
                  onTap: () => _openResolveModal(Map<String, dynamic>.from(t)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 40, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            'Aucune opération pour le moment.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FOND ORBES (identique dashboard)
  // ==========================================
  // CORRECTION : sigma réduit de 90 à 20. Un flou aussi extrême (90) sur un
  // BackdropFilter couvrant tout l'écran est très coûteux pour le GPU et
  // provoquait une frame grise/incomplète juste après la navigation vers
  // cette page, le temps que le moteur de rendu rattrape le calcul du flou.
  Widget _buildAnimatedMesh() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B9D).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD32A).withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D2FF).withOpacity(0.06),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGETS RÉUTILISABLES
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
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.backgroundDark,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  Widget _glassInput({
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
    TextStyle? style,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style:
          style ??
          const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.backgroundDark,
          ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        suffix: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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

  Widget _glassDropdown({
    required String value,
    required void Function(String?) onChanged,
  }) {
    const items = [
      {'value': 'depense', 'label': '📉 Dépense'},
      {'value': 'revenu', 'label': '📈 Revenu'},
      {'value': 'dette', 'label': '⚠️ Dette'},
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          items: items
              .map(
                (i) => DropdownMenuItem<String>(
                  value: i['value'],
                  child: Text(
                    i['label']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _datePicker({
    required DateTime date,
    required void Function(DateTime) onPicked,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.backgroundDark,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
    bool showLabel = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: showLabel ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: AppColors.textSecondary,
      letterSpacing: 0.8,
    ),
  );

  Widget _modalLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    ),
  );
}