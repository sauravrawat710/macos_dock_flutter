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
            builder: (icon, scale, translateX) {
              return Transform.translate(
                offset: Offset(translateX * .2, 0),
                child: Container(
                  height: 64 * scale,
                  width: 64 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(icon),
                  ),
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
  final Widget Function(T item, double scale, double translateX) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T extends Object> extends State<Dock<T>> {
  late final List<T> _items = widget.items.toList();
  int? _hoveredIndex;
  int? _draggedIndex;

  double _calculateScale(int hoveredIndex, int currentIndex) {
    final distance = (hoveredIndex - currentIndex).abs();
    return 1.8 - (distance * 0.3).clamp(0.0, 0.8); // More prominent scaling.
  }

  double _calculateTranslateX(int hoveredIndex, int currentIndex) {
    if (_hoveredIndex == null) return 0;
    final distance = currentIndex - hoveredIndex;
    return (distance * 20.0) * (1.0 - (distance.abs() * 0.2).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black26,
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.1)
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
                  child: widget.builder(item, 1.5, 0), // Larger feedback icon.
                ),
                childWhenDragging: const SizedBox.shrink(),
                child: MouseRegion(
                  onEnter: (_) => setState(() {
                    _hoveredIndex = index;
                  }),
                  onExit: (_) => setState(() {
                    _hoveredIndex = null;
                  }),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(
                      begin: 1.0,
                      end: _hoveredIndex != null
                          ? _calculateScale(_hoveredIndex!, index)
                          : 1.0,
                    ),
                    builder: (context, scale, child) {
                      final translateX = _hoveredIndex != null
                          ? _calculateTranslateX(_hoveredIndex!, index)
                          : 0.0;
                      return widget.builder(item, scale, translateX);
                    },
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
