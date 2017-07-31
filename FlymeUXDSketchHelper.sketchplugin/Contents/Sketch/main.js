function prepareSelectedArtboards (context) {
	var selection = context.selection;
	
	// 提取所选画板
	var selectedArtboards = [];
	for (var i = 0; i < selection.length; i++) {
		if (selection[i].isMemberOfClass(MSArtboardGroup)) {
			selectedArtboards.push(selection[i]);
		}
	}

	// 将画板按照画布中的位置排序
	function compareArtboards (firstAB, secondAB) {
		if (firstAB.frame().y() != secondAB.frame().y()) {
			return firstAB.frame().y() - secondAB.frame().y();
		} else {
			return firstAB.frame().x() - secondAB.frame().x();
		}
	}
	selectedArtboards.sort(compareArtboards);
	return selectedArtboards;
}

function updatePageNumbersOfArtboards (artboards) {

	// 未选择图层提示
	if (selectedArtboards.length == 0) {
		NSApp.displayDialog("请选择文档的所有画板（包括封面和概述）");
		return false;
	} 

	// 获取要修改的图层 ID
	var layerIDs = null
    function getLayerIDs(symbolInstance) {
        var symbolMaster = symbolInstance.symbolMaster();
        var children = symbolMaster.children();
        var layerIDs = {};

        for (var i = 0; i < [children count]; i++){
            var layer = children[i];
            if( layer.name() == "3" )   { layerIDs.currentPage_ID   = layer.objectID() }
            if( layer.name() == "10" )    { layerIDs.totalPages_ID    = layer.objectID() }
        }
        return layerIDs;
    }
    
    // 从第三个画板开始，找到页码图层并更新内容
    for (var i = 0; i < artboards.length; i++) {
		if (i > 1) {
            var layersInArtboard = artboards[i].children();
            for (var j = 0; j < layersInArtboard.length; j++) {
                if (layersInArtboard[j].name() == "交互图例 / 页码") {
                    if (layerIDs == null ) {
                        layerIDs = getLayerIDs(layersInArtboard[j]);
                        if (layerIDs == null) {
                            NSApp.displayDialog("请选择文档的所有画板（包括封面和概述）");
		                    return;
                        }
                    }
                    var pageData = {};
                    pageData[layerIDs.currentPage_ID.toString()] = (i+1).toString();
                    pageData[layerIDs.totalPages_ID.toString()] = artboards.length.toString();
                    layersInArtboard[j].overrides = pageData;
                }
            }
		}
	}
	return true;
}

var updatePageNumbers = function (context) {
	var selectedArtboards = prepareSelectedArtboards(context);
	var result = updatePageNumbersOfArtboards(selectedArtboards);
	if (result) { context.document.showMessage("页码更新成功") }
}

function updateCatalog (context) {
	var selectedArtboards = prepareSelectedArtboards(context);
	var result = updatePageNumbersOfArtboards(selectedArtboards);
	if (!result) { return }
		
	// 清理旧目录

	// 生成新目录

	context.document.showMessage("目录更新成功");
}
