<?php

use Illuminate\Support\Facades\Route;
use App\Models\FCMToken;
use App\Http\Controllers\FCMController;

Route::get('/', function () {
    return view('welcome');
});

//Das sollte später entfernt werden
Route::get('/clear', function () {
    FCMToken::truncate();
    return Response()->json(['message' => 'All tokens were deleted']);
});

//Das sollte später entfernt werden
Route::get('/send-message', [FCMController::class, 'sendMessage']);