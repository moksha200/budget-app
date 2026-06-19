// lib/views/dashboard_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';
import 'custom_header_priv.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isLoading = true;
  
  // Variables globales du bilan financier
  int _soldeActuel = 0;
  int _totalRevenu = 0;
  int _totalDepense = 0;
  int _totalDette = 0;
  
  List<dynamic> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ==========================================
  // LOGIQUE DE RÉCUPÉRATION DES DONNÉES (API)
  // ==========================================
  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService().get('dashboard.php');

      if (mounted && response != null) {
        setState(() {
          // 1. Extraction blindée du niveau racine ou 'data'
          Map<String, dynamic> dataMap = {};
          if (response is Map) {
            if (response.containsKey('data') && response['data'] is Map) {
              dataMap = Map<String, dynamic>.from(response['data']);
            } else {
              dataMap = Map<String, dynamic>.from(response);
            }
          }

          // 2. Extraction blindée de l'objet 'summary'
          Map<String, dynamic> summary = {};
          if (dataMap.containsKey('summary') && dataMap['summary'] is Map) {
            summary = Map<String, dynamic>.from(dataMap['summary']);
          }

          // 3. Extraction sécurisée des montants (ne crashera plus sur null)
          _totalRevenu = int.tryParse(summary['total_revenu']?.toString() ?? '0') ?? 0;
          _totalDepense = int.tryParse(summary['total_depense']?.toString() ?? '0') ?? 0;
          _totalDette = int.tryParse(summary['total_dette']?.toString() ?? '0') ?? 0;
          
          _soldeActuel = _totalRevenu - _totalDepense;
          
          // 4. Extraction blindée de la liste des transactions
          if (dataMap.containsKey('recent_transactions') && dataMap['recent_transactions'] is List) {
            _recentTransactions = dataMap['recent_transactions'];
          } else {
            _recentTransactions = [];
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de synchronisation : ${e.toString()}"),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // Formateur de devise maison (sépare les milliers par un espace)
  String _formatCurrency(num value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]} '
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = context.watch<AuthProvider>().currentUser?.name ?? "poto";
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF), // var(--bg)
      extendBody: true, // Laisse passer le scroll derrière le dock flottant
      bottomNavigationBar: const CustomHeaderPriv(currentRoute: '/app/dashboard'),
      body: Stack(
        children: [
          // 1. LE FOND : ORBES ARC-EN-CIEL MULTIPLES
          _buildAnimatedMesh(),

          // 2. LE REFRESH INDICATOR ET LE SCROLL
          RefreshIndicator(
            onRefresh: _fetchDashboardData,
            color: AppColors.primary,
            backgroundColor: Colors.white,
            edgeOffset: 40,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48), // Compensation de la barre d'état

                  // --- SECTION BIENVENUE ---
                  _buildWelcomeHeader(username),
                  const SizedBox(height: 24),

                  // --- ZONE DE CHARGEMENT SQUELETTE / ENTIÈRE ---
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else ...[
                    // --- GRILLE DES CARTES FINANCIÈRES ---
                    _buildStatsGrid(screenWidth),
                    const SizedBox(height: 28),

                    // --- COMPOSANT : ACTIVITÉ RÉCENTE ---
                    _buildRecentActivitySection(),
                  ],
                  
                  const SizedBox(height: 120), // Zone de sécurité pour le dock
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPOSANT: EN-TÊTE BIENVENUE
  // ==========================================
  Widget _buildWelcomeHeader(String username) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Vue d'ensemble",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.backgroundDark, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                "Gérez vos finances d'une main de maître, $username.",
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        // Bouton "+" rapide calqué sur ton bouton "Nouvelle Opération"
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/app/add'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.backgroundDark.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        )
      ],
    );
  }

  // ==========================================
  // COMPOSANT: GRILLE DES STATS RESPONSIVE
  // ==========================================
  Widget _buildStatsGrid(double screenWidth) {
    // Largeur dynamique des cartes (2 colonnes sur mobile)
    final double cardWidth = (screenWidth - 44) / 2;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // 1. Solde Actuel (Prend toute la largeur sur mobile pour l'importance)
        _buildStatCard(
          title: "Solde Actuel",
          value: "${_formatCurrency(_soldeActuel)} FCFA",
          borderColor: const Color(0xFF6366F1), // indigo-500
          icon: Icons.account_balance_wallet_rounded,
          iconBg: const Color(0xFFEEF2FF),
          iconColor: const Color(0xFF4F46E5),
          width: double.infinity,
        ),
        // 2. Revenus
        _buildStatCard(
          title: "Revenus",
          value: "+${_formatCurrency(_totalRevenu)}",
          borderColor: const Color(0xFF10B981), // emerald-500
          icon: Icons.arrow_upward_rounded,
          iconBg: const Color(0xFFECFDF5),
          iconColor: const Color(0xFF059669),
          width: cardWidth,
          textColor: const Color(0xFF059669),
        ),
        // 3. Dépenses
        _buildStatCard(
          title: "Dépenses",
          value: "-${_formatCurrency(_totalDepense)}",
          borderColor: const Color(0xFFF43F5E), // rose-500
          icon: Icons.arrow_downward_rounded,
          iconBg: const Color(0xFFFFF1F2),
          iconColor: const Color(0xFFE11D48),
          width: cardWidth,
          textColor: const Color(0xFFE11D48),
        ),
        // 4. Dettes
        _buildStatCard(
          title: "Dettes en cours",
          value: _formatCurrency(_totalDette),
          borderColor: const Color(0xFFF59E0B), // amber-500
          icon: Icons.hourglass_empty_rounded,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          width: double.infinity,
          textColor: const Color(0xFFD97706),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color borderColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required double width,
    Color? textColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
            boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 8))],
          ),
          child: Stack(
            children: [
              // Ligne de couleur sur le côté gauche ou haut (Calqué sur border-t-4)
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(width: 4, decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2))),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8)),
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                          child: Icon(icon, color: iconColor, size: 16),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: width == double.infinity ? 26 : 20, 
                        fontWeight: FontWeight.w900, 
                        color: textColor ?? AppColors.backgroundDark,
                        letterSpacing: -0.5
                      ),
                    ),
                    if (title == "Solde Actuel" || title == "Dettes en cours")
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Text("FCFA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black26)),
                      )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // COMPOSANT: SECTION ACTIVITÉ RÉCENTE (MOBILE-FIRST)
  // ==========================================
  Widget _buildRecentActivitySection() {
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
            boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Activité Récente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/app/history'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                      child: const Text("Tout voir", style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),

              if (_recentTransactions.isEmpty)
                _buildEmptyState()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentTransactions.length,
                  itemBuilder: (context, index) {
                    final t = _recentTransactions[index];
                    return _buildTransactionItem(t);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> t) {
    Color badgeBg = Colors.grey.shade100;
    Color badgeText = Colors.grey.shade700;
    Color amountColor = AppColors.backgroundDark;
    String sign = '';
    String label = 'Flux';

    // Extraction et typage précis des données
    final String type = t['type'] ?? 'depense';
    final String description = t['description'] ?? 'Sans description';
    final String category = t['category'] ?? '';
    final int amount = int.tryParse(t['amount']?.toString() ?? '0') ?? 0;
    final String rawDate = t['transaction_date'] ?? DateTime.now().toString();

    if (type == 'revenu') {
      badgeBg = const Color(0xFFD1FAE5); // bg-emerald-100
      badgeText = const Color(0xFF047857); // text-emerald-700
      amountColor = const Color(0xFF059669);
      sign = '+';
      label = 'Revenu';
    } else if (type == 'depense') {
      badgeBg = const Color(0xFFFFE4E6); // bg-rose-100
      badgeText = const Color(0xFFB91C1C); // text-rose-700
      amountColor = AppColors.backgroundDark;
      sign = '-';
      label = 'Dépense';
    } else if (type == 'dette') {
      badgeBg = const Color(0xFFFEF3C7); // bg-amber-100
      badgeText = const Color(0xFFB45309); // text-amber-700
      amountColor = const Color(0xFFD97706);
      sign = '⚠ ';
      label = 'Dette';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85), // class="glass-item"
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(label.toUpperCase(), style: TextStyle(color: badgeText, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 6),
                    Text(description, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.backgroundDark, fontSize: 14, height: 1.2)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("$sign${_formatCurrency(amount)}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: amountColor)),
                  const Text("FCFA", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black26)),
                ],
              )
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
          Divider(color: Colors.blueGrey.withOpacity(0.1), height: 1),
          const Padding(padding: EdgeInsets.symmetric(vertical: 2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Affichage propre de la date récupérée
              Text(
                rawDate.length >= 10 ? "${rawDate.substring(8, 10)}/${rawDate.substring(5, 7)}/${rawDate.substring(0, 4)}" : rawDate,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              if (category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
                )
              else
                const Text("Autre", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black26)),
            ],
          )
        ],
      ),
    );
  }

  // ==========================================
  // COMPOSANT: EMPTY STATE "C'EST UN PEU CALME ICI"
  // ==========================================
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Icon(Icons.info_outline_rounded, color: Colors.black38, size: 28),
          ),
          const SizedBox(height: 16),
          const Text("C'est un peu calme ici", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
          const SizedBox(height: 4),
          const Text("Vous n'avez pas encore enregistré de transaction.", style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/app/add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: const Text("Ajouter le premier flux", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          )
        ],
      ),
    );
  }

  // ==========================================
  // MAILLAGE DES ORBES LUMINEUX (BACKGROUND)
  // ==========================================
  Widget _buildAnimatedMesh() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Orb 1
          Positioned(
            top: -100, left: -50,
            child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF6B9D).withOpacity(0.08))),
          ),
          // Orb 2
          Positioned(
            top: 200, right: -100,
            child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFD32A).withOpacity(0.05))),
          ),
          // Orb 3
          Positioned(
            bottom: -50, right: -50,
            child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00D2FF).withOpacity(0.06))),
          ),
          // Filtre de flou pour mixer le design
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 90.0, sigmaY: 90.0), child: Container(color: Colors.transparent)),
        ],
      ),
    );
  }
}