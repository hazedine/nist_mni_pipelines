#! /bin/sh


PREFIX=$(pwd)/../../python
PARALLEL=4

export PYTHONPATH=$PREFIX:$PYTHONPATH


cat - > library_description_ants.json <<END
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
  "non_linear_register": true,
  "resample_order": 2,
  "resample_baa": true,
  "non_linear_register_ants": true
}
END


if [ ! -e test_lib_ants/library.json ];then
# create the library
python -m scoop -n $PARALLEL $PREFIX/iplScoopFusionSegmentation.py  \
  --create library_description_ants.json --output test_lib_ants --debug
fi

# run cross-validation


cat - > cv_ants4.json <<END
{
  "validation_library":"seg_subjects.lst",
  "iterations":-1,
  "cv":1,
  "fuse_variant":"fuse",
  "ec_variant":"ec4",
  "cv_variant":"cv4"
}
END


cat - > segment_ants.json <<END
{
  "local_linear_register": true,
  "non_linear_pairwise": true,
  "non_linear_register": true,
  "non_linear_register_ants": true,
  "non_linear_pairwise_ants": true,

  "simple_fusion": false,
  "non_linear_register_level": 4,
  "pairwise_level": 4,

  "resample_order": 2,
  "resample_baa": true,
  "library_preselect": 3,
  "segment_symmetric": false,

  "fuse_options":
  {
      "patch": 1,
      "search": 1,
      "threshold": 0.0,
      "gco_diagonal": false,
      "gco_wlabel": 0.0001,
      "gco":true
  },

  "ec_options":
  {
        "method" : "lSVC",
        "method_n" : 100,
        "border_mask": true,
        "border_mask_width": 3,
        "use_coord": true,
        "use_joint": false,
        "use_patch": false,
        "normalize_input": false
  }
}
END

cat - > ec_train_ants4.json <<END
{
  "method" : "AdaBoost" ,
  "method_n" : 100 ,
  "border_mask": true ,
  "border_mask_width": 3,
  "use_coord": true ,
  "use_joint": true ,
  "patch_size": 1 ,
  "normalize_input": false,
  "use_raw": true ,
  "primary_features": 1,


  "antialias_labels": true,
  "blur_labels": 2,
  "expit_labels": 2,
  "normalize_labels": true,

  "split": null
}
END

python -m scoop -n $PARALLEL \
  $PREFIX/iplScoopFusionSegmentation.py \
   --output test_cv_ants \
   --debug  \
   --segment test_lib_ants \
   --cv cv_ants4.json \
   --options segment_ants.json \
   --train-ec ec_train_ants4.json

