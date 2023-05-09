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
var data = ee.FeatureCollection('users/dh-conciani/help/tonomapa/tnm_abr23_final')
  // insert 'inner' string as metadata
  .map(function(feature) {
    return (feature.set('geometry_posit', 'inner'));
  });

// compute buffer zones
var buffer = data.map(function(feature){
  return (feature.buffer(10000)
  // and retain only difference (outter feature)
  .difference(feature))
  // insert 'buffer' string as metadata
  .set('geometry_posit', 'buffer_zone');
});

// Create a function to perform the erase operation over buffers and communities/territories
var eraseOverlap = function(feature) {
  var diff = feature.geometry().difference(data.geometry(), ee.ErrorMargin(1));
  return ee.Feature(diff, feature.toDictionary());
};

// apply the function
var buffer = ee.FeatureCollection(buffer.map(eraseOverlap));

// merge territories and buffer zones
var merged = data.merge(buffer);
// * --

// -- *
// get territory names
var communityNames = data.aggregate_array('Comunidade').getInfo();
//var communityNames = communityNames.slice(0,1);    // get a subset of the three first entries to test

// plot data
Map.addLayer(data, {}, 'comunities', false);
Map.addLayer(buffer, {}, 'buffer', false);
Map.addLayer(merged, {}, 'merged', false);
// * --

// -- * // Define a function to convert the string column to a number
function stringToNumber(feature) {
  // Get the string value of the column
  var stringValue = feature.get("id");
  // Convert the string to a number using ee.Number.parse()
  var numberValue = ee.Number.parse(stringValue);
  // Return the feature with the number value set
  return feature.set("ID", numberValue);
}

// create empty recipe
var recipe = ee.FeatureCollection([]);

// for each community/territory
communityNames.forEach(function(index) {
  
  // read community [i]
  var community_i = merged.filterMetadata('Comunidade', 'equals', index);
  
  // convert it into an image (1= inner, 2= buffer zone)
  var territory = ee.Image(1).clip(community_i.filterMetadata('geometry_posit', 'equals', 'inner'))
    .blend(ee.Image(2).clip(community_i.filterMetadata('geometry_posit', 'equals', 'buffer_zone')))
    .rename('territory');
    
  //Map.addLayer(territory.randomVisualizer());
  
  // get geometry bounds
  var geometry = community_i.geometry();
  
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
                  .set('territory', territory)
                  .set('class_id', classId)
                  .set('area', area)
                  .set('community', index);
                  
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
  recipe = recipe.merge(areas);
});

// flatten data
// export data
Export.table.toDrive({
    collection: recipe,
    description: 'to-no-mapa-lulc',
    folder: driverFolder,
    fileFormat: 'CSV'
});
