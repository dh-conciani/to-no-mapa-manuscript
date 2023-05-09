// get area by territory 
// dhemerson.costa@ipam.org.br

// read collection of images in which areas will be computed
var collection = ee.Image('projects/mapbiomas-workspace/public/collection7_1/mapbiomas_collection71_integration_v1');

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


Map.addLayer(data, {}, 'comunities', false);
Map.addLayer(buffer, {}, 'buffer', false);
Map.addLayer(merged, {}, 'merged', false);



// Define function to compute areas for each polygon/geometry
var x = merged.limit(3).aside(print);

var getArea = function(feature) {
  
}


// get files to bem processed
//var tnm = ee.FeatureCollection('users/dh-conciani/help/tonomapa/tnm_abr23_final');
//var buffer = ee.FeatureCollection('users/dh-conciani/help/tonomapa/erased_buffer_tnp_abr23_final')

/*

var entry = ee.FeatureCollection('users/dh-conciani/help/tonomapa/tnm_abr23_final');
Map.addLayer(entry)

// Define a function to convert the string column to a number
function stringToNumber(feature) {
  // Get the string value of the column
  var stringValue = feature.get("id");
  
  // Convert the string to a number using ee.Number.parse()
  var numberValue = ee.Number.parse(stringValue);
  
  // Return the feature with the number value set
  return feature.set("ID", numberValue);
}

// Map the conversion function over the FeatureCollection
var numericEntry = entry.map(stringToNumber);

print(numericEntry);

// define classification regions 
var territory = numericEntry
  .filter(ee.Filter.notNull(['ID']))
  .reduceToImage({
    properties: ['ID'],
    reducer: ee.Reducer.first(),
}).rename('territory');


// plot regions
Map.addLayer(territory.randomVisualizer());


// change the scale if you need.
var scale = 30;

// define the years to bem computed 
var years = ee.List.sequence({'start': 1985, 'end': 2021, 'step': 1}).getInfo();

// define a Google Drive output folder 
var driverFolder = 'AREA-EXPORT-TNM';

// for each file 
// get the classification for the file[i] 
var asset_i = ee.ImageCollection('projects/mapbiomas-workspace/TRANSVERSAIS/COLECAO7/agua')
  .toBands()
  .aside(print)
  .selfMask();
  
// Image area in km2
var pixelArea = ee.Image.pixelArea().divide(10000);

// Geometry to export
var geometry = asset_i.geometry();

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
        var image = asset_i.select(year + '-1_classification');
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

areas = ee.FeatureCollection(areas).flatten();

Export.table.toDrive({
    collection: areas,
    description: 'comunidades',
    folder: driverFolder,
    fileFormat: 'CSV'
});

*/
