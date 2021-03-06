part of bluebear;

/**
 * This is the main class of the game, it handles the creation
 * of the stage and the creation of the cells.
 */
class Editor extends Base {
  String layerSelectorName;
  String pencilSelectorName;
  Jikpoze.Cell debugPointer;
  Point lastCursorPosition;

  Editor(canvas, Map options) : super(canvas, options) {
    showGrid = true;
    Jikpoze.GridPencil.showCoordinates = true;
  }

  void parseOptions(Map options) {
    super.parseOptions(options);

    if (options.containsKey('layerSelectorName')) {
      layerSelectorName = options['layerSelectorName'];
    }
    if (options.containsKey('pencilSelectorName')) {
      pencilSelectorName = options['pencilSelectorName'];
    }
  }

  void attachStageEvents() {
    super.attachStageEvents();

    // Disabled for the moment: was causing issue with edition
//        stage.onMouseWheel.listen((MouseEvent e) {
//            if (e.deltaY.isNegative) {
//                scaleX *= 1.1;
//                scaleY *= 1.1;
//            } else {
//                scaleX *= 0.9;
//                scaleY *= 0.9;
//            }
//        });

    createDebugPointer(Point position) {
      debugPointer = map.createCell(selectedLayer, position, selectedPencil);
      if (null == debugPointer) {
        return;
      }
      debugPointer.alpha = 0.6;
      debugPointer.zIndex = 1000;
//      map.sortChildren(map.sortCells);
    }

    stage.onMouseMove.listen((MouseEvent e) {
      // Display transparent cell under the mouse cursor to show where the "pencil" is
      Point cellPosition = viewPointToGamePoint(new Point(e.stageX, e.stageY));
      if (lastCursorPosition == cellPosition) {
        return; // Don't do anything if the cursor is over the same cell than before
      }
      lastCursorPosition = cellPosition;
      Point position = gamePointToViewPoint(cellPosition);
      if (null == debugPointer) {
        createDebugPointer(cellPosition);
      }
      if (debugPointer.pencil != selectedPencil) {
        debugPointer.layer.cells.remove(debugPointer.position);
        map.removeChild(debugPointer);
        createDebugPointer(cellPosition);
      }
      debugPointer.x = position.x;
      debugPointer.y = position.y;
    });

    map.onMouseClick.listen((MouseEvent e) {
      if (dragging != null) {
        return;
      }
      // remove large mouse offset
      if (e.stageX - 2 > dragEvent.stageX || dragEvent.stageX > e.stageX + 2) {
        return;
      }
      if (e.stageY - 2 > dragEvent.stageY || dragEvent.stageY > e.stageY + 2) {
        return;
      }

      Point position = viewPointToGamePoint(new Point(e.stageX, e.stageY));

      try {
        Jikpoze.Layer targetLayer = selectedLayer;
        if (targetLayer.cells.containsKey(position)) {
          Jikpoze.Cell cellToRemove = removeCell(targetLayer, position);
          if (cellToRemove.pencil == selectedPencil) {
            return;
          }
        }
        createCell(targetLayer, position, selectedPencil);
      } catch (exception) {
        print(exception);
      }
    });
    addButton();
  }

  void attachMapItemEvents(MapItem mapItem) {
    if (null == mapItem.cell) {
      // This means the object has no representation on the board for some reason (check logs)
      return;
    }
    mapItem.cell.onMouseClick.listen((MouseEvent e) {
      // do stuff when cell is clicked
    });
  }

  Jikpoze.Layer get selectedLayer {
    Html.ElementList els = Html.querySelectorAll('[name="$layerSelectorName"]');
    for (Html.Element el in els) {
      if ('SELECT' == el.tagName) {
        return map.layers[(el as Html.SelectElement).value];
      }
    }
    throw "No layer selected or missing layer";
  }

  Jikpoze.Pencil get selectedPencil {
    Html.ElementList els =
        Html.querySelectorAll('[name="$pencilSelectorName"]');
    for (Html.Element el in els) {
      if ('SELECT' == el.tagName) {
        return pencils[(el as Html.SelectElement).value];
      }
      if ('INPUT' == el.tagName) {
        Html.InputElement input = (el as Html.InputElement);
        if ('radio' == input.type && input.checked) {
          return pencils[input.value];
        }
      }
    }
    throw "No pencil selected or missing pencil";
  }

  SimpleButton addButton() {
    var shape = new Shape();
    shape.graphics.rectRound(2, 2, 100, 25, 5, 5);
    shape.graphics.strokeColor(Color.LightGray, 2);
    GraphicsGradient grad = new GraphicsGradient.linear(0, 0, 0, 40);
    grad.addColorStop(0, Color.WhiteSmoke);
    grad.addColorStop(0.2, Color.White);
    grad.addColorStop(1, Color.GhostWhite);
    shape.graphics.fillGradient(grad);
    SimpleButton button = new SimpleButton(shape, shape, shape);
    button.hitTestState = shape;
    button.onMouseClick.listen((MouseEvent e) {
      showGrid = !showGrid;
      for (Jikpoze.Layer layer in map.layers.values) {
        if (layer.type != 'grid') {
          continue;
        }
        for (Jikpoze.Cell cell in layer.cells.values) {
          cell.visible = showGrid;
        }
      }
    });
    stage.addChild(button);
    return button;
  }
}
