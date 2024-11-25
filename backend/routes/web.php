<?php

use Illuminate\Support\Facades\Route;
use App\Models\FCMToken;

Route::get('/', function () {
    return view('welcome');
});

//Das sollte später entfernt werden
Route::get('/clear', function () {
    FCMToken::truncate();
    return Response()->json(['message' => 'All tokens were deleted']);
});