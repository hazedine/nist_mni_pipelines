#! /bin/sh


PREFIX=$(pwd)/../../python

export PYTHONPATH=$PREFIX:$PYTHONPATH
PARALLEL=3

cat - > library_description_nl.json <<END
{
  "reference_model": "data/ellipse_0_blur.mnc",
  "reference_mask":  "data/ellipse_0_mask.mnc",
  "reference_local_model" : null,
  "reference_local_mask" :  null,
  "library":"seg_subjects.lst",
  "build_remap":         [ [1, 1], [2,2], [3,3], [4,4], [5,5], [6,6],  [7,7], [8,8] ],
  "build_flip_remap":    null,
  "parts": 0,
  "classes": 9,
  "build_symmetric": false,
  "build_symmetric_flip": false,
  "symmetric_lut": null,
  "denoise": false,
  "denoise_beta": null,
  "linear_register": false,
  "local_linear_register": true,
  "non_linear_register": false,
  "resample_order": 2,
  "resample_baa": true,
  "non_linear_register_level": 4
}
END


if [ ! -e test_lib_nl/library.json ];then
# create the library
python -m scoop -n $PARALLEL $PREFIX/iplScoopFusionSegmentation.py  \
  --create library_description_nl.json --output test_lib_nl --debug
fi

# run cross-validation

cat - > cv_nl.json <<END
{
  "validation_library":"seg_subjects.lst",
  "iterations":-1,
  "cv":1
}
END


cat - > segment_nl_ext.json <<END
{
  "local_linear_register": true,
  "non_linear_pairwise": false,
  "non_linear_register": false,

  "simple_fusion": false,
  "non_linear_register_level": 4,
  "pairwise_level": 4,

  "resample_order": 1,
  "resample_baa": true,
  "library_preselect": 3,
  "segment_symmetric": false,
  
  "generate_library": false,

  "fuse_options":
  {
      "ext":"cp {model_atlas} {output}",
      "gco":false
  }

}
END

python -m scoop -n $PARALLEL \
  $PREFIX/iplScoopFusionSegmentation.py \
   --output test_cv_nl_ext \
   --debug  \
   --segment test_lib_nl \
   --cv cv_nl.json \
   --options segment_nl_ext.json 

