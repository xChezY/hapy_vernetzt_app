<?php

use App\Http\Controllers\FCMController;
use App\Http\Middleware\EnsureApiTokenIsValid;
use Illuminate\Support\Facades\Route;

Route::post('/send-device-token', [FCMController::class, 'sendDeviceToken'])->middleware(EnsureApiTokenIsValid::class);