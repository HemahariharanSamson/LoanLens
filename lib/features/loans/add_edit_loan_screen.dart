import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/loan_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/loan_calculator.dart';
import '../../core/services/notification_service.dart';
import '../dashboard/dashboard_screen.dart';

/// Screen for adding or editing a loan
class AddEditLoanScreen extends ConsumerStatefulWidget {
  final LoanModel? loan;

  const AddEditLoanScreen({super.key, this.loan});

  @override
  ConsumerState<AddEditLoanScreen> createState() =>
      _AddEditLoanScreenState();
}

class _AddEditLoanScreenState extends ConsumerState<AddEditLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _loanNameController;
  late TextEditingController _lenderNameController;
  late TextEditingController _principalController;
  late TextEditingController _interestRateController;
  late TextEditingController _emiController;
  late TextEditingController _tenureController;
  late TextEditingController _monthsPaidController;
  late TextEditingController _amountPaidController;

  String _interestType = AppConstants.interestTypeSimple;
  String _tenureUnit = AppConstants.tenureUnitMonths;
  DateTime _startDate = DateTime.now();
  bool _notificationsEnabled = true;
  int _reminderDaysBefore = 1;
  bool _autoCalculateEMI = true;
  bool _alreadyRepaying = false;
  DateTime? _firstEmiDate;

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    _loanNameController = TextEditingController(text: loan?.loanName ?? '');
    _lenderNameController = TextEditingController(text: loan?.lenderName ?? '');
    _principalController = TextEditingController(
        text: loan?.principalAmount.toString() ?? '');
    _interestRateController =
        TextEditingController(text: loan?.interestRate.toString() ?? '');
    _emiController = TextEditingController(text: loan?.emiAmount.toString() ?? '');
    _tenureController = TextEditingController(text: loan?.tenure.toString() ?? '');
    _monthsPaidController = TextEditingController(
        text: loan?.monthsPaidSoFar.toString() ?? '0');
    _amountPaidController = TextEditingController(
        text: loan?.amountPaidSoFar.toString() ?? '0');

    if (loan != null) {
      _interestType = loan.interestType;
      _tenureUnit = loan.tenureUnit;
      _startDate = loan.startDate;
      _notificationsEnabled = loan.notificationsEnabled;
      _reminderDaysBefore = loan.reminderDaysBefore;
      _alreadyRepaying = loan.monthsPaidSoFar > 0 || loan.amountPaidSoFar > 0;
      _firstEmiDate = loan.firstEmiDate;
    }
  }

  @override
  void dispose() {
    _loanNameController.dispose();
    _lenderNameController.dispose();
    _principalController.dispose();
    _interestRateController.dispose();
    _emiController.dispose();
    _tenureController.dispose();
    _monthsPaidController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  void _calculateEMI() {
    if (_principalController.text.isEmpty ||
        _interestRateController.text.isEmpty ||
        _tenureController.text.isEmpty) {
      return;
    }

    final principal = double.tryParse(_principalController.text) ?? 0;
    final interestRate = double.tryParse(_interestRateController.text) ?? 0;
    final tenure = int.tryParse(_tenureController.text) ?? 0;
    final tenureMonths = _tenureUnit == AppConstants.tenureUnitYears
        ? tenure * 12
        : tenure;

    if (principal > 0 && tenureMonths > 0) {
      final emi = LoanCalculator.calculateEMI(
        principal: principal,
        annualInterestRate: interestRate,
        tenureMonths: tenureMonths,
      );
      _emiController.text = emi.toStringAsFixed(2);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectFirstEmiDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstEmiDate ?? _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _firstEmiDate = picked;
      });
    }
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_autoCalculateEMI) {
      _calculateEMI();
    }

    final principal = double.parse(_principalController.text);
    final interestRate = double.parse(_interestRateController.text);
    final emi = double.parse(_emiController.text);
    final tenure = int.parse(_tenureController.text);
    final monthsPaid = _alreadyRepaying
        ? (int.tryParse(_monthsPaidController.text) ?? 0)
        : 0;
    final amountPaid = _alreadyRepaying
        ? (double.tryParse(_amountPaidController.text) ?? 0.0)
        : 0.0;

    final repository = ref.read(loanRepositoryProvider);

    final loan = widget.loan?.copyWith(
          loanName: _loanNameController.text,
          lenderName: _lenderNameController.text,
          principalAmount: principal,
          interestRate: interestRate,
          interestType: _interestType,
          emiAmount: emi,
          startDate: _startDate,
          tenure: tenure,
          tenureUnit: _tenureUnit,
          notificationsEnabled: _notificationsEnabled,
          reminderDaysBefore: _reminderDaysBefore,
          monthsPaidSoFar: monthsPaid,
          amountPaidSoFar: amountPaid,
          firstEmiDate: _firstEmiDate,
        ) ??
        LoanModel(
          loanName: _loanNameController.text,
          lenderName: _lenderNameController.text,
          principalAmount: principal,
          interestRate: interestRate,
          interestType: _interestType,
          emiAmount: emi,
          startDate: _startDate,
          tenure: tenure,
          tenureUnit: _tenureUnit,
          notificationsEnabled: _notificationsEnabled,
          reminderDaysBefore: _reminderDaysBefore,
          monthsPaidSoFar: monthsPaid,
          amountPaidSoFar: amountPaid,
          firstEmiDate: _firstEmiDate,
        );

    await repository.addLoan(loan);
    
    // Reschedule notification for this loan
    await NotificationService.scheduleEMIReminder(loan);
    
    ref.invalidate(loansProvider);
    ref.invalidate(dashboardSummaryProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.loan == null
              ? 'Loan added successfully'
              : 'Loan updated successfully'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loan == null ? 'Add Loan' : 'Edit Loan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _loanNameController,
              decoration: const InputDecoration(
                labelText: 'Loan Name',
                hintText: 'e.g., Home Loan',
                prefixIcon: Icon(Icons.account_balance),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter loan name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lenderNameController,
              decoration: const InputDecoration(
                labelText: 'Lender Name',
                hintText: 'e.g., HDFC Bank',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter lender name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _principalController,
              decoration: const InputDecoration(
                labelText: 'Principal Amount (₹)',
                hintText: '1000000',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter principal amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              onChanged: (_) {
                if (_autoCalculateEMI) {
                  _calculateEMI();
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _interestRateController,
                    decoration: const InputDecoration(
                      labelText: 'Interest Rate (%)',
                      hintText: '8.5',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final rate = double.tryParse(value);
                      if (rate == null || rate < 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_autoCalculateEMI) {
                        _calculateEMI();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _interestType,
                    decoration: const InputDecoration(
                      labelText: 'Interest Type',
                      prefixIcon: Icon(Icons.calculate),
                    ),
                    items: [
                      AppConstants.interestTypeSimple,
                      AppConstants.interestTypeCompound,
                    ].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _interestType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tenureController,
                    decoration: const InputDecoration(
                      labelText: 'Tenure',
                      hintText: '20',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final tenure = int.tryParse(value);
                      if (tenure == null || tenure <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_autoCalculateEMI) {
                        _calculateEMI();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _tenureUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                    ),
                    items: [
                      AppConstants.tenureUnitMonths,
                      AppConstants.tenureUnitYears,
                    ].map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _tenureUnit = value!;
                        if (_autoCalculateEMI) {
                          _calculateEMI();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emiController,
                    decoration: const InputDecoration(
                      labelText: 'EMI Amount (₹)',
                      hintText: '8500',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter EMI amount';
                      }
                      final emi = double.tryParse(value);
                      if (emi == null || emi <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Auto Calculate'),
                    value: _autoCalculateEMI,
                    onChanged: (value) {
                      setState(() {
                        _autoCalculateEMI = value ?? true;
                        if (_autoCalculateEMI) {
                          _calculateEMI();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(DateFormat(AppConstants.dateFormat).format(_startDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),
            // Past Payments Section
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: const Text(
                        'Already repaying this loan?',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'If you\'ve already made some payments',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _alreadyRepaying,
                      onChanged: (value) {
                        setState(() {
                          _alreadyRepaying = value ?? false;
                          if (!_alreadyRepaying) {
                            _monthsPaidController.text = '0';
                            _amountPaidController.text = '0';
                            _firstEmiDate = null;
                          }
                        });
                      },
                    ),
                    if (_alreadyRepaying) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _monthsPaidController,
                        decoration: const InputDecoration(
                          labelText: 'Months Already Paid',
                          hintText: '12',
                          prefixIcon: Icon(Icons.calendar_view_month),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_alreadyRepaying) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter months paid';
                            }
                            final months = int.tryParse(value);
                            if (months == null || months < 0) {
                              return 'Please enter a valid number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountPaidController,
                        decoration: const InputDecoration(
                          labelText: 'Total Amount Paid So Far (₹)',
                          hintText: '102000',
                          prefixIcon: Icon(Icons.payments),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_alreadyRepaying) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter amount paid';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount < 0) {
                              return 'Please enter a valid amount';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.event),
                        title: const Text('First EMI Date (Optional)'),
                        subtitle: Text(_firstEmiDate != null
                            ? DateFormat(AppConstants.dateFormat).format(_firstEmiDate!)
                            : 'Tap to select date'),
                        trailing: _firstEmiDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _firstEmiDate = null;
                                  });
                                },
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _selectFirstEmiDate,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Get reminders before EMI due date'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            if (_notificationsEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Reminder Days Before'),
                subtitle: Slider(
                  value: _reminderDaysBefore.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  label: '$_reminderDaysBefore day${_reminderDaysBefore > 1 ? 's' : ''}',
                  onChanged: (value) {
                    setState(() {
                      _reminderDaysBefore = value.toInt();
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveLoan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Loan'),
            ),
          ],
        ),
      ),
    );
  }
}

