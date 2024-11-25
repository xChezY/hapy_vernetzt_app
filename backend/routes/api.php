<?php

use App\Http\Controllers\FCMController;
use Illuminate\Support\Facades\Route;

Route::post('/send-device-token', [FCMController::class, 'sendDeviceToken']);