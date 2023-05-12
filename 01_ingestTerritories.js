// prepare data
// create a image collection in which each territory is exported as a unique image containing their bounds and buffer zone
// dhemerson.costa@ipam.org.br

// input territories data as features
var input = ee.FeatureCollection('users/dh-conciani/help/tonomapa/vecs_aps_meso')//.limit(2);

// build auxiliary as image
var input_image = ee.Image(1).clip(input);
Map.addLayer(input_image);

// set buffer zone size
var buffer_size = 10000;

// set output imageCollection
var output = 'users/dh-conciani/help/tonomapa/sites';

// read input data
var data = ee.ImageCollection(
  input.map(function(feature) {
    // get ocjectid
    var obj = feature.get('OBJECTID');
    // compute buffer zone
    var buffer = feature.buffer(buffer_size)
      // and retain only difference (outer space)
      .difference(feature);
    // convert it to an image
    var image = ee.Image(1).clip(feature)
      .blend(ee.Image(2).clip(buffer))
      .set('territory', obj);
    
    // remove overlaps with other territories
    image = image.where(image.eq(2).and(input_image.eq(1)), 0).selfMask();
    
    return (image);
  })
);

print('raw', data);

// convert to list
var imageList = data.toList(data.size());

// export each image
for (var i = 0; i < imageList.length().getInfo(); i++) {
  var image = ee.Image(imageList.get(i));
  var count = i + 1;
  Export.image.toAsset({
        image: image,
        description: count.toString(),
        assetId: output + '/' + count.toString(),
        scale: 10,
        //region: image.geometry()
      });
}

/*
// vec
var vec = ee.FeatureCollection('users/dh-conciani/help/tonomapa/vecs_aps_meso');
var files_vec = vec.aggregate_array('OBJECTID');
print(files_vec);

// image
var image = ee.ImageCollection('users/dh-conciani/help/tonomapa/sites');
// get files in the image collection
var files_image = image.aggregate_array('territory');
print(files_image);

// Find the values that are unique 
var uniqueValues = files_vec.filter(ee.Filter.inList('item', files_image).not()).distinct();
print(uniqueValues);
*/
