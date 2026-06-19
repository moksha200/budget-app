// lib/views/loans_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants.dart';
import 'custom_header_priv.dart';

class LoansView extends StatefulWidget {
  const LoansView({Key? key}) : super(key: key);

  @override
  State<LoansView> createState() => _LoansViewState();
}

class _LoansViewState extends State<LoansView> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showForm = false;

  List<dynamic> _activeLoans = [];
  List<dynamic> _settledLoans = [];

  // Formulaire "Nouveau Prêt"
  final _formKey    = GlobalKey<FormState>();
  final _debtorCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _loanDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  @override
  void dispose() {
    _debtorCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // RÉCUPÉRATION DES DONNÉES
  // ==========================================
  Future<void> _fetchLoans() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('loans.php');
      if (mounted && response != null) {
        setState(() {
          if (response is Map && response.containsKey('data') && response['data'] is Map) {
            final data = response['data'];
            _activeLoans = data['active_loans'] is List ? data['active_loans'] : [];
            _settledLoans = data['settled_loans'] is List ? data['settled_loans'] : [];
          } else {
            _activeLoans = [];
            _settledLoans = [];
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
  Future<void> _submitAddLoan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await ApiService().post('loans.php', {
        'action':      'add_loan',
        'debtor_name': _debtorCtrl.text.trim(),
        'amount':      double.parse(_amountCtrl.text),
        'loan_date':   _formatDate(_loanDate),
      });
      if (mounted && response != null && response['success'] == true) {
        await _fetchLoans(); // On rafraîchit pour avoir les vrais IDs et la synchro
        _debtorCtrl.clear();
        _amountCtrl.clear();
        setState(() { _loanDate = DateTime.now(); _showForm = false; });
        _showSnack(response['message'] ?? "Le prêt a été enregistré avec succès.");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitEditLoan({
    required int id,
    required String debtorName,
    required double amount,
    required DateTime date,
  }) async {
    try {
      final response = await ApiService().post('loans.php', {
        'action':      'edit_loan',
        'loan_id':     id,
        'debtor_name': debtorName,
        'amount':      amount,
        'loan_date':   _formatDate(date),
      });
      if (mounted && response != null && response['success'] == true) {
        await _fetchLoans();
        _showSnack(response['message'] ?? "Le prêt a été mis à jour.");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    }
  }

  Future<void> _submitDeleteLoan(int id) async {
    try {
      final response = await ApiService().post('loans.php', {
        'action':  'delete_loan',
        'loan_id': id,
      });
      if (mounted && response != null && response['success'] == true) {
        setState(() => _activeLoans.removeWhere((l) => l['id'] == id));
        _showSnack(response['message'] ?? "Le prêt a été supprimé définitivement.");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    }
  }

  Future<void> _submitRepay(int id, double amount) async {
    try {
      final response = await ApiService().post('loans.php', {
        'action':       'repay_loan',
        'loan_id':      id,
        'repay_amount': amount,
      });
      if (mounted && response != null && response['success'] == true) {
        await _fetchLoans(); // Rafraîchit les listes (peut passer en 'rembourse')
        _showSnack(response['message'] ?? "Remboursement validé !");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    }
  }

  // ==========================================
  // MODALES
  // ==========================================
  void _openEditModal(Map<String, dynamic> l) {
    final debtorCtrl = TextEditingController(text: l['debtor_name'] ?? '');
    final amountCtrl = TextEditingController(
        text: ((l['amount'] as num?) ?? 0).toStringAsFixed(0));
    DateTime editDate;
    try { editDate = DateTime.parse(l['loan_date']); } catch (_) { editDate = DateTime.now(); }
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: const Color(0x661A1A2E),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: _glassModalShell(
            title: "Modifier le prêt",
            topBorderColor: AppColors.primary,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _modalLabel('Nom du débiteur'),
                const SizedBox(height: 6),
                _glassInput(
                  controller: debtorCtrl,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.backgroundDark),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _modalLabel('Montant Total'),
                      const SizedBox(height: 6),
                      _glassInput(
                        controller: amountCtrl,
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
                      _modalLabel('Date'),
                      const SizedBox(height: 6),
                      _datePicker(
                        date: editDate,
                        onPicked: (d) => setModal(() => editDate = d),
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
                      await _submitEditLoan(
                        id:         l['id'] as int,
                        debtorName: debtorCtrl.text.trim(),
                        amount:     double.parse(amountCtrl.text),
                        date:       editDate,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.backgroundDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Text('Mettre à jour', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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
            const Text("Annuler ce prêt ?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
            const SizedBox(height: 8),
            const Text(
              "Ceci supprimera le suivi de cette dette définitivement.",
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
                  child: const Text('Retour', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _submitDeleteLoan(id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: AppColors.danger.withOpacity(0.3),
                  ),
                  child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
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
  String _formatDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  
  String _formatDateDisplay(String raw) {
    const mois = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    if (raw.length < 10) return raw;
    final d = int.tryParse(raw.substring(8, 10)) ?? 0;
    final m = int.tryParse(raw.substring(5, 7)) ?? 0;
    final y = raw.substring(0, 4);
    return '${d.toString().padLeft(2, '0')} ${mois[m]} $y';
  }

  String _formatCurrency(num value) {
    return value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
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
      bottomNavigationBar: const CustomHeaderPriv(currentRoute: '/app/loans'),
      body: Stack(
        children: [
          _buildAnimatedMesh(),

          RefreshIndicator(
            onRefresh: _fetchLoans,
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
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(color: AppColors.primary)))
                  else ...[
                    // --- CREANCES EN COURS ---
                    Row(
                      children: [
                        Container(
                          width: 12, height: 12,
                          margin: const EdgeInsets.only(right: 10, left: 8),
                          decoration: BoxDecoration(color: const Color(0xFFF59E0B), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.6), blurRadius: 8)]),
                        ),
                        const Text('Créances en cours', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_activeLoans.isEmpty)
                      _buildEmptyState()
                    else
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 225, // Hauteur fixe pour la carte
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _activeLoans.length,
                        itemBuilder: (ctx, i) => _ActiveLoanCard(
                          loan: _activeLoans[i],
                          onEdit: () => _openEditModal(_activeLoans[i]),
                          onDelete: () => _openDeleteModal(_activeLoans[i]['id']),
                          onRepay: (id, amount) => _submitRepay(id, amount),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // --- CREANCES SOLDEES ---
                    Row(
                      children: [
                        Container(
                          width: 12, height: 12,
                          margin: const EdgeInsets.only(right: 10, left: 8),
                          decoration: BoxDecoration(color: const Color(0xFF10B981), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.6), blurRadius: 8)]),
                        ),
                        const Text('Créances soldées', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_settledLoans.isEmpty)
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.65), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.9))),
                        child: const Text("Aucun historique de prêt remboursé.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      )
                    else
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 80,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _settledLoans.length,
                        itemBuilder: (ctx, i) {
                          final sl = _settledLoans[i];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: const Border(left: BorderSide(color: Color(0xFF10B981), width: 4), top: BorderSide(color: Colors.white), right: BorderSide(color: Colors.white), bottom: BorderSide(color: Colors.white)),
                              boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(sl['debtor_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.backgroundDark)),
                                    Text("Fermé le ${_formatDateDisplay(sl['updated_at'] ?? '')}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("${_formatCurrency((sl['amount'] as num).toInt())} FCFA", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                                    Container(
                                      margin: const EdgeInsets.only(top: 2), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Terminé', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                                    )
                                  ],
                                )
                              ],
                            ),
                          );
                        }
                      ),
                  ],

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
  // COMPOSANTS UI
  // ==========================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Prêts & Créances", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.backgroundDark, letterSpacing: -0.5)),
              SizedBox(height: 4),
              Text("Suivez l'argent que vous avez prêté.", style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => setState(() => _showForm = !_showForm),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.backgroundDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
          ),
          icon: Icon(_showForm ? Icons.close_rounded : Icons.add_rounded, size: 20),
          label: Text(_showForm ? "Fermer" : "Nouveau Prêt", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65), borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
            boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enregistrer un prêt accordé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
              const SizedBox(height: 18),
              Form(
                key: _formKey,
                child: Column(children: [
                  _fieldLabel('Nom du débiteur'),
                  const SizedBox(height: 6),
                  _glassInput(controller: _debtorCtrl, hintText: 'À qui avez-vous prêté ? (Ex: Marc)', validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Montant Prêté'),
                        const SizedBox(height: 6),
                        _glassInput(
                          controller: _amountCtrl, hintText: '0', keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffix: const Text('FCFA', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.backgroundDark),
                          validator: (v) { final n = double.tryParse(v ?? ''); return (n == null || n <= 0) ? 'Invalide' : null; },
                        ),
                      ],
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Date du prêt'),
                        const SizedBox(height: 6),
                        _datePicker(date: _loanDate, onPicked: (d) => setState(() => _loanDate = d), context: context),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAddLoan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 6,
                      ),
                      child: _isSubmitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Valider et impacter le solde", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.65), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.9))),
      child: const Text("Personne ne vous doit d'argent actuellement.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
    );
  }

  // ==========================================
  // WIDGETS RÉUTILISABLES & FOND
  // ==========================================
  // CORRECTION : sigma réduit de 90 à 20 (même raison que dans add_view.dart :
  // un flou aussi extrême sur tout l'écran provoquait une frame grise au
  // moment de la navigation vers cette page).
  Widget _buildAnimatedMesh() {
    return Positioned.fill(
      child: Stack(children: [
        Positioned(top: -100, left: -50, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF6B9D).withOpacity(0.08)))),
        Positioned(top: 200, right: -100, child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFD32A).withOpacity(0.05)))),
        Positioned(bottom: -50, right: -50, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00D2FF).withOpacity(0.06)))),
        BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(color: Colors.transparent)),
      ]),
    );
  }

  Widget _glassModalShell({required Widget child, String? title, Color? topBorderColor}) {
    return Container(
      width: double.infinity, constraints: const BoxConstraints(maxWidth: 420), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5), // SECURITE ANTI-CRASH
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 12))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (topBorderColor != null) Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: topBorderColor, borderRadius: BorderRadius.circular(10))),
        if (title != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), splashRadius: 20),
            ],
          ),
          const SizedBox(height: 16),
        ],
        child,
      ]),
    );
  }

  Widget _glassInput({required TextEditingController controller, String? hintText, TextInputType? keyboardType, String? Function(String?)? validator, Widget? suffix, TextStyle? style, bool dense = false}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, validator: validator,
      style: style ?? const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.backgroundDark),
      decoration: InputDecoration(
        hintText: hintText, hintStyle: const TextStyle(color: AppColors.textSecondary), suffix: suffix,
        filled: true, fillColor: Colors.white.withOpacity(0.8), isDense: dense, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 12 : 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger)),
      ),
    );
  }

  Widget _datePicker({required DateTime date, required void Function(DateTime) onPicked, required BuildContext context}) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100),
          builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
        child: Row(children: [
          Expanded(child: Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.backgroundDark))),
          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
        ]),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8));
  Widget _modalLabel(String text) => Align(alignment: Alignment.centerLeft, child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8)));
}

