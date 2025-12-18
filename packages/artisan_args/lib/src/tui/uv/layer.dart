import 'dart:math' as math;

import 'buffer.dart' show styledStringBounds;
import 'canvas.dart';
import 'geometry.dart';
import 'screen.dart';
import 'styled_string.dart';
import 'width.dart';

/// Layer represents a visual layer with content and positioning.
///
/// Upstream: `third_party/lipgloss/layer.go` (`Layer`).
final class Layer {
  Layer(this.content, [List<Layer> layers = const []]) : _layers = [...layers] {
    _recomputeSize();
  }

  String id = '';
  String content;
  int x = 0;
  int y = 0;
  int z = 0;

  int width = 0;
  int height = 0;

  final List<Layer> _layers;

  List<Layer> get layers => List.unmodifiable(_layers);

  Layer setId(String value) {
    id = value;
    return this;
  }

  Layer setX(int value) {
    x = value;
    _recomputeSize();
    return this;
  }

  Layer setY(int value) {
    y = value;
    _recomputeSize();
    return this;
  }

  Layer setZ(int value) {
    z = value;
    return this;
  }

  Layer addLayers(List<Layer> layers) {
    _layers.addAll(layers);
    _recomputeSize();
    return this;
  }

  Layer? getLayer(String lookupId) {
    if (lookupId.isEmpty) return null;
    if (id == lookupId) return this;
    for (final child in _layers) {
      final found = child.getLayer(lookupId);
      if (found != null) return found;
    }
    return null;
  }

  int maxZ() {
    var maxZ = z;
    for (final child in _layers) {
      maxZ = math.max(maxZ, child.maxZ());
    }
    return maxZ;
  }

  void _recomputeSize() {
    final area = _boundsWithOffset(0, 0);
    width = area.width;
    height = area.height;
  }

  Rectangle _boundsWithOffset(int parentX, int parentY) {
    final absX = x + parentX;
    final absY = y + parentY;

    final bounds = styledStringBounds(content, WidthMethod.grapheme);
    var area = Rectangle(
      minX: absX,
      minY: absY,
      maxX: absX + bounds.width,
      maxY: absY + bounds.height,
    );

    for (final child in _layers) {
      area = area.union(child._boundsWithOffset(absX, absY));
    }
    return area;
  }
}

final class LayerHit {
  const LayerHit({this.id = '', this.layer, this.bounds});

  final String id;
  final Layer? layer;
  final Rectangle? bounds;

  bool get isEmpty => layer == null;
}

final class _CompositeLayer {
  const _CompositeLayer({
    required this.layer,
    required this.absX,
    required this.absY,
    required this.bounds,
  });

  final Layer layer;
  final int absX;
  final int absY;
  final Rectangle bounds;
}

/// Compositor manages layer composition, drawing and hit testing.
///
/// Upstream: `third_party/lipgloss/layer.go` (`Compositor`).
final class Compositor implements Drawable {
  Compositor([List<Layer> layers = const []])
    : _root = Layer('')..addLayers(layers) {
    // Upstream: `third_party/lipgloss/layer.go` (`NewCompositor`) flattens on
    // construction so `Bounds`, `Hit`, and `GetLayer` work immediately.
    _flatten();
  }

  final Layer _root;

  final List<_CompositeLayer> _layers = [];
  final Map<String, Layer> _index = {};
  Rectangle _bounds = const Rectangle(minX: 0, minY: 0, maxX: 0, maxY: 0);

  void refresh() => _flatten();

  void addLayers(List<Layer> layers) {
    _root.addLayers(layers);
    _flatten();
  }

  Rectangle bounds() => _bounds;

  Layer? getLayer(String id) => _index[id];

  LayerHit hit(int x, int y) {
    final p = Position(x, y);
    for (var i = _layers.length - 1; i >= 0; i--) {
      final cl = _layers[i];
      if (cl.layer.id.isNotEmpty && cl.bounds.contains(p)) {
        return LayerHit(id: cl.layer.id, layer: cl.layer, bounds: cl.bounds);
      }
    }
    return const LayerHit();
  }

  @override
  void draw(Screen scr, Rectangle area) {
    if (_layers.isEmpty) _flatten();
    for (final cl in _layers) {
      if (cl.bounds.overlaps(area)) {
        final content = newStyledString(cl.layer.content);
        content.draw(scr, cl.bounds);
      }
    }
  }

  String render() {
    if (_layers.isEmpty) _flatten();
    final w = _bounds.width;
    final h = _bounds.height;
    final canvas = Canvas(w, h);
    canvas.compose(this);
    return canvas.render();
  }

  void _flatten() {
    _layers.clear();
    _index.clear();
    _bounds = const Rectangle(minX: 0, minY: 0, maxX: 0, maxY: 0);

    void recurse(Layer layer, int parentX, int parentY) {
      final absX = layer.x + parentX;
      final absY = layer.y + parentY;
      final b = styledStringBounds(layer.content, WidthMethod.grapheme);
      final bounds = Rectangle(
        minX: absX,
        minY: absY,
        maxX: absX + b.width,
        maxY: absY + b.height,
      );

      _layers.add(
        _CompositeLayer(layer: layer, absX: absX, absY: absY, bounds: bounds),
      );

      if (layer.id.isNotEmpty) {
        _index[layer.id] = layer;
      }

      for (final child in layer.layers) {
        recurse(child, absX, absY);
      }
    }

    recurse(_root, 0, 0);
    _layers.sort((a, b) => a.layer.z.compareTo(b.layer.z));

    if (_layers.isNotEmpty) {
      var b = _layers.first.bounds;
      for (var i = 1; i < _layers.length; i++) {
        b = b.union(_layers[i].bounds);
      }
      _bounds = b;
    }
  }
}
