import 'package:flutter/material.dart';

import '../theme/field_guide_theme.dart';

Future<void> showGuestAccessSheet(
    BuildContext context, {
      String title = 'Unlock the full experience',
      String message =
      'Login or create a free account to view full profiles, contact guides and tour operators, save tours and make bookings.',
    }) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(.52),

    builder: (sheetContext) {
      return _GuestAccessSheet(
        title: title,
        message: message,
      );
    },
  );
}

class _GuestAccessSheet extends StatelessWidget {
  const _GuestAccessSheet({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  static const Color _primary =
      FieldGuidePalette.primary;

  static const Color _secondary =
      FieldGuidePalette.secondary;

  static const Color _background =
      FieldGuidePalette.background;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(
          top: 80,
        ),

        padding: const EdgeInsets.fromLTRB(
          24,
          12,
          24,
          26,
        ),

        decoration: const BoxDecoration(
          color: _background,

          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(34),
            topRight: Radius.circular(34),
          ),
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,

              decoration: BoxDecoration(
                color: const Color(
                  0xFFD1CBC2,
                ),

                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: 58,
              height: 58,

              decoration: BoxDecoration(
                color: _primary.withOpacity(
                  .08,
                ),

                shape: BoxShape.circle,

                border: Border.all(
                  color:
                  _secondary.withOpacity(
                    .45,
                  ),
                ),
              ),

              child: const Icon(
                Icons.lock_open_rounded,
                color: _secondary,
                size: 27,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              textAlign: TextAlign.center,

              style: const TextStyle(
                color:
                FieldGuidePalette.ink,

                fontSize: 22,

                fontWeight:
                FontWeight.w800,

                letterSpacing: -.5,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              message,
              textAlign: TextAlign.center,

              style: const TextStyle(
                color:
                FieldGuidePalette
                    .mutedText,

                fontSize: 13,

                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            _PremiumActionButton(
              label: 'Login',

              onPressed: () {
                Navigator.pop(context);

                Navigator.pushNamed(
                  context,
                  '/login',
                );
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: OutlinedButton(
                style:
                OutlinedButton.styleFrom(
                  foregroundColor:
                  _primary,

                  side: const BorderSide(
                    color: _primary,
                    width: 1.2,
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      100,
                    ),
                  ),
                ),

                onPressed: () {
                  Navigator.pop(context);

                  Navigator.pushNamed(
                    context,
                    '/register',
                  );
                },

                child: const Text(
                  'Create Account',

                  style: TextStyle(
                    fontSize: 14,

                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Continue browsing',

                style: TextStyle(
                  color:
                  FieldGuidePalette
                      .mutedText,

                  fontSize: 13,

                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumActionButton
    extends StatelessWidget {
  const _PremiumActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,

      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient:
          const LinearGradient(
            begin:
            Alignment.topCenter,

            end:
            Alignment.bottomCenter,

            colors: [
              Color(0xFF165B5D),
              Color(0xFF0A3D3F),
            ],
          ),

          borderRadius:
          BorderRadius.circular(
            100,
          ),

          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(
                .12,
              ),

              blurRadius: 10,

              offset:
              const Offset(
                0,
                4,
              ),
            ),
          ],
        ),

        child: Material(
          color: Colors.transparent,

          borderRadius:
          BorderRadius.circular(
            100,
          ),

          child: InkWell(
            onTap: onPressed,

            borderRadius:
            BorderRadius.circular(
              100,
            ),

            child: Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                5,
                6,
                5,
              ),

              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        label,

                        style:
                        const TextStyle(
                          color:
                          Colors.white,

                          fontSize: 14,

                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  Container(
                    width: 38,
                    height: 38,

                    decoration:
                    const BoxDecoration(
                      color:
                      Colors.white,

                      shape:
                      BoxShape.circle,
                    ),

                    child:
                    const Icon(
                      Icons
                          .arrow_forward_rounded,

                      color:
                      Colors.black,

                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}