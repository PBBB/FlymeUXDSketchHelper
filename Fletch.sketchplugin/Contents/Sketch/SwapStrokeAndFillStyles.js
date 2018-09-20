@import 'Libraries/ga.js'

function swapStrokeAndFillStyles (context) {

	var sketch = require('sketch/dom');
	var UI = require('sketch/ui');
    var ga = new Analytics(context);

    var selection = sketch.getSelectedDocument().selectedLayers;

    if (selection.length <= 0) {
    	UI.alert('请先选择图层','');
    	return;
    }

    var hasShapeLayer = false;
    var shapeLayerCount = 0;
    selection.forEach ( layer => {
    	if (layer.type == "Shape") {
    		hasShapeLayer = true;
    		shapeLayerCount++;

    		var fills = layer.style.fills;
    		layer.style.fills = layer.style.borders;
    		layer.style.borders = fills;
    	} else {
    		hasOtherLayer = true;
    	}
    });

    if (!hasShapeLayer) {
    	UI.alert('请选择形状图层','');
        ga.sendEvent('SwapStrokeAndFillStyles', 'Fail', 'NoShapeLayerSelected');
    } else {
        ga.sendEvent('SwapStrokeAndFillStyles', 'Success', 'Success', shapeLayerCount);
    }
}