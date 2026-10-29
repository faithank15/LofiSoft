<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cloudinary
    |--------------------------------------------------------------------------
    | cloud_url   : cloudinary://api_key:api_secret@cloud_name (variable CLOUDINARY_URL)
    | folder      : dossier racine dans lequel les images sont rangées
    | max_size_kb : taille maximale d'une image envoyée (en Ko), 8192 = 8 Mo
    */

    'cloud_url' => env('CLOUDINARY_URL'),

    'folder' => env('CLOUDINARY_UPLOAD_FOLDER', 'lofisoft'),

    'max_size_kb' => (int) env('CLOUDINARY_MAX_SIZE_KB', 8192),

];
