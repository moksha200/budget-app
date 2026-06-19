// lib/views/history_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants.dart';
import 'custom_header_priv.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({Key? key}) : super(key: key);

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  bool _isLoading = true;

  List<dynamic> _transactions = [];
  String _currentFilter = 'all';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // ==========================================
  // RÉCUPÉRATION DE L'HISTORIQUE (filtré + paginé)
  // ==========================================
  Future<void> _fetchHistory({String? filter, int? page}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final useFilter = filter ?? _currentFilter;
    final usePage    = page ?? _currentPage;

    try {
      final query = <String, String>{
        'type': useFilter,
        'page': usePage.toString(),
      };
      // CORRECTION : Pas de slash initial avant history.php
      final response = await ApiService().get(
        'history.php?${Uri(queryParameters: query).query}',
      );

      if (mounted && response != null) {
        setState(() {
          // Extraction blindée (comme dans Dashboard)
          Map<String, dynamic> dataMap = {};
          if (response is Map) {
            if (response.containsKey('data') && response['data'] is Map) {
              dataMap = Map<String, dynamic>.from(response['data']);
            } else {
              dataMap = Map<String, dynamic>.from(response);
            }
          }

          // Assignation sécurisée avec des valeurs par défaut solides
          _transactions      = (dataMap['transactions'] is List) ? dataMap['transactions'] : [];
          _currentPage       = int.tryParse(dataMap['current_page']?.toString() ?? '1') ?? 1;
          _totalPages        = int.tryParse(dataMap['total_pages']?.toString() ?? '1') ?? 1;
          _totalTransactions = int.tryParse(dataMap['total_transactions']?.toString() ?? '0') ?? 0;
          _currentFilter     = dataMap['current_filter']?.toString() ?? useFilter;

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
  // SUPPRESSION
  // ==========================================
  Future<void> _deleteTransaction(int id) async {
    try {
      // CORRECTION : Pas de slash initial avant history.php
      final response = await ApiService().post('history.php', {
        'action':         'delete',
        'transaction_id': id,
      });
      if (mounted && response != null && response['success'] == true) {
        setState(() => _transactions.removeWhere((t) => t['id'] == id));
        _totalTransactions = (_totalTransactions - 1).clamp(0, double.infinity).toInt();
        _showSnack("Opération supprimée avec succès.");

        // Si la page devient vide et qu'il existe une page précédente, on recharge
        if (_transactions.isEmpty && _currentPage > 1) {
          await _fetchHistory(page: _currentPage - 1);
        }
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    }
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
            const Text("Supprimer l'opération ?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
            const SizedBox(height: 8),
            const Text(
              "Cette action est définitive et effacera cette trace de votre historique.",
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
                    await _deleteTransaction(id);
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
  String _formatDateDisplay(String raw) {
    if (raw.length < 10) return raw;
    return '${raw.substring(8, 10)}/${raw.substring(5, 7)}/${raw.substring(0, 4)}';
  }

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
      bottomNavigationBar: const CustomHeaderPriv(currentRoute: '/app/history'),
      body: Stack(
        children: [
          _buildAnimatedMesh(),

          RefreshIndicator(
            onRefresh: () => _fetchHistory(),
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

                  _buildFilters(),
                  const SizedBox(height: 20),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else
                    _buildListCard(),

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historique',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.backgroundDark,
                          letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Gérez et analysez tous vos flux financiers.',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // brancher vers /app/export si dispo
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.file_download_outlined, size: 17, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('Export CSV',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textSecondary)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/app/add'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.backgroundDark.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.add_rounded, size: 17, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Ajouter',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                ]),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  // ==========================================
  // COMPOSANT : FILTRES
  // ==========================================
  Widget _buildFilters() {
    final filters = [
      {'key': 'all',     'label': 'Tout'},
      {'key': 'revenu',  'label': 'Revenus'},
      {'key': 'depense', 'label': 'Dépenses'},
      {'key': 'dette',   'label': 'Dettes'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isActive = _currentFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (!isActive) _fetchHistory(filter: f['key'], page: 1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.backgroundDark : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(18),
                  border: isActive ? null : Border.all(color: Colors.white.withOpacity(0.9)),
                  boxShadow: isActive
                      ? [BoxShadow(color: AppColors.backgroundDark.withOpacity(0.25), blurRadius: 14)]
                      : null,
                ),
                child: Text(f['label']!,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // COMPOSANT : CARTE LISTE (glass card)
  // ==========================================
  Widget _buildListCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
            boxShadow: [BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.08),
                blurRadius: 30, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            if (_transactions.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                itemBuilder: (_, i) => _buildTransactionRow(_transactions[i]),
              ),

            if (_totalPages > 1) ...[
              const SizedBox(height: 8),
              Divider(color: Colors.blueGrey.withOpacity(0.12), height: 1),
              const SizedBox(height: 12),
              _buildPagination(),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> t) {
    final String type        = t['type']        ?? 'depense';
    final String description = t['description'] ?? 'Sans description';
    final String category    = t['category']    ?? '';
    final int    amount      = int.tryParse(t['amount']?.toString() ?? '0') ?? 0;
    final String rawDate     = t['transaction_date'] ?? '';
    final int    id          = t['id'] is int ? t['id'] : int.tryParse(t['id'].toString()) ?? 0;

    Color badgeBg, badgeFg, amountColor;
    String sign, label;

    if (type == 'revenu') {
      badgeBg = const Color(0xFFD1FAE5); badgeFg = const Color(0xFF047857);
      amountColor = const Color(0xFF059669); sign = '+'; label = 'Revenu';
    } else if (type == 'dette') {
      badgeBg = const Color(0xFFFEF3C7); badgeFg = const Color(0xFFB45309);
      amountColor = const Color(0xFFD97706); sign = '⚠ '; label = 'Dette';
    } else {
      badgeBg = const Color(0xFFFFE4E6); badgeFg = const Color(0xFFB91C1C);
      amountColor = AppColors.backgroundDark; sign = '-'; label = 'Dépense';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: badgeBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(label.toUpperCase(),
                        style: TextStyle(
                            color: badgeFg,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 6),
                  Text(description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.backgroundDark,
                          fontSize: 14,
                          height: 1.2)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$sign${_formatCurrency(amount)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: amountColor)),
                const Text('FCFA',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black26)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.blueGrey.withOpacity(0.1), height: 1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDateLong(rawDate),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(category.isNotEmpty ? category : 'Autre',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black38)),
              ],
            ),
            GestureDetector(
              onTap: () => _openDeleteModal(id),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0))),
          child: const Icon(Icons.help_outline_rounded, color: Colors.black38, size: 32),
        ),
        const SizedBox(height: 16),
        const Text('Aucune transaction trouvée',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
        const SizedBox(height: 4),
        const Text("L'historique est vide pour cette sélection.",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ==========================================
  // COMPOSANT : PAGINATION
  // ==========================================
  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Page $_currentPage sur $_totalPages',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
        Row(children: [
          _pageBtn(
            label: 'Précédent',
            enabled: _currentPage > 1,
            onTap: () => _fetchHistory(page: _currentPage - 1),
          ),
          const SizedBox(width: 8),
          _pageBtn(
            label: 'Suivant',
            enabled: _currentPage < _totalPages,
            onTap: () => _fetchHistory(page: _currentPage + 1),
          ),
        ]),
      ],
    );
  }

  Widget _pageBtn({required String label, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: enabled ? const Color(0xFFE2E8F0) : const Color(0xFFEDF1F5)),
          boxShadow: enabled ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)] : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: enabled ? AppColors.backgroundDark : Colors.black26)),
      ),
    );
  }

  // ==========================================
  // FOND ORBES (identique dashboard/add)
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
  // MODALE SHELL RÉUTILISABLE
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
        border: topBorderColor != null
            ? Border(
                top: BorderSide(color: topBorderColor, width: 4),
                left: BorderSide(color: Colors.white.withOpacity(0.9)),
                right: BorderSide(color: Colors.white.withOpacity(0.9)),
                bottom: BorderSide(color: Colors.white.withOpacity(0.9)),
              )
            : Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 40,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
}