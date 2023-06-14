var geometry = 
    ee.Geometry.Polygon(
        [[[-61.118412106319006, -1.41719583588691],
          [-61.118412106319006, -25.09564275680497],
          [-40.244388668819006, -25.09564275680497],
          [-40.244388668819006, -1.41719583588691]]], null, false);

// load meso-regions
var meso = ee.FeatureCollection('users/dh-conciani/help/tonomapa/meso_Cerrado')
  // convert id to numbers 
  .map(function(feature) {
    return feature.set('CD_MESO2', ee.Number.parse(feature.get('CD_MESO')));
  });

// Make an image 
var meso2 = meso.reduceToImage({
    properties: ['CD_MESO2'],
    reducer: ee.Reducer.first()
});

Map.addLayer(meso2.randomVisualizer());


// read protected areas and communities and convert to image
var protected_area = ee.Image(1).clip(
  ee.FeatureCollection('users/dh-conciani/help/tonomapa/protected_areas_with_date')).unmask(0);

// read communities
var communities = ee.Image(1).clip(
  ee.FeatureCollection('users/dh-conciani/help/tonomapa/tnm_abr23_final')).unmask(0);

// remove aps and communities from meso-regions
var territories = meso2.updateMask(protected_area.neq(1))
           .updateMask(communities.neq(1));


var territory = territories.rename('territory');
Map.addLayer(territory.randomVisualizer());

Export.image.toAsset({
		image: territory,
    description: 'cerrado_meso_img_without_pas',
    assetId: 'users/dh-conciani/help/tonomapa/cerrado_meso_img_without_pas',
//	pyramidingPolicy:,
//	dimensions:,
    region: geometry,
    scale: 30,
//	crs:,
//	crsTransform:,
    maxPixels: 1e13,
//	shardSize:,
});
