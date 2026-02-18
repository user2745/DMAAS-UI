import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/purchase_cubit.dart';
import '../cubit/purchase_state.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PaywallPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PurchaseCubit, PurchaseState>(
      listener: (context, state) {
        if (state.isPurchased) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Welcome aboard. You\'re all set.'),
              backgroundColor: const Color(0xFF3FB950),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: const Color(0xFFF85149),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF8B949E)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
            child: BlocBuilder<PurchaseCubit, PurchaseState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon / emblem
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF58A6FF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF58A6FF).withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFF58A6FF),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Headline
                    const Text(
                      'You\'ve built real\nmomentum.',
                      style: TextStyle(
                        color: Color(0xFFC9D1D9),
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sub-headline
                    const Text(
                      'Keep everything you\'ve built — and everything coming next.',
                      style: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Feature list
                    _featureRow(
                      Icons.all_inclusive_rounded,
                      'Unlimited tasks & custom fields',
                      'No caps, no slowdowns.',
                    ),
                    const SizedBox(height: 20),
                    _featureRow(
                      Icons.auto_awesome_rounded,
                      'AI task automation — coming soon',
                      'Let the app execute tasks for you, using credits you control.',
                    ),
                    const SizedBox(height: 20),
                    _featureRow(
                      Icons.workspace_premium_rounded,
                      'Every future feature, included',
                      'Roadmap, board improvements, reporting — all yours.',
                    ),
                    const SizedBox(height: 44),

                    // Price block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF30363D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Full Access',
                            style: TextStyle(
                              color: Color(0xFF8B949E),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                '\$199',
                                style: TextStyle(
                                  color: Color(0xFFC9D1D9),
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              SizedBox(width: 10),
                              Padding(
                                padding: EdgeInsets.only(bottom: 6),
                                child: Text(
                                  'one-time',
                                  style: TextStyle(
                                    color: Color(0xFF8B949E),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Buy it once, own it forever.',
                            style: TextStyle(
                              color: Color(0xFF58A6FF),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CTA button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.isPurchasing
                            ? null
                            : () => context.read<PurchaseCubit>().purchase(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF58A6FF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF58A6FF).withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: state.isPurchasing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Get Full Access  ·  \$199',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Restore purchase
                    Center(
                      child: TextButton(
                        onPressed: state.isPurchasing
                            ? null
                            : () => context.read<PurchaseCubit>().restorePurchases(),
                        child: const Text(
                          'Restore Purchase',
                          style: TextStyle(
                            color: Color(0xFF8B949E),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Legal fine print
                    const Center(
                      child: Text(
                        'One-time purchase. No subscription. No renewal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF484F58),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // AI credits teaser — coming soon
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF30363D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFFBB86FC),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'AI Task Automation',
                                style: TextStyle(
                                  color: Color(0xFFC9D1D9),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBB86FC).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFBB86FC).withOpacity(0.3),
                                  ),
                                ),
                                child: const Text(
                                  'Coming Soon',
                                  style: TextStyle(
                                    color: Color(0xFFBB86FC),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Describe a task. The AI handles it. You review the result. Credits let you control how much you delegate — buy more when you need them.',
                            style: TextStyle(
                              color: Color(0xFF8B949E),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Icon(icon, color: const Color(0xFF58A6FF), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFC9D1D9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
