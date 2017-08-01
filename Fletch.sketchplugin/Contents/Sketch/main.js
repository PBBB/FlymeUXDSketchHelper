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
	if (artboards.length == 0) {
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
            var pageTitleLayer = null;
            var pageNumberLayer = null;

            for (var j = 0; j < layersInArtboard.length; j++) {

            	// 筛选出功能概述
            	if (layersInArtboard[j].name() == "功能概述") {
            		pageTitleLayer = layersInArtboard[j]
                }

                // 筛选出页码
                if (layersInArtboard[j].name() == "交互图例 / 页码") {
                	pageNumberLayer = layersInArtboard[j]
                    if (layerIDs == null ) {
                        layerIDs = getLayerIDs(pageNumberLayer);
                        if (layerIDs == null) {
                            NSApp.displayDialog("页码图层需为 symbol");
		                    return;
                        }
                    }
                }
            }

            if (pageTitleLayer == null || pageNumberLayer == null) {
                	NSApp.displayDialog("未找到功能概述或页码");
                	return;
                }

            // 设定页码值
            var pageData = {};
            pageData[layerIDs.currentPage_ID.toString()] = (i+1).toString();
            pageData[layerIDs.totalPages_ID.toString()] = artboards.length.toString();
            pageNumberLayer.overrides = pageData;

            //更新标题与页码的间距
            pageTitleLayer.frame().setX(164);
            pageTitleLayer.frame().setY(65);
            pageNumberLayer.frame().setX(pageTitleLayer.frame().x() + pageTitleLayer.frame().width() + 50);
            pageNumberLayer.frame().setY(pageTitleLayer.frame().y() - 2)
		}
	}
	return true;
}

var updatePageNumbers = function (context) {
	var selectedArtboards = prepareSelectedArtboards(context);
	var result = updatePageNumbersOfArtboards(selectedArtboards);
	if (result) { context.document.showMessage("页码更新成功") }
}
