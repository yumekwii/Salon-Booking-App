import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Mobile-first presentation shell.
///
/// Real Android/iOS devices use the full available width. On Flutter Web,
/// desktop browsers show the app inside a phone mockup frame so the deployed
/// experience remains intentionally mobile-sized.
class MobileAppShell extends StatelessWidget {
  final Widget child;

  const MobileAppShell({super.key, required this.child});

  static const double maxMobileWidth = 430;
  static const double frameRadius = 42;
  static const double framePadding = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usePhoneFrame = kIsWeb && constraints.maxWidth > 700;
        final contentWidth = usePhoneFrame
            ? maxMobileWidth
            : constraints.maxWidth;

        final mediaQuery = MediaQuery.of(context);
        final adaptedMediaQuery = mediaQuery.copyWith(
          size: Size(contentWidth, constraints.maxHeight),
        );

        final app = MediaQuery(
          data: adaptedMediaQuery,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(usePhoneFrame ? 34 : 0),
            child: ColoredBox(
              color: Colors.white,
              child: child,
            ),
          ),
        );

        if (!usePhoneFrame) {
          return ColoredBox(
            color: Colors.white,
            child: app,
          );
        }

        return ColoredBox(
          color: const Color(0xFFE9E3DE),
          child: Center(
            child: Container(
              width: maxMobileWidth + (framePadding * 2),
              height: constraints.maxHeight - 28,
              padding: const EdgeInsets.all(framePadding),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(frameRadius),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 36,
                    spreadRadius: 2,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: app),
                  // Dynamic-island style camera/sensor cutout.
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 118,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(right: 11),
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF242424),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Subtle bottom home indicator.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 7,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 118,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
