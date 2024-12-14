import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Dock(
            items: [
              'assets/icons/app-store.png',
              'assets/icons/mail.png',
              'assets/icons/music.png',
              'assets/icons/notes.png',
              'assets/icons/vscode.png',
            ],
            builder: (icon, scale, translateX, translateY) {
              return Transform.translate(
                offset: Offset(
                    translateX * .2, translateY), // Add vertical movement
                child: Container(
                  height: 64 * scale,
                  width: 64 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Image.asset(icon)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock widget to mimic macOS Dock behavior.
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// List of items to display.
  final List<T> items;

  /// Builder for constructing each item.
  final Widget Function(
      T item, double scale, double translateX, double translateY) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T extends Object> extends State<Dock<T>> {
  late final List<T> _items = widget.items.toList();
  double? _mouseX; // Tracks the mouse's x-axis position.
  int? _draggedIndex;

  /// Calculates the scale based on the mouse's x-coordinate.
  double _calculateScale(double mouseX, double iconX) {
    final distance = (mouseX - iconX).abs();
    return 1.7 -
        (distance * 0.005).clamp(0.0, 0.8); // Scale based on proximity.
  }

  /// Calculates horizontal translation based on the mouse's x-coordinate.
  double _calculateTranslateX(double mouseX, double iconX) {
    final distance = mouseX - iconX;
    return (distance * 0.1).clamp(-20.0, 20.0); // Horizontal shift effect.
  }

  /// Calculates vertical translation to create an arc effect.
  double _calculateTranslateY(double mouseX, double iconX) {
    final distance = (mouseX - iconX).abs();
    return -17.0 *
        (1.0 - (distance * 0.005).clamp(0.0, 1.0)); // Arc peak at proximity.
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            height: 80,
            width: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black26,
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 70,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: MouseRegion(
            // Update the mouse's x-coordinate dynamically.
            onHover: (event) {
              setState(() {
                _mouseX = event.localPosition.dx; // Capture mouse position.
              });
            },
            onExit: (_) {
              setState(() {
                _mouseX = null; // Reset when mouse exits the dock.
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_items.length, (index) {
                final item = _items[index];

                return DragTarget<T>(
                  onWillAcceptWithDetails: (data) => true,
                  onAcceptWithDetails: (data) {
                    setState(() {
                      final draggedItem = _items.removeAt(_draggedIndex!);
                      _items.insert(index, draggedItem);
                      _draggedIndex = null;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Draggable<T>(
                      data: item,
                      onDragStarted: () {
                        setState(() {
                          _draggedIndex = index;
                        });
                      },
                      onDragEnd: (_) {
                        setState(() {
                          _draggedIndex = null;
                        });
                      },
                      feedback: Material(
                        color: Colors.transparent,
                        child: widget.builder(
                            item, 1.5, 0, 0), // Larger feedback icon.
                      ),
                      childWhenDragging: const SizedBox.shrink(),
                      child: TweenAnimationBuilder<double>(
                        // Reduced animation duration for responsiveness
                        duration: const Duration(milliseconds: 80),
                        curve: Curves.linear,
                        tween: Tween<double>(
                          begin: 1.0,
                          end: _mouseX != null
                              ? _calculateScale(
                                  _mouseX!,
                                  (index + 0.5) * 100, // Icon's x-coordinate.
                                )
                              : 1.0,
                        ),
                        builder: (context, scale, child) {
                          final translateX = _mouseX != null
                              ? _calculateTranslateX(
                                  _mouseX!,
                                  (index + 0.5) * 100,
                                )
                              : 0.0;
                          final translateY = _mouseX != null
                              ? _calculateTranslateY(
                                  _mouseX!,
                                  (index + 0.5) * 100,
                                )
                              : 0.0;
                          return widget.builder(
                              item, scale, translateX, translateY);
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