// ==========================================
// SOUS-COMPOSANT : CARTE PRÊT ACTIF (Gestion de l'input encaissement)
// ==========================================
class _ActiveLoanCard extends StatefulWidget {
  final Map<String, dynamic> loan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(int, double) onRepay;

  const _ActiveLoanCard({Key? key, required this.loan, required this.onEdit, required this.onDelete, required this.onRepay}) : super(key: key);

  @override
  State<_ActiveLoanCard> createState() => _ActiveLoanCardState();
}

class _ActiveLoanCardState extends State<_ActiveLoanCard> {
  final _repayCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _repayCtrl.dispose();
    super.dispose();
  }

  String _formatCurrency(num value) {
    return value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    final int id = widget.loan['id'] as int;
    final String debtor = widget.loan['debtor_name'] ?? '';
    final double amount = (widget.loan['amount'] as num?)?.toDouble() ?? 0;
    final double amountPaid = (widget.loan['amount_paid'] as num?)?.toDouble() ?? 0;
    final String date = widget.loan['loan_date'] ?? '';
    
    final double remaining = amount - amountPaid;
    final int percent = amount > 0 ? ((amountPaid / amount) * 100).clamp(0, 100).round() : 0;

    // Formatage date local
    String formattedDate = date;
    if (date.length >= 10) {
      const mois = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
      final d = int.tryParse(date.substring(8, 10)) ?? 0;
      final m = int.tryParse(date.substring(5, 7)) ?? 0;
      final y = date.substring(0, 4);
      formattedDate = '${d.toString().padLeft(2, '0')} ${mois[m]} $y';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // En-tête
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debtor, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
                    const SizedBox(height: 2),
                    Text("Prêté le $formattedDate", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onEdit,
                    child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.danger)),
                  ),
                ],
              )
            ],
          ),

          // Nombres
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Remboursé: ${_formatCurrency(amountPaid.toInt())}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                  Text("Reste: ${_formatCurrency(remaining.toInt())}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
                ],
              ),
              const SizedBox(height: 8),
              // Barre
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 10, color: const Color(0xFFF1F5F9),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft, widthFactor: (percent / 100).clamp(0, 1),
                    child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFF10B981)]))),
                  ),
                ),
              ),
            ],
          ),

          // Formulaire Encaissement
          Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _repayCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.backgroundDark),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return '!';
                      if (n > remaining) return 'Max: $remaining';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Montant perçu', hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      filled: true, fillColor: Colors.white, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.danger)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (!_formKey.currentState!.validate()) return;
                    final amt = double.parse(_repayCtrl.text);
                    _repayCtrl.clear();
                    widget.onRepay(id, amt);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(10)),
                    child: const Text('Encaisser', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF047857))),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}