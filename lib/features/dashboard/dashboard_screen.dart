import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/local/sqlite_storage.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/user_profile.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/loan_card.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/pdf_service.dart';
import '../../routes/app_routes.dart';
import '../onboarding/onboarding_dialog.dart';

/// Provider for loan repository
final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepository(SqliteStorage());
});

/// Provider for dashboard summary (with caching)
final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final repository = ref.read(loanRepositoryProvider);
  // Keep alive for 30 seconds to avoid unnecessary recalculations
  ref.keepAlive();
  return await repository.getDashboardSummary();
});

/// Provider for loans list (with caching)
final loansProvider = FutureProvider.autoDispose<List<LoanModel>>((ref) async {
  final repository = ref.read(loanRepositoryProvider);
  // Keep alive for 30 seconds to avoid unnecessary reloads
  ref.keepAlive();
  return await repository.getAllLoans();
});

/// Provider for user profile (with caching)
final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final storage = SqliteStorage();
  // Keep alive for 30 seconds to avoid unnecessary reloads
  ref.keepAlive();
  return await storage.getUserProfile();
});

/// Dashboard screen showing loan overview
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasCheckedProfile = false;

  @override
  void initState() {
    super.initState();
    // Check profile after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptForName();
    });
  }

  Future<void> _checkAndPromptForName() async {
    if (_hasCheckedProfile || !mounted) return;
    
    // Wait a bit for the profile to load
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;
    _hasCheckedProfile = true;
    
    try {
      final storage = SqliteStorage();
      final profile = await storage.getUserProfile();
      
      // If no name is set, show the dialog
      if ((profile == null || !profile.hasName) && mounted) {
        _showNameDialog();
      }
    } catch (e) {
      debugPrint('Error checking profile: $e');
    }
  }

  Future<void> _showNameDialog() async {
    // Get current profile to pre-fill name if available
    String? currentName;
    try {
      final storage = SqliteStorage();
      final profile = await storage.getUserProfile();
      currentName = profile?.name;
    } catch (e) {
      debugPrint('Error getting profile: $e');
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => OnboardingDialog(
        initialName: currentName,
        isUpdate: currentName != null && currentName.isNotEmpty,
      ),
    );

    // Refresh profile after dialog closes
    if (mounted) {
      ref.invalidate(userProfileProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final loansAsync = ref.watch(loansProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LoanLens'),
        actions: [
          // Share PDF button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareAllLoansAsPdf(context, ref),
            tooltip: 'Share All Loans as PDF',
          ),
          // Profile icon to update name
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              _showNameDialog();
            },
            tooltip: 'Update Profile',
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.analytics);
            },
            tooltip: 'Analytics',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(loansProvider);
          ref.invalidate(userProfileProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Personalized Greeting
            SliverToBoxAdapter(
              child: userProfileAsync.when(
                data: (profile) {
                  final greeting = profile?.hasName == true && profile != null
                      ? 'Hello, ${profile.displayName}'
                      : 'Hello there';
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: InkWell(
                      onTap: () => _showNameDialog(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                greeting,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                            ),
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            
            // Summary Cards
            SliverToBoxAdapter(
              child: summaryAsync.when(
                data: (summary) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Outstanding',
                              amount: summary.totalOutstanding,
                              icon: Icons.account_balance_wallet,
                              color: const Color(0xFFE57373), // Soft red
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Monthly EMI',
                              amount: summary.totalMonthlyEMI,
                              icon: Icons.payment,
                              color: const Color(0xFF64B5F6), // Soft blue
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StatCard(
                        title: 'Total Interest Payable',
                        amount: summary.totalInterestPayable,
                        icon: Icons.trending_up,
                        color: const Color(0xFFFFB74D), // Soft orange
                      ),
                      const SizedBox(height: 12),
                      StatCard(
                        title: 'Total Paid',
                        amount: summary.totalPaid,
                        icon: Icons.check_circle,
                        color: const Color(0xFF81C784), // Soft green
                      ),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),
            ),

            // Loans List (only ongoing loans)
            loansAsync.when(
              data: (loans) {
                // Filter out closed loans from main list
                final ongoingLoans = loans.where((loan) => !loan.isClosed).toList();
                final closedLoans = loans.where((loan) => loan.isClosed).toList();
                
                if (ongoingLoans.isEmpty && closedLoans.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No loans yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap + to add your first loan',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < ongoingLoans.length) {
                        final loan = ongoingLoans[index];
                        return LoanCard(
                          loan: loan,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.loanDetails,
                              arguments: loan.id,
                            );
                          },
                          onDelete: () => _showDeleteDialog(
                            context,
                            ref,
                            loan,
                          ),
                        );
                      } else {
                        // Show closed loans section
                        final closedIndex = index - ongoingLoans.length;
                        if (closedIndex == 0) {
                          // Header for closed loans
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: Text(
                              'Closed Loans (${closedLoans.length})',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                            ),
                          );
                        }
                        final loan = closedLoans[closedIndex - 1];
                        return LoanCard(
                          loan: loan,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.loanDetails,
                              arguments: loan.id,
                            );
                          },
                          onDelete: () => _showDeleteDialog(
                            context,
                            ref,
                            loan,
                          ),
                        );
                      }
                    },
                    childCount: ongoingLoans.length + (closedLoans.isNotEmpty ? closedLoans.length + 1 : 0),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addLoan);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Loan'),
      ),
    );
  }

  /// Share all loans as PDF
  Future<void> _shareAllLoansAsPdf(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Get all loans
      final repository = ref.read(loanRepositoryProvider);
      final loans = await repository.getAllLoans();

      if (loans.isEmpty) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No loans to share')),
          );
        }
        return;
      }

      // Get user profile
      final storage = SqliteStorage();
      final userProfile = await storage.getUserProfile();

      // Generate PDF
      final pdf = await PdfService.generateAllLoansPdf(
        loans: loans,
        repository: repository,
        userProfile: userProfile,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Share PDF
      if (context.mounted) {
        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          name: 'AllLoans_Report.pdf',
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    LoanModel loan,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan'),
        content: Text('Are you sure you want to delete "${loan.loanName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final repository = ref.read(loanRepositoryProvider);
              await repository.deleteLoan(loan.id);
              
              // Cancel notification for deleted loan
              await NotificationService.cancelEMIReminder(loan.id);
              
              ref.invalidate(loansProvider);
              ref.invalidate(dashboardSummaryProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loan deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

