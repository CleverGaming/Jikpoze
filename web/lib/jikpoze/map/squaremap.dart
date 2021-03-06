part of jikpoze;

/**
 * This is the main class of the game, it handles the creation
 * of the stage and the creation of the cells.
 */
class SquareMap extends DisplayObjectContainer {
  Board board;
  Pencil _gridPencil;
  Map<String, Layer> layers = new Map<String, Layer>();
  num skewFactor = 1;
  int renderOffset = 1;

  SquareMap(Board board) {
    if (null == board) {
      throw 'board cannot be null';
    }
    board.addChild(this);
    this.board = board;
  }

  Pencil get gridPencil {
    if (null == _gridPencil) {
      _gridPencil = new GridPencil(board);
    }
    return _gridPencil;
  }

  Cell createCell(Layer layer, Point point, Pencil pencil) {
    if (layer.type != pencil.type) {
      print("Warning ! Layer and pencil types does not match: ${layer
          .type} != ${pencil.type} for layer '${layer
          .name}' and pencil '${pencil.name}' at position ${point.x}, ${point
          .y}");
      return null;
    }
    Cell cell = new Cell(layer, point, pencil);
    if (layer.type == 'grid' && !board.showGrid) {
      cell.visible = false;
    }
    return cell;
  }

  Cell removeCell(Layer layer, Point point) {
    if (!layer.cells.containsKey(point)) {
      return null;
    }
    Cell cell = layer.cells[point];
    layer.cells.remove(point);
    removeChild(cell);
    return cell;
  }

  void updateGrid() {
    for (Layer layer in layers.values) {
      if (layer.type == 'grid') {
        Point topLeft = viewPointToGamePoint(cacheViewPort.topLeft);
        Point bottomRight = viewPointToGamePoint(cacheViewPort.bottomRight);
        int dist = (bottomRight.x - topLeft.x).floor();
        int x = topLeft.x.floor();
        int y = topLeft.y.floor();
        for (int line = 0; line < (bottomRight.y - topLeft.y).floor(); line++) {
          renderLayerLine(layer, x, y, x + dist, y);
          y++;
        }
      }
    }
  }

  void renderCell(Layer layer, Point point) {
    if (layer.cells.containsKey(point)) {
    } else if (layer.type == 'grid') {
      createCell(layer, point, gridPencil);
    }
  }

  Rectangle get cacheViewPort {
    return new Rectangle(
        -board.x - stage.stageWidth / 3,
        -board.y - stage.stageHeight / 3,
        stage.stageWidth * (1 + 2 / 3),
        stage.stageHeight * (1 + 2 / 3));
  }

  Point gamePointToViewPoint(Point gamePoint) {
    return new Point(
        gamePoint.x * board.cellSize, gamePoint.y * board.cellSize);
  }

  Point viewPointToGamePoint(Point viewPoint) {
    return new Point((viewPoint.x / board.cellSize).floor(),
        (viewPoint.y / board.cellSize).floor());
  }

  void addChild(DisplayObject child) {
    super.addChild(child);
    if (child is Cell) {
      sortChildren(sortCells); // @todo optimize this?
    }
  }

  int sortCells(DisplayObject a, DisplayObject b) {
    if (a is! Cell || b is! Cell) {
      return 0;
    }
    Cell ac = a as Cell;
    Cell bc = b as Cell;
    List specificLayerTypes = ['background', 'land', 'grid', 'events'];
    if (ac.layer.index != bc.layer.index) {
      // For certain layer types, there is no need to check the position, they are always above or below others
      if (specificLayerTypes.contains(ac.layer.type) ||
          specificLayerTypes.contains(bc.layer.type)) {
        return ac.layer.index - bc.layer.index;
      }
    }
    // In some cases, (hovering with pencil in edition mode) the z-index of the item will always prevail
    // just like if it was on a "virtual" layer just above the actual layer.
    if (ac.layer.index == bc.layer.index && ac.zIndex != bc.zIndex) {
      return ac.zIndex - bc.zIndex;
    }
    // if on same column
    if (ac.position.y == bc.position.y) {
      // if exactly same position
      if (ac.position.x == bc.position.x) {
        // then the layer's index will sort them
        return ac.layer.index - bc.layer.index;
      }
      // left to right order
      return ac.position.x - bc.position.x;
    }
    // back to front order
    return ac.position.y - bc.position.y;
  }

  void renderLayerLine(Layer layer, int x1, int y1, int x2, int y2) {
    int dx = x2 - x1;
    int dy = y2 - y1;
    int y;
    for (int x = x1; x <= x2; x++) {
      y = (y1 + dy * (x - x1) / dx).floor();
      renderCell(layer, new Point(x, y));
    }
  }

  void buildCellGraphics(Graphics g) {
    int size = (board.cellSize / 2).floor();
    g.moveTo(size, size);
    g.lineTo(size, -size);
    g.lineTo(-size, -size);
    g.lineTo(-size, size);
    g.lineTo(size, size);
    g.closePath();
  }
}
