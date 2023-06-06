// get area by territory 
// dhemerson.costa@ipam.org.br

// -- * 
// read collection of images in which areas will be computed
var collection = ee.Image('projects/mapbiomas-workspace/public/collection7_1/mapbiomas_collection71_integration_v1');

// define the years to bem computed 
var years = ee.List.sequence({'start': 1985, 'end': 2021, 'step': 1}).getInfo();
// *-- 

// -- *
// compute areas in hectares
var pixelArea = ee.Image.pixelArea().divide(10000);

// change scale if you need (in meters)
var scale = 30;

// * --
// define a Google Drive output folder 
var driverFolder = 'AREA-EXPORT-TNM';
// * -- 

// -- *
// read input data
var input = ee.Image('users/dh-conciani/help/tonomapa/communities-image');


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

// read protected areas and communities and convert to image
var protected_area = ee.Image(1).clip(
  ee.FeatureCollection('users/dh-conciani/help/tonomapa/vecs_aps_meso')).unmask(0);

// read communities
var communities = ee.Image(1).clip(
  ee.FeatureCollection('users/dh-conciani/help/tonomapa/tnm_abr23_final')).unmask(0);

// remove aps and communities from meso-regions
var territories = meso2.updateMask(protected_area.neq(1))
           .updateMask(communities.neq(1));

Map.addLayer(territories.randomVisualizer());

print(territories);



var territory = territories;

// get geometry boundsma
var geometry = meso.geometry();
  
  // convert a complex object to a simple feature collection 
  var convert2table = function (obj) {
    obj = ee.Dictionary(obj);
      var territory = obj.get('territory');
      var classesAndAreas = ee.List(obj.get('groups'));
      
      var tableRows = classesAndAreas.map(
          function (classAndArea) {
              classAndArea = ee.Dictionary(classAndArea);
              var classId = classAndArea.get('class');
              var area = classAndArea.get('sum');
              var tableColumns = ee.Feature(null)
                  .set('CD_MESO', territory)
                  .set('class_id', classId)
                  .set('area', area);
                  
              return tableColumns;
          }
      );
      
      
  
      return ee.FeatureCollection(ee.List(tableRows));
  };
  
  // compute the area
  var calculateArea = function (image, territory, geometry) {
      var territotiesData = pixelArea.addBands(territory).addBands(image)
          .reduceRegion({
              reducer: ee.Reducer.sum().group(1, 'class').group(1, 'territory'),
              geometry: geometry,
              scale: scale,
              maxPixels: 1e12
          });
          
      territotiesData = ee.List(territotiesData.get('groups'));
      var areas = territotiesData.map(convert2table);
      areas = ee.FeatureCollection(areas).flatten();
      return areas;
  };
  
  // perform per year 
  var areas = years.map(
      function (year) {
          var image = collection.select('classification_' + year);
          var areas = calculateArea(image, territory, geometry);
          // set additional properties
          areas = areas.map(
              function (feature) {
                  return feature.set('year', year);
              }
          );
          return areas;
      }
  );
  
  // store
  areas = ee.FeatureCollection(areas).flatten();
  

// export data
Export.table.toDrive({
      collection: areas,
      description: 'areas-to-no-mapa-meso-erased',
      folder: driverFolder,
      fileFormat: 'CSV'
});
