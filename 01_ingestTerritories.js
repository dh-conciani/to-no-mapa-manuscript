// prepare data
// create a image collection in which each territory is exported as a unique image containing their bounds and buffer zone
// dhemerson.costa@ipam.org.br

// input territories data as features
var input = ee.FeatureCollection('users/dh-conciani/help/tonomapa/vecs_aps_meso').limit(5);

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
    
    return (image.rename('id_' + obj.toString()));
  })
);

print(data)
var x = data.toBands()
print(x)


/*
// convert to list
var imageList = data.toList(data.size()).getInfo();

// create a counter
var counter = 0;

// export each one
imageList.forEach(function(image) {
  counter = counter + 1;
  
    Export.image.toAsset({
      image: image,
      description: counter,
      assetId: output + '/' + counter,
      scale: 30,
      region: image.geometry()
    });
})
*/
